extends Control


const MENU = 0
const LOBBY = 1
const PLAYING = 2
const RESULTS = 3

var m
var font: Font
var title_font: Font
const TitleFill = preload("res://scripts/title_fill.gd")
const TITLE_BANDS = 24

const TITLE_STOPS = [Color(1.0, 0.93, 0.3), Color(1.0, 0.55, 0.08), Color(0.85, 0.1, 0.08)]
var bands = []
var btns = {}
const GOLD = Color(1.0, 0.85, 0.3)
const LIT = Color(1.0, 0.97, 0.6)


func _ready() -> void:
	font = ThemeDB.fallback_font


	var sf = SystemFont.new()
	sf.font_names = PackedStringArray(["Eurostile Extended", "Microgramma D Extended", "Bank Gothic", "BankGothic Md BT", "Segoe UI Black", "Arial Black", "Verdana"])
	sf.font_weight = 900
	title_font = sf
	for i in TITLE_BANDS:
		var b = TitleFill.new()
		b.visible = false
		add_child(b)
		bands.append(b)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_dt: float) -> void:

	if m != null and m.state != MENU and m.state != LOBBY and bands.size() > 0 and bands[0].visible:
		for b in bands:
			b.visible = false
	queue_redraw()


func txt(s: String, pos: Vector2, sz: int, col: Color, center: bool = false) -> void:
	var p = pos
	if center:
		p.x -= font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x * 0.5
	draw_string(font, p + Vector2(3, 3), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(0, 0, 0, 0.8))
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func title_col(k: float) -> Color:
	k = clampf(k, 0.0, 1.0) * 2.0
	if k < 1.0:
		return TITLE_STOPS[0].lerp(TITLE_STOPS[1], k)
	return TITLE_STOPS[1].lerp(TITLE_STOPS[2], k - 1.0)




func title(s: String, center: Vector2, sz: int) -> void:
	var w = title_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x

	var room = size.x * 0.92
	if w > room:
		sz = int(sz * room / w)
		w = title_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var lean = 0.0
	draw_set_transform_matrix(Transform2D(Vector2(1, 0), Vector2(lean, 1), center))
	var at = Vector2(-w * 0.5, 0)
	var k = sz / 100.0
	draw_string_outline(title_font, at + Vector2(8, 8) * k, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, int(20 * k), Color(0, 0, 0, 0.55))
	draw_string_outline(title_font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, int(20 * k), Color(0.05, 0.07, 0.2))
	draw_string_outline(title_font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, int(7 * k), Color(1, 1, 1))
	draw_string(title_font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, title_col(0.5))
	draw_set_transform_matrix(Transform2D.IDENTITY)

	var asc = title_font.get_ascent(sz)
	var desc = title_font.get_descent(sz)
	var cap = asc * 0.8
	var slice = (asc + desc) / float(TITLE_BANDS)
	for i in TITLE_BANDS:
		var b = bands[i]
		var y = center.y - asc + slice * i
		b.position = Vector2(0, y)
		b.size = Vector2(size.x, slice + 1.0)
		b.text = s
		b.tfont = title_font
		b.sz = sz
		b.anchor = center
		b.lean = lean
		b.col = title_col((y + slice * 0.5 - (center.y - cap)) / cap)
		b.visible = true
		b.queue_redraw()


func bar(pos: Vector2, w: float, h: float, frac: float, col: Color, label: String) -> void:
	draw_rect(Rect2(pos - Vector2(4, 4), Vector2(w + 8, h + 8)), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(pos, Vector2(w * clampf(frac, 0.0, 1.0), h)), col)
	draw_rect(Rect2(pos - Vector2(4, 4), Vector2(w + 8, h + 8)), Color.WHITE, false, 3.0)
	txt(label, pos + Vector2(0, -14), 26, Color.WHITE)




