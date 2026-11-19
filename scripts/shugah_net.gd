extends Node

# Shugah Net Online (1.2.0): play over the internet with nobody seeing anybody's IP address.
#
#   1. POST <server>/api/turn-credentials  -> short-lived Cloudflare TURN servers
#   2. WebSocket <server>/api/lobby/<CODE> -> the lobby's signaling room (Cloudflare Worker)
#   3. WebRTC connections that may ONLY use Cloudflare TURN relay candidates, so every player
#      sees Cloudflare's addresses, never another player's. Gameplay goes straight over WebRTC
#      data channels (Godot's WebRTCMultiplayerPeer: reliable + unreliable channels), the Worker
#      only carries the few join messages.
#   4. A client closes its signaling socket as soon as it is connected. The host keeps its socket
#      open while it hosts, so new players can still find it.
#
# The game's normal rpc code runs unchanged on top: host = peer 1, clients get 2, 3, ...
# Needs the webrtc-native GDExtension (webrtc/ folder) on desktop builds.

signal hosted(code: String)
signal joined()
signal failed(msg: String)
signal progress(msg: String)
signal games_listed(games: Array, err: String)

const CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const CONNECT_TIMEOUT = 25.0

var server_url = ""          # e.g. https://shugah-net.yourname.workers.dev
var app_key = ""             # optional, must match the Worker's APP_KEY secret
var client_tag = "gpu-bandits/0"

var rtc: WebRTCMultiplayerPeer
var ws: WebSocketPeer
var ws_open = false
var is_host = false
var code = ""
var my_peer = ""
var host_peer = ""
var net_id = 0
var ice_servers = []
var conns = {}               # peer_id (string) -> {"pc": WebRTCPeerConnection, "net": int}
var pending = []             # messages to send once the socket opens
var mode = ""                # "", "host", "join"
var wait_t = 0.0
var connected = false
var http: HTTPRequest
var host_retry = 0
var list_http: HTTPRequest
var info_last = {}
var info_dirty = {}
var info_t = 0.0
const INFO_GAP = 4.0         # the host updates its game-list row at most this often


# Ask for the list of open games (one request; the player presses REFRESH for more).
func list_games() -> void:
	if server_url.strip_edges() == "":
		games_listed.emit([], "Set the Shugah Net server address first.")
		return
	if list_http == null:
		list_http = HTTPRequest.new()
		list_http.timeout = 10.0
		add_child(list_http)
		list_http.request_completed.connect(_on_list)
	list_http.cancel_request()
	var h = PackedStringArray(["X-Shugah-Client: " + client_tag])
	if app_key != "":
		h.append("X-Shugah-Key: " + app_key)
	if list_http.request(_base() + "/api/games", h) != OK:
		games_listed.emit([], "Could not reach Shugah Net.")


