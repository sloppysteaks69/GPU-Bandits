# Shugah Net

Shugah Net is the anonymous lobby and signaling service behind GPU Bandits' **SHUGAH NET ONLINE** button. It runs on the Cloudflare Workers Free plan.

## How it works

- The **host** presses HOST ONLINE and gets a 6-character lobby code. **Players** type that code and press JOIN ONLINE.
- The Worker does two jobs:
  - It hands out 4-hour Cloudflare Realtime TURN credentials.
  - It relays a few WebRTC signaling messages per join through a SQLite-backed Durable Object. The Durable Object uses the WebSocket Hibernation API, so it uses no compute while idle.
- Every WebRTC connection is relay-only. Each side only ever sends `typ relay` candidates, and the Durable Object strips anything else, as a second layer of protection:
  - `host` and `srflx` candidates are removed.
  - `raddr` (your public IP as TURN saw it) is blanked.
  - `c=` lines are set to `0.0.0.0`.

  Players only ever see Cloudflare's addresses.
- Gameplay goes straight over WebRTC data channels through Cloudflare TURN, never through the Worker. Godot's `WebRTCMultiplayerPeer` provides a reliable ordered channel and unreliable channels, and the game's normal RPCs run on top.
- `GET /api/games` lists open lobbies (name, mode, player count, in lobby or playing) from a small Directory Durable Object, so players can pick a game instead of typing a code. The host updates its entry every few seconds and removes it when it leaves; entries older than 12 hours are dropped. Players who join a game in progress spectate until the next round.
- A client closes its signaling socket as soon as it is connected. The host keeps its socket open while it hosts, so new players can still join.

### Cost

About 5–8 Worker/Durable Object requests per player join. Incoming WebSocket messages are billed at 20:1, so the Free limit of 100,000 requests a day covers thousands of joins.

TURN usage is billed separately by Cloudflare Realtime, and its free allowance is generous. Check your dashboard for current limits.

## Deploy (one time)

1. Create a TURN key: in the Cloudflare dashboard, go to **Realtime → TURN Server → Create**. Note the **Key ID** and **API token**.
2. Install and log in. This needs Node.js 18 or newer:
   ```
   cd shugah-net
   npm install
   npx wrangler login
   ```
3. Add the secrets. Each command asks you to paste the value:
   ```
   npx wrangler secret put TURN_KEY_ID
   npx wrangler secret put TURN_API_TOKEN
   npx wrangler secret put APP_KEY      # optional: makes random people's requests fail
   ```
4. Deploy:
   ```
   npx wrangler deploy
   ```
   If you deployed 1.2.0 before, run `npx wrangler deploy` again for 1.2.1: it adds the game list (migration v2).
   Wrangler prints the address, for example `https://shugah-net.<your-subdomain>.workers.dev`.
5. In the game, open SHUGAH NET ONLINE and paste that address into **Shugah Net server**. It is remembered.
   - To build it in instead, set `SHUGAH_URL` near the top of the Shugah Net section in `scripts/main.gd`.
   - If you set an `APP_KEY`, also set it in `shugah_net.gd` (`app_key`).

## Test locally

```
npx wrangler dev                 # http://localhost:8787
curl localhost:8787/health
```

`/api/turn-credentials` needs the real TURN secrets. For local testing, put them in a `.dev.vars` file:

```
TURN_KEY_ID=...
TURN_API_TOKEN=...
```

Never commit `.dev.vars`.

Lobby sockets work locally with no secrets: `ws://localhost:8787/api/lobby/ABC234`.

## Signaling protocol (JSON over WebSocket)

| From | Message |
|---|---|
| client/host → DO | `{"type":"join","role":"host"|"client"}` |
| DO → joiner | `{"type":"welcome","peer_id","net_id","host_id","peers"}`. The host gets net_id 1; clients get 2, 3, … (the game's peer ids). |
| DO → host | `{"type":"peer_joined","peer_id","net_id"}` |
| host ↔ client | `sdp_offer` / `sdp_answer` `{target_id, sdp}`, `ice_candidate` `{target_id, candidate, mid, index}`. Relayed with `from_id` and scrubbed. |
| client → DO | `{"type":"p2p_ready"}`, then the client closes its socket |
| host → DO | `{"type":"peer_left","net_id"}` (frees a slot), `{"type":"set_state","state":"OPEN"|"IN_GAME"}`, `{"type":"set_info","info":{name,mode,players,playing,ver}}` (game list entry) |
| DO → anyone | `{"type":"error","error":"no_such_lobby"|"lobby_full"|"code_in_use"|...}`, `host_left`, `peer_left` |

The maximum is 15 players per lobby: 1 host and 14 clients.

## Game side

The game client is `scripts/shugah_net.gd`. It needs the official Godot **webrtc-native** GDExtension (from godotengine/webrtc-native) in the project's `webrtc/` folder, because desktop builds of Godot don't include WebRTC by themselves. Its DLL ships next to `GPU Bandits.exe`.