func _draw_wings(pos: Vector2) -> void:
	txt("MISSILES", pos + Vector2(0, -6), 26, Color.WHITE)
	var sw = 204.0
	var sh = 44.0
	for i in 2:
		var cd: float = m.wing_cd[i]
		var ready = cd <= 0.0
		var r = Rect2(pos + Vector2(i * (sw + 12.0), 4), Vector2(sw, sh))
		draw_rect(r.grow(4), Color(0, 0, 0, 0.7))
		var frac = 1.0 if ready else 1.0 - cd / maxf(0.01, m.ROCKET_COOLDOWN)
		draw_rect(Rect2(r.position, Vector2(sw * clampf(frac, 0.0, 1.0), sh)), Color(0.2, 0.75, 0.3, 0.55) if ready else Color(0.45, 0.45, 0.5, 0.6))
		draw_rect(r.grow(4), Color(0.3, 1.0, 0.4) if ready else Color.WHITE, false, 3.0)

		var c = r.position + Vector2(18, sh * 0.5)
		var ic = Color(1, 1, 1) if ready else Color(1, 1, 1, 0.25)
		draw_rect(Rect2(c + Vector2(0, -5), Vector2(70, 10)), ic)
		draw_colored_polygon(PackedVector2Array([c + Vector2(70, -5), c + Vector2(88, 0), c + Vector2(70, 5)]), ic)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -5), c + Vector2(14, -5), c + Vector2(0, -14)]), ic)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, 5), c + Vector2(14, 5), c + Vector2(0, 14)]), ic)
		var tag = ("L" if i == 0 else "R") + ("  READY" if ready else "  %.1f" % cd)
		txt(tag, r.position + Vector2(100, sh * 0.5 + 9), 24, Color(0.3, 1.0, 0.4) if ready else Color.WHITE)


func _draw() -> void:
	if m == null:
		return
	var w = size.x
	var h = size.y
	var cx = w * 0.5
	if m.state == MENU and m.join_title:
		_draw_join_title(w, h, cx)
	elif m.state == MENU:
		title("GPU BANDITS", Vector2(cx, h * 0.2), 132)
		txt("Co-op boss hunt or 3-life deathmatch for up to 16 pilots  -  v" + m.VERSION, Vector2(cx, h * 0.2 + 60), 32, Color.WHITE, true)
		txt(m.status, Vector2(cx, h * 0.9), 28, Color(1, 0.85, 0.3), true)
	elif m.state == LOBBY:
		_draw_lobby(w, h, cx)
	elif m.state == PLAYING:
		_draw_play(w, h, cx)
	elif m.state == RESULTS:
		_draw_results(w, h, cx)