func _on_list(result: int, status: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or status != 200:
		games_listed.emit([], "Shugah Net is not answering (%s)." % ("HTTP %d" % status if result == HTTPRequest.RESULT_SUCCESS else "no connection, code %d" % result))
		return
	var d = JSON.parse_string(body.get_string_from_utf8())
	if typeof(d) != TYPE_DICTIONARY or typeof(d.get("games")) != TYPE_ARRAY:
		games_listed.emit([], "Shugah Net sent a bad game list.")
		return
	games_listed.emit(d.games, "")


# Host: what the game list should say about this game. Sent only when it changes, and at most
# every INFO_GAP seconds, to stay far inside the free plan.
func update_info(info: Dictionary) -> void:
	if not is_host or mode != "host":
		return
	if info != info_last:
		info_dirty = info.duplicate()


func available() -> bool:
	return ClassDB.class_exists("WebRTCPeerConnection") and _rtc_ok()


func _rtc_ok() -> bool:
	var pc = WebRTCPeerConnection.new()
	var ok = pc.initialize({}) == OK
	pc.close()
	return ok


func host_lobby() -> void:
	_reset()
	mode = "host"
	is_host = true
	code = _new_code()
	_get_turn()


func join_lobby(lobby_code: String) -> void:
	_reset()
	mode = "join"
	is_host = false
	code = lobby_code.strip_edges().to_upper()
	if code.length() != 6:
		_fail("Lobby codes are 6 letters and numbers.")
		return
	_get_turn()


# A player left the game: free their lobby slot.
func player_left(id: int) -> void:
	if is_host and ws_open:
		_send({"type": "peer_left", "net_id": id})


func set_in_game(on: bool) -> void:
	if is_host and ws_open:
		_send({"type": "set_state", "state": "IN_GAME" if on else "OPEN"})


func close() -> void:
	_reset()


func _reset() -> void:
	if ws != null:
		ws.close()
	ws = null
	ws_open = false
	for k in conns:
		conns[k].pc.close()
	conns.clear()
	pending.clear()
	rtc = null
	mode = ""
	connected = false
	info_last = {}
	info_dirty = {}
	info_t = 0.0
	my_peer = ""
	host_peer = ""
	net_id = 0
	wait_t = 0.0
	if http != null:
		http.cancel_request()


func _new_code() -> String:
	var s = ""
	for i in 6:
		s += CODE_CHARS[randi() % CODE_CHARS.length()]
	return s


func _fail(msg: String) -> void:
	_reset()
	failed.emit(msg)


func _base() -> String:
	var u = server_url.strip_edges()
	while u.ends_with("/"):
		u = u.left(u.length() - 1)
	if not u.begins_with("http"):
		u = "https://" + u
	return u


func _get_turn() -> void:
	if server_url.strip_edges() == "":
		_fail("Set the Shugah Net server address first.")
		return
	progress.emit("Getting relay servers...")
	if http == null:
		http = HTTPRequest.new()
		http.timeout = 15.0
		add_child(http)
		http.request_completed.connect(_on_turn)
	var h = PackedStringArray(["Content-Type: application/json", "X-Shugah-Client: " + client_tag])
	if app_key != "":
		h.append("X-Shugah-Key: " + app_key)
	var err = http.request(_base() + "/api/turn-credentials", h, HTTPClient.METHOD_POST, "{}")
	if err != OK:
		_fail("Could not reach Shugah Net.")


func _on_turn(result: int, status: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if mode == "":
		return
	if result != HTTPRequest.RESULT_SUCCESS or status != 200:
		_fail("Shugah Net is not answering (%s)." % ("HTTP %d" % status if result == HTTPRequest.RESULT_SUCCESS else "no connection, code %d" % result))
		return
	var d = JSON.parse_string(body.get_string_from_utf8())
	if typeof(d) != TYPE_DICTIONARY or not d.has("iceServers"):
		_fail("Shugah Net sent no relay servers.")
		return
	ice_servers = []
	for s in d.iceServers:
		var urls = []
		for u in (s.urls if typeof(s.urls) == TYPE_ARRAY else [s.urls]):
			if str(u).begins_with("turn"):
				urls.append(str(u))
		if not urls.is_empty():
			ice_servers.append({"urls": urls, "username": str(s.get("username", "")), "credential": str(s.get("credential", ""))})
	if ice_servers.is_empty():
		_fail("Shugah Net sent no relay servers.")
		return
	_open_socket()


func _open_socket() -> void:
	progress.emit("Opening lobby %s..." % code)
	ws = WebSocketPeer.new()
	ws.inbound_buffer_size = 1 << 17
	var url = _base().replace("https://", "wss://").replace("http://", "ws://") + "/api/lobby/" + code
	if app_key != "":
		url += "?k=" + app_key.uri_encode()
	var err = ws.connect_to_url(url)
	if err != OK:
		_fail("Could not open the lobby connection.")
		return
	ws_open = false
	wait_t = 0.0
	_send({"type": "join", "role": "host" if is_host else "client"})


func _send(msg: Dictionary) -> void:
	if ws == null:
		return
	if not ws_open:
		pending.append(msg)
		return
	ws.send_text(JSON.stringify(msg))


func _process(dt: float) -> void:
	info_t -= dt
	if not info_dirty.is_empty() and info_t <= 0.0 and ws_open and is_host:
		info_last = info_dirty
		info_dirty = {}
		info_t = INFO_GAP
		var m = info_last.duplicate()
		m["type"] = "set_info"
		_send(m)
	if ws != null:
		ws.poll()
		var st = ws.get_ready_state()
		if st == WebSocketPeer.STATE_OPEN:
			if not ws_open:
				ws_open = true
				for m in pending:
					ws.send_text(JSON.stringify(m))
				pending.clear()
			while ws != null and ws.get_available_packet_count() > 0:
				var d = JSON.parse_string(ws.get_packet().get_string_from_utf8())
				if typeof(d) == TYPE_DICTIONARY:
					_on_msg(d)
		elif st == WebSocketPeer.STATE_CLOSED:
			var was_open = ws_open
			ws = null
			ws_open = false
			if mode == "join" and not connected:
				_fail("Lost the lobby connection before joining.")
			elif mode == "host" and not was_open:
				_fail("Could not reach Shugah Net.")
	if mode == "join" and not connected:
		wait_t += dt
		if wait_t > CONNECT_TIMEOUT:
			_fail("Timed out connecting through the relay.")


func _on_msg(d: Dictionary) -> void:
	match str(d.get("type", "")):
		"welcome":
			my_peer = str(d.peer_id)
			host_peer = str(d.get("host_id", ""))
			net_id = int(d.net_id)
			rtc = WebRTCMultiplayerPeer.new()
			if is_host:
				rtc.create_server()
				multiplayer.multiplayer_peer = rtc
				hosted.emit(code)
			else:
				rtc.create_client(net_id)
				multiplayer.multiplayer_peer = rtc
				_new_conn(host_peer, 1)
				progress.emit("Connecting through the relay...")
		"peer_joined":
			if is_host and rtc != null:
				var c = _new_conn(str(d.peer_id), int(d.net_id))
				if c != null:
					c.pc.create_offer()
		"sdp_offer":
			if not is_host and conns.has(str(d.from_id)):
				conns[str(d.from_id)].pc.set_remote_description("offer", _clean_sdp(str(d.sdp)))
		"sdp_answer":
			if is_host and conns.has(str(d.from_id)):
				conns[str(d.from_id)].pc.set_remote_description("answer", _clean_sdp(str(d.sdp)))
		"ice_candidate":
			var cand = str(d.get("candidate", ""))
			if conns.has(str(d.from_id)) and _is_relay(cand):
				conns[str(d.from_id)].pc.add_ice_candidate(str(d.get("mid", "0")), int(d.get("index", 0)), cand)
		"peer_left", "peer_gone":
			var pid = str(d.get("peer_id", ""))
			if conns.has(pid) and is_host:
				var nid = conns[pid].net
				conns.erase(pid)
				if rtc != null and rtc.has_peer(nid) and rtc.get_peer(nid).connected == false:
					rtc.remove_peer(nid)
		"host_left":
			if not connected:
				_fail("The host closed the lobby.")
		"error":
			var e = str(d.get("error", ""))
			if e == "code_in_use" and is_host and host_retry < 3:
				host_retry += 1
				host_lobby()
				return
			var why = {"no_such_lobby": "No lobby with that code.", "lobby_full": "That lobby is full.", "lobby_closed": "That game has already started.", "slow_down": "Too many tries - wait a minute."}
			_fail(why.get(e, "Shugah Net said: " + e))


func _new_conn(peer_id: String, nid: int):
	var pc = WebRTCPeerConnection.new()
	# relay only: Cloudflare TURN is the sole way in or out, so no player's IP is ever shared
	var err = pc.initialize({"iceServers": ice_servers, "iceTransportPolicy": "relay"})
	if err != OK:
		_fail("WebRTC is not available in this build.")
		return null
	pc.session_description_created.connect(_on_sdp.bind(peer_id, pc))
	pc.ice_candidate_created.connect(_on_ice.bind(peer_id))
	rtc.add_peer(pc, nid)
	conns[peer_id] = {"pc": pc, "net": nid}
	return conns[peer_id]


func _on_sdp(type: String, sdp: String, peer_id: String, pc: WebRTCPeerConnection) -> void:
	pc.set_local_description(type, sdp)
	_send({"type": "sdp_offer" if type == "offer" else "sdp_answer", "target_id": peer_id, "sdp": _clean_sdp(sdp)})


func _on_ice(media: String, index: int, cand: String, peer_id: String) -> void:
	# only relay candidates ever leave this machine
	if _is_relay(cand):
		_send({"type": "ice_candidate", "target_id": peer_id, "candidate": _scrub(cand), "mid": media, "index": index})


func _is_relay(cand: String) -> bool:
	return cand.find(" typ relay") >= 0


# A relay candidate carries "raddr <our public IP>": blank it before it leaves this machine.
func _scrub(line: String) -> String:
	var i = line.find(" raddr ")
	if i < 0:
		return line
	var rest = line.substr(i + 7).split(" ")
	var tail = ""
	if rest.size() >= 3 and rest[1] == "rport":
		tail = " ".join(rest.slice(3))
	return line.left(i) + " raddr 0.0.0.0 rport 0" + (" " + tail if tail != "" else "")


func _clean_sdp(sdp: String) -> String:
	var out = PackedStringArray()
	for line in sdp.replace("\r\n", "\n").split("\n"):
		if line.begins_with("a=candidate:"):
			if _is_relay(line):
				out.append(_scrub(line))
			continue
		if line.begins_with("c=IN IP4 "):
			out.append("c=IN IP4 0.0.0.0")
			continue
		if line.begins_with("c=IN IP6 "):
			out.append("c=IN IP6 ::")
			continue
		if line.begins_with("a=rtcp:"):
			continue
		out.append(line)
	return "\r\n".join(out)


# Called by main when the multiplayer layer says we are in.
func on_connected() -> void:
	if mode == "join" and not connected:
		connected = true
		_send({"type": "p2p_ready"})
		if ws != null:
			ws.close()
		joined.emit()
