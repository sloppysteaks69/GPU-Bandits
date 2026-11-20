// Shugah Net: anonymous lobby + WebRTC signaling for GPU Bandits on Cloudflare Workers Free.
//
//   POST /api/turn-credentials   -> short-lived Cloudflare Realtime TURN ice servers (4 h)
//   GET  /api/lobby/:code        -> WebSocket to that lobby's Durable Object (LobbyDO)
//   GET  /api/games              -> list of open games (one Directory DO, updated by hosts)
//   GET  /health                 -> ok + this billing month's TURN usage against the cap
//
// Spending guard: every 10 minutes (cron) the Worker asks Cloudflare's GraphQL analytics how
// many TURN bytes the whole account used since the billing month started. At TURN_CAP_GB
// (default 900 of the free 1,000 GB) it stops handing out TURN credentials until the next
// billing month, so no new game can start. If the usage check keeps failing for 2 hours it
// also stops (fails closed), because it can no longer see how much is used.
//
// The Worker never carries gameplay. A lobby DO only matches players and relays a few
// signaling messages (offer / answer / relay ICE candidates) per join, using the WebSocket
// Hibernation API so an idle lobby costs no compute. Every SDP and ICE candidate is scrubbed
// so only "typ relay" candidates (Cloudflare TURN addresses) ever reach another player.

export interface Env {
  LOBBY: DurableObjectNamespace;
  DIRECTORY: DurableObjectNamespace;
  TURN_KEY_ID: string;
  TURN_API_TOKEN: string;
  APP_KEY?: string;
  TURN_LIMIT?: RateLimit;
  LOBBY_LIMIT?: RateLimit;
  CF_ACCOUNT_ID?: string;       // secret: the account id (dashboard sidebar / Workers overview)
  CF_ANALYTICS_TOKEN?: string;  // secret: API token with only "Account Analytics: Read"
  TURN_CAP_GB?: string;         // var: stop at this many GB a billing month (default 900)
  BILLING_DAY?: string;         // var: day of month the Cloudflare billing month starts (1-28)
}

interface RateLimit {
  limit(opts: { key: string }): Promise<{ success: boolean }>;
}

const CODE_RE = /^[A-Z2-9]{6}$/;
const MAX_PLAYERS = 15; // 1 host + 14 clients
const TURN_TTL = 14400;
const MAX_MSG = 16 * 1024;
const GB = 1e9;
const CHECK_EVERY_MS = 10 * 60 * 1000;   // refresh usage on demand if older than this
const STALE_CLOSE_MS = 2 * 60 * 60 * 1000; // no good reading for this long -> stop

function json(body: unknown, status = 200, extra: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", "cache-control": "no-store", ...extra },
  });
}

function clientIp(req: Request): string {
  return req.headers.get("cf-connecting-ip") ?? "unknown";
}

function keyOk(req: Request, env: Env): boolean {
  if (!env.APP_KEY) return true;
  return req.headers.get("x-shugah-key") === env.APP_KEY;
}