func heading(s: String, center: Vector2, sz: int, col: Color, align_center: bool = true) -> float:
	var w = title_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var at = center - Vector2(w * 0.5 if align_center else 0.0, 0)
	var k = sz / 100.0
	draw_string_outline(title_font, at + Vector2(6, 6) * k, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, int(16 * k) + 2, Color(0, 0, 0, 0.5))
	draw_string_outline(title_font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, int(16 * k) + 2, Color(0.05, 0.07, 0.2))
	draw_string_outline(title_font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, int(5 * k) + 1, Color(1, 1, 1))
	draw_string(title_font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
	return w



func word_button(id: String, s: String, center: Vector2, sz: int) -> void:
	var w = title_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var r = Rect2(center.x - w * 0.5 - 16, center.y - sz * 0.85, w + 32, sz * 1.1)
	btns[id] = r
	heading(s, center, sz, LIT if r.has_point(get_local_mouse_position()) else GOLD)


func button_at(pos: Vector2) -> String:
	for id in btns:
		if btns[id].has_point(pos):
			return id
	return ""




const MODE_INFO = [
	"Everyone against the mecha boss. No time limit: the match ends when he goes down. Highest score wins.",
	"Pilots against pilots. 3 lives each, no time limit. The last pilot still flying wins.",
]


func _draw_lobby(w: float, h: float, cx: float) -> void:
	btns.clear()
	draw_rect(Rect2(0, 0, w, h), Color(0.0, 0.0, 0.04, 0.4))
	title("GPU BANDITS", Vector2(cx, 118), 96)
	heading("LOBBY  -  %d / %d PILOTS" % [m.players.size(), m.lobby_max], Vector2(cx, 186), 40, GOLD)
	var mode_name = m.MODE_NAMES[m.game_mode]
	if m.is_host:
		word_button("mode", "MODE:  " + mode_name + "   (CLICK OR TAB)", Vector2(cx, 250), 40)
	else:
		heading("MODE:  " + mode_name, Vector2(cx, 250), 40, Color(0.92, 0.96, 1.0))
	txt(MODE_INFO[m.game_mode], Vector2(cx, 288), 24, Color(0.75, 0.9, 1.0), true)
	if m.host_addr != "":
		txt(("PLAYERS JOIN:  " if m.is_host else "HOST:  ") + m.host_addr, Vector2(cx, 322), 24, Color.WHITE, true)
	var ids = m.players.keys()
	var cols = 1 if ids.size() <= 8 else 2
	var row_h = 46.0
	var col_w = 600.0
	var rows = maxi(1, int(ceil(ids.size() / float(cols))))
	var pw = col_w * cols + 60.0
	var ph = rows * row_h + 36.0
	var panel = Rect2(cx - pw * 0.5, 342, pw, ph)
	draw_rect(panel, Color(0.02, 0.03, 0.1, 0.78))
	draw_rect(panel, Color(1.0, 0.55, 0.08), false, 4.0)
	draw_rect(panel.grow(-6), Color(1, 1, 1, 0.25), false, 1.5)
	for i in ids.size():
		var id = ids[i]
		var p = m.players[id]
		var x = panel.position.x + 30 + col_w * (i % cols)
		var y = panel.position.y + 18 + row_h * (i / cols)
		draw_rect(Rect2(x, y + 12, 26, 26), m.COLORS[p.col])
		draw_rect(Rect2(x, y + 12, 26, 26), Color(1, 1, 1, 0.8), false, 2.0)
		var me = id == m.my_id
		heading(str(p.name).to_upper(), Vector2(x + 44, y + 40), 34, GOLD if me else Color(0.92, 0.96, 1.0), false)
		var tag = ""
		if id == 1:
			tag = "HOST - YOU" if me else "HOST"
		elif me:
			tag = "YOU"
		elif m.bots.has(id):
			tag = "BOT"
		if tag != "":
			var tw = font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
			txt(tag, Vector2(x + col_w - 40 - tw, y + 36), 24, Color(1.0, 0.55, 0.08))
	var y2 = panel.end.y + 40
	var dots = ".".repeat(1 + int(m.t * 2.5) % 3)
	var hint = ""
	if m.t < m.leave_confirm_until:
		hint = "PRESS ESC AGAIN TO LEAVE" + ("  -  THIS CLOSES THE GAME FOR EVERYBODY" if m.is_host else "")
	elif m.t < m.lobby_note_until:
		hint = "START GAME NEEDS A SECOND PILOT  (B ADDS A BOT)"
	elif m.autostart >= 0.0:
		hint = "STARTING IN %d" % int(ceil(m.autostart))
	elif m.is_host:
		hint = "PRESS ENTER TO START  -  F1 SETTINGS" if m.players.size() > 1 else "WAITING FOR PILOTS TO JOIN" + dots
	else:
		hint = "WAITING FOR THE HOST TO START" + dots
	txt(hint, Vector2(cx, y2), 30, Color(0.75, 0.9, 1.0), true)
	var by = y2 + 150
	if m.is_host:
		word_button("start", "START GAME", Vector2(cx, y2 + 78), 64)
		word_button("addbot", "ADD BOT", Vector2(cx - 480, by), 38)
		word_button("delbot", "REMOVE BOT", Vector2(cx - 170, by), 38)
		word_button("settings", "SETTINGS", Vector2(cx + 150, by), 38)
		word_button("leave", "LEAVE", Vector2(cx + 430, by), 38)
	else:
		word_button("settings", "SETTINGS", Vector2(cx - 150, y2 + 90), 44)
		word_button("leave", "LEAVE", Vector2(cx + 150, y2 + 90), 44)
	txt("Aim MOUSE    Lasers LEFT CLICK    Missiles RIGHT CLICK (one per wing)    W throttle up    S slow down    SHIFT afterburner    A / D bank", Vector2(cx, h - 70), 24, Color.WHITE, true)
	txt("Tap W three times to loop    Double-tap A / D to barrel roll    I = invert pitch    M = music    F11 = fullscreen    ESC twice = leave", Vector2(cx, h - 38), 24, Color.WHITE, true)
	if m.settings_open:
		_draw_settings(w, h, cx)




func _draw_join_title(w: float, h: float, cx: float) -> void:
	btns.clear()
	draw_rect(Rect2(0, 0, w, h), Color(0.0, 0.0, 0.04, 0.4))
	title("GPU BANDITS", Vector2(cx, h * 0.24), 132)
	txt("90-second vote by combat  -  v" + m.VERSION, Vector2(cx, h * 0.24 + 64), 34, Color.WHITE, true)
	var connecting = m.multiplayer.multiplayer_peer is ENetMultiplayerPeer
	if connecting:
		heading("JOINING" + ".".repeat(1 + int(m.t * 2.5) % 3), Vector2(cx, h * 0.52), 72, GOLD)
	else:
		word_button("join", "JOIN GAME", Vector2(cx, h * 0.52), 80)
	word_button("settings", "SETTINGS", Vector2(cx, h * 0.52 + 100), 56)
	word_button("quit", "QUIT", Vector2(cx, h * 0.52 + 180), 56)
	txt(m.status, Vector2(cx, h * 0.86), 30, Color(1, 0.85, 0.3), true)
	txt("ENTER = JOIN    F1 = SETTINGS    ESC = QUIT", Vector2(cx, h - 54), 26, Color.WHITE, true)
	if m.settings_open:
		_draw_settings(w, h, cx)



func _draw_settings(w: float, h: float, cx: float) -> void:
	btns.clear()
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.6))
	var panel = Rect2(cx - 420, h * 0.5 - 250, 840, 500)
	draw_rect(panel, Color(0.02, 0.03, 0.1, 0.92))
	draw_rect(panel, Color(1.0, 0.55, 0.08), false, 4.0)
	heading("SETTINGS", Vector2(cx, panel.position.y + 80), 64, GOLD)
	var on_off = func(b): return "ON" if b else "OFF"
	word_button("invert", "INVERT PITCH:  " + on_off.call(m.invert_y), Vector2(cx, panel.position.y + 180), 44)
	word_button("music", "MUSIC:  " + on_off.call(m.music_on), Vector2(cx, panel.position.y + 250), 44)
	word_button("fullscreen", "FULLSCREEN:  " + on_off.call(get_window().mode == Window.MODE_FULLSCREEN), Vector2(cx, panel.position.y + 320), 44)
	word_button("back", "BACK", Vector2(cx, panel.position.y + 420), 56)




