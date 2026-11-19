// Shugah Net: anonymous lobby + WebRTC signaling for GPU Bandits on Cloudflare Workers Free.
//
//   POST /api/turn-credentials   -> short-lived Cloudflare Realtime TURN ice servers (4 h)
//   GET  /api/lobby/:code        -> WebSocket to that lobby's Durable Object (LobbyDO)
//
// The Worker never carries gameplay. A lobby DO only matches players and relays a few
// signaling messages (offer / answer / relay ICE candidates) per join, using the WebSocket
// Hibernation API so an idle lobby costs no compute. Every SDP and ICE candidate is scrubbed
// so only "typ relay" candidates (Cloudflare TURN addresses) ever reach another player.

export interface Env {
  LOBBY: DurableObjectNamespace;
  TURN_KEY_ID: string;
  TURN_API_TOKEN: string;
  APP_KEY?: string;
  TURN_LIMIT?: RateLimit;
  LOBBY_LIMIT?: RateLimit;
}

interface RateLimit {
  limit(opts: { key: string }): Promise<{ success: boolean }>;
}

const CODE_RE = /^[A-Z2-9]{6}$/;
const MAX_PLAYERS = 15; // 1 host + 14 clients
const TURN_TTL = 14400;
const MAX_MSG = 16 * 1024;

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

    if (url.pathname === "/" || url.pathname === "/health") return json({ ok: true, service: "shugah-net" });
    return json({ error: "not_found" }, 404);
  },
};

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

  constructor(ctx: DurableObjectState, _env: Env) {
    this.ctx = ctx;
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
    // every row goes; the empty table stays so this object can host the next lobby
    this.sql.exec("DELETE FROM meta");
  }

  async fetch(req: Request): Promise<Response> {
    if (this.ctx.getWebSockets().length >= MAX_PLAYERS + 2) return json({ error: "full" }, 503);
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
      await this.wipe();
      return;
    }
    const host_id = this.get("host_id");
    const host = host_id ? this.find(host_id) : null;
    if (host) this.send(host, { type: "peer_left", peer_id: me.peer_id, net_id: me.net_id });
  }
}