async function limited(lim: RateLimit | undefined, key: string): Promise<boolean> {
  if (!lim) return false;
  try {
    const { success } = await lim.limit({ key });
    return !success;
  } catch {
    return false;
  }
}

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);

    if (url.pathname === "/api/turn-credentials") {
      if (req.method !== "POST") return json({ error: "method" }, 405);
      if (!keyOk(req, env)) return json({ error: "forbidden" }, 403);
      if (!(req.headers.get("x-shugah-client") ?? "").startsWith("gpu-bandits/"))
        return json({ error: "forbidden" }, 403);
      if (await limited(env.TURN_LIMIT, clientIp(req))) return json({ error: "slow_down" }, 429, { "retry-after": "60" });
      const u = await usage(env, "/usage");
      if (!u.open) return json({ error: u.reason, reopens: u.reopens }, 503);
      return turnCredentials(env);
    }

    const m = url.pathname.match(/^\/api\/lobby\/([A-Za-z0-9]{6})$/);
    if (m) {
      const code = m[1].toUpperCase();
      if (!CODE_RE.test(code)) return json({ error: "bad_code" }, 400);
      if (req.headers.get("upgrade")?.toLowerCase() !== "websocket") return json({ error: "websocket_only" }, 426);
      if (!keyOk(req, env) && url.searchParams.get("k") !== env.APP_KEY) return json({ error: "forbidden" }, 403);
      if (await limited(env.LOBBY_LIMIT, clientIp(req))) return json({ error: "slow_down" }, 429, { "retry-after": "60" });
      const stub = env.LOBBY.get(env.LOBBY.idFromName(code));
      return stub.fetch(req);
    }

    if (url.pathname === "/api/games") {
      if (req.method !== "GET") return json({ error: "method" }, 405);
      if (!keyOk(req, env)) return json({ error: "forbidden" }, 403);
      if (await limited(env.LOBBY_LIMIT, clientIp(req))) return json({ error: "slow_down" }, 429, { "retry-after": "60" });
      const dir = env.DIRECTORY.get(env.DIRECTORY.idFromName("directory"));
      return dir.fetch("https://dir/list");
    }

    if (url.pathname === "/" || url.pathname === "/health") {
      const u = await usage(env, "/usage");
      return json({ ok: true, service: "shugah-net", turn: u });
    }
    return json({ error: "not_found" }, 404);
  },

  async scheduled(_ev: unknown, env: Env, ctx: { waitUntil(p: Promise<unknown>): void }): Promise<void> {
    ctx.waitUntil(usage(env, "/usage/check"));
  },
};

interface Usage {
  open: boolean;
  reason?: string;
  guard: "on" | "off";
  used_gb?: number;
  cap_gb?: number;
  since?: string;
  reopens?: string;
  checked?: string;
}

async function usage(env: Env, op: string): Promise<Usage> {
  const dir = env.DIRECTORY.get(env.DIRECTORY.idFromName("directory"));
  const r = await dir.fetch("https://dir" + op, { method: "POST" });
  return (await r.json()) as Usage;
}

// The billing month that contains `now`, as [start, next start] dates (UTC).
function billingMonth(now: Date, day: number): [Date, Date] {
  let y = now.getUTCFullYear();
  let m = now.getUTCMonth();
  if (now.getUTCDate() < day) m -= 1;
  const start = new Date(Date.UTC(y, m, day));
  const next = new Date(Date.UTC(y, m + 1, day));
  return [start, next];
}

const ymd = (d: Date) => d.toISOString().slice(0, 10);

// Account-wide TURN bytes (both directions, so it can only over-count) since `from`.
async function turnBytesSince(env: Env, from: Date, to: Date): Promise<number> {
  const acct = String(env.CF_ACCOUNT_ID).replace(/[^0-9a-fA-F]/g, "");
  const q = `query { viewer { accounts(filter: { accountTag: "${acct}" }) {
    callsTurnUsageAdaptiveGroups(limit: 1, filter: { date_geq: "${ymd(from)}", date_leq: "${ymd(to)}" }) {
      sum { egressBytes ingressBytes } } } } }`;
  const r = await fetch("https://api.cloudflare.com/client/v4/graphql", {
    method: "POST",
    headers: { authorization: `Bearer ${env.CF_ANALYTICS_TOKEN}`, "content-type": "application/json" },
    body: JSON.stringify({ query: q }),
  });
  if (!r.ok) throw new Error("graphql http " + r.status);
  const d: any = await r.json();
  if (d.errors && d.errors.length) throw new Error("graphql " + JSON.stringify(d.errors).slice(0, 300));
  const groups = d?.data?.viewer?.accounts?.[0]?.callsTurnUsageAdaptiveGroups;
  if (!Array.isArray(groups)) throw new Error("graphql: no data");
  let total = 0;
  for (const g of groups) total += Number(g?.sum?.egressBytes ?? 0) + Number(g?.sum?.ingressBytes ?? 0);
  return total;
}