func _draw_afterburner(w: float, h: float, k: float, ign: float) -> void:
	if w < 8.0 or h < 8.0:
		return
	var c = Vector2(w, h) * 0.5
	var segs = 36
	var outer = Color(0.0, 0.03, 0.14, 0.8 * k)
	var inner = Color(0.2, 0.5, 1.0, 0.0)
	var r_in = 0.72 - 0.17 * k
	for i in segs:
		var a0 = TAU * i / segs
		var a1 = TAU * (i + 1) / segs
		var d0 = Vector2(cos(a0), sin(a0))
		var d1 = Vector2(cos(a1), sin(a1))
		var pts = PackedVector2Array([c + d0 * c * r_in, c + d1 * c * r_in, c + d1 * c * 1.6, c + d0 * c * 1.6])
		draw_primitive(pts, PackedColorArray([inner, inner, outer, outer]), PackedVector2Array())
	if ign > 0.0:
		draw_rect(Rect2(0, 0, w, h), Color(0.6, 0.8, 1.0, 0.22 * ign * ign))
	var n = 110
	var tt = m.t
	for i in n:
		var a = TAU * fmod(i * 0.618034, 1.0)
		var sp = 1.6 + fmod(i * 0.37, 1.0) * 1.4
		var ph = fmod(tt * sp + fmod(i * 0.731, 1.0), 1.0)
		var d = Vector2(cos(a), sin(a))
		var r0 = 0.3 + ph * 1.1
		var r1 = r0 + 0.14 + 0.4 * k
		var p0 = c + d * c * r0
		var p1 = c + d * c * r1
		var al = 0.6 * k * minf(1.0, ph * 3.0)
		draw_line(p0, p1, Color(0.85, 0.93, 1.0, al), 2.5 + 3.0 * ph, true)


func _draw_play(w: float, h: float, cx: float) -> void:
	var me = m.ships.get(m.my_id)
	var mine = m.players.get(m.my_id)
	var cam = m.cam
	if m.boost_fx > 0.01:
		_draw_afterburner(w, h, m.boost_fx, m.cam_shake)

	for i in m.boss.parts.size():
		if (m.active_mask & (1 << i)) != 0:
			var wp = m.boss.parts[i].pos
			if not cam.is_position_behind(wp):
				var sp = cam.unproject_position(wp)

				if not (is_finite(sp.x) and is_finite(sp.y)) or absf(sp.x) > 20000.0 or absf(sp.y) > 20000.0:
					continue
				var k = 16.0 + 5.0 * sin(m.t * 9.0)
				draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -k - 26), sp + Vector2(k * 0.6, -26 - k * 2), sp + Vector2(-k * 0.6, -26 - k * 2)]), Color(1, 0.15, 0.1))

	for id in m.ships:
		if id == m.my_id:
			continue
		var s = m.ships[id]
		if not s.visible or not m.players.has(id):
			continue
		var pos = s.position + Vector3(0, 6, 0)
		if cam.is_position_behind(pos):
			continue
		var sp2 = cam.unproject_position(pos)
		var p = m.players[id]
		txt(p.name, sp2 + Vector2(0, -8), 22, m.COLORS[p.col], true)
		draw_rect(Rect2(sp2 + Vector2(-30, 0), Vector2(60 * clampf(p.hp / float(m.SHIELD_MAX), 0.0, 1.0), 4)), Color(0.45, 0.85, 1.0))
		draw_rect(Rect2(sp2 + Vector2(-30, 6), Vector2(60 * clampf(p.ar / float(m.ARMOR_MAX), 0.0, 1.0), 4)), Color(0.95, 0.6, 0.2))

	for id in m.ships:
		if id > m.ENEMY_BASE:
			continue
		var es = m.ships[id]
		if not es.visible:
			continue
		var epos = es.position + Vector3(0, 10, 0)
		if cam.is_position_behind(epos):
			continue
		var esp = cam.unproject_position(epos)
		var pink = Color(1.0, 0.3, 0.75)
		txt("PINK ACE", esp + Vector2(0, -8), 24, pink, true)
		draw_rect(Rect2(esp + Vector2(-40, 0), Vector2(80 * clampf(m.enemy_hp.get(id, 0) / float(m.ENEMY_HP), 0.0, 1.0), 6)), pink)
		draw_rect(Rect2(esp + Vector2(-40, 0), Vector2(80, 6)), pink, false, 1.5)

	if me != null and me.alive:
		var f = -me.basis.z
		var col = Color(1, 0.3, 0.2) if m.hit_t > 0.0 else Color(0.3, 1.0, 0.4)
		for pair in [[70.0, 30.0], [170.0, 16.0]]:
			var rp = me.position + f * pair[0]
			if not cam.is_position_behind(rp):
				var c = cam.unproject_position(rp)
				var k2 = pair[1]
				draw_rect(Rect2(c - Vector2(k2, k2), Vector2(k2 * 2, k2 * 2)), col, false, 3.0)

	# match clock counts up (there is no time limit)
	var mt = int(maxf(0.0, m.match_t))
	txt("%d:%02d" % [mt / 60, mt % 60], Vector2(cx, 74), 44, Color.WHITE, true)
	var dm = m.game_mode == m.MODE_DM

	if dm:
		var flying = 0
		for pid in m.players:
			if m.players[pid].lives > 0:
				flying += 1
		heading("DEATHMATCH  -  %d FLYING" % flying, Vector2(cx, 128), 36, GOLD)
	else:
		var bw = 640.0
		var frac = clampf(m.boss_hp / float(maxi(1, m.boss_hp_max)), 0.0, 1.0)
		var bpos = Vector2(cx - bw * 0.5, 100)
		draw_rect(Rect2(bpos - Vector2(4, 4), Vector2(bw + 8, 26)), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(bpos, Vector2(bw * frac, 18)), Color(0.95, 0.2, 0.15))
		draw_rect(Rect2(bpos - Vector2(4, 4), Vector2(bw + 8, 26)), Color.WHITE, false, 3.0)
		if m.boss_hp <= 0:
			txt(m.boss_name + " IS FINISHED", Vector2(cx, 154), 30, Color(1, 0.85, 0.3), true)
		else:
			txt(m.boss_name, Vector2(cx, 150), 24, Color.WHITE, true)

	if mine != null and dm:
		txt("KILLS %d" % mine.score, Vector2(40, 80), 56, Color(1, 0.85, 0.3))
		txt("LIVES", Vector2(40, h - 190), 26, Color.WHITE)
		for li in m.DM_LIVES:
			var lc = m.COLORS[mine.col] if li < mine.lives else Color(1, 1, 1, 0.15)
			var lp = Vector2(130 + li * 44, h - 212)
			draw_colored_polygon(PackedVector2Array([lp + Vector2(16, 0), lp + Vector2(32, 26), lp + Vector2(16, 20), lp + Vector2(0, 26)]), lc)
	elif mine != null:
		txt("SCORE %d" % mine.score, Vector2(40, 80), 56, Color(1, 0.85, 0.3))
	if mine != null:
		bar(Vector2(40, h - 70), 420, 28, mine.hp / float(m.SHIELD_MAX), Color(0.45, 0.85, 1.0), "SHIELD")
		bar(Vector2(40, h - 140), 420, 20, mine.ar / float(m.ARMOR_MAX), Color(0.95, 0.6, 0.2) if mine.ar > m.ARMOR_MAX * 0.3 else Color(1.0, 0.25, 0.15), "ARMOR")
	_draw_wings(Vector2(w - 460, h - 176))
	bar(Vector2(w - 460, h - 70), 420, 28, m.boost, Color(1, 0.4, 0.2) if m.overheated else Color(1, 0.8, 0.2), "BOOST")
	txt("SPEED %d%%" % int(round(100.0 * m.speed / maxf(m.BASE_SPEED, 0.01))), Vector2(w - 120, h - 84), 24, Color(0.6, 0.85, 1.0) if me != null and me.boosting else Color.WHITE, true)

	var rank = m.ranking()
	for i in rank.size():
		var p = m.players[rank[i]]
		var tag = "%2d. %s" % [i + 1, p.name]
		var y = 60 + 30 * i
		if rank[i] == m.my_id:
			draw_rect(Rect2(w - 370, y - 24, 350, 30), Color(1, 1, 1, 0.15))
		if dm:
			var outc = Color(1, 1, 1, 0.35)
			txt(tag, Vector2(w - 360, y), 24, m.COLORS[p.col] if p.lives > 0 else outc)
			if p.lives > 0:
				for li in p.lives:
					draw_rect(Rect2(w - 150 + li * 14, y - 16, 10, 14), m.COLORS[p.col])
			else:
				txt("OUT", Vector2(w - 152, y), 20, outc)
			txt(str(p.score), Vector2(w - 70, y), 24, Color.WHITE)
		else:
			txt(tag, Vector2(w - 360, y), 24, m.COLORS[p.col])
			txt(str(p.score), Vector2(w - 90, y), 24, Color.WHITE)

	for i in m.feed.size():
		txt(m.feed[i][0], Vector2(40, 140 + 30 * i), 24, Color(1, 1, 1, clampf(m.feed[i][1], 0.0, 1.0)))
	if m.comm != null:
		_draw_comm(Vector2(40, h - 320))
	if me != null and not me.alive:
		if dm and mine != null and mine.lives <= 0:
			txt("YOU ARE OUT", Vector2(cx, h * 0.2), 70, Color(1, 0.3, 0.2), true)
			var sname = m.players[m.spec_target].name if m.players.has(m.spec_target) else "nobody"
			txt("watching %s  -  click to watch someone else  -  ESC twice to leave" % sname, Vector2(cx, h * 0.2 + 46), 30, Color.WHITE, true)
		elif dm and mine != null:
			txt("SHOT DOWN  -  %d %s LEFT" % [mine.lives, "LIFE" if mine.lives == 1 else "LIVES"], Vector2(cx, h * 0.45), 72, Color(1, 0.3, 0.2), true)
			txt("relaunching...", Vector2(cx, h * 0.45 + 50), 36, Color.WHITE, true)
		else:
			txt("SHOT DOWN  -%d" % m.DEATH_PENALTY, Vector2(cx, h * 0.45), 80, Color(1, 0.3, 0.2), true)
			txt("relaunching...", Vector2(cx, h * 0.45 + 50), 36, Color.WHITE, true)
	elif m.match_t < 4.0:
		if dm:
			txt("3 LIVES EACH. LAST PILOT FLYING WINS.", Vector2(cx, h * 0.3), 54, Color(1, 0.85, 0.3), true)
		else:
			txt("SHOOT THE RED SPOTS. SHOOT THE PINK JETS. TAKE HIM DOWN.", Vector2(cx, h * 0.3), 50, Color(1, 0.85, 0.3), true)