async function turnCredentials(env: Env): Promise<Response> {
  if (!env.TURN_KEY_ID || !env.TURN_API_TOKEN) return json({ error: "turn_not_configured" }, 500);
  const r = await fetch(
    `https://rtc.live.cloudflare.com/v1/turn/keys/${env.TURN_KEY_ID}/credentials/generate-ice-servers`,
    {
      method: "POST",
      headers: { authorization: `Bearer ${env.TURN_API_TOKEN}`, "content-type": "application/json" },
      body: JSON.stringify({ ttl: TURN_TTL }),
    },
  );
  if (!r.ok) return json({ error: "turn_upstream", status: r.status }, 502);
  const data = (await r.json()) as { iceServers?: unknown };
  // Only TURN urls go to the client: no STUN, so nothing ever asks for a public address.
  const raw = Array.isArray(data.iceServers) ? data.iceServers : data.iceServers ? [data.iceServers] : [];
  const iceServers = raw
    .map((s: any) => {
      const urls = (Array.isArray(s.urls) ? s.urls : [s.urls]).filter(
        (u: unknown) => typeof u === "string" && (u.startsWith("turn:") || u.startsWith("turns:")),
      );
      return { urls, username: s.username, credential: s.credential };
    })
    .filter((s: any) => s.urls.length > 0);
  return json({ iceServers, ttl: TURN_TTL, iceTransportPolicy: "relay" });
}

// ---------------------------------------------------------------------------------------------
// Privacy filter: only relay candidates survive, and connection lines never carry a real IP.

// A relay candidate's "raddr" is the player's own public address as TURN saw it: blank it.
function scrubRaddr(line: string): string {
  return line.replace(/ raddr \S+ rport \d+/g, " raddr 0.0.0.0 rport 0");
}

export function cleanCandidate(c: unknown): string | null {
  if (typeof c !== "string" || c.length > 1024) return null;
  const s = c.trim();
  if (!/\btyp relay\b/.test(s)) return null;
  return scrubRaddr(s);
}

export function cleanSdp(sdp: unknown): string | null {
  if (typeof sdp !== "string" || sdp.length > MAX_MSG) return null;
  const out: string[] = [];
  for (const line of sdp.split(/\r?\n/)) {
    if (line.startsWith("a=candidate:") || line.startsWith("candidate:")) {
      if (/\btyp relay\b/.test(line)) out.push(scrubRaddr(line));
      continue;
    }
    if (line.startsWith("c=IN IP4 ")) { out.push("c=IN IP4 0.0.0.0"); continue; }
    if (line.startsWith("c=IN IP6 ")) { out.push("c=IN IP6 ::"); continue; }
    if (line.startsWith("a=rtcp:")) continue;
    out.push(line);
  }
  return out.join("\r\n");
}

// ---------------------------------------------------------------------------------------------

interface Att {
  peer_id: string;
  net_id: number; // the game's multiplayer id: host = 1, clients 2..
  role: "host" | "client";
}

function rid(): string {
  const b = new Uint8Array(4);
  crypto.getRandomValues(b);
  return "p_" + Array.from(b, (x) => x.toString(16).padStart(2, "0")).join("");
}

export class LobbyDO {
  ctx: DurableObjectState;
  sql: SqlStorage;

  env: Env;

  constructor(ctx: DurableObjectState, env: Env) {
    this.ctx = ctx;
    this.env = env;
    this.sql = ctx.storage.sql;
    this.sql.exec("CREATE TABLE IF NOT EXISTS meta (k TEXT PRIMARY KEY, v TEXT NOT NULL)");
  }

  get(k: string): string | null {
    const rows = this.sql.exec("SELECT v FROM meta WHERE k = ?", k).toArray();
    return rows.length ? (rows[0].v as string) : null;
  }

  set(k: string, v: string): void {
    this.sql.exec("INSERT INTO meta (k, v) VALUES (?, ?) ON CONFLICT(k) DO UPDATE SET v = excluded.v", k, v);
  }

  async wipe(): Promise<void> {
    // every row goes (except this lobby's own code); the empty table stays for the next lobby
    this.sql.exec("DELETE FROM meta WHERE k != 'code'");
  }