func _draw_comm(at: Vector2) -> void:
	var c = m.comm
	var col = Color(1.0, 0.25, 0.2)
	var who = m.boss_name
	if m.players.has(c.id):
		col = m.COLORS[m.players[c.id].col]
		who = m.players[c.id].name
	elif c.id <= m.ENEMY_BASE:
		col = Color(1.0, 0.3, 0.75)
		who = "PINK ACE"
	var is_clip = c.clip >= 0 and c.clip < m.ace_clips.size()
	var is_face = m.huang_face_on()
	var psize = Vector2(208, 156) if (is_clip or is_face) else Vector2(106, 106)
	if is_clip or is_face:
		at.y -= 50.0
	var box = Vector2(760 if (is_clip or is_face) else 660, psize.y + 26.0)
	draw_rect(Rect2(at, box), Color(0.0, 0.05, 0.1, 0.8))
	draw_rect(Rect2(at, box), col, false, 3.0)
	var pr = Rect2(at + Vector2(13, 13), psize)
	var talking = c.t < c.text.length() / 34.0
	if is_clip:
		var f = mini(int(c.t * m.ACE_CLIP_FPS), m.ACE_CLIP_FRAMES - 1)
		var src = Rect2((f % m.ACE_CLIP_COLS) * m.ACE_CLIP_W, (f / m.ACE_CLIP_COLS) * m.ACE_CLIP_H, m.ACE_CLIP_W, m.ACE_CLIP_H)
		draw_texture_rect_region(m.ace_clips[c.clip].tex, pr, src)
	elif is_face:
		draw_texture_rect(m.huang_vp.get_texture(), pr, false)
	elif m.portraits.has(c.id):
		draw_texture_rect(m.portraits[c.id], pr, false)
	else:
		_draw_avatar(pr, c.id, col, talking)

	var lines = int(psize.y / 8.0)
	for i in lines:
		draw_rect(Rect2(pr.position + Vector2(0, 8.0 * i + fmod(m.t * 20.0, 8.0)), Vector2(pr.size.x, 1.5)), Color(0, 0, 0, 0.25))
	draw_rect(pr, col, false, 3.0)
	var tx = psize.x + 30.0
	txt(who, at + Vector2(tx, 40), 30, col)
	var shown = c.text.substr(0, int(c.t * 34.0))
	draw_multiline_string(font, at + Vector2(tx, 76), shown, HORIZONTAL_ALIGNMENT_LEFT, box.x - tx - 20.0, 26, 3, Color.WHITE)