  async fetch(req: Request): Promise<Response> {
    if (this.ctx.getWebSockets().length >= MAX_PLAYERS + 2) return json({ error: "full" }, 503);
    const m = new URL(req.url).pathname.match(/\/api\/lobby\/([A-Za-z0-9]{6})$/);
    if (m) this.set("code", m[1].toUpperCase());
    const pair = new WebSocketPair();
    const [client, server] = [pair[0], pair[1]];
    this.ctx.acceptWebSocket(server); // hibernatable: no listeners, no timers
    return new Response(null, { status: 101, webSocket: client });
  }

  att(ws: WebSocket): Att | null {
    return (ws.deserializeAttachment() as Att | null) ?? null;
  }

  find(peer_id: string): WebSocket | null {
    for (const ws of this.ctx.getWebSockets()) if (this.att(ws)?.peer_id === peer_id) return ws;
    return null;
  }

  send(ws: WebSocket, msg: unknown): void {
    try { ws.send(JSON.stringify(msg)); } catch { /* socket already gone */ }
  }

  async webSocketMessage(ws: WebSocket, data: string | ArrayBuffer): Promise<void> {
    if (typeof data !== "string" || data.length > MAX_MSG) return this.fail(ws, "bad_message");
    let msg: any;
    try { msg = JSON.parse(data); } catch { return this.fail(ws, "bad_json"); }
    const me = this.att(ws);

    if (msg.type === "join") {
      if (me) return;
      const host_id = this.get("host_id");
      if (msg.role === "host") {
        if (host_id && this.find(host_id)) return this.fail(ws, "code_in_use");
        await this.wipe();
        const a: Att = { peer_id: rid(), net_id: 1, role: "host" };
        ws.serializeAttachment(a);
        this.set("host_id", a.peer_id);
        this.set("next_net", "2");
        this.set("state", "OPEN");
        this.send(ws, { type: "welcome", peer_id: a.peer_id, net_id: 1, host_id: a.peer_id, peers: [] });
        return;
      }
      if (msg.role !== "client") return this.fail(ws, "bad_role");
      const host = host_id ? this.find(host_id) : null;
      if (!host) return this.fail(ws, "no_such_lobby");
      if (this.get("state") !== "OPEN") return this.fail(ws, "lobby_closed");
      const count = this.ctx.getWebSockets().filter((w) => this.att(w)).length + Number(this.get("ready") ?? "0");
      if (count >= MAX_PLAYERS) return this.fail(ws, "lobby_full");
      const net = Number(this.get("next_net") ?? "2");
      this.set("next_net", String(net + 1));
      const a: Att = { peer_id: rid(), net_id: net, role: "client" };
      ws.serializeAttachment(a);
      this.send(ws, { type: "welcome", peer_id: a.peer_id, net_id: net, host_id, peers: [host_id] });
      this.send(host, { type: "peer_joined", peer_id: a.peer_id, net_id: net });
      return;
    }

    if (!me) return this.fail(ws, "join_first");

    if (msg.type === "sdp_offer" || msg.type === "sdp_answer" || msg.type === "ice_candidate") {
      // star topology: clients only talk to the host, the host talks to anyone
      const host_id = this.get("host_id");
      if (me.role === "client" && msg.target_id !== host_id) return;
      const target = typeof msg.target_id === "string" ? this.find(msg.target_id) : null;
      if (!target) return this.send(ws, { type: "peer_gone", peer_id: msg.target_id });
      if (msg.type === "ice_candidate") {
        const c = cleanCandidate(msg.candidate);
        if (!c) return; // dropped: not a relay candidate
        const mid = typeof msg.mid === "string" ? msg.mid.slice(0, 32) : "0";
        const index = Number.isInteger(msg.index) ? msg.index : 0;
        return this.send(target, { type: "ice_candidate", from_id: me.peer_id, candidate: c, mid, index });
      }
      const sdp = cleanSdp(msg.sdp);
      if (!sdp) return;
      return this.send(target, { type: msg.type, from_id: me.peer_id, net_id: me.net_id, sdp });
    }

    if (msg.type === "p2p_ready") {
      // the client is connected over TURN; it closes its socket right after this
      if (me.role === "client") {
        this.set("ready", String(Number(this.get("ready") ?? "0") + 1));
        ws.serializeAttachment(null);
        try { ws.close(1000, "ready"); } catch { /* ignore */ }
      }
      return;
    }

    if (msg.type === "set_info" && me.role === "host") {
      // what the game list shows: host name, mode, player count, lobby or playing, version
      const info = {
        code: this.get("code") ?? "",
        name: String(msg.name ?? "").slice(0, 32),
        mode: String(msg.mode ?? "").slice(0, 24),
        players: Math.max(0, Math.min(MAX_PLAYERS, Number(msg.players) || 0)),
        max: MAX_PLAYERS,
        playing: !!msg.playing,
        ver: String(msg.ver ?? "").slice(0, 16),
      };
      if (info.code) await this.dir("put", info);
      return;
    }

    if (msg.type === "set_state" && me.role === "host") {
      if (msg.state === "OPEN" || msg.state === "IN_GAME") this.set("state", msg.state);
      return;
    }

    if (msg.type === "peer_left" && me.role === "host") {
      // a connected player quit the game: free their slot
      this.set("ready", String(Math.max(0, Number(this.get("ready") ?? "0") - 1)));
      return;
    }
  }

  async dir(op: "put" | "del", body: Record<string, unknown>): Promise<void> {
    try {
      const d = this.env.DIRECTORY.get(this.env.DIRECTORY.idFromName("directory"));
      await d.fetch("https://dir/" + op, { method: "POST", body: JSON.stringify(body) });
    } catch { /* the list is best-effort */ }
  }

  fail(ws: WebSocket, error: string): void {
    this.send(ws, { type: "error", error });
    try { ws.close(4000, error); } catch { /* ignore */ }
  }

  async webSocketClose(ws: WebSocket, code: number, _reason: string, _clean: boolean): Promise<void> {
    await this.gone(ws);
    try { ws.close(code === 1005 ? 1000 : code, "bye"); } catch { /* ignore */ }
  }

  async webSocketError(ws: WebSocket): Promise<void> {
    await this.gone(ws);
  }

  async gone(ws: WebSocket): Promise<void> {
    const me = this.att(ws);
    if (!me) return;
    ws.serializeAttachment(null);
    if (me.role === "host") {
      // host left: the lobby is over, tell anyone still signaling and forget everything
      for (const w of this.ctx.getWebSockets()) {
        if (w !== ws && this.att(w)) {
          this.send(w, { type: "host_left" });
          try { w.close(1000, "host_left"); } catch { /* ignore */ }
        }
      }
      const code = this.get("code");
      if (code) await this.dir("del", { code });
      await this.wipe();
      return;
    }
    const host_id = this.get("host_id");
    const host = host_id ? this.find(host_id) : null;
    if (host) this.send(host, { type: "peer_left", peer_id: me.peer_id, net_id: me.net_id });
  }
}

// ---------------------------------------------------------------------------------------------
// Directory: one Durable Object holding the list of open games. Hosts' lobbies put / delete
// their row; players read the list when they open JOIN A GAME (no polling, no timers).

const STALE_MS = 12 * 3600 * 1000;

export class Directory {
  ctx: DurableObjectState;
  sql: SqlStorage;

  env: Env;

  constructor(ctx: DurableObjectState, env: Env) {
    this.ctx = ctx;
    this.env = env;
    this.sql = ctx.storage.sql;
    this.sql.exec(
      "CREATE TABLE IF NOT EXISTS games (code TEXT PRIMARY KEY, name TEXT, mode TEXT, players INTEGER, max INTEGER, playing INTEGER, ver TEXT, updated INTEGER)",
    );
    this.sql.exec("CREATE TABLE IF NOT EXISTS usage (k TEXT PRIMARY KEY, v TEXT NOT NULL)");
  }

  uget(k: string): string | null {
    const rows = this.sql.exec("SELECT v FROM usage WHERE k = ?", k).toArray();
    return rows.length ? String(rows[0].v) : null;
  }