func _draw_avatar(r: Rect2, id: int, col: Color, talking: bool) -> void:
	var c = r.position + r.size * 0.5
	var open = (4.0 + 7.0 * absf(sin(m.t * 22.0))) if talking else 3.0
	if id == 0:
		draw_rect(r, Color(0.08, 0.02, 0.03))
		draw_rect(Rect2(c + Vector2(-34, -22), Vector2(24, 9)), Color(1.0, 0.2, 0.1))
		draw_rect(Rect2(c + Vector2(10, -22), Vector2(24, 9)), Color(1.0, 0.2, 0.1))
		draw_rect(Rect2(c + Vector2(-24, 12), Vector2(48, open * 2.0)), Color(1.0, 0.45, 0.1))
		return
	draw_rect(r, Color(0.05, 0.1, 0.18))
	draw_circle(c + Vector2(0, -4), 40.0, col)
	draw_rect(Rect2(c + Vector2(-40, 22), Vector2(80, 31)), col.darkened(0.35))
	draw_rect(Rect2(c + Vector2(-30, -22), Vector2(60, 24)), Color(0.05, 0.08, 0.12))
	draw_rect(Rect2(c + Vector2(-24, -18), Vector2(20, 5)), Color(0.6, 0.9, 1.0, 0.8))
	draw_rect(Rect2(c + Vector2(-22, 6), Vector2(44, 22)), Color(0.95, 0.78, 0.62))
	draw_rect(Rect2(c + Vector2(-9, 14), Vector2(18, open)), Color(0.25, 0.05, 0.05))