  uset(k: string, v: string): void {
    this.sql.exec("INSERT INTO usage (k, v) VALUES (?, ?) ON CONFLICT(k) DO UPDATE SET v = excluded.v", k, v);
  }

  // Spending guard state. force = run the analytics query now (cron); otherwise only when the
  // last reading is older than CHECK_EVERY_MS.
  async usage(force: boolean): Promise<Usage> {
    const env = this.env;
    if (!env.CF_ACCOUNT_ID || !env.CF_ANALYTICS_TOKEN) return { open: true, guard: "off" };
    const capGb = Math.max(1, Number(env.TURN_CAP_GB) || 900);
    const day = Math.min(28, Math.max(1, Math.floor(Number(env.BILLING_DAY) || 1)));
    const now = new Date();
    const [start, next] = billingMonth(now, day);
    const period = ymd(start);
    if (this.uget("period") !== period) {
      // new billing month: forget last month's numbers
      this.uset("period", period);
      this.uset("used", "0");
      this.uset("good_at", "0");
    }
    const goodAt = Number(this.uget("good_at") ?? 0);
    const tryAt = Number(this.uget("try_at") ?? 0);
    if (force || (Date.now() - goodAt > CHECK_EVERY_MS && Date.now() - tryAt > 60_000)) {
      this.uset("try_at", String(Date.now()));
      try {
        const used = await turnBytesSince(env, start, now);
        this.uset("used", String(used));
        this.uset("good_at", String(Date.now()));
        this.uset("err", "");
      } catch (e) {
        this.uset("err", String(e).slice(0, 300));
      }
    }
    const used = Number(this.uget("used") ?? 0);
    const good = Number(this.uget("good_at") ?? 0);
    const base: Usage = {
      open: true,
      guard: "on",
      used_gb: Math.round((used / GB) * 100) / 100,
      cap_gb: capGb,
      since: period,
      reopens: ymd(next),
      checked: good ? new Date(good).toISOString() : "never",
    };
    if (used >= capGb * GB) return { ...base, open: false, reason: "monthly_cap" };
    if (Date.now() - good > STALE_CLOSE_MS) {
      const err = this.uget("err") ?? "";
      return { ...base, open: false, reason: "usage_unknown", ...(err ? { error: err } : {}) } as Usage;
    }
    return base;
  }

  async fetch(req: Request): Promise<Response> {
    const op = new URL(req.url).pathname;
    if (op === "/usage" || op === "/usage/check") return json(await this.usage(op === "/usage/check"));
    if (op === "/list") {
      this.sql.exec("DELETE FROM games WHERE updated < ?", Date.now() - STALE_MS);
      const games = this.sql
        .exec("SELECT code, name, mode, players, max, playing, ver FROM games ORDER BY updated DESC LIMIT 100")
        .toArray()
        .map((r) => ({ ...r, playing: !!r.playing }));
      return json({ games });
    }
    let b: any;
    try { b = await req.json(); } catch { return json({ error: "bad_json" }, 400); }
    const code = String(b.code ?? "").toUpperCase();
    if (!CODE_RE.test(code)) return json({ error: "bad_code" }, 400);
    if (op === "/put") {
      this.sql.exec(
        "INSERT INTO games (code, name, mode, players, max, playing, ver, updated) VALUES (?, ?, ?, ?, ?, ?, ?, ?) " +
          "ON CONFLICT(code) DO UPDATE SET name = excluded.name, mode = excluded.mode, players = excluded.players, " +
          "max = excluded.max, playing = excluded.playing, ver = excluded.ver, updated = excluded.updated",
        code, String(b.name ?? ""), String(b.mode ?? ""), Number(b.players) || 0, Number(b.max) || MAX_PLAYERS,
        b.playing ? 1 : 0, String(b.ver ?? ""), Date.now(),
      );
      return json({ ok: true });
    }
    if (op === "/del") {
      this.sql.exec("DELETE FROM games WHERE code = ?", code);
      return json({ ok: true });
    }
    return json({ error: "not_found" }, 404);
  }
}