func _draw_results(w: float, h: float, cx: float) -> void:
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.55))
	var rank = m.ranking()
	if m.end_lines.size() >= 2:

		var sz = 110
		while sz > 24:
			var widest = 0.0
			for l in m.end_lines:
				widest = maxf(widest, title_font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x)
			if widest <= w - 100.0:
				break
			sz -= 4
		heading(m.end_lines[0], Vector2(cx, 170), sz, GOLD)
		heading(m.end_lines[1], Vector2(cx, 170 + sz * 1.05), int(sz * 0.62), Color(0.92, 0.96, 1.0))
	elif rank.size() > 0:
		var top = m.players[rank[0]]
		txt(top.name + " WINS", Vector2(cx, 170), 120, m.COLORS[top.col], true)
		txt("...and picks the next game", Vector2(cx, 225), 40, Color.WHITE, true)
	var dm = m.game_mode == m.MODE_DM
	txt("KILLS" if dm else "SCORE", Vector2(cx + 250, 318), 26, Color(0.75, 0.9, 1.0))
	for i in rank.size():
		var p = m.players[rank[i]]
		txt("%2d.  %s" % [i + 1, p.name], Vector2(cx - 330, 360 + 42 * i), 36, m.COLORS[p.col])
		txt(str(p.score), Vector2(cx + 250, 360 + 42 * i), 36, Color.WHITE)
	txt("BACK TO THE LOBBY IN %d" % int(ceil(maxf(0.0, m.results_t))), Vector2(cx, h - 60), 30, Color(0.75, 0.9, 1.0), true)
