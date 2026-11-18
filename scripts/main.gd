extends Node3D








const Lib = preload("res://scripts/lib.gd")
const Ship = preload("res://scripts/ship.gd")
const Boss = preload("res://scripts/boss.gd")
const Hud = preload("res://scripts/hud.gd")
const OUTLINE = preload("res://shaders/outline.gdshader")
const FLOOR = preload("res://shaders/floor.gdshader")

# GPU Bandits standalone: its own menu (host on a port, join by IP and port), no match clock,
# two modes: BOSS HUNT (co-op, highest score wins) and DEATHMATCH (3 lives, last pilot flying wins).
# Forked from the LAN launcher minigame 0.6.8.
const VERSION = "1.0.2"
const DISCOVERY_PORT = 27017
const BEACON = "GPU_BANDITS_SA1"
const MAX_PLAYERS = 16
const DEFAULT_PORT = 27016
const USER_CFG = "user://standalone.cfg"
enum {MODE_BOSS, MODE_DM}
const MODE_NAMES = ["BOSS HUNT", "DEATHMATCH"]
const DM_LIVES = 3
const DM_KILL_SCORE = 1

const ARENA_R = 430.0
const CEILING = 300.0
const SHIP_R = 3.4

var BASE_SPEED = 41.25


var AB_PCT = 150.0
var SLOW_PCT = 50.0
var BOOST_SPEED = 61.875
var BRAKE_SPEED = 20.625
var throttle = 1.0
const TURN_RATE = 1.5
const MAX_PITCH_AIM = 1.25
var NOSE_SLEW = 2.6
var MOUSE_SENS = 0.0022
var ROLL_TIME = 0.55
var ROLL_DODGE = 28.0
var ROLL_CAM_FOLLOW = 4.0
const ROLL_CAM_MAX = 16.0

var LASER_SPEED = 420.0
var LASER_LIFE = 1.1
var LASER_DMG = 12
var VOLLEY_SHOTS = 9
var VOLLEY_GAP = 0.0707
var VOLLEY_PERIOD = 1.7
const FIRE_INTERVAL = 0.075
var SPLASH_R = 24.0
var SPLASH_DMG = 18
var ROCKET_SPEED = 170.0
var ROCKET_LIFE = 3.0
var ROCKET_DMG = 35
var ROCKET_COOLDOWN = 2.5
var BOLT_SPEED = 200.0
var BOLT_DMG = 12
var MISSILE_SPEED = 56.25
var MISSILE_DMG = 25
const MISSILE_LIFE = 9.0

const ENEMY_BASE = -100
const ENEMY_COUNT = 3
var ENEMY_HP = 300
var ENEMY_BONUS = 200
var ENEMY_SPEED = 54.0
var ENEMY_RESPAWN = -1.0
var TURRET_RESPAWN = 100000.0
var BEAM_DMG = 12
const BEAM_HIT_R = 13.0
var DEATH_PENALTY = 100
var WEAK_MULT = 2
var BODY_MULT = 0.5
var WEAK_HP = 250
var WEAK_BONUS = 150
var TURRET_HP = 100
var SHIELD_MAX = 150
var ARMOR_MAX = 150
var SHIELD_DELAY = 4.0
var SHIELD_REGEN = 30.0
var BANK_TURN_BOOST = 1.7
var LOOP_TIME = 2.4
var TURRET_BONUS = 75
var POD_HP = 160
var POD_BONUS = 100
var MISSILE_BONUS = 30
var PDC_HP = 120
var PDC_BONUS = 75
var PDC_RATE = 45.0
const PDC_SPEED = 300.0
const PDC_LIFE = 1.0
var PDC_RANGE = 280.0
const PDC_PILOT_RANGE = 170.0
var PDC_DMG = 3
const PDC_MAX = 500
const BOSS_HP_PER_PILOT = 900
const BOSS_HP_PER_BOT = 300
const BOSS_HP_MIN = 1500
var BOSS_BREAK_DMG = 250
var BOSS_KILL_BONUS = 500
var TURRET_BLAST_DMG = 200
var RESPAWN_TIME = 3.5


const TUNABLES = {
	"match/music_db": "MUSIC_DB",
	"flight/base_speed": "BASE_SPEED",
	"flight/afterburner_pct": "AB_PCT",
	"flight/slow_pct": "SLOW_PCT",
	"flight/turn_rate": "NOSE_SLEW",
	"flight/bank_turn_boost": "BANK_TURN_BOOST",
	"flight/mouse_sensitivity": "MOUSE_SENS",
	"flight/roll_time": "ROLL_TIME",
	"flight/roll_dodge": "ROLL_DODGE",
	"flight/roll_camera_follow": "ROLL_CAM_FOLLOW",
	"flight/loop_time": "LOOP_TIME",
	"pilot/shield": "SHIELD_MAX",
	"pilot/armor": "ARMOR_MAX",
	"pilot/shield_delay": "SHIELD_DELAY",
	"pilot/shield_regen": "SHIELD_REGEN",
	"pilot/respawn_time": "RESPAWN_TIME",
	"pilot/death_penalty": "DEATH_PENALTY",
	"cannon/damage": "LASER_DMG",
	"cannon/speed": "LASER_SPEED",
	"cannon/life": "LASER_LIFE",
	"cannon/volley_shots": "VOLLEY_SHOTS",
	"cannon/volley_gap": "VOLLEY_GAP",
	"cannon/volley_period": "VOLLEY_PERIOD",
	"missile/damage": "ROCKET_DMG",
	"missile/speed": "ROCKET_SPEED",
	"missile/life": "ROCKET_LIFE",
	"missile/cooldown": "ROCKET_COOLDOWN",
	"missile/splash_radius": "SPLASH_R",
	"missile/splash_damage": "SPLASH_DMG",
	"missile/shootdown_bonus": "MISSILE_BONUS",
	"boss/hp_per_player": "cfg_hp_player",
	"boss/hp_per_bot": "cfg_hp_bot",
	"boss/hp_minimum": "cfg_hp_min",
	"boss/body_multiplier": "BODY_MULT",
	"boss/weak_multiplier": "WEAK_MULT",
	"boss/weak_spot_hp": "WEAK_HP",
	"boss/weak_spot_bonus": "WEAK_BONUS",
	"boss/weak_spot_crack_damage": "BOSS_BREAK_DMG",
	"boss/turret_blast_damage": "TURRET_BLAST_DMG",
	"boss/kill_bonus": "BOSS_KILL_BONUS",
	"boss/beam_damage": "BEAM_DMG",
	"turrets/laser_hp": "TURRET_HP",
	"turrets/laser_bonus": "TURRET_BONUS",
	"turrets/laser_damage": "BOLT_DMG",
	"turrets/laser_speed": "BOLT_SPEED",
	"turrets/pod_hp": "POD_HP",
	"turrets/pod_bonus": "POD_BONUS",
	"turrets/homing_damage": "MISSILE_DMG",
	"turrets/homing_speed": "MISSILE_SPEED",
	"turrets/pdc_hp": "PDC_HP",
	"turrets/pdc_bonus": "PDC_BONUS",
	"turrets/pdc_damage": "PDC_DMG",
	"turrets/pdc_rate": "PDC_RATE",
	"turrets/pdc_range": "PDC_RANGE",
	"turrets/respawn": "TURRET_RESPAWN",
	"aces/hp": "ENEMY_HP",
	"aces/bonus": "ENEMY_BONUS",
	"aces/speed": "ENEMY_SPEED",
	"aces/respawn": "ENEMY_RESPAWN",
	"towers/hp": "TOWER_HP",
	"towers/bonus": "TOWER_BONUS",
}

enum {MENU, LOBBY, PLAYING, RESULTS}

const COLORS = [
	Color(0.95, 0.25, 0.25), Color(0.25, 0.55, 1.0), Color(0.3, 0.9, 0.35), Color(1.0, 0.85, 0.2),
	Color(1.0, 0.5, 0.1), Color(0.75, 0.35, 1.0), Color(0.2, 0.9, 0.9), Color(1.0, 0.45, 0.75),
	Color(0.6, 0.4, 0.2), Color(0.95, 0.95, 0.95), Color(0.5, 0.75, 0.2), Color(0.3, 0.3, 0.9),
	Color(0.9, 0.6, 0.6), Color(0.4, 0.7, 0.6), Color(0.7, 0.7, 0.3), Color(0.55, 0.55, 0.65),
]

var state = MENU
var is_host = false
var port = DEFAULT_PORT
var my_name = "Pilot"
var my_id = 1
var game_mode = MODE_BOSS
var match_t = 0.0
var end_timer = -1.0
var elim_seq = 0
var autostart = -1.0
var lobby_max = MAX_PLAYERS
var end_lines = []
var reject_msg = ""
var leave_confirm_until = 0.0
var spec_target = 0
var host_addr = ""
var arg_mode = -1
var port_edit: LineEdit
var found_port = DEFAULT_PORT
var settings_open = false
var focus_in_ms = 0
var lobby_note_until = 0.0
var press_btn = ""
var launched_by_args = false
const TITLE_HOLD = 4.0
var title_wait = -1.0
var arg_host = false
var arg_join = ""
var arg_autojoin = false
var join_title = false
var arg_windowed = false
var invert_y = false
var status = ""
var t = 0.0

var players = {}
var enemies = {}
var enemy_hp = {}
var beam_cd = 12.0
var cfg_hp_player = BOSS_HP_PER_PILOT
var cfg_hp_bot = BOSS_HP_PER_BOT
var cfg_hp_min = BOSS_HP_MIN
var boss_name = "MECHA HUANG"
var boss_hp = 1
var boss_hp_max = 1
var defeat_fx = 0.0
var pdc_b = []
var pdc_acc = {}
var pdc_mm: MultiMesh
var pdc_hit_cd = 0.0
var beam_tick = 0.0
var chimney_cd = 0.0
var bots = {}
var arg_bots = 0
var hostp = {}
var ships = {}
var shots = []
var missiles = {}
var smoke = []
var hole_a = PackedVector4Array()
var hole_b = PackedVector4Array()
var hole_next = 0
var hole_count = 0
const HOLE_MAX = 32
var fireballs = []
var fx = []
var feed = []
var towers = []
var tower_hp = []
var last_tower = -1
const TOWER_SEGS = 5
var TOWER_HP = 500
var TOWER_BONUS = 100
var wrecks = []
var my_wreck = null
var pillars = []

var boss
var cam: Camera3D
var hud
var menu_root: Control
var name_edit: LineEdit
var ip_edit: LineEdit
var found_ip = ""


var speed = BASE_SPEED
var boost = 1.0
var overheated = false
var fire_cd = 0.0
var fire_side = 1.0
var volley_left = 0
var volley_t = 0.0
var volley_cd = 0.0
var sfx_volley: AudioStream
var music: AudioStreamPlayer
var music_on = true
var MUSIC_DB = -13.0
var sfx_thruster: AudioStream
var sfx_enemy_lasers = []
var sfx_explosions = []
var sfx_crash: AudioStream
var sfx_beam: AudioStream
var beam_was_on = false
var sfx_shield_hits = []
var shield_snd_cd = 0.0
var last_sh = SHIELD_MAX
var last_ar = ARMOR_MAX
var sfx_impacts = []
var impact_cd = 0.0
var loop_t = 0.0
var loop_cd = 0.0
var loop_pitch0 = 0.0
var wear = 0.0
var dmg_smoke = {}
var sfx_missiles = []
var thr_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var wing_cd = [0.0, 0.0]
var wing_next = 0
var launch_was = false
var wingtest = false
var wingtest_t = 0.0
var wingtest_log = {}
var snap_dir = ""
var snap_t = -1.0
var roll_t = 0.0
var roll_dir = 0.0
var roll_side = Vector3.ZERO
var roll_p0 = Vector3.ZERO
var roll_yaw0 = 0.0
var cam_slide = Vector3.ZERO

var boost_fx = 0.0
var cam_shake = 0.0
var cam_was_boost = false
var cam_k = 0.0
var cam_snaps = 0
var cam_base_fov = 70.0
var camlog = false
var camlog_last = []
var camlog_max = [0.0, 0.0]
var camlog_frames = 0

var streaks = []
var streak_mat: StandardMaterial3D = null
var cfg_path = ""
var cfg_mtime = 0
var cfg_check = 0.0
var cfg_warning = ""
var los_log = {}
var lostest = false
var lostest_t = 0.0
var lostest_phase = ""
var speedlog = false
var keyscript = false
var keyscript_t = 0.0
var keyscript_down = {}
var speedlog_t = 0.0
var speedlog_at = {}
var boosttest = false
var boosttest_t = 0.0
var boosttest_fps_t = 0.0
var boosttest_on_t = 0.0
var boosttest_off_t = 0.0
var rolltest = false
var rolltest_t = 0.0
var rolltest_log = {}
var w_tap_n = 0
var w_tap_t = -10.0
var w_roll_side = 1.0
var base_roll = 0.0
var last_tap = {-1: -10.0, 1: -10.0}
var shield_t = 0.0
var bump_cd = 0.0
var send_cd = 0.0
var hit_t = 0.0
var cam_yaw = 0.0
var aim_yaw = 0.0
var aim_pitch = 0.0
var cam_pitch = 0.0
var results_t = 0.0


var part_hp = []
var part_alive = []
var part_cd = []
var part_respawn = []
var weak_active = []
var weak_timer = 0.0
var alive_mask = 0
var active_mask = 0
var missile_seq = 0
var host_missiles = {}
const LOS_EVERY_MS = 100
var los_cache = {}
var snap_cd = 0.0
var beacon_cd = 0.0
var udp_out: PacketPeerUDP
var udp_in: PacketPeerUDP

const PILOT_CHATTER = false
var comm_q = []
var comm = null
var portraits = {}
var my_portrait = PackedByteArray()
var arg_portrait = ""
var ace_clips = []
const ACE_CLIP_SOUND = false
const ACE_CLIP_COLS = 8
const ACE_CLIP_FRAMES = 40
const ACE_CLIP_FPS = 12.0
const ACE_CLIP_W = 240
const ACE_CLIP_H = 180
var babble = []
var voice: AudioStreamPlayer
var laser_mesh: BoxMesh
var heart_mesh: ArrayMesh
var heart_cd = {}
var pop_mesh: SphereMesh
var mat_cache = {}




func _ready() -> void:
	randomize()
	var env_name = OS.get_environment("USERNAME")
	if env_name != "":
		my_name = env_name.left(16)
	_load_config()
	_parse_args()
	_build_world()
	_build_ui()
	_make_babble()
	voice = AudioStreamPlayer.new()
	voice.volume_db = -8.0
	add_child(voice)
	_load_portrait()
	_load_ace_clips()
	sfx_volley = _load_sound("res://sounds/pulse_volley_v033.ogg")
	sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = sfx_volley
	sfx_player.volume_db = -4.0
	add_child(sfx_player)
	music = AudioStreamPlayer.new()
	music.stream = _load_sound("res://sounds/soundtrack_v041.ogg")
	if music.stream != null:
		music.stream.set("loop", true)
	music.volume_db = MUSIC_DB
	add_child(music)
	sfx_thruster = _load_sound("res://sounds/thruster_loop_v034.ogg")
	sfx_beam = _load_sound("res://sounds/boss_beam_v038.ogg")
	sfx_crash = _load_sound("res://sounds/ship_crash_v039.ogg")
	for n in [1, 2, 3, 4, 5, 6]:
		var es = _load_sound("res://sounds/enemy_laser_%d_v036.ogg" % n)
		if es != null:
			sfx_enemy_lasers.append(es)
	for n in 4:
		var ss = _load_sound("res://sounds/shield_impact_%d_v048.ogg" % (n + 1))
		if ss != null:
			sfx_shield_hits.append(ss)
	for n in 8:
		var hs = _load_sound("res://sounds/impact_%d_v0310.ogg" % (n + 1))
		if hs != null:
			sfx_impacts.append(hs)
	for n in [1, 2, 3]:
		var xs = _load_sound("res://sounds/explosion_%d_v037.ogg" % n)
		if xs != null:
			sfx_explosions.append(xs)
	for n in [1, 2, 3]:
		var ms = _load_sound("res://sounds/missile_%d_v035.ogg" % n)
		if ms != null:
			sfx_missiles.append(ms)
	if sfx_thruster != null:
		sfx_thruster.set("loop", true)
	thr_player = AudioStreamPlayer.new()
	thr_player.stream = sfx_thruster
	thr_player.volume_db = -14.0
	add_child(thr_player)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	multiplayer.server_disconnected.connect(_on_server_lost)
	udp_in = PacketPeerUDP.new()
	if udp_in.bind(DISCOVERY_PORT) != OK:
		udp_in = null
	if not arg_windowed and DisplayServer.get_name() != "headless" and _user_get("fullscreen", true):
		get_window().mode = Window.MODE_FULLSCREEN
	if arg_host or arg_join != "":
		call_deferred("_args_launch")


# Optional quick start from the command line (--host / --join=<ip>). The game never quits by itself.
func _args_launch() -> void:
	status = ""
	if arg_host:
		_host()
	elif arg_join != "":
		_join(arg_join)


func _user_get(key: String, def):
	var c = ConfigFile.new()
	if c.load(USER_CFG) != OK:
		return def
	return c.get_value("menu", key, def)


func _user_set(key: String, value) -> void:
	var c = ConfigFile.new()
	c.load(USER_CFG)
	c.set_value("menu", key, value)
	c.save(USER_CFG)






func _load_config() -> void:

	var exe_dir = OS.get_executable_path().get_base_dir()
	var res_dir = ProjectSettings.globalize_path("res://")
	var dirs = []
	for d in ([res_dir, exe_dir] if OS.has_feature("editor") else [exe_dir, res_dir]):
		if d != "" and not dirs.has(d):
			dirs.append(d)
	var cfg = ConfigFile.new()
	var found = ""
	var broken = false
	cfg_warning = ""
	for d in dirs:
		var path = d.path_join("scalper_config.cfg")
		if FileAccess.file_exists(path):
			found = path
			if cfg.load(path) != OK:


				broken = true
				cfg = _parse_config_loose(path)
			break
	var complete = found != "" and not broken
	if found != "":
		var nm = str(cfg.get_value("boss", "name", boss_name)).strip_edges().left(40)
		if nm != "":
			boss_name = nm
		for full in TUNABLES:
			var parts = full.split("/")
			if cfg.has_section_key(parts[0], parts[1]):
				_set_tunable(TUNABLES[full], cfg.get_value(parts[0], parts[1]))
			else:
				complete = false
	var target = found if found != "" else dirs[0].path_join("scalper_config.cfg")
	if broken:
		DirAccess.copy_absolute(found, found + ".bad")
		cfg_warning += " (your file was kept as scalper_config.cfg.bad)"
	if not complete:
		_write_config(target)
	cfg_path = target
	cfg_mtime = FileAccess.get_modified_time(target) if FileAccess.file_exists(target) else 0
	if cfg_warning != "":
		print("CONFIG_WARNING:" + cfg_warning)
	print("CONFIG:%s roll_dodge=%s roll_time=%s roll_camera_follow=%s" % [target, ROLL_DODGE, ROLL_TIME, ROLL_CAM_FOLLOW])




func _parse_config_loose(path: String) -> ConfigFile:
	var cfg = ConfigFile.new()
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return cfg
	var num = RegEx.new()
	num.compile("^[-+]?(\\d+\\.?\\d*|\\.\\d+)([eE][-+]?\\d+)?$")
	var section = ""
	var n = 0
	var bad = []
	while not f.eof_reached():
		var raw = f.get_line()
		n += 1
		var line = raw.strip_edges()
		if line == "" or line.begins_with(";") or line.begins_with("#"):
			continue
		if line.begins_with("[") and line.ends_with("]"):
			section = line.substr(1, line.length() - 2).strip_edges()
			continue
		var eq = line.find("=")
		if eq < 1 or section == "":
			bad.append("line %d \"%s\"" % [n, line.left(40)])
			continue
		var key = line.left(eq).strip_edges()
		var val = line.substr(eq + 1).strip_edges()
		if val.begins_with("\""):
			var close = val.find("\"", 1)
			cfg.set_value(section, key, val.substr(1, close - 1) if close > 0 else val.substr(1))
			continue
		var semi = val.find(";")
		if semi >= 0:
			val = val.left(semi).strip_edges()
		if val.is_valid_int():
			cfg.set_value(section, key, int(val))
		elif num.search(val) != null:
			cfg.set_value(section, key, float(val))
		else:
			bad.append("line %d \"%s\"" % [n, line.left(40)])
	f.close()
	cfg_warning = "scalper_config.cfg: ignored " + (", ".join(bad) if bad.size() > 0 else "an unreadable line")
	return cfg





func _watch_config(dt: float) -> void:
	cfg_check -= dt
	if cfg_check > 0.0 or cfg_path == "":
		return
	cfg_check = 1.0
	if not (is_host or state == MENU):
		return
	if not FileAccess.file_exists(cfg_path) or FileAccess.get_modified_time(cfg_path) == cfg_mtime:
		return
	_load_config()
	_say("Settings reloaded: barrel roll %s m" % str(ROLL_DODGE))
	if cfg_warning != "":
		_say(cfg_warning)
	print("CONFIG_RELOAD roll_dodge=%s" % str(ROLL_DODGE))
	if is_host and state == PLAYING and multiplayer.has_multiplayer_peer():
		rpc("ev_tuning", _collect_tuning())


@rpc("authority", "call_remote", "reliable")
func ev_tuning(tuning: Dictionary) -> void:
	if not is_host:
		_apply_tuning(tuning)
		_say("Host changed the settings: barrel roll %s m" % str(ROLL_DODGE))



func _speed_caps() -> void:
	BOOST_SPEED = BASE_SPEED * maxf(AB_PCT, 100.0) / 100.0
	BRAKE_SPEED = BASE_SPEED * clampf(SLOW_PCT, 10.0, 100.0) / 100.0


func _set_tunable(vname: String, value) -> void:
	if not (value is int or value is float):
		return
	if get(vname) is int:
		set(vname, int(value))
	else:
		set(vname, float(value))


func _collect_tuning() -> Dictionary:
	var d = {}
	for full in TUNABLES:
		d[full] = get(TUNABLES[full])
	return d


func _apply_tuning(d: Dictionary) -> void:
	for full in d:
		if TUNABLES.has(full):
			_set_tunable(TUNABLES[full], d[full])


func _write_config(path: String) -> void:
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_line("; GPU Bandits settings. Edit with any text editor, then restart the game.")
	f.store_line("; In a network match the host's settings are the ones everybody plays with.")
	var section = ""
	for full in TUNABLES:
		var parts = full.split("/")
		if parts[0] != section:
			section = parts[0]
			f.store_line("")
			f.store_line("[" + section + "]")
			if section == "boss":
				f.store_line("name=\"" + boss_name + "\"")
		f.store_line(parts[1] + "=" + str(get(TUNABLES[full])))
	f.close()


func _parse_args() -> void:
	var args = Array(OS.get_cmdline_args()) + Array(OS.get_cmdline_user_args())
	for a in args:
		if a == "--host":
			arg_host = true
		elif a.begins_with("--join="):
			arg_join = a.substr(7)
		elif a.begins_with("--name="):
			my_name = a.substr(7).left(16)
		elif a.begins_with("--port="):
			port = int(a.substr(7))
		elif a.begins_with("--autostart="):
			autostart = float(a.substr(12))
		elif a.begins_with("--mode="):
			arg_mode = MODE_DM if a.substr(7).strip_edges().to_lower() in ["dm", "deathmatch", "1"] else MODE_BOSS
		elif a.begins_with("--portrait="):
			arg_portrait = a.substr(11)
		elif a.begins_with("--bots="):
			arg_bots = int(a.substr(7))
		elif a == "--windowed":
			arg_windowed = true
		elif a == "--wingtest":
			wingtest = true
		elif a == "--rolltest":
			rolltest = true
		elif a == "--boosttest":
			boosttest = true
		elif a == "--speedlog":
			speedlog = true
		elif a == "--lostest":
			lostest = true
		elif a == "--camlog":
			camlog = true
		elif a == "--keyscript":
			keyscript = true
			speedlog = true
		elif a.begins_with("--snap="):
			snap_dir = a.substr(7).strip_edges()
	launched_by_args = false
	join_title = false


func _build_world() -> void:
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sm = ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.1, 0.2, 0.55)
	sm.sky_horizon_color = Color(0.95, 0.6, 0.45)
	sm.ground_bottom_color = Color(0.05, 0.08, 0.12)
	sm.ground_horizon_color = Color(0.95, 0.6, 0.45)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.8)
	env.ambient_light_energy = 0.9
	env.glow_enabled = true
	env.glow_intensity = 0.8
	var we = WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 900.0
	add_child(sun)

	var floor_mesh = PlaneMesh.new()
	floor_mesh.size = Vector2(3000, 3000)
	var fm = ShaderMaterial.new()
	fm.shader = FLOOR
	fm.set_shader_parameter("arena_r", ARENA_R)
	var floor_mi = MeshInstance3D.new()
	floor_mi.mesh = floor_mesh
	floor_mi.material_override = fm
	add_child(floor_mi)


	var pyl_a = Lib.toon_hole(Color(0.3, 0.32, 0.4))
	var pyl_b = Lib.toon_hole(Color(0.2, 0.5, 0.55))
	var lamp = Lib.glow(Color(1.0, 0.85, 0.3), 3.0)
	for i in 32:
		var a = TAU * i / 32.0
		var hgt = 70.0 + 50.0 * (i % 2)
		var p = Vector3(cos(a) * (ARENA_R + 30.0), hgt * 0.5, sin(a) * (ARENA_R + 30.0))
		Lib.box(self, Vector3(30, hgt, 30), p, pyl_a if i % 2 == 0 else pyl_b, Vector3(0, -a, 0))
		Lib.box(self, Vector3(12, 6, 12), p + Vector3(0, hgt * 0.5 + 3.0, 0), lamp, Vector3(0, -a, 0))

	for i in 8:
		if i == 7:
			continue
		var a2 = TAU * (i + 0.5) / 8.0
		var hgt2 = 150.0 + 60.0 * (i % 2)
		var c = Vector2(cos(a2) * 250.0, sin(a2) * 250.0)

		var segs = []
		var rest = []
		for k in TOWER_SEGS:
			var y0 = hgt2 * k / float(TOWER_SEGS)
			var y1 = hgt2 * (k + 1) / float(TOWER_SEGS)
			var r0 = lerpf(14.0, 10.0, k / float(TOWER_SEGS))
			var r1 = lerpf(14.0, 10.0, (k + 1) / float(TOWER_SEGS))
			segs.append(Lib.cyl(self, r1, r0, y1 - y0, 6, Vector3(c.x, (y0 + y1) * 0.5, c.y), pyl_a))
		segs.append(Lib.cyl(self, 16.0, 16.0, 6.0, 6, Vector3(c.x, hgt2, c.y), pyl_b))
		for sg in segs:
			rest.append(sg.transform)
		pillars.append([c, 14.0, hgt2 + 4.0])
		towers.append({"segs": segs, "rest": rest, "h": hgt2 + 4.0, "part": -1, "down": false, "fall": [], "top": Vector3(c.x, hgt2 + 10.0, c.y), "kind": Boss.TURRET if i % 2 == 0 else (Boss.PDC if (i == 1 or i == 5) else -1)})
		tower_hp.append(TOWER_HP)

	boss = Boss.new()
	add_child(boss)
	boss.build()
	for tw in towers:
		if tw.kind >= 0:
			tw.part = boss.parts.size()
			boss.add_static_part(tw.kind, tw.top, 9.0, 1.7)

			boss.parts[tw.part].min_pitch = -0.4
	_reset_parts()

	cam = Camera3D.new()
	cam.near = 0.5
	cam.far = 4000.0
	cam.fov = 70.0
	add_child(cam)
	cam.current = true
	var quad = MeshInstance3D.new()
	var qm = QuadMesh.new()
	qm.size = Vector2(2, 2)
	quad.mesh = qm
	var om = ShaderMaterial.new()
	om.shader = OUTLINE
	om.render_priority = -100
	quad.material_override = om
	quad.custom_aabb = AABB(Vector3(-10000, -10000, -10000), Vector3(20000, 20000, 20000))
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cam.add_child(quad)

	var tracer = BoxMesh.new()
	tracer.size = Vector3(0.45, 0.45, 4.5)
	tracer.material = Lib.glow(Color(1.0, 0.8, 0.35), 5.0)
	pdc_mm = MultiMesh.new()
	pdc_mm.transform_format = MultiMesh.TRANSFORM_3D
	pdc_mm.mesh = tracer
	pdc_mm.instance_count = PDC_MAX
	pdc_mm.visible_instance_count = 0
	var pdc_node = MultiMeshInstance3D.new()
	pdc_node.multimesh = pdc_mm
	pdc_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pdc_node.custom_aabb = AABB(Vector3(-2000, -100, -2000), Vector3(4000, 1200, 4000))
	add_child(pdc_node)
	_setup_sparks()
	laser_mesh = BoxMesh.new()
	laser_mesh.size = Vector3(0.45, 0.45, 8.0)
	heart_mesh = _make_heart()
	pop_mesh = SphereMesh.new()
	pop_mesh.radius = 1.0
	pop_mesh.height = 2.0
	pop_mesh.radial_segments = 8
	pop_mesh.rings = 4


func _build_ui() -> void:
	var layer = CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.m = self
	layer.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	menu_root = CenterContainer.new()
	menu_root.visible = false
	layer.add_child(menu_root)
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var outer = VBoxContainer.new()
	menu_root.add_child(outer)
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 230)
	outer.add_child(spacer)
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.03, 0.1, 0.82)
	sb.border_color = Color(1.0, 0.55, 0.08)
	sb.set_border_width_all(3)
	sb.set_content_margin_all(26)
	panel.add_theme_stylebox_override("panel", sb)
	outer.add_child(panel)
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(620, 0)
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var saved_port = int(_user_get("port", DEFAULT_PORT))
	if port == DEFAULT_PORT and saved_port != DEFAULT_PORT:
		port = saved_port
	name_edit = _field(box, "Pilot name", str(_user_get("name", my_name)))
	ip_edit = _field(box, "Host IP to join (blank = first game found on your LAN)", str(_user_get("ip", "")))
	port_edit = _field(box, "Port (UDP) - the host picks it, joiners type the same one", str(port))
	port_edit.max_length = 5
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	var hb = Button.new()
	hb.text = "HOST GAME"
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_theme_font_size_override("font_size", 32)
	hb.pressed.connect(_on_host_pressed)
	row.add_child(hb)
	var jb = Button.new()
	jb.text = "JOIN GAME"
	jb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	jb.add_theme_font_size_override("font_size", 32)
	jb.pressed.connect(_on_join_pressed)
	row.add_child(jb)
	ip_edit.text_submitted.connect(func(_s): _on_join_pressed())
	var qb = Button.new()
	qb.text = "QUIT"
	qb.add_theme_font_size_override("font_size", 24)
	qb.pressed.connect(func(): get_tree().quit())
	box.add_child(qb)
	var note = Label.new()
	note.text = "Over the internet the host forwards the port (UDP) on their router\nand gives the others their public IP address."
	note.add_theme_font_size_override("font_size", 18)
	note.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note)


func _field(parent: Control, label: String, value: String) -> LineEdit:
	var l = Label.new()
	l.text = label
	l.add_theme_font_size_override("font_size", 22)
	parent.add_child(l)
	var e = LineEdit.new()
	e.text = value
	e.max_length = 40
	e.add_theme_font_size_override("font_size", 28)
	parent.add_child(e)
	return e


func _on_host_pressed() -> void:
	if not _read_menu():
		return
	_host()


func _on_join_pressed() -> void:
	if not _read_menu():
		return
	var ip = ip_edit.text.strip_edges()
	if ip == "":
		if found_ip == "":
			status = "No game found on the LAN yet - type the host's IP address."
			return
		ip = found_ip
		port = found_port
		port_edit.text = str(port)
	_join(ip)


# Reads name and port from the menu and remembers them (and the IP) for next time.
func _read_menu() -> bool:
	var n = name_edit.text.strip_edges().left(16)
	if n != "":
		my_name = n
	var ps = port_edit.text.strip_edges()
	if not ps.is_valid_int() or int(ps) < 1024 or int(ps) > 65535 or int(ps) == DISCOVERY_PORT:
		status = "Port must be a number from 1024 to 65535 (not %d)." % DISCOVERY_PORT
		return false
	port = int(ps)
	_user_set("name", my_name)
	_user_set("ip", ip_edit.text.strip_edges())
	_user_set("port", port)
	return true




func _host() -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, lobby_max - 1)
	if err != OK:
		status = "Could not host on port %d (already in use?)" % port
		return
	multiplayer.multiplayer_peer = peer
	is_host = true
	my_id = 1
	state = LOBBY
	status = ""
	if arg_mode >= 0:
		game_mode = arg_mode
	var ips = local_ips()
	host_addr = ("%s   PORT %d" % [ips, port]) if ips != "" else "PORT %d" % port
	print("GB_HOST port=%d mode=%s" % [port, MODE_NAMES[game_mode]])
	udp_out = PacketPeerUDP.new()
	udp_out.set_broadcast_enabled(true)
	udp_out.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	ev_roster({1: [my_name, 0]})
	_share_portrait()
	for i in clampi(arg_bots, 0, lobby_max - 1):
		_add_bot()


func _join(ip: String) -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port)
	if err != OK:
		status = "Could not start a connection to " + ip
		return
	multiplayer.multiplayer_peer = peer
	reject_msg = ""
	host_addr = "%s   PORT %d" % [ip, port]
	status = "Connecting to %s port %d..." % [ip, port]


func _on_connected() -> void:
	my_id = multiplayer.get_unique_id()
	state = LOBBY
	status = ""
	rpc_id(1, "c_hello", my_name, VERSION)
	_share_portrait()


func _on_failed() -> void:
	status = "Could not reach the host (wrong IP or port, port not open, or the game is full)."
	_drop_to_menu()


func _on_server_lost() -> void:
	status = reject_msg if reject_msg != "" else "Lost connection to the host."
	_drop_to_menu()


# Leave the current game (host: ends it for everybody) and go back to the main menu.
func _leave_to_menu(why: String) -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	status = why
	_drop_to_menu()


func _drop_to_menu() -> void:
	multiplayer.multiplayer_peer = null
	for id in ships.keys():
		ships[id].queue_free()
	ships.clear()
	players.clear()
	bots.clear()
	hostp.clear()
	enemies.clear()
	enemy_hp.clear()
	host_missiles.clear()
	_clear_action()
	is_host = false
	udp_out = null
	my_id = 1
	end_timer = -1.0
	autostart = -1.0
	settings_open = false
	if music != null:
		music.stop()
	state = MENU


func _on_peer_connected(_id: int) -> void:
	pass


func _on_peer_disconnected(id: int) -> void:
	if not is_host or not players.has(id):
		return
	var d = {}
	for p in players:
		if p != id:
			d[p] = [players[p].name, players[p].col]
	hostp.erase(id)
	rpc("ev_roster", d)


func _discovery(dt: float) -> void:
	if is_host and udp_out != null and state != MENU:
		beacon_cd -= dt
		if beacon_cd <= 0.0:
			beacon_cd = 1.0
			udp_out.put_packet(("%s:%d:%s" % [BEACON, port, my_name]).to_utf8_buffer())
	if udp_in != null:
		while udp_in.get_available_packet_count() > 0:
			var pkt = udp_in.get_packet().get_string_from_utf8().split(":")
			if state == MENU and pkt.size() >= 2 and pkt[0] == BEACON and pkt[1].is_valid_int():
				found_ip = udp_in.get_packet_ip()
				found_port = int(pkt[1])
				var who = pkt[2] if pkt.size() >= 3 else "a pilot"
				status = "LAN game found: %s at %s port %d - leave the IP blank and press JOIN" % [who, found_ip, found_port]


func local_ips() -> String:
	var out = PackedStringArray()
	for a in IP.get_local_addresses():
		if a.count(".") == 3 and not a.begins_with("127.") and not a.begins_with("169.254."):
			out.append(a)
	return ", ".join(out)


func _sender() -> int:
	var s = multiplayer.get_remote_sender_id()
	return my_id if s == 0 else s



func _to_host(method: String, args: Array) -> void:
	if is_host:
		callv(method, args)
	elif args.size() == 1:
		rpc_id(1, method, args[0])
	else:
		rpc_id(1, method, args[0], args[1])




@rpc("any_peer", "call_remote", "reliable")
func c_hello(pname: String, ver: String) -> void:
	if not is_host:
		return
	var id = multiplayer.get_remote_sender_id()
	if id == 0 or players.has(id):
		return
	if ver != VERSION:
		_reject(id, "The host runs GPU Bandits %s, you have %s. Use the same version." % [VERSION, ver])
		return
	if players.size() >= lobby_max:
		_reject(id, "That game is full (%d pilots)." % lobby_max)
		return
	var used = []
	for p in players:
		used.append(players[p].col)
	var col = 0
	while col in used:
		col += 1
	var d = {}
	for p in players:
		d[p] = [players[p].name, players[p].col]
	var clean = pname.strip_edges().left(16)
	if clean == "":
		clean = "Pilot %d" % (col + 1)
	d[id] = [clean, col % MAX_PLAYERS]
	hostp[id] = {"alive": true, "respawn": 0.0, "protect": 3.0}
	if state == PLAYING and game_mode == MODE_DM:
		# A deathmatch is already running: the newcomer watches and plays the next round.
		hostp[id] = {"alive": false, "respawn": INF, "protect": 0.0, "out": true}
	rpc("ev_lobby_size", lobby_max)
	rpc("ev_mode", game_mode)
	rpc("ev_roster", d)
	if state == PLAYING and game_mode == MODE_DM and players.has(id):
		players[id].lives = 0
	print("GB_JOINED:%s id=%d" % [clean, id])


func _reject(id: int, msg: String) -> void:
	rpc_id(id, "ev_reject", msg)
	get_tree().create_timer(0.5).timeout.connect(_kick.bind(id))


func _kick(id: int) -> void:
	if is_host and multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.disconnect_peer(id)


@rpc("authority", "call_remote", "reliable")
func ev_reject(msg: String) -> void:
	reject_msg = msg


@rpc("authority", "call_local", "reliable")
func ev_mode(mode: int) -> void:
	game_mode = clampi(mode, 0, MODE_NAMES.size() - 1)


func _set_mode(mode: int) -> void:
	if not is_host or state != LOBBY:
		return
	rpc("ev_mode", mode)


@rpc("authority", "call_remote", "reliable")
func ev_lobby_size(n: int) -> void:

	if n >= 2 and n <= MAX_PLAYERS:
		lobby_max = n


@rpc("authority", "call_local", "reliable")
func ev_roster(d: Dictionary) -> void:
	for id in d:
		if not players.has(id):
			players[id] = {"name": d[id][0], "col": d[id][1], "score": 0, "hp": SHIELD_MAX, "ar": ARMOR_MAX, "lives": DM_LIVES, "elim": 0}
			var s = Ship.new()
			add_child(s)
			s.build(COLORS[d[id][1]])
			s.visible = false
			ships[id] = s
			if id > 0 and id != my_id and state != MENU:
				_share_portrait()
	for id in players.keys():
		if not d.has(id):
			players.erase(id)
			if ships.has(id):
				ships[id].queue_free()
				ships.erase(id)
	print("GB_LOBBY:%d/%d" % [players.size(), lobby_max])


func _host_start() -> void:
	match_t = 0.0
	end_timer = -1.0
	elim_seq = 0
	for id in players:
		players[id].score = 0
		players[id].hp = SHIELD_MAX
		players[id].ar = ARMOR_MAX
		players[id].lives = DM_LIVES
		players[id].elim = 0
		hostp[id] = {"alive": true, "respawn": 0.0, "protect": 3.0}
	_reset_parts()
	_shuffle_weak()
	host_missiles.clear()
	enemies.clear()
	rpc("ev_begin", boss_name, _collect_tuning(), game_mode)
	for id in bots:
		bots[id] = _ai_state()
		_bot_place(id, TAU * players[id].col / float(MAX_PLAYERS))
	if game_mode == MODE_DM:
		# Deathmatch: the boss is only scenery and cover. His guns, weak spots, mouth laser and
		# the pink aces are switched off so every kill belongs to a pilot.
		for i in part_alive.size():
			part_alive[i] = false
			part_respawn[i] = INF
			weak_active[i] = false
		weak_timer = INF
		beam_cd = INF
		_recalc_masks()
		boss_hp_max = 1
		boss_hp = 1
		_radio(players.keys()[randi() % players.size()], ["Three lives each. Make them count.", "Last one flying buys the GPUs!", "No friends up here today."])
		print("GB_START_MODE:DEATHMATCH")
		return
	_radio(players.keys()[randi() % players.size()], ["All ships, check in!", "Cut off his GPU supply!", "Stay out of his face and watch the towers!"])
	for e in ENEMY_COUNT:
		var eid = ENEMY_BASE - 1 - e
		enemies[eid] = _ai_state()
		enemies[eid]["hp"] = ENEMY_HP
		enemies[eid]["alive"] = true
		enemies[eid]["respawn"] = 0.0
		_enemy_place(eid)
	beam_cd = 12.0

	var n_bots = bots.size()
	var n_humans = maxi(0, players.size() - n_bots)
	boss_hp_max = maxi(cfg_hp_min, cfg_hp_player * n_humans + cfg_hp_bot * n_bots)
	boss_hp = boss_hp_max
	print("GB_START_MODE:BOSS_HUNT hp=%d" % boss_hp_max)


@rpc("authority", "call_local", "reliable")
func ev_begin(bname: String, tuning: Dictionary, mode: int) -> void:

	if bname.strip_edges() != "":
		boss_name = bname.strip_edges().left(40)
	game_mode = clampi(mode, 0, MODE_NAMES.size() - 1)
	if not is_host:
		_apply_tuning(tuning)
	for id in players:
		players[id].lives = DM_LIVES
		players[id].elim = 0
		players[id].score = 0
	_begin_local()


func _begin_local() -> void:
	if state == PLAYING and not is_host:
		return
	state = PLAYING
	match_t = 0.0
	leave_confirm_until = 0.0
	spec_target = 0
	los_cache.clear()
	if cfg_warning != "" and is_host:
		_say(cfg_warning)

	if music.stream != null and music_on:
		music.volume_db = MUSIC_DB
		music.play(0.0)
	if not is_host:
		boss_hp = 1
		boss_hp_max = 1
	_clear_action()
	_reset_holes()
	_reset_towers()
	feed.clear()
	for e in ENEMY_COUNT:
		var eid = ENEMY_BASE - 1 - e
		if not ships.has(eid):
			var es = Ship.new()
			add_child(es)
			es.build(Color(1.0, 0.15, 0.6), true)
			es.visible = false
			ships[eid] = es
		enemy_hp[eid] = ENEMY_HP
	for id in ships:
		ships[id].alive = true
		ships[id].has_net = false
	var slot = 0
	if players.has(my_id):
		slot = players[my_id].col
	_place_me(TAU * slot / float(MAX_PLAYERS))
	if game_mode == MODE_DM and players.has(my_id) and players[my_id].lives <= 0 and ships.has(my_id):
		# joined while a deathmatch was running: watch this round
		ships[my_id].alive = false


func _place_me(angle: float) -> void:
	var s = ships.get(my_id)
	if s == null:
		return
	s.position = Vector3(cos(angle) * 370.0, 90.0, sin(angle) * 370.0)
	s.yaw = atan2(s.position.x, s.position.z)
	s.pitch = 0.0
	s.roll = 0.0
	s.alive = true
	s.apply()
	speed = BASE_SPEED
	throttle = 1.0
	boost = 1.0
	overheated = false
	roll_t = 0.0
	cam_slide = Vector3.ZERO
	base_roll = 0.0
	shield_t = 3.0
	wing_cd = [0.0, 0.0]
	wing_next = 0
	s.set_wings(true, true)
	loop_t = 0.0
	loop_cd = 0.0
	volley_left = 0
	volley_cd = 0.0
	cam_yaw = s.yaw
	cam_pitch = 0.0
	aim_yaw = s.yaw
	aim_pitch = 0.0


func _clear_action() -> void:
	for sh in shots:
		sh.n.queue_free()
	shots.clear()
	for mid in missiles:
		missiles[mid].n.queue_free()
	missiles.clear()
	for sm in smoke:
		sm.n.queue_free()
	smoke.clear()
	for w in wrecks:
		w.n.queue_free()
	wrecks.clear()
	for fb in fireballs:
		fb.n.queue_free()
	fireballs.clear()
	pdc_b.clear()
	pdc_mm.visible_instance_count = 0
	_clear_sparks()
	my_wreck = null


const RESULTS_TIME = 12.0


func _host_end() -> void:
	state = RESULTS
	results_t = RESULTS_TIME
	end_timer = -1.0
	_send_snap()
	var r = ranking()
	var wname = ""
	if r.size() > 0:
		wname = players[r[0]].name
	print("WINNER:" + wname)
	_make_end_text()


func _make_end_text() -> void:
	var r = ranking()
	if r.size() == 0:
		return
	var wname = players[r[0]].name
	var how = ""
	if game_mode == MODE_DM:
		how = "LAST PILOT FLYING  -  %d KILLS" % players[r[0]].score
	else:
		how = "TOP SCORE %d  -  %s IS SCRAP" % [players[r[0]].score, boss_name]
	end_lines = [wname.to_upper() + " WINS!", how]
	print("END_TEXT:" + " | ".join(end_lines))



func _try_start(why: String) -> void:
	if state != LOBBY or not is_host:
		return
	if players.size() < 2:
		print("GB_START_REFUSED:%s players=%d" % [why, players.size()])
		lobby_note_until = t + 2.5
		return
	print("GB_START:%s players=%d" % [why, players.size()])
	autostart = -1.0
	_host_start()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focus_in_ms = Time.get_ticks_msec()




func _lobby_click(e: InputEventMouseButton) -> void:
	var b = hud.button_at(hud.get_local_mouse_position())
	if e.pressed:
		press_btn = b if (get_window().has_focus() and Time.get_ticks_msec() - focus_in_ms > 500) else ""
		return
	var was = press_btn
	press_btn = ""
	if b == "" or b != was:
		return
	match b:
		"start":
			_try_start("start button")
		"mode":
			_set_mode((game_mode + 1) % MODE_NAMES.size())
		"addbot":
			_add_bot()
		"delbot":
			_remove_bot()
		"leave":
			_leave_to_menu("You left the game.")
		"join":
			_title_join()
		"quit":
			get_tree().quit()
		"settings":
			settings_open = true
		"back":
			settings_open = false
		"invert":
			invert_y = not invert_y
		"music":
			_toggle_music()
		"fullscreen":
			_toggle_fullscreen()




var snaps_done = {}
var snap_state_t = 0.0
var snap_last_state = -1


func _tick_snap(dt: float) -> void:
	if snap_dir == "":
		return
	if state != snap_last_state:
		snap_last_state = state
		snap_state_t = 0.0
	snap_state_t += dt
	var want = ""
	if state == MENU and join_title and snap_state_t > 1.5:
		want = "title"
	elif state == LOBBY and snap_state_t > 0.8:
		want = "lobby"
	elif state == PLAYING and snap_state_t > 3.0 and snap_state_t < 3.9:
		want = "hud_ready"
	elif state == PLAYING and wingtest and wingtest_t > 4.6:
		want = "hud_reload"
	elif state == PLAYING and boosttest:
		want = _boosttest_snap()
	elif state == PLAYING and lostest and not is_host and lostest_phase != "" and lostest_phase != "done" and fmod(lostest_t, 7.0) > 5.5:
		want = "roof_" + lostest_phase
	if want == "" or snaps_done.has(want):
		return
	snaps_done[want] = true
	var img = get_viewport().get_texture().get_image()
	var path = snap_dir.path_join(want + ".png")
	img.save_png(path)
	print("GB_SNAP:" + path)



func _title_join() -> void:
	if state != MENU or not join_title or multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		return
	settings_open = false
	print("GB_TITLE_JOIN:" + arg_join)
	_join(arg_join)


func _toggle_music() -> void:
	music_on = not music_on
	if not music_on:
		music.stop()
	elif music.stream != null and (state == PLAYING or state == RESULTS):
		music.volume_db = MUSIC_DB
		music.play(0.0)


func _toggle_fullscreen() -> void:
	var w = get_window()
	w.mode = Window.MODE_FULLSCREEN if w.mode == Window.MODE_WINDOWED else Window.MODE_WINDOWED
	_user_set("fullscreen", w.mode == Window.MODE_FULLSCREEN)


# Boss hunt: highest score first. Deathmatch: pilots still flying first, then whoever was
# knocked out last, then kills.
func ranking() -> Array:
	var ids = players.keys()
	if game_mode == MODE_DM:
		ids.sort_custom(func(a, b): return _dm_key(a) > _dm_key(b))
	else:
		ids.sort_custom(func(a, b): return players[a].score > players[b].score)
	return ids


func _dm_key(id: int) -> int:
	var p = players[id]
	var alive_rank = 1000 + p.lives if p.lives > 0 else p.elim
	return alive_rank * 100000 + p.score




func _process(dt: float) -> void:
	t += dt
	_discovery(dt)
	_watch_config(dt)

	menu_root.visible = state == MENU and not launched_by_args
	if state != LOBBY and not (state == MENU and join_title):
		settings_open = false
	_tick_snap(dt)
	var mm = Input.MOUSE_MODE_CAPTURED if state == PLAYING else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != mm:
		Input.mouse_mode = mm
	boss.defeated = state != MENU and state != LOBBY and boss_hp <= 0
	boss.animate(t, dt, alive_mask, active_mask)
	if boss.defeated and state == PLAYING:

		defeat_fx -= dt
		if defeat_fx <= 0.0:
			defeat_fx = 0.35
			var n_static = boss.static_solids.size()
			if boss.solids.size() > n_static:
				var sol = boss.solids[n_static + randi() % (boss.solids.size() - n_static)]
				_fireball(sol[0] + Vector3(randf_range(-8, 8), randf_range(-8, 8), randf_range(-8, 8)), 16.0)
	chimney_cd -= dt
	if chimney_cd <= 0.0:
		chimney_cd = 0.3
		for cp in boss.chimneys:
			_puff(cp, 9.0, 3.0)
	if is_host:
		_host_tick(dt)
	if state == PLAYING:
		_local_flight(dt)
		_tick_shots(dt)
		_tick_missiles(dt)
		_tick_beam(dt)
		_track_turrets(dt)
		_tick_pdc(dt)
	elif state == RESULTS:
		results_t -= dt
		if results_t <= 0.0 and is_host:
			# back to the lobby; clients follow with the next snapshot
			state = LOBBY
			_send_snap()
	for id in ships:
		var s = ships[id]
		if id != my_id:
			s.tick_remote(dt)
		s.tick_fx(t)
		var vis = state == PLAYING and s.alive and (id == my_id or s.has_net)
		if vis and s.shielded:
			vis = fmod(t, 0.2) < 0.1
		s.visible = vis

		if players.has(id):
			var hurt = clampf(1.0 - players[id].ar / float(ARMOR_MAX), 0.0, 1.0)
			s.set_damage(hurt)
			s.set_shield(players[id].hp / float(SHIELD_MAX))
			# armour went down since last frame (any source, also seen through host snapshots)
			var ar_now = players[id].ar
			var ar_was = ar_seen.get(id, ar_now)
			ar_seen[id] = ar_now
			if vis and ar_now < ar_was and ar_now > 0 and t - s.last_scorch > 0.25:
				_hull_hit(s, Vector3(randf_range(-1, 1), randf_range(-0.2, 1), randf_range(-1, 1)))
			# a badly hurt ship spits sparks from its wounds
			if vis and hurt > 0.35:
				spark_cd[id] = spark_cd.get(id, 0.0) - dt
				if spark_cd[id] <= 0.0:
					spark_cd[id] = randf_range(0.12, 0.5) * (1.6 - hurt)
					var off = s.basis * Vector3(randf_range(-2.4, 2.4), randf_range(-0.4, 0.8), randf_range(-2.0, 3.0))
					_sparks(s.position + off, s.basis * Vector3(randf_range(-1, 1), 1.0, 0.6), int(3 + 7 * hurt), Color(1.0, 0.62, 0.22), 24.0)
			if vis and hurt > 0.2:
				dmg_smoke[id] = dmg_smoke.get(id, 0.0) - dt
				if dmg_smoke[id] <= 0.0:
					dmg_smoke[id] = lerpf(0.3, 0.05, hurt)
					_puff(s.position + s.basis.z * 5.0, 1.4 + 2.2 * hurt, 1.3, false, true)
					if hurt > 0.7 and randf() < 0.3:
						_pop(s.position + s.basis.z * 4.0, 2.5, Color(1.0, 0.5, 0.1))

		if vis and id <= ENEMY_BASE:
			heart_cd[id] = heart_cd.get(id, 0.0) - dt
			if heart_cd[id] <= 0.0:
				heart_cd[id] = 0.11
				_puff(s.position + s.basis.z * 18.0, 4.5, 1.8, true)

	if boss.beam_on and not beam_was_on and state == PLAYING:
		_sfx(sfx_beam, -1.0)
	beam_was_on = boss.beam_on

	if music.playing and state != PLAYING and state != RESULTS:
		music.volume_db -= 30.0 * dt
		if music.volume_db < -50.0:
			music.stop()
	_tick_hit_sound(dt)
	_tick_engines(dt)
	_tick_wrecks(dt)
	_tick_towers(dt)
	_tick_comm(dt)
	_tick_fx(dt)
	_camera(dt)
	hit_t -= dt
	var i = feed.size() - 1
	while i >= 0:
		feed[i][1] -= dt
		if feed[i][1] <= 0.0:
			feed.remove_at(i)
		i -= 1


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		var k = e.physical_keycode
		var title_menu = state == MENU and join_title
		if k == KEY_ESCAPE:
			if settings_open:
				settings_open = false
			elif state == MENU:
				get_tree().quit()
			elif t < leave_confirm_until:
				_leave_to_menu("You left the game.")
			else:
				leave_confirm_until = t + 2.5
				_say("Press ESC again to leave" + (" - this ends the game for everybody" if is_host else ""))
		elif k == KEY_TAB and state == LOBBY and is_host and not settings_open:
			_set_mode((game_mode + 1) % MODE_NAMES.size())
		elif k == KEY_B and state == LOBBY and is_host and not settings_open:
			_add_bot()
		elif k == KEY_N and state == LOBBY and is_host and not settings_open:
			_remove_bot()
		elif k == KEY_F1 and (state == LOBBY or title_menu):
			settings_open = not settings_open
		elif (k == KEY_ENTER or k == KEY_KP_ENTER) and title_menu and not settings_open:
			_title_join()
		elif k == KEY_F11:
			_toggle_fullscreen()
		elif k == KEY_I:
			invert_y = not invert_y
		elif k == KEY_M:
			_toggle_music()
		elif (k == KEY_ENTER or k == KEY_KP_ENTER) and state == LOBBY and is_host and not settings_open:
			_try_start("enter key")
		elif k == KEY_W:
			_w_tap()
		elif k == KEY_A:
			_tap(-1)
		elif k == KEY_D:
			_tap(1)
	elif e is InputEventJoypadButton and e.pressed:
		if e.button_index == JOY_BUTTON_LEFT_SHOULDER:
			_tap(-1)
		elif e.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			_tap(1)
		elif e.button_index == JOY_BUTTON_START and state == LOBBY and is_host:
			_try_start("start pad button")
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and (state == LOBBY or (state == MENU and join_title)):
		_lobby_click(e)
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and state == PLAYING:
		var me = ships.get(my_id)
		if me != null and not me.alive and game_mode == MODE_DM and players.has(my_id) and players[my_id].lives <= 0:
			spec_target = _next_spectate(spec_target)




func _w_tap() -> void:
	if state != PLAYING:
		return
	if t - w_tap_t > 0.3:
		w_tap_n = 0
	w_tap_n += 1
	w_tap_t = t
	var me = ships.get(my_id)
	if w_tap_n >= 3 and loop_t <= 0.0 and loop_cd <= 0.0 and me != null and me.alive:
		w_tap_n = 0
		loop_t = LOOP_TIME
		loop_pitch0 = me.pitch


func _tap(dir: int) -> void:
	if state != PLAYING:
		return
	if t - last_tap[dir] < 0.3 and roll_t <= 0.0:
		roll_t = ROLL_TIME
		roll_dir = -float(dir)
		var me = ships.get(my_id)
		if me != null:
			roll_side = _roll_side(me.yaw, roll_dir)
			roll_p0 = me.position
			roll_yaw0 = me.yaw
			print("ROLL_START dir=%s dodge=%s time=%s x=%.2f z=%.2f" % ["left" if dir < 0 else "right", str(ROLL_DODGE), str(ROLL_TIME), me.position.x, me.position.z])
	last_tap[dir] = t




func _roll_side(yaw: float, dir: float) -> Vector3:
	return Vector3(cos(yaw), 0.0, -sin(yaw)) * -dir




func _roll_slide(left: float, dur: float) -> float:
	return ROLL_DODGE * smoothstep(0.0, 1.0, 1.0 - clampf(left / maxf(dur, 0.001), 0.0, 1.0))


func _key(k: int) -> bool:
	return Input.is_physical_key_pressed(k)


func _axis() -> Vector2:
	var x = 0.0
	var y = 0.0
	if _key(KEY_LEFT):
		x -= 1.0
	if _key(KEY_RIGHT):
		x += 1.0
	if _key(KEY_UP):
		y += 1.0
	if _key(KEY_DOWN):
		y -= 1.0
	var jx = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var jy = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if absf(jx) > 0.2:
		x += jx
	if absf(jy) > 0.2:
		y -= jy
	return Vector2(clampf(x, -1.0, 1.0), clampf(y, -1.0, 1.0))


func _input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and state == PLAYING and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		aim_yaw -= e.relative.x * MOUSE_SENS
		aim_pitch -= e.relative.y * MOUSE_SENS * (-1.0 if invert_y else 1.0)




func _local_flight(dt: float) -> void:
	var s = ships.get(my_id)
	if s == null:
		return
	shield_t = maxf(0.0, shield_t - dt)
	bump_cd -= dt
	fire_cd -= dt
	for wi in 2:
		wing_cd[wi] = maxf(0.0, wing_cd[wi] - dt)
	s.set_wings(wing_cd[0] <= 0.0, wing_cd[1] <= 0.0)
	if not s.alive:
		return
	if rolltest:
		_rolltest_tick(dt, s)
	if boosttest:
		_boosttest_tick(dt)
	if keyscript:
		_keyscript_tick(dt)
	if speedlog:
		_speedlog_tick(dt)


	var ax = _axis()
	aim_yaw -= ax.x * 2.2 * dt
	aim_pitch += ax.y * 1.8 * dt * (-1.0 if invert_y else 1.0)
	var bank = 0.0
	if _key(KEY_A) or Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER):
		bank += 1.0
	if _key(KEY_D) or Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER):
		bank -= 1.0


	if Vector2(s.position.x, s.position.z).length() > ARENA_R - 30.0:
		var d = wrapf(atan2(s.position.x, s.position.z) - aim_yaw, -PI, PI)
		aim_yaw += signf(d) * minf(absf(d), 3.0 * dt)
	if s.position.y < 12.0:
		aim_pitch = maxf(aim_pitch, 0.3)
	if s.position.y > CEILING:
		aim_pitch = minf(aim_pitch, -0.3)
	aim_pitch = clampf(aim_pitch, -MAX_PITCH_AIM, MAX_PITCH_AIM)

	aim_yaw = s.yaw + clampf(wrapf(aim_yaw - s.yaw, -PI, PI), -1.2, 1.2)

	wear = 0.0
	if players.has(my_id):
		wear = clampf(1.0 - players[my_id].ar / float(ARMOR_MAX), 0.0, 1.0)
	var slew = NOSE_SLEW * (1.0 - 0.5 * wear)
	var shake = maxf(0.0, wear - 0.35)
	aim_yaw += sin(t * 2.7) * 0.55 * shake * dt
	aim_pitch += cos(t * 3.4) * 0.45 * shake * dt
	var yaw_step = 0.0
	loop_cd -= dt
	if loop_t > 0.0:


		loop_t -= dt
		s.pitch = loop_pitch0 + TAU * (1.0 - maxf(loop_t, 0.0) / LOOP_TIME)
		aim_yaw = s.yaw
		if loop_t <= 0.0:
			s.pitch = loop_pitch0
			aim_pitch = loop_pitch0
			loop_cd = 1.5
	else:


		var yaw_slew = slew
		var turn = aim_yaw - s.yaw
		if bank != 0.0 and absf(turn) > 0.02 and signf(bank) == signf(turn):
			yaw_slew *= BANK_TURN_BOOST
		yaw_step = clampf(turn, -yaw_slew * dt, yaw_slew * dt)
		s.yaw += yaw_step
		s.pitch += clampf(aim_pitch - s.pitch, -slew * dt, slew * dt)





	_speed_caps()
	var want_boost = _key(KEY_SHIFT) or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.5
	var braking = _key(KEY_S) or _key(KEY_CTRL) or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT) > 0.5
	var raising = _key(KEY_W)
	if boosttest:

		want_boost = is_host and boosttest_t >= 5.0 and fmod(boosttest_t - 5.0, 6.0) < 3.0
		braking = false
		raising = false
		boost = maxf(boost, 0.5)
		overheated = false
	var boosting = want_boost and not overheated and boost > 0.0
	var slow = clampf(SLOW_PCT / 100.0, 0.1, 1.0)
	if boosting:
		throttle = 1.0
		boost -= 0.45 * dt
		if boost <= 0.0:
			boost = 0.0
			overheated = true
	else:
		if braking:
			throttle = maxf(slow, throttle - 0.15 * dt)
		elif raising:
			throttle = minf(1.0, throttle + 0.25 * dt)
		boost = minf(1.0, boost + 0.28 * dt)
		if overheated and boost > 0.35:
			overheated = false
	throttle = clampf(throttle, slow, 1.0)
	var target = BASE_SPEED * throttle
	if boosting:
		target = BOOST_SPEED
	if loop_t > 0.0:
		target = BOOST_SPEED
	target = minf(target, lerpf(BOOST_SPEED, BASE_SPEED + 8.0, wear))
	speed = lerpf(speed, target, minf(1.0, (2.5 if target > speed else 3.0) * dt))
	s.boosting = boosting
	s.position += s.fwd() * speed * dt
	if boosttest and not is_host and ships.has(1):
		var hs = ships[1]
		s.yaw = hs.yaw
		s.pitch = hs.pitch
		aim_yaw = hs.yaw
		aim_pitch = hs.pitch
		s.position = hs.position - hs.fwd() * 14.0 + Vector3(0.0, 6.0, 0.0) + Vector3(cos(hs.yaw), 0.0, -sin(hs.yaw)) * 30.0
	if lostest:
		_lostest_tick(dt, s)

	var spin = 0.0
	if roll_t > 0.0:



		var slide0 = _roll_slide(roll_t, ROLL_TIME)
		roll_t -= dt
		var slide_step = roll_side * (_roll_slide(roll_t, ROLL_TIME) - slide0)
		s.position += slide_step


		cam_slide = (cam_slide - slide_step).limit_length(ROLL_CAM_MAX)
		spin = roll_dir * TAU * (1.0 - maxf(roll_t, 0.0) / ROLL_TIME)
		if roll_t <= 0.0:
			var moved = s.position - roll_p0
			var right = Vector3(cos(roll_yaw0), 0.0, -sin(roll_yaw0))
			print("ROLL_END side=%.2f (right +) fwd=%.2f dodge=%s x=%.2f z=%.2f" % [moved.dot(right), moved.dot(Vector3(-sin(roll_yaw0), 0.0, -cos(roll_yaw0))), str(ROLL_DODGE), s.position.x, s.position.z])

	var lean = 0.0
	if dt > 0.0:
		lean = yaw_step / (slew * dt) * 0.45 + sin(t * 5.0) * 0.3 * shake
	base_roll = lerpf(base_roll, bank * 1.25 + lean, minf(1.0, 6.0 * dt))
	s.roll = base_roll + spin
	s.rolling = roll_t > 0.0
	s.shielded = shield_t > 0.0


	if s.position.y < 3.0:
		s.position.y = 3.0
		s.pitch = maxf(s.pitch, 0.3)
		aim_pitch = maxf(aim_pitch, 0.3)
		_bump(4)
	for sol in boss.solids:
		var dv = s.position - sol[0]
		var rr = sol[1] + SHIP_R * 0.6
		if dv.length() < rr:
			var out = dv.normalized()
			s.position = sol[0] + out * (rr + 1.0)
			s.yaw = atan2(-out.x, -out.z)
			aim_yaw = s.yaw
			_bump(20)
	for pl in pillars:
		if s.position.y < pl[2]:
			var dv2 = Vector2(s.position.x, s.position.z) - pl[0]
			if dv2.length() < pl[1] + 3.0:
				var o2 = dv2.normalized()
				s.position.x = pl[0].x + o2.x * (pl[1] + 4.0)
				s.position.z = pl[0].y + o2.y * (pl[1] + 4.0)
				s.yaw = atan2(-o2.x, -o2.y)
				aim_yaw = s.yaw
				_bump(20)
	s.apply()



	var firing = _key(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	volley_cd -= dt
	if firing and volley_left == 0 and volley_cd <= 0.0:
		volley_left = VOLLEY_SHOTS
		volley_t = 0.0
		volley_cd = VOLLEY_PERIOD
		if sfx_volley != null:
			sfx_player.play()
		rpc("fx_volley")
	if volley_left > 0:
		volley_t -= dt
		while volley_t <= 0.0 and volley_left > 0:
			volley_left -= 1
			volley_t += VOLLEY_GAP
			var b = s.basis
			var dir = -b.z
			fire_side = -fire_side
			var mz = s.position + b * Vector3(2.4 * fire_side, 0.0, -2.3)
			_spawn_shot(mz, dir, my_id)
			_pop(mz + dir * 2.0, 1.6, Color(1.0, 0.85, 0.3))
			rpc("fx_shot", mz, dir)


	var launch = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_joy_button_pressed(0, JOY_BUTTON_B)
	if wingtest:
		launch = _wingtest_tick(dt)
	if launch and not launch_was:
		var wi = _pick_wing(wing_cd, wing_next)
		if wi >= 0:
			wing_cd[wi] = ROCKET_COOLDOWN
			wing_next = 1 - wi
			s.set_wings(wing_cd[0] <= 0.0, wing_cd[1] <= 0.0)
			var rp = s.wing_point(wi)
			_spawn_shot(rp, -s.basis.z, my_id, true)
			rpc("fx_rocket", rp, -s.basis.z)
	launch_was = launch

	send_cd -= dt
	if send_cd <= 0.0:
		send_cd = 1.0 / 30.0
		var flags = (1 if s.boosting else 0) | (2 if s.rolling else 0) | (4 if s.shielded else 0) | _wing_flags(wing_cd)
		rpc("st", s.position, s.yaw, s.pitch, s.roll, flags)



func _pick_wing(cd: Array, prefer: int) -> int:
	if cd[prefer] <= 0.0:
		return prefer
	if cd[1 - prefer] <= 0.0:
		return 1 - prefer
	return -1



func _wing_flags(cd: Array) -> int:
	return (8 if cd[0] > 0.0 else 0) | (16 if cd[1] > 0.0 else 0)







func _rolltest_tick(dt: float, me: Node3D) -> void:
	rolltest_t += dt
	for k in [["L", 4.0, -1], ["R", 7.0, 1]]:
		if rolltest_t >= k[1] and not rolltest_log.has("tap" + k[0]):
			rolltest_log["tap" + k[0]] = true
			last_tap[k[2]] = -10.0
			_tap(k[2])
			_tap(k[2])
	for id in ships:
		var o = ships[id]
		var key = "r%d" % id
		var on = (roll_t > 0.0) if id == my_id else o.rolling
		var rec = rolltest_log.get(key)
		if on and (rec == null or rec.done):
			rolltest_log[key] = {"p0": o.position, "yaw0": o.yaw, "t0": rolltest_t, "end": -1.0, "done": false}
		elif rec != null and not rec.done:
			if not on and rec.end < 0.0:

				rec.end = rolltest_t + (0.0 if id == my_id else 0.4)
			if rec.end >= 0.0 and rolltest_t >= rec.end:
				rec.done = true
				var d = o.position - rec.p0
				var right = Vector3(cos(rec.yaw0), 0.0, -sin(rec.yaw0))
				var fwd = Vector3(-sin(rec.yaw0), 0.0, -cos(rec.yaw0))
				print("ROLLTEST me=%d ship=%d %s side=%.2f fwd=%.2f up=%.2f yaw_change=%.3f t=%.2f" % [my_id, id, "own" if id == my_id else "remote", d.dot(right), d.dot(fwd), d.y, wrapf(o.yaw - rec.yaw0, -PI, PI), rolltest_t])




func _wingtest_tick(dt: float) -> bool:
	wingtest_t += dt
	var t = wingtest_t
	var pressed = (t >= 4.0 and t < 4.05) or (t >= 4.1 and t < 4.15)
	for wi in 2:
		var key = "w%d" % wi
		if wing_cd[wi] > 0.0 and not wingtest_log.has(key + "_fired"):
			wingtest_log[key + "_fired"] = t
			print("WINGTEST fired wing=%d t=%.2f" % [wi, t])
		if wingtest_log.has(key + "_fired") and not wingtest_log.has(key + "_back") and wing_cd[wi] <= 0.0:
			wingtest_log[key + "_back"] = t
			print("WINGTEST reloaded wing=%d t=%.2f after=%.2f" % [wi, t, t - wingtest_log[key + "_fired"]])
	return pressed





func _camlog_tick(s: Node3D) -> void:
	var off = cam.position - s.position
	var cur = [off, cam.fov]
	if not camlog_last.is_empty():
		var dp = off.distance_to(camlog_last[0])
		var df = absf(cam.fov - camlog_last[1])
		if cam_k > 0.0 and cam_k < 1.0 or s.boosting != cam_was_boost:
			camlog_max[0] = maxf(camlog_max[0], dp)
			camlog_max[1] = maxf(camlog_max[1], df)
		var lk = -cam.global_transform.basis.z
		print("CAM t=%.3f ab=%s k=%.3f cam=(%.2f,%.2f,%.2f) ship=(%.2f,%.2f,%.2f) look=(%.3f,%.3f,%.3f) off=(%.3f,%.3f,%.3f) dist=%.3f fov=%.3f d_off=%.4f d_fov=%.4f" % [t, s.boosting, cam_k, cam.global_position.x, cam.global_position.y, cam.global_position.z, s.position.x, s.position.y, s.position.z, lk.x, lk.y, lk.z, off.x, off.y, off.z, off.length(), cam.fov, dp, df])
	camlog_last = cur
	camlog_frames += 1
	if camlog_frames % 60 == 0:
		print("CAMMAX max_offset_change_per_frame=%.4f max_fov_change_per_frame=%.4f" % [camlog_max[0], camlog_max[1]])




const LOSTEST = [["A_wall_below_roof", Vector3(0, 100, 60)], ["B_behind_building", Vector3(0, 160, -90)],
	["D_side_below_roof", Vector3(60, 140, 22)], ["C_clear_view", Vector3(0, 215, 90)]]
var lostest_min_pitch = 90.0


func _lostest_tick(dt: float, s: Node3D) -> void:
	lostest_t += dt
	if is_host:
		s.position = Vector3(-300, 150, 250)
		return
	var idx = int(lostest_t / 7.0)
	var ph = LOSTEST[idx][0] if idx < LOSTEST.size() else "done"
	if ph != lostest_phase:
		if lostest_phase != "":
			print("LOSTEST phase=%s roof_rounds_fired=%d roof_held_los=%d roof_held_pitch=%d pdc_rounds_stopped_by_building=%d roof_gun_lowest_pitch_deg=%.1f" % [lostest_phase, los_log.get("roof_rounds_fired", 0), los_log.get("roof_held_los", 0), los_log.get("roof_held_pitch", 0), los_log.get("pdc_rounds_stopped_by_building", 0), lostest_min_pitch])
		los_log = {}
		lostest_min_pitch = 90.0
		lostest_phase = ph
	if idx >= LOSTEST.size():
		return
	var gun: Vector3 = boss.parts[boss.roof_gun_i].pos
	s.position = boss.dc_xform * LOSTEST[idx][1]
	var d = (gun - s.position).normalized()
	s.yaw = atan2(-d.x, -d.z)
	s.pitch = clampf(asin(d.y), -0.9, 0.9)
	aim_yaw = s.yaw
	aim_pitch = s.pitch
	lostest_min_pitch = minf(lostest_min_pitch, rad_to_deg(asin(clampf(boss.muzzle_dir(boss.roof_gun_i).y, -1.0, 1.0))))




const KEYSCRIPT = [[0.0, "cruise", []], [3.0, "S", [KEY_S]], [8.0, "none", []], [10.0, "W", [KEY_W]],
	[14.0, "W_at_100", [KEY_W]], [16.0, "SHIFT", [KEY_SHIFT]], [18.0, "shift_let_go", []], [18.25, "SHIFT_again", [KEY_SHIFT]],
	[20.0, "none_after_shift", []], [24.0, "end", []]]


func _keyscript_tick(dt: float) -> void:
	if not is_host:
		return
	var before = keyscript_t
	keyscript_t += dt
	for step in KEYSCRIPT:
		if before < step[0] and keyscript_t >= step[0] or (before == 0.0 and step[0] == 0.0):
			for k in [KEY_W, KEY_S, KEY_SHIFT]:
				var want = step[2].has(k)
				if keyscript_down.get(k, false) != want:
					var ev = InputEventKey.new()
					ev.physical_keycode = k
					ev.keycode = k
					ev.pressed = want
					Input.parse_input_event(ev)
					keyscript_down[k] = want
			print("KEYSCRIPT t=%.1f phase=%s" % [keyscript_t, step[1]])




func _speedlog_tick(dt: float) -> void:
	speedlog_t += dt
	if speedlog_t < 0.5:
		return
	var span = speedlog_t
	speedlog_t = 0.0
	var me = ships.get(my_id)
	var line = "SPEED t=%.1f me=%d speed=%.2f pct=%.0f throttle=%.2f ab=%s fx=%.2f W=%s S=%s SHIFT=%s" % [t, my_id, speed, 100.0 * speed / BASE_SPEED, throttle, me != null and me.boosting, boost_fx, _key(KEY_W), _key(KEY_S), _key(KEY_SHIFT)]
	for id in ships:
		if id == my_id or id < 0:
			continue
		var o = ships[id]
		if speedlog_at.has(id):
			line += " seen[%d]=%.2f%s" % [id, o.position.distance_to(speedlog_at[id]) / span, "(ab)" if o.boosting else ""]
		speedlog_at[id] = o.position
	print(line)


func _boosttest_tick(dt: float) -> void:
	boosttest_t += dt
	var hs = ships.get(1)
	if hs != null and hs.boosting:
		boosttest_on_t += dt
		boosttest_off_t = 0.0
	else:
		boosttest_off_t += dt
		boosttest_on_t = 0.0
	boosttest_fps_t += dt
	if boosttest_fps_t >= 1.0:
		boosttest_fps_t = 0.0
		print("BOOSTTEST t=%.1f fps=%d host_boosting=%s" % [boosttest_t, Engine.get_frames_per_second(), hs != null and hs.boosting])


func _boosttest_snap() -> String:
	var tag = "_v" + VERSION
	if boosttest_t < 3.5:
		return ""
	if is_host:
		if boosttest_off_t > 1.5:
			return "pilot_cruise" + tag
		if boosttest_on_t > 0.08 and boosttest_on_t < 0.25:
			return "pilot_ignite" + tag
		if boosttest_on_t > 0.9 and boosttest_on_t < 1.3:
			return "pilot_boost" + tag
	else:
		if boosttest_off_t > 1.5:
			return "other_cruise" + tag
		if boosttest_on_t > 0.08 and boosttest_on_t < 0.25:
			return "other_ignite" + tag
		if boosttest_on_t > 0.9 and boosttest_on_t < 1.3:
			return "other_boost" + tag
	return ""


func _bump(dmg: int) -> void:
	if bump_cd > 0.0:
		return
	bump_cd = 0.6
	var s = ships.get(my_id)
	if s != null:
		_pop(s.position, 4.0, Color(1, 1, 1))
	if shield_t <= 0.0:
		if s != null:
			_my_shield(s.position + s.fwd() * 5.0)
		_to_host("c_took", [dmg, 0])


@rpc("any_peer", "call_remote", "unreliable_ordered")
func st(p: Vector3, y: float, pch: float, r: float, flags: int) -> void:
	_net_state(multiplayer.get_remote_sender_id(), p, y, pch, r, flags)



@rpc("authority", "call_remote", "unreliable_ordered")
func bst(id: int, p: Vector3, y: float, pch: float, r: float, flags: int) -> void:
	_net_state(id, p, y, pch, r, flags)


func _net_state(id: int, p: Vector3, y: float, pch: float, r: float, flags: int) -> void:
	var s = ships.get(id)
	if s == null:
		return
	s.net_pos = p
	s.net_yaw = y
	s.net_pitch = pch
	s.net_roll = r
	s.boosting = (flags & 1) != 0
	s.rolling = (flags & 2) != 0
	s.shielded = (flags & 4) != 0
	var wl = (flags & 8) == 0
	var wr = (flags & 16) == 0
	if wingtest and (wl != s.wing_loaded[0] or wr != s.wing_loaded[1]):
		print("WINGTEST remote id=%d left=%s right=%s t=%.2f" % [id, wl, wr, wingtest_t])
	s.set_wings(wl, wr)
	if not s.has_net:
		s.position = p
		s.yaw = y
		s.pitch = pch
		s.roll = r
		s.has_net = true
		s.apply()


@rpc("authority", "call_remote", "unreliable")
func bfx_fire(id: int, l: Vector3, r: Vector3, dir: Vector3) -> void:
	if state != PLAYING:
		return
	_spawn_shot(l, dir, id)
	_spawn_shot(r, dir, id)


@rpc("authority", "call_remote", "unreliable")
func bfx_shot(id: int, mz: Vector3, dir: Vector3) -> void:
	if state != PLAYING:
		return
	_spawn_shot(mz, dir, id)


@rpc("authority", "call_remote", "reliable")
func bfx_rocket(id: int, p: Vector3, dir: Vector3) -> void:
	if state != PLAYING:
		return
	_spawn_shot(p, dir, id, true)



@rpc("any_peer", "call_remote", "unreliable")
func fx_volley() -> void:
	if state != PLAYING or sfx_volley == null:
		return
	var sh = ships.get(multiplayer.get_remote_sender_id())
	if sh == null or not sh.visible:
		return
	var pl = sh.get_node_or_null("Cannon")
	if pl == null:
		pl = AudioStreamPlayer3D.new()
		pl.name = "Cannon"
		pl.stream = sfx_volley
		pl.unit_size = 45.0
		pl.max_distance = 600.0
		pl.volume_db = -3.0
		sh.add_child(pl)
	pl.play()


@rpc("any_peer", "call_remote", "unreliable")
func fx_shot(mz: Vector3, dir: Vector3) -> void:
	if state != PLAYING:
		return
	_spawn_shot(mz, dir, multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "unreliable")
func fx_fire(l: Vector3, r: Vector3, dir: Vector3) -> void:
	if state != PLAYING:
		return
	var id = multiplayer.get_remote_sender_id()
	_spawn_shot(l, dir, id)
	_spawn_shot(r, dir, id)


@rpc("any_peer", "call_remote", "reliable")
func fx_rocket(p: Vector3, dir: Vector3) -> void:
	if state != PLAYING:
		return
	_spawn_shot(p, dir, multiplayer.get_remote_sender_id(), true)




func _glow_mat(key: String, col: Color, energy: float) -> Material:
	if not mat_cache.has(key):
		mat_cache[key] = Lib.glow(col, energy)
	return mat_cache[key]


func _spawn_shot(p: Vector3, dir: Vector3, owner_id: int, rocket: bool = false) -> void:
	var n: Node3D
	var spin: Node3D = null
	var v = dir.normalized() * LASER_SPEED
	var life = LASER_LIFE
	var dmg = LASER_DMG
	if rocket:

		n = Node3D.new()
		var col = Color(0.9, 0.9, 0.9)
		if owner_id <= ENEMY_BASE:
			col = Color(1.0, 0.15, 0.6)
		if players.has(owner_id):
			col = COLORS[players[owner_id].col]
		Lib.missile_model(n, col, true)
		v = dir.normalized() * ROCKET_SPEED
		life = ROCKET_LIFE
		_sfx_missile(owner_id, p)
		dmg = ROCKET_DMG
	else:
		var mi = MeshInstance3D.new()
		mi.mesh = laser_mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if owner_id == 0:
			mi.material_override = _glow_mat("bolt", Color(1.0, 0.15, 0.1), 5.0)
			v = dir.normalized() * BOLT_SPEED
			life = 2.2
		else:
			mi.material_override = _glow_mat("acebolt", Color(1.0, 0.3, 0.75), 4.0)
		n = mi
		if owner_id > ENEMY_BASE and owner_id != 0:

			mi.free()
			n = Node3D.new()
			spin = Node3D.new()
			spin.rotation.x = randf() * TAU
			n.add_child(spin)
			var oval = MeshInstance3D.new()
			oval.mesh = pop_mesh
			oval.material_override = _glow_mat("gold_oval", Color(1.0, 0.78, 0.15), 3.5)
			oval.scale = Vector3(1.15, 0.7, 2.0)
			oval.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			spin.add_child(oval)

			var fleck = MeshInstance3D.new()
			fleck.mesh = pop_mesh
			fleck.material_override = _glow_mat("gold_fleck", Color(1.0, 0.97, 0.8), 7.0)
			fleck.scale = Vector3(0.5, 0.3, 0.6)
			fleck.position = Vector3(0, 0.55, 1.1)
			fleck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			spin.add_child(fleck)
	add_child(n)
	Lib.face(n, p, dir)
	if owner_id == 0:
		n.scale = Vector3(2.2, 2.2, 1.0)

	if not rocket and (owner_id == 0 or owner_id <= ENEMY_BASE) and not sfx_enemy_lasers.is_empty():
		_sfx(sfx_enemy_lasers[randi() % sfx_enemy_lasers.size()], -5.0, p)
	shots.append({"n": n, "p": p, "o": p, "v": v, "life": life, "owner": owner_id, "dmg": dmg, "rocket": rocket, "trail": 0.0, "spin": spin})


func _tick_shots(dt: float) -> void:
	var me = ships.get(my_id)
	var i = shots.size() - 1
	while i >= 0:
		var sh = shots[i]
		var p0 = sh.p
		var p1 = p0 + sh.v * dt
		var dead = false
		sh.life -= dt
		if sh.spin != null:
			sh.spin.rotation.x += 13.0 * dt
		if sh.rocket:
			sh.trail -= dt
			if sh.trail <= 0.0:
				sh.trail = 0.02
				if sh.owner <= ENEMY_BASE:
					_puff(p0 - sh.v.normalized() * 5.0, 2.6, 1.1, true)
				else:
					_puff(p0 - sh.v.normalized() * 5.0, 1.8, 1.1)
		if sh.life <= 0.0 or p1.y < 0.0:
			dead = true
		elif sh.owner == 0 and (_seg_pillar(p0, p1) >= 0 or _seg_box(p0, p1) or _seg_solid(p0, p1, sh.o, sh.o)):
			# 0.6.5: turret bolts stop at towers and the boss instead of passing through
			dead = true
			_pop(p1, 2.5, Color(1.0, 0.4, 0.1))
		elif sh.owner == 0:
			if me != null and me.alive and Lib.seg_sphere(p0, p1, me.position, SHIP_R):
				dead = true
				if me.rolling:
					_pop(p1, 3.0, Color(1, 1, 1))
				elif shield_t <= 0.0:
					_pop(p1, 4.0, Color(1.0, 0.4, 0.1))
					_my_shield(p0)
					_to_host("c_took", [BOLT_DMG, 1])
			if not dead and is_host:
				for bid in bots:
					var bs = ships.get(bid)
					if bs != null and bs.alive and Lib.seg_sphere(p0, p1, bs.position, SHIP_R):
						dead = true
						_pop(p1, 4.0, Color(1.0, 0.4, 0.1))
						_apply_took(bid, BOLT_DMG, 1)
						rpc("ev_shield", bid, (p0 - bs.position).normalized())
						break
		else:
			if sh.owner == my_id or (is_host and sh.owner < 0):
				dead = _my_shot_hits(p0, p1, sh.dmg, sh.owner)
			if not dead:
				var hk = _hit_kind(p0, p1)
				if hk != 0:
					dead = true
					_pop(p1, 2.0, Color(0.8, 0.8, 0.9))
					_make_hole(hk, p1, sh.v.normalized(), sh.rocket)
					if hk == 1:

						if sh.owner == my_id:
							_to_host("c_hit_body", [sh.dmg])
						elif is_host and sh.owner < 0 and sh.owner > ENEMY_BASE:
							_apply_hit_body(sh.owner, sh.dmg)
					if hk == 2 and last_tower >= 0:
						if sh.owner == my_id:
							_to_host("c_hit_tower", [last_tower, sh.dmg])
						elif is_host and sh.owner < 0 and sh.owner > ENEMY_BASE:
							_apply_hit_tower(sh.owner, last_tower, sh.dmg)
		if dead:

			if not sh.rocket and sh.life > 0.0 and p1.y >= 0.0:
				_sfx_impact(p1)
			if sh.life > 0.0:
				if p1.y < 0.0:
					_impact_fx(Vector3(p1.x, 0.4, p1.z), Vector3.UP, sh.rocket, sh.owner == 0 or sh.owner <= ENEMY_BASE)
				else:
					_impact_fx(p1, -sh.v.normalized(), sh.rocket, sh.owner == 0 or sh.owner <= ENEMY_BASE)
			if sh.rocket:
				_fireball(p1, 26.0)
				if sh.owner == my_id or (is_host and sh.owner < 0 and sh.owner > ENEMY_BASE):
					_splash(p1, sh.owner)
			sh.n.queue_free()
			shots.remove_at(i)
		else:
			sh.p = p1
			sh.n.position = p1
		i -= 1




func _hit_kind(p0: Vector3, p1: Vector3) -> int:
	var n_static = boss.static_solids.size()
	for k in boss.solids.size():
		var sol = boss.solids[k]
		if Lib.seg_sphere(p0, p1, sol[0], sol[1]):
			return 2 if k < n_static else 1
	last_tower = _seg_pillar(p0, p1)
	if last_tower >= 0:
		return 2
	if _seg_box(p0, p1):
		return 2
	return 0


# 0.6.5 line of sight. The world has no physics bodies: towers are vertical cylinders in `pillars`
# ([centre xz, radius, height]) and the boss is spheres in boss.solids, so LOS uses the same shapes
# the shots collide with. Returns the first tower the segment p0-p1 passes through, or -1.
func _seg_pillar(p0: Vector3, p1: Vector3) -> int:
	var a = Vector2(p0.x, p0.z)
	var d = Vector2(p1.x - p0.x, p1.z - p0.z)
	var dd = d.length_squared()
	for k in pillars.size():
		var pl = pillars[k]
		var h: float = pl[2]
		if h <= 0.0 or (p0.y >= h and p1.y >= h):
			continue
		var f: Vector2 = a - pl[0]
		var c = f.length_squared() - pl[1] * pl[1]
		var t0 = 0.0
		var t1 = 1.0
		if dd < 1.0e-06:
			if c > 0.0:
				continue
		else:
			var bq = f.dot(d)
			var disc = bq * bq - dd * c
			if disc < 0.0:
				continue
			var sq = sqrt(disc)
			t0 = maxf(0.0, (-bq - sq) / dd)
			t1 = minf(1.0, (-bq + sq) / dd)
			if t0 > t1:
				continue
		if minf(lerpf(p0.y, p1.y, t0), lerpf(p0.y, p1.y, t1)) < h:
			return k
	return -1


# True if the segment passes through a boss solid. Spheres holding `origin` (the shooter's own
# mount) or `to` (a target sitting on the boss) are skipped.
func _seg_solid(p0: Vector3, p1: Vector3, origin: Vector3, to: Vector3) -> bool:
	for sol in boss.solids:
		var c: Vector3 = sol[0]
		var r: float = sol[1]
		if origin.distance_to(c) < r or to.distance_to(c) < r + SHIP_R:
			continue
		if Lib.seg_sphere(p0, p1, c, r):
			return true
	return false


func _los(from: Vector3, to: Vector3) -> bool:
	return _seg_pillar(from, to) < 0 and not _seg_box(from, to) and not _seg_solid(from, to, from, to)





func _seg_box(p0: Vector3, p1: Vector3) -> bool:
	for bx in boss.static_boxes:
		if Lib.seg_box(p0, p1, bx[0], bx[1]):
			return true
	return false


# Same answer for LOS_EVERY seconds per key (turret+target, missile), so each pair raycasts ~10x a second.
func _los_cached(key: String, from: Vector3, to: Vector3) -> bool:
	var now = Time.get_ticks_msec()
	var e = los_cache.get(key)
	if e != null and now - e[0] < LOS_EVERY_MS:
		return e[1]
	if los_cache.size() > 4096:
		los_cache.clear()
	var ok = _los(from, to)
	los_cache[key] = [now, ok]
	return ok


func _muzzle(i: int, tpos: Vector3) -> Vector3:
	var pp: Vector3 = boss.parts[i].pos
	return pp + (tpos - pp).normalized() * 9.0





func _make_hole(kind: int, p: Vector3, dir: Vector3, big: bool) -> void:
	if kind == 1:
		if big:
			boss.carve(p + dir * 5.0, dir, 13.0, 0.0)
		else:
			boss.carve(p - dir * 4.0, dir, 2.2, 44.0)
	elif kind == 2:
		if hole_a.size() < HOLE_MAX:
			hole_a.resize(HOLE_MAX)
			hole_b.resize(HOLE_MAX)
		var a = p - dir * 6.0
		var b = p + dir * (4.0 if big else 60.0)
		hole_a[hole_next] = Vector4(a.x, a.y, a.z, 16.0 if big else 2.8)
		hole_b[hole_next] = Vector4(b.x, b.y, b.z, 0.0)
		hole_next = (hole_next + 1) % HOLE_MAX
		hole_count = mini(hole_count + 1, HOLE_MAX)
		_push_holes()


func _push_holes() -> void:
	for mat in Lib.hole_mats:
		mat.set_shader_parameter("hole_a", hole_a)
		mat.set_shader_parameter("hole_b", hole_b)
		mat.set_shader_parameter("hole_n", hole_count)


func _reset_holes() -> void:
	hole_next = 0
	hole_count = 0
	_push_holes()
	boss.reset_damage()





func _my_shot_hits(p0: Vector3, p1: Vector3, dmg: int, shooter: int) -> bool:
	var real = shooter == my_id
	var from_enemy = shooter <= ENEMY_BASE
	var dm = game_mode == MODE_DM and not from_enemy
	for id in ships:
		if dm:
			# deathmatch: any other pilot is a target
			if id == shooter or id <= ENEMY_BASE or not players.has(id):
				continue
		elif (id <= ENEMY_BASE) == from_enemy:
			continue
		var o = ships[id]
		if not o.alive or not (o.has_net or id == my_id):
			continue
		if Lib.seg_sphere(p0, p1, o.position, SHIP_R * (2.0 if id <= ENEMY_BASE else 1.0)):
			if o.rolling:
				_pop(p1, 3.0, Color(1, 1, 1))
			elif not o.shielded:
				_pop(p1, 3.0, Color(1.0, 0.6, 0.1))
				if real:
					hit_t = 0.12
					_to_host("c_hit_player", [id, dmg])
				else:
					_apply_hit_player(shooter, id, dmg)
					if from_enemy:
						rpc("ev_shield", id, (p0 - o.position).normalized())
				if dm:
					rpc("fx_pilot_hit", id, (p0 - o.position).normalized())
			return true
	if from_enemy:
		return false
	for i in boss.parts.size():
		if (alive_mask & (1 << i)) == 0 or dm:
			continue
		var pt = boss.parts[i]
		if Lib.seg_sphere(p0, p1, pt.pos, pt.r):
			if pt.kind == Boss.WEAK and (active_mask & (1 << i)) == 0:

				_pop(p1, 2.0, Color(0.8, 0.8, 0.9))
				if real:
					_to_host("c_hit_body", [dmg])
				else:
					_apply_hit_body(shooter, dmg)
			else:
				_pop(p1, 3.5, Color(1.0, 0.6, 0.1))
				_make_hole(1 if pt.bone >= 0 else 2, p1, (p1 - p0).normalized(), dmg > 10)
				if real:
					hit_t = 0.12
					_to_host("c_hit_part", [i, dmg])
				else:
					_apply_hit_part(shooter, i, dmg)
			return true
	if real:
		for mid in missiles:
			if Lib.seg_sphere(p0, p1, missiles[mid].p, 4.0):
				_to_host("c_hit_missile", [mid])
				return true
	return false



func _tick_beam(dt: float) -> void:
	if not boss.beam_on:
		return
	beam_tick -= dt
	if beam_tick > 0.0:
		return
	beam_tick = 0.15
	var me = ships.get(my_id)
	if me != null and me.alive and shield_t <= 0.0 and _beam_dist(me.position) < BEAM_HIT_R:
		_pop(me.position, 5.0, Color(1.0, 0.2, 0.2))
		_my_shield(boss.beam_origin)
		_to_host("c_took", [BEAM_DMG, 3])
	if is_host:
		for bid in bots:
			var bs = ships.get(bid)
			if bs != null and bs.alive and _beam_dist(bs.position) < BEAM_HIT_R:
				_apply_took(bid, BEAM_DMG, 3)


func _beam_dist(p: Vector3) -> float:
	var o: Vector3 = boss.beam_origin
	var d: Vector3 = boss.beam_dir
	return p.distance_to(o + d * clampf((p - o).dot(d), 0.0, boss.BEAM_LEN))


@rpc("authority", "call_local", "reliable")
func ev_beam(yaw: float, pitch: float, sweep: float) -> void:
	boss.start_beam(yaw, pitch, sweep)
	_say("%s IS CHARGING HIS LASER - get out of his face" % boss_name)


func _tick_missiles(dt: float) -> void:
	var me = ships.get(my_id)
	for mid in missiles.keys():
		var ms = missiles[mid]
		ms.life -= dt
		var tgt = ships.get(ms.target)
		# 0.6.5: only home while the target is in line of sight; without it the missile flies straight
		if tgt != null and tgt.alive and _los_cached("m%d" % mid, ms.p, tgt.position):
			var want = (tgt.position - ms.p).normalized()
			ms.d = (ms.d + (want - ms.d) * minf(1.0, 1.6 * dt)).normalized()
		var mp0: Vector3 = ms.p
		ms.p += ms.d * MISSILE_SPEED * dt
		Lib.face(ms.n, ms.p, ms.d)
		ms.trail -= dt
		if ms.trail <= 0.0:
			ms.trail = 0.04
			_puff(ms.p - ms.d * 5.0, 2.2, 1.5)
		var gone = ms.life <= 0.0 or ms.p.y < 0.0
		if not gone and (_seg_pillar(mp0, ms.p) >= 0 or _seg_box(mp0, ms.p) or _seg_solid(mp0, ms.p, ms.o, ms.o)):
			gone = true
			if is_host:
				host_missiles.erase(mid)
				rpc("ev_missile_gone", mid)
		if ms.target == my_id and me != null and me.alive and ms.p.distance_to(me.position) < SHIP_R + 2.0:
			gone = true
			if shield_t <= 0.0:
				_my_shield(ms.p - ms.d * 4.0)
				_to_host("c_took", [MISSILE_DMG, 2])
			_to_host("c_missile_gone", [mid])
		if is_host and bots.has(ms.target) and tgt != null and tgt.alive and ms.p.distance_to(tgt.position) < SHIP_R + 2.0:
			gone = true
			host_missiles.erase(mid)
			_apply_took(ms.target, MISSILE_DMG, 2)
			rpc("ev_missile_gone", mid)
		if gone and missiles.has(mid):
			_fireball(ms.p, 20.0)
			ms.n.queue_free()
			missiles.erase(mid)


func _pop(pos: Vector3, size: float, col: Color) -> void:
	var n = MeshInstance3D.new()
	n.mesh = pop_mesh
	n.material_override = _glow_mat("pop" + col.to_html(), col, 4.0)
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.position = pos
	n.scale = Vector3.ONE * 0.01
	add_child(n)
	fx.append({"n": n, "t": 0.0, "dur": 0.25 + size * 0.02, "size": size})



# ---- Sparks and debris (standalone 1.0.1) -------------------------------------------------
# Sparks are one MultiMesh of short glowing streaks moved on the CPU; debris are a few small
# tumbling chunks. Both are purely visual and run on every machine from the local shot sim.
const SPARK_MAX = 800
const DEBRIS_MAX = 80
const SPARK_GRAVITY = 45.0
var spark_mm: MultiMesh
var sparks = []
var debris = []
var debris_mesh: BoxMesh


func _setup_sparks() -> void:
	var streak = BoxMesh.new()
	streak.size = Vector3(0.16, 0.16, 1.0)
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	streak.material = mat
	spark_mm = MultiMesh.new()
	spark_mm.transform_format = MultiMesh.TRANSFORM_3D
	spark_mm.use_colors = true
	spark_mm.mesh = streak
	spark_mm.instance_count = SPARK_MAX
	spark_mm.visible_instance_count = 0
	var node = MultiMeshInstance3D.new()
	node.multimesh = spark_mm
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.custom_aabb = AABB(Vector3(-2000, -100, -2000), Vector3(4000, 1200, 4000))
	add_child(node)
	debris_mesh = BoxMesh.new()
	debris_mesh.size = Vector3(0.9, 0.5, 0.7)


func _sparks(pos: Vector3, normal: Vector3, count: int, col: Color, spd: float) -> void:
	var n = normal.normalized() if normal.length() > 0.001 else Vector3.UP
	for k in count:
		var r = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
		var v = (n + r * 0.85).normalized() * spd * randf_range(0.35, 1.15)
		var life = randf_range(0.25, 0.7)
		sparks.append({"p": pos, "v": v, "life": life, "max": life, "col": col})
	while sparks.size() > SPARK_MAX:
		sparks.pop_front()


func _debris(pos: Vector3, normal: Vector3, count: int, col: Color) -> void:
	if not mat_cache.has("debris" + col.to_html()):
		mat_cache["debris" + col.to_html()] = Lib.toon(col)
	for k in count:
		var mi = MeshInstance3D.new()
		mi.mesh = debris_mesh
		mi.material_override = mat_cache["debris" + col.to_html()]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = pos
		mi.scale = Vector3.ONE * randf_range(0.6, 1.6)
		add_child(mi)
		var v = (normal.normalized() + Vector3(randf_range(-1, 1), randf_range(-0.3, 1), randf_range(-1, 1)) * 0.9).normalized() * randf_range(12.0, 30.0)
		debris.append({"n": mi, "v": v, "w": Vector3(randf_range(-9, 9), randf_range(-9, 9), randf_range(-9, 9)), "life": randf_range(1.2, 2.2), "smoke": 0.0})
	while debris.size() > DEBRIS_MAX:
		debris[0].n.queue_free()
		debris.pop_front()


# A shot hit something solid (boss, tower, building, ground) or was deflected.
func _impact_fx(pos: Vector3, normal: Vector3, big: bool, enemy_shot: bool) -> void:
	var col = Color(1.0, 0.35, 0.15) if enemy_shot else Color(1.0, 0.78, 0.35)
	if big:
		_sparks(pos, normal, 34, col, 60.0)
		_sparks(pos, normal, 10, Color(1, 1, 0.85), 85.0)
		_debris(pos, normal, 5, Color(0.22, 0.22, 0.25))
		_puff(pos + normal * 2.0, 5.0, 1.6, false, true)
	else:
		_sparks(pos, normal, 10, col, 40.0)
		if randf() < 0.35:
			_debris(pos, normal, 1, Color(0.3, 0.3, 0.33))
		if randf() < 0.5:
			_puff(pos + normal * 1.0, 1.6, 0.8, false, true)


# Shield flash on a ship: a ring of cold blue sparks off the shield bubble.
func _shield_sparks(s: Node3D, dir: Vector3) -> void:
	if s == null or dir.length() < 0.001:
		return
	_sparks(s.position + dir.normalized() * SHIP_R * 1.3, dir, 9, Color(0.45, 0.85, 1.0), 32.0)


# Shield is down: hot sparks, a puff of smoke and a chunk of hull.
var ar_seen = {}
var spark_cd = {}


func _hull_hit(s, dir: Vector3) -> void:
	if s == null:
		return
	var d = dir.normalized() if dir.length() > 0.001 else Vector3.UP
	var at = s.position + d * SHIP_R
	s.add_scorch(d, t)
	_sparks(at, d, 16, Color(1.0, 0.6, 0.2), 45.0)
	_pop(at, 2.5, Color(1.0, 0.5, 0.1))
	_puff(at, 2.2, 1.0, false, true)
	if randf() < 0.5:
		_debris(at, d, 1, Color(0.5, 0.5, 0.55))


func _tick_sparks(dt: float) -> void:
	if spark_mm == null:
		return
	var keep = []
	var drag = maxf(0.0, 1.0 - 1.8 * dt)
	for s in sparks:
		s.life -= dt
		if s.life <= 0.0:
			continue
		s.v.y -= SPARK_GRAVITY * dt
		s.v *= drag
		s.p += s.v * dt
		if s.p.y < 0.2 and s.v.y < 0.0:
			s.p.y = 0.2
			s.v.y = -s.v.y * 0.35
		keep.append(s)
	sparks = keep
	spark_mm.visible_instance_count = sparks.size()
	for k in sparks.size():
		var s = sparks[k]
		var sp = s.v.length()
		var z = s.v / maxf(sp, 0.001)
		var up = Vector3.UP if absf(z.y) < 0.98 else Vector3.RIGHT
		var b = Basis.looking_at(z, up) * Basis.from_scale(Vector3(1.0, 1.0, clampf(sp * 0.05, 0.4, 3.0)))
		spark_mm.set_instance_transform(k, Transform3D(b, s.p))
		var f = s.life / s.max
		spark_mm.set_instance_color(k, s.col * (1.0 + 3.0 * f))
	var j = debris.size() - 1
	while j >= 0:
		var d = debris[j]
		d.life -= dt
		if d.life <= 0.0:
			d.n.queue_free()
			debris.remove_at(j)
		else:
			d.v.y -= 30.0 * dt
			d.n.position += d.v * dt
			d.n.rotation += d.w * dt
			if d.n.position.y < 0.4:
				d.n.position.y = 0.4
				d.v = Vector3(d.v.x * 0.5, absf(d.v.y) * 0.3, d.v.z * 0.5)
				d.w *= 0.6
			d.smoke -= dt
			if d.smoke <= 0.0 and d.life > 0.6:
				d.smoke = 0.12
				_puff(d.n.position, 0.9, 0.6, false, true)
		j -= 1


func _clear_sparks() -> void:
	sparks.clear()
	if spark_mm != null:
		spark_mm.visible_instance_count = 0
	for d in debris:
		d.n.queue_free()
	debris.clear()


func _puff(pos: Vector3, size: float, dur: float, heart: bool = false, dark: bool = false) -> void:
	if not mat_cache.has("smoke"):
		mat_cache["smoke"] = Lib.toon(Color(0.86, 0.86, 0.9))
		var hm = Lib.glow(Color(1.0, 0.35, 0.7), 1.6)
		hm.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat_cache["heart"] = hm
		mat_cache["dark"] = Lib.toon(Color(0.13, 0.13, 0.15))
	var n = MeshInstance3D.new()
	n.mesh = heart_mesh if heart else pop_mesh
	n.material_override = mat_cache["heart"] if heart else (mat_cache["dark"] if dark else mat_cache["smoke"])
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.position = pos + Vector3(randf_range(-0.4, 0.4), randf_range(-0.4, 0.4), randf_range(-0.4, 0.4))
	n.scale = Vector3.ONE * 0.01
	add_child(n)
	smoke.append({"n": n, "t": 0.0, "dur": dur, "size": size * randf_range(0.8, 1.2), "heart": heart})



func _make_heart() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts = []
	var cnt = 24
	for k in cnt:
		var a = TAU * k / cnt
		var sn = sin(a)
		pts.append(Vector2(16.0 * sn * sn * sn, 13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a)) / 16.0)
	var d = 0.25
	for k in cnt:
		var p0: Vector2 = pts[k]
		var p1: Vector2 = pts[(k + 1) % cnt]
		for z in [d, -d]:
			st.add_vertex(Vector3(0, 0, z))
			st.add_vertex(Vector3(p0.x, p0.y, z))
			st.add_vertex(Vector3(p1.x, p1.y, z))
		st.add_vertex(Vector3(p0.x, p0.y, d))
		st.add_vertex(Vector3(p1.x, p1.y, d))
		st.add_vertex(Vector3(p1.x, p1.y, -d))
		st.add_vertex(Vector3(p0.x, p0.y, d))
		st.add_vertex(Vector3(p1.x, p1.y, -d))
		st.add_vertex(Vector3(p0.x, p0.y, -d))
	return st.commit()




func _spawn_wreck(s, id: int) -> void:
	var w = Ship.new()
	add_child(w)
	w.build(s.col, s.elite)
	w.transform = s.transform
	for f in w.flames:
		f.visible = false
	if not s.elite:
		w.set_damage(1.0)
	var v = s.fwd() * (ENEMY_SPEED if s.elite else BASE_SPEED) * 0.85
	wrecks.append({"n": w, "v": v, "t": 0.0, "ang": s.roll, "dir": 1.0 if randf() < 0.5 else -1.0, "smoke": 0.0, "elite": s.elite})
	if id == my_id:
		my_wreck = w


func _point_in_solid(p: Vector3) -> bool:
	for sol in boss.solids:
		if p.distance_to(sol[0]) < sol[1]:
			return true
	for pl in pillars:
		if p.y < pl[2] and Vector2(p.x, p.z).distance_to(pl[0]) < pl[1]:
			return true
	return false


func _tick_wrecks(dt: float) -> void:
	var i = wrecks.size() - 1
	while i >= 0:
		var w = wrecks[i]
		w.t += dt
		w.v = w.v.rotated(Vector3.UP, 1.5 * w.dir * dt)
		w.v.y -= 32.0 * dt
		var p: Vector3 = w.n.position + w.v * dt
		w.ang += (5.0 + 4.0 * w.t) * w.dir * dt
		Lib.face(w.n, p, w.v)
		w.n.basis = w.n.basis * Basis(Vector3(0, 0, 1), w.ang)
		w.smoke -= dt
		if w.smoke <= 0.0:
			w.smoke = 0.03
			_puff(p, 5.0 if w.elite else 3.2, 1.7, false, true)
			if w.elite and randf() < 0.25:
				_puff(p, 4.0, 1.7, true)
		if p.y <= 2.0 or w.t > 9.0 or (w.t > 0.4 and _point_in_solid(p)):
			p.y = maxf(p.y, 2.0)

			if my_wreck == w.n:
				_sfx(sfx_crash, 0.0)
			else:
				_sfx(sfx_crash, 0.0, p)
			_pop(p, 26.0 if w.elite else 18.0, Color(1.0, 0.5, 0.1))
			_pop(p, 14.0 if w.elite else 10.0, Color(1, 1, 1))
			for k in 8:
				var off = Vector3(randf_range(-9, 9), randf_range(0, 10), randf_range(-9, 9))
				_puff(p + off, 7.0, 2.4, w.elite, not w.elite)
			if my_wreck == w.n:
				my_wreck = null
			w.n.queue_free()
			wrecks.remove_at(i)
		i -= 1







func _tick_pdc(dt: float) -> void:
	pdc_hit_cd -= dt
	var me = ships.get(my_id)
	for i in boss.parts.size():
		var pt = boss.parts[i]
		if pt.kind != Boss.PDC or (alive_mask & (1 << i)) == 0:
			continue
		var aim = null
		var best_d = PDC_RANGE
		for sh in shots:
			if sh.rocket and sh.owner > ENEMY_BASE and sh.owner != 0:
				var dd = sh.p.distance_to(pt.pos)
				if dd < best_d and _los(_muzzle(i, sh.p), sh.p):
					best_d = dd
					aim = sh.p + sh.v * (dd / PDC_SPEED)
		if aim == null:
			var tid = _nearest_pilot(pt.pos, PDC_PILOT_RANGE, i)
			if tid != 0:
				var ts = ships[tid]
				var td = ts.position.distance_to(pt.pos)
				aim = ts.position + ts.fwd() * BASE_SPEED * (td / PDC_SPEED)
		if aim == null:
			continue
		if boss.below_mount(i, aim - pt.pos):

			if i == boss.roof_gun_i:
				los_log["roof_held_pitch"] = los_log.get("roof_held_pitch", 0) + 1
			continue
		boss.track(i, aim, dt)
		boss.kick(i)
		pdc_acc[i] = pdc_acc.get(i, 0.0) + PDC_RATE * dt
		var dir = boss.muzzle_dir(i)
		while pdc_acc[i] >= 1.0:
			pdc_acc[i] -= 1.0
			if i == boss.roof_gun_i:
				los_log["roof_rounds_fired"] = los_log.get("roof_rounds_fired", 0) + 1
			if pdc_b.size() < PDC_MAX:
				var d = (dir + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * 0.012).normalized()
				pdc_b.append([pt.pos + d * 14.0, d * PDC_SPEED, PDC_LIFE])


	var k = pdc_b.size() - 1
	while k >= 0:
		var bl = pdc_b[k]
		var p0: Vector3 = bl[0]
		var p1: Vector3 = p0 + bl[1] * dt
		bl[0] = p1
		bl[2] -= dt
		var gone = bl[2] <= 0.0 or p1.y < 0.0 or _seg_pillar(p0, p1) >= 0
		if not gone and _seg_box(p0, p1):

			gone = true
			los_log["pdc_rounds_stopped_by_building"] = los_log.get("pdc_rounds_stopped_by_building", 0) + 1
		if not gone:
			for si in shots.size():
				var sh = shots[si]
				if sh.rocket and sh.owner > ENEMY_BASE and sh.owner != 0 and Lib.seg_sphere(p0, p1, sh.p, 3.5):

					_pop(sh.p, 7.0, Color(1.0, 0.7, 0.3))
					_sfx_impact(sh.p)
					sh.n.queue_free()
					shots.remove_at(si)
					gone = true
					break
		if not gone and me != null and me.alive and Lib.seg_sphere(p0, p1, me.position, SHIP_R):
			gone = true
			if pdc_hit_cd <= 0.0 and shield_t <= 0.0 and not me.rolling:
				pdc_hit_cd = 0.1
				_my_shield(p0)
				_to_host("c_took", [PDC_DMG, 1])
		if not gone and is_host:
			for bid in bots:
				var bs = ships.get(bid)
				if bs != null and bs.alive and Lib.seg_sphere(p0, p1, bs.position, SHIP_R):
					gone = true
					_apply_took(bid, PDC_DMG, 1)
					rpc("ev_shield", bid, (p0 - bs.position).normalized())
					break
		if gone:
			pdc_b.remove_at(k)
		k -= 1
	var count = pdc_b.size()
	pdc_mm.visible_instance_count = count
	for n in count:
		var bb = pdc_b[n]
		var vd: Vector3 = bb[1].normalized()
		pdc_mm.set_instance_transform(n, Transform3D(Basis.looking_at(vd, Vector3.UP if absf(vd.y) < 0.95 else Vector3.RIGHT), bb[0]))



func _track_turrets(dt: float) -> void:
	for i in boss.parts.size():
		var pt = boss.parts[i]
		if pt.kind == Boss.WEAK or pt.kind == Boss.PDC or (alive_mask & (1 << i)) == 0:
			continue
		var tgt = _nearest_pilot(pt.pos, 450.0, i)
		if tgt != 0:
			boss.track(i, ships[tgt].position, dt)



# part >= 0: only pilots that boss part can see (cached LOS from its muzzle).
func _nearest_pilot(from: Vector3, max_d: float, part: int = -1) -> int:
	var best = 0
	var best_d = max_d
	for id in ships:
		if id <= ENEMY_BASE or not players.has(id):
			continue
		var o = ships[id]
		if not o.alive or not (o.has_net or id == my_id):
			continue
		var dd = o.position.distance_to(from)
		if dd < best_d and part >= 0 and boss.below_mount(part, o.position - boss.parts[part].pos):
			if part == boss.roof_gun_i:
				los_log["roof_held_pitch"] = los_log.get("roof_held_pitch", 0) + 1
			continue
		if dd < best_d and part >= 0 and part == boss.roof_gun_i and not _los_cached("p%d_%d" % [part, id], _muzzle(part, o.position), o.position):
			los_log["roof_held_los"] = los_log.get("roof_held_los", 0) + 1
			continue
		if dd < best_d and (part < 0 or _los_cached("p%d_%d" % [part, id], _muzzle(part, o.position), o.position)):
			best_d = dd
			best = id
	return best




func _fireball(pos: Vector3, size: float) -> void:
	if not sfx_explosions.is_empty():
		_sfx(sfx_explosions[randi() % sfx_explosions.size()], 0.0, pos)
	var n = Node3D.new()
	n.position = pos
	add_child(n)
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.75, 0.2, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.1)
	mat.emission_energy_multiplier = 3.0
	var shell = MeshInstance3D.new()
	shell.mesh = pop_mesh
	shell.material_override = mat
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(shell)
	var core = MeshInstance3D.new()
	core.mesh = pop_mesh
	core.material_override = _glow_mat("fb_core", Color(1.0, 0.95, 0.75), 7.0)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(core)
	n.scale = Vector3.ONE * 0.01
	fireballs.append({"n": n, "shell": shell, "core": core, "mat": mat, "t": 0.0, "dur": 1.9, "size": size, "puff": 0.0})


func _tick_fireballs(dt: float) -> void:
	var i = fireballs.size() - 1
	while i >= 0:
		var fb = fireballs[i]
		fb.t += dt
		var k = fb.t / fb.dur
		if k >= 1.0:
			fb.n.queue_free()
			fireballs.remove_at(i)
		else:

			var grow = 1.0 - pow(1.0 - k, 4.0)
			fb.n.scale = Vector3.ONE * maxf(0.01, fb.size * grow)
			fb.core.scale = Vector3.ONE * maxf(0.01, 0.75 * (1.0 - k * 1.6))
			fb.core.visible = k < 0.6
			var hot = Color(1.0, 0.8, 0.25).lerp(Color(0.75, 0.08, 0.02), k)
			fb.mat.albedo_color = Color(hot.r, hot.g, hot.b, 0.85 * pow(1.0 - k, 1.3))
			fb.mat.emission = hot
			fb.mat.emission_energy_multiplier = 3.5 * (1.0 - k) + 0.3
			fb.puff -= dt
			if fb.puff <= 0.0 and k > 0.35:
				fb.puff = 0.12
				var off = Vector3(randf_range(-1, 1), randf_range(-0.3, 1), randf_range(-1, 1)).normalized() * fb.size * grow * 0.8
				_puff(fb.n.position + off, fb.size * 0.22, 1.6, false, true)
		i -= 1



func _splash(pos: Vector3, shooter: int) -> void:
	var real = shooter == my_id
	for id in ships:
		if game_mode == MODE_DM:
			if id == shooter or id <= ENEMY_BASE or not players.has(id):
				continue
		elif id > ENEMY_BASE:
			continue
		var o = ships[id]
		if o.alive and (o.has_net or id == my_id) and o.position.distance_to(pos) < SPLASH_R:
			if real:
				_to_host("c_hit_player", [id, SPLASH_DMG])
			else:
				_apply_hit_player(shooter, id, SPLASH_DMG)
	for i in boss.parts.size():
		if (alive_mask & (1 << i)) == 0:
			continue
		var pt = boss.parts[i]
		if pt.kind == Boss.WEAK and (active_mask & (1 << i)) == 0:
			continue
		if pt.pos.distance_to(pos) < SPLASH_R:
			if real:
				_to_host("c_hit_part", [i, SPLASH_DMG])
			else:
				_apply_hit_part(shooter, i, SPLASH_DMG)


func _tick_fx(dt: float) -> void:
	_tick_fireballs(dt)
	_tick_sparks(dt)
	var j = smoke.size() - 1
	while j >= 0:
		var sm = smoke[j]
		sm.t += dt
		if sm.t >= sm.dur:
			sm.n.queue_free()
			smoke.remove_at(j)
		else:
			var k = sm.t / sm.dur
			var sc = maxf(0.01, sm.size * minf(1.0, 0.35 + k * 5.0) * (1.0 - k * k))
			if sm.heart:

				sm.n.basis = cam.global_transform.basis.orthonormalized().scaled(Vector3.ONE * sc)
			else:
				sm.n.scale = Vector3.ONE * sc
			sm.n.position.y += 1.5 * dt
		j -= 1
	var i = fx.size() - 1
	while i >= 0:
		var f = fx[i]
		f.t += dt
		if f.t >= f.dur:
			f.n.queue_free()
			fx.remove_at(i)
		else:
			f.n.scale = Vector3.ONE * maxf(0.01, f.size * sin(f.t / f.dur * PI))
		i -= 1


func _camera(dt: float) -> void:
	var s = ships.get(my_id)
	if state == PLAYING and s != null:
		if not s.alive:
			var wreck_ok = my_wreck != null and is_instance_valid(my_wreck) and not my_wreck.is_queued_for_deletion()
			var out = game_mode == MODE_DM and players.has(my_id) and players[my_id].lives <= 0
			if out and not wreck_ok:
				# knocked out of the deathmatch: ride along behind a pilot who is still flying
				if not _can_spectate(spec_target):
					spec_target = _next_spectate(spec_target)
				if spec_target != 0:
					var ts = ships[spec_target]
					var sb = Basis.from_euler(Vector3(ts.pitch * 0.5, ts.yaw, 0.0))
					var want = ts.position + sb * Vector3(0.0, 7.0, 28.0)
					cam.position = cam.position.lerp(want, minf(1.0, 4.0 * dt))
					if cam.position.distance_to(ts.position) > 2.0:
						cam.look_at(ts.position + sb * Vector3(0.0, 2.0, -30.0), Vector3.UP)
			elif wreck_ok:
				if cam.position.distance_to(my_wreck.position) > 2.0:
					cam.look_at(my_wreck.position, Vector3.UP)
			boost_fx = 0.0
			cam_shake = 0.0
			_tick_streaks(dt, null)
			return
		if s.boosting and not cam_was_boost:
			cam_shake = 1.0
			_sfx_ignite()
		cam_was_boost = s.boosting
		boost_fx = move_toward(boost_fx, 1.0 if s.boosting else 0.0, dt * (5.0 if s.boosting else 2.0))
		cam_shake = maxf(0.0, cam_shake - dt * 2.2)
		if loop_t > 0.0:


			var rel = cam.global_position - s.position
			if rel.length() > CAM_FOLLOW_D * 1.4:
				cam.global_position = s.position + rel.normalized() * CAM_FOLLOW_D * 1.4
			_cam_leash(s)
			if cam.position.distance_to(s.position) > 2.0:
				var up = Vector3.UP
				if absf((s.position - cam.position).normalized().y) > 0.97:
					up = Vector3.FORWARD
				cam.look_at(s.position, up)
			_tick_streaks(dt, null)
			if camlog:
				_camlog_tick(s)
			return


		cam_yaw = lerp_angle(cam_yaw, s.yaw, minf(1.0, 5.0 * dt))
		cam_pitch = lerpf(cam_pitch, s.pitch, minf(1.0, 4.0 * dt))
		var b = Basis.from_euler(Vector3(cam_pitch * 0.7, cam_yaw, 0.0))
		cam_slide = cam_slide.lerp(Vector3.ZERO, minf(1.0, maxf(ROLL_CAM_FOLLOW, 0.1) * dt))



		cam_k = move_toward(cam_k, 1.0 if s.boosting else 0.0, dt / 0.4)
		var e = smoothstep(0.0, 1.0, cam_k)
		cam.position = s.position + cam_slide + b * Vector3(0.0, 4.0, 19.0)
		cam.look_at(s.position + cam_slide + b * Vector3(0.0, 1.5, -40.0), Vector3.UP)
		_cam_leash(s)
		var base_fov = 63.0 if speed < BASE_SPEED - 8.0 else 70.0
		cam_base_fov = lerpf(cam_base_fov, base_fov, minf(1.0, 4.0 * dt))
		cam.fov = clampf(cam_base_fov + 5.0 * e, 55.0, 80.0)
		_tick_streaks(dt, s)
		_cam_leash(s)
		if camlog:
			_camlog_tick(s)
	else:
		boost_fx = 0.0
		cam_shake = 0.0
		_tick_streaks(dt, null)


		var a = t * 0.15
		cam.position = Vector3(cos(a) * 330.0, 150.0, sin(a) * 330.0)
		cam.look_at(Vector3(0, 105, 0), Vector3.UP)
		cam.fov = 70.0




func _can_spectate(id: int) -> bool:
	return id != 0 and id != my_id and ships.has(id) and players.has(id) and ships[id].alive and ships[id].visible


func _next_spectate(cur: int) -> int:
	var ids = ranking()
	if ids.is_empty():
		return 0
	var start = ids.find(cur)
	for k in ids.size():
		var id = ids[(start + 1 + k) % ids.size()]
		if _can_spectate(id):
			return id
	return 0


const CAM_FOLLOW_D = 19.42
func _cam_leash(s: Node3D) -> void:
	var p: Vector3 = cam.global_position
	var bad = not (is_finite(p.x) and is_finite(p.y) and is_finite(p.z))
	if bad or p.distance_to(s.position) > CAM_FOLLOW_D * 1.5:
		var b = Basis.from_euler(Vector3(s.pitch * 0.7, s.yaw, 0.0))
		cam_yaw = s.yaw
		cam_pitch = s.pitch
		cam_slide = Vector3.ZERO
		cam.global_position = s.position + b * Vector3(0.0, 4.0, 19.0)
		cam.look_at(s.position + b * Vector3(0.0, 1.5, -40.0), Vector3.UP)
		cam_snaps += 1
		print("CAM_SNAP n=%d was=%.1f m" % [cam_snaps, -1.0 if bad else p.distance_to(s.position)])


func _streak_spot(far: bool) -> Vector3:
	var a = randf() * TAU
	var r = randf_range(5.0, 26.0)
	return Vector3(cos(a) * r, sin(a) * r * 0.75, randf_range(-95.0, -60.0) if far else randf_range(-95.0, 25.0))


func _tick_streaks(dt: float, s) -> void:
	var on = s != null and boost_fx > 0.01
	if not on:
		for st in streaks:
			st[0].visible = false
		return
	if streaks.is_empty():
		streak_mat = StandardMaterial3D.new()
		streak_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		streak_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		streak_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		streak_mat.albedo_color = Color(0.7, 0.88, 1.0, 0.0)
		var bm = BoxMesh.new()
		bm.size = Vector3(0.1, 0.1, 1.0)
		for i in 48:
			var mi = MeshInstance3D.new()
			mi.mesh = bm
			mi.material_override = streak_mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mi)
			streaks.append([mi, _streak_spot(false)])
	streak_mat.albedo_color.a = 0.6 * boost_fx
	var b = Basis.from_euler(Vector3(s.pitch, s.yaw, 0.0))
	var length = 4.0 + 16.0 * boost_fx
	var rush = (speed * 1.4 + 40.0) * dt
	var stretch = b * Basis.from_scale(Vector3(1.0, 1.0, length))
	for st in streaks:
		var off: Vector3 = st[1]
		off.z += rush
		if off.z > 25.0:
			off = _streak_spot(true)
		st[1] = off
		st[0].visible = true
		st[0].transform = Transform3D(stretch, s.position + b * off)


func _say(text: String) -> void:
	feed.append([text, 5.0])
	if feed.size() > 6:
		feed.remove_at(0)




func _host_tick(dt: float) -> void:
	if state == LOBBY:
		if autostart >= 0.0:
			autostart -= dt
			if autostart <= 0.0:
				autostart = -1.0
				_host_start()
	elif state == PLAYING:
		match_t += dt
		for id in hostp:
			var h = hostp[id]
			h.protect = maxf(0.0, h.protect - dt)

			if h.alive and players.has(id):
				h["since"] = h.get("since", 0.0) + dt
				if h["since"] > SHIELD_DELAY and players[id].hp < SHIELD_MAX:
					h["regen"] = h.get("regen", 0.0) + SHIELD_REGEN * dt
					var whole = int(h["regen"])
					if whole > 0:
						h["regen"] -= whole
						players[id].hp = mini(SHIELD_MAX, players[id].hp + whole)
			if not h.alive:
				h.respawn -= dt
				if h.respawn <= 0.0 and players.has(id):
					h.alive = true
					h.protect = 2.5
					players[id].hp = SHIELD_MAX
					players[id].ar = ARMOR_MAX
					rpc("ev_respawn", id)
					if bots.has(id):
						_bot_place(id, randf() * TAU)
		for mid in host_missiles.keys():
			host_missiles[mid] -= dt
			if host_missiles[mid] <= 0.0:
				host_missiles.erase(mid)
		if game_mode == MODE_BOSS:
			_host_boss(dt)
			_host_enemies(dt)
		_host_bots(dt)
		if game_mode == MODE_DM and end_timer < 0.0:
			var flying = 0
			for id in players:
				if players[id].lives > 0:
					flying += 1
			if flying <= 1:
				end_timer = 3.0
				print("GB_DM_OVER flying=%d" % flying)
		if end_timer >= 0.0:
			end_timer -= dt
			if end_timer <= 0.0:
				_host_end()
	snap_cd -= dt
	if snap_cd <= 0.0:
		snap_cd = 0.1
		_send_snap()


func _send_snap() -> void:
	var ids = PackedInt32Array()
	var scores = PackedInt32Array()
	var hps = PackedInt32Array()
	var ars = PackedInt32Array()
	var lv = PackedInt32Array()
	var el = PackedInt32Array()
	for id in players:
		ids.append(id)
		scores.append(players[id].score)
		hps.append(players[id].hp)
		ars.append(players[id].ar)
		lv.append(players[id].lives)
		el.append(players[id].elim)
	var ehp = PackedInt32Array()
	for e in ENEMY_COUNT:
		var eid = ENEMY_BASE - 1 - e
		var v = -1
		if enemies.has(eid) and enemies[eid].alive:
			v = enemies[eid].hp
		ehp.append(v)
		enemy_hp[eid] = v
	var tmask = 0
	for k in towers.size():
		if towers[k].down:
			tmask |= 1 << k
	rpc("snap", state, match_t, ids, scores, hps, ars, alive_mask, active_mask, ehp, tmask, boss_hp, boss_hp_max, lv, el, game_mode)


@rpc("authority", "call_remote", "unreliable_ordered")
func snap(s: int, tl: float, ids: PackedInt32Array, scores: PackedInt32Array, hps: PackedInt32Array, ars: PackedInt32Array, am: int, acm: int, ehp: PackedInt32Array, tmask: int, bhp: int, bmax: int, lv: PackedInt32Array, el: PackedInt32Array, mode: int) -> void:
	if state == MENU or not players.has(my_id):
		return
	match_t = tl
	game_mode = clampi(mode, 0, MODE_NAMES.size() - 1)
	boss_hp = bhp
	boss_hp_max = bmax
	alive_mask = am
	active_mask = acm
	for i in ids.size():
		if players.has(ids[i]):
			players[ids[i]].score = scores[i]
			players[ids[i]].hp = hps[i]
			players[ids[i]].ar = ars[i]
			if i < lv.size():
				players[ids[i]].lives = lv[i]
			if i < el.size():
				players[ids[i]].elim = el[i]
	for e in ehp.size():
		enemy_hp[ENEMY_BASE - 1 - e] = ehp[e]
	if state == PLAYING and s == PLAYING:
		for k in towers.size():
			if (tmask & (1 << k)) != 0 and not towers[k].down:
				_fell_tower(k, 0.0, true)
	if s != state:
		if s == PLAYING:
			_begin_local()
		elif s == RESULTS:
			state = RESULTS
			results_t = RESULTS_TIME
			_make_end_text()
		elif s == LOBBY:
			state = LOBBY


func _reset_parts() -> void:
	part_hp.clear()
	part_alive.clear()
	part_cd.clear()
	part_respawn.clear()
	weak_active.clear()
	for p in boss.parts:
		var hp = _kind_hp(p.kind)
		part_hp.append(hp)
		part_alive.append(true)
		part_cd.append(randf_range(2.0, 5.0))
		part_respawn.append(0.0)
		weak_active.append(false)
	_recalc_masks()


func _kind_hp(kind: int) -> int:
	if kind == Boss.TURRET:
		return TURRET_HP
	if kind == Boss.POD:
		return POD_HP
	if kind == Boss.PDC:
		return PDC_HP
	return WEAK_HP


func _recalc_masks() -> void:
	alive_mask = 0
	active_mask = 0
	for i in part_alive.size():
		if part_alive[i]:
			alive_mask |= 1 << i
		if weak_active[i]:
			active_mask |= 1 << i


func _weak_indices() -> Array:
	var out = []
	for i in boss.parts.size():
		if boss.parts[i].kind == Boss.WEAK:
			out.append(i)
	return out


func _shuffle_weak() -> void:
	var w = _weak_indices()
	w.shuffle()
	for i in weak_active.size():
		weak_active[i] = false
	for i in mini(3, w.size()):
		weak_active[w[i]] = true
		part_hp[w[i]] = WEAK_HP
	weak_timer = 10.0
	_recalc_masks()


func _host_boss(dt: float) -> void:
	beam_cd -= dt
	if beam_cd <= 0.0:
		beam_cd = randf_range(16.0, 22.0)
		var cands = []
		for id in hostp:
			if hostp[id].alive and ships.has(id) and (id == my_id or ships[id].has_net):
				cands.append(id)
		if cands.size() > 0:
			var tp: Vector3 = ships[cands[randi() % cands.size()]].position
			var yaw = clampf(atan2(tp.x, tp.z), -2.0, 2.0)
			var pitch = clampf(atan2(tp.y - 163.0, maxf(1.0, Vector2(tp.x, tp.z).length())), -0.6, 0.6)
			rpc("ev_beam", yaw, pitch, 1.0 if randf() < 0.5 else -1.0)
			_radio(0, ["FEED. THE. FURNACE.", "GET OUT OF MY FACE.", "YOU ARE IN MY WAY."])
	weak_timer -= dt
	if weak_timer <= 0.0:
		_shuffle_weak()
	var changed = false
	for i in boss.parts.size():
		var p = boss.parts[i]
		if p.kind == Boss.WEAK:
			continue
		if not part_alive[i]:
			part_respawn[i] -= dt
			if part_respawn[i] <= 0.0:
				part_alive[i] = true
				part_hp[i] = _kind_hp(p.kind)
				part_cd[i] = 2.0
				changed = true
			continue
		if p.kind == Boss.PDC:
			continue
		part_cd[i] -= dt
		if part_cd[i] > 0.0:
			continue
		if p.kind == Boss.TURRET:
			part_cd[i] = randf_range(1.6, 2.8)
			var best = null
			var best_d = 320.0
			for id in ships:
				if hostp.has(id) and hostp[id].alive and (id == my_id or ships[id].has_net):
					var dd = ships[id].position.distance_to(p.pos)
					if dd < best_d and _los_cached("p%d_%d" % [i, id], _muzzle(i, ships[id].position), ships[id].position):
						best_d = dd
						best = ships[id]
			if best == null:
				part_cd[i] = 0.25
			else:
				var lead = best.position + best.fwd() * BASE_SPEED * (best_d / BOLT_SPEED)
				var dir = (lead - p.pos).normalized()
				if boss.below_mount(i, dir):

					part_cd[i] = 0.25
					continue
				dir = (dir + Vector3(randf_range(-0.03, 0.03), randf_range(-0.03, 0.03), randf_range(-0.03, 0.03))).normalized()
				rpc("ev_bolt", i, dir)
		else:
			part_cd[i] = randf_range(5.0, 8.0)
			var tgt = _nearest_pilot(p.pos, 520.0, i)
			if tgt == 0:
				part_cd[i] = 0.5
			elif hostp.has(tgt) and hostp[tgt].alive:
				missile_seq += 1
				host_missiles[missile_seq] = MISSILE_LIFE
				rpc("ev_missile", missile_seq, i, tgt)
	if changed:
		_recalc_masks()


@rpc("any_peer", "call_remote", "reliable")
func c_hit_body(dmg: int) -> void:
	if is_host:
		_apply_hit_body(_sender(), dmg)


func _apply_hit_body(from: int, dmg: int) -> void:
	if state != PLAYING or boss_hp <= 0 or not players.has(from) or game_mode == MODE_DM:
		return
	var amount = maxi(1, int(round(clampi(dmg, 0, 1000) * BODY_MULT)))
	players[from].score += amount
	_boss_damage(from, amount)





func _boss_damage(from: int, amount: int) -> void:
	if boss_hp <= 0:
		return
	boss_hp = maxi(0, boss_hp - amount)
	if boss_hp > 0:
		return
	if players.has(from):
		players[from].score += BOSS_KILL_BONUS
		rpc("ev_feed", "%s FINISHED %s  +%d" % [players[from].name, boss_name, BOSS_KILL_BONUS])
	for i in boss.parts.size():
		if boss.parts[i].bone >= 0:
			part_alive[i] = false
			part_respawn[i] = 100000.0
		weak_active[i] = false
	weak_timer = 100000.0
	beam_cd = 100000.0
	_recalc_masks()
	# no match clock any more: the boss going down is what ends a boss hunt
	end_timer = 6.0
	print("GB_BOSS_DOWN by=%d" % from)




func _hurt(id: int, dmg: int) -> bool:
	var pl = players[id]
	hostp[id]["since"] = 0.0
	var through = dmg
	if pl.hp > 0:
		through = maxi(0, dmg - pl.hp)
		pl.hp = maxi(0, pl.hp - dmg)
	pl.ar -= through
	return pl.ar <= 0


func _host_kill(victim: int, killer: int, why: int) -> void:
	var h = hostp[victim]
	h.alive = false
	h.respawn = RESPAWN_TIME
	players[victim].hp = 0
	players[victim].ar = 0
	if game_mode == MODE_DM:
		players[victim].lives = maxi(0, players[victim].lives - 1)
		if killer != victim and players.has(killer):
			players[killer].score += DM_KILL_SCORE
		if players[victim].lives <= 0:
			h.respawn = INF
			h["out"] = true
			elim_seq += 1
			players[victim].elim = elim_seq
	else:
		players[victim].score = maxi(0, players[victim].score - DEATH_PENALTY)
	rpc("ev_death", victim, killer, why)
	if game_mode == MODE_DM:
		var left = players[victim].lives
		rpc("ev_feed", ("%s IS OUT!" % players[victim].name) if left <= 0 else "%s has %d %s left" % [players[victim].name, left, "life" if left == 1 else "lives"])
	print("GB_KILL victim=%d killer=%d why=%d lives=%d" % [victim, killer, why, players[victim].lives])
	_radio(victim, ["I'm hit! Going down!", "Mayday, mayday!", "Tell my graphics card I loved her!", "Aaaaaagh!"])


@rpc("any_peer", "call_remote", "reliable")
func c_hit_player(target: int, dmg: int) -> void:
	if is_host:
		_apply_hit_player(_sender(), target, dmg)


func _apply_hit_player(from: int, target: int, dmg: int) -> void:
	if state != PLAYING:
		return
	dmg = clampi(dmg, 0, 1000)
	if target <= ENEMY_BASE:

		if from <= ENEMY_BASE or not enemies.has(target) or not players.has(from):
			return
		var e = enemies[target]
		if not e.alive:
			return
		players[from].score += dmg
		e.hp -= dmg
		if e.hp <= 0:
			e.alive = false
			e.respawn = ENEMY_RESPAWN
			players[from].score += ENEMY_BONUS
			rpc("ev_death", target, from, 0)
			rpc("ev_comm", target, ["No, no, NO! I'm going down!", "Eject! EJECT! It won't--", "Tell daddy Huang I tried..."][randi() % 3])
			_radio(from, ["Splash one pink ace!", "Scratch one ace!", "Hearts everywhere. Gross.", "That's for my wingman!"])
	elif from <= ENEMY_BASE:

		if not hostp.has(target) or not players.has(target):
			return
		var h = hostp[target]
		if not h.alive or h.protect > 0.0:
			return
		if _hurt(target, dmg):
			_host_kill(target, from, 0)
	elif game_mode == MODE_DM:
		# deathmatch: pilots shoot each other
		if from == target or not players.has(from) or not players.has(target):
			return
		if not hostp.has(from) or not hostp[from].alive or not hostp.has(target):
			return
		var th = hostp[target]
		if not th.alive or th.protect > 0.0:
			return
		if _hurt(target, dmg):
			_host_kill(target, from, 4)



@rpc("any_peer", "call_remote", "reliable")
func c_took(dmg: int, why: int) -> void:
	if is_host:
		_apply_took(_sender(), dmg, why)


func _apply_took(from: int, dmg: int, why: int) -> void:
	if state != PLAYING:
		return
	if not hostp.has(from) or not players.has(from) or not hostp[from].alive or hostp[from].protect > 0.0:
		return
	if _hurt(from, clampi(dmg, 0, 1000)):
		_host_kill(from, 0, why)


@rpc("any_peer", "call_remote", "reliable")
func c_hit_part(idx: int, dmg: int) -> void:
	if is_host:
		_apply_hit_part(_sender(), idx, dmg)


func _apply_hit_part(from: int, idx: int, dmg: int) -> void:
	if state != PLAYING:
		return
	if not players.has(from) or idx < 0 or idx >= boss.parts.size() or not part_alive[idx] or game_mode == MODE_DM:
		return
	dmg = clampi(dmg, 0, 1000)
	var p = boss.parts[idx]
	if p.kind == Boss.WEAK:
		if not weak_active[idx]:
			return
		players[from].score += dmg * WEAK_MULT
		part_hp[idx] -= dmg
		_boss_damage(from, dmg * WEAK_MULT)
		if part_hp[idx] <= 0:
			players[from].score += WEAK_BONUS
			weak_active[idx] = false
			var cands = []
			for w in _weak_indices():
				if w != idx and not weak_active[w]:
					cands.append(w)
			if cands.size() > 0:
				var nw = cands[randi() % cands.size()]
				weak_active[nw] = true
				part_hp[nw] = WEAK_HP
			rpc("ev_pop", p.pos, 26.0)
			_boss_damage(from, BOSS_BREAK_DMG)
			_radio(from, ["Weak spot cracked!", "That one hurt him!", "He felt that!"])
			rpc("ev_feed", "%s cracked a weak spot  +%d" % [players[from].name, WEAK_BONUS])
	else:
		players[from].score += dmg
		part_hp[idx] -= dmg
		if part_hp[idx] <= 0:
			part_alive[idx] = false
			part_respawn[idx] = TURRET_RESPAWN
			var bonus = TURRET_BONUS
			var what = "turret"
			if p.kind == Boss.POD:
				bonus = POD_BONUS
				what = "missile pod"
			elif p.kind == Boss.PDC:
				bonus = PDC_BONUS
				what = "point-defence cannon"
			players[from].score += bonus
			rpc("ev_blast", p.pos, 24.0 if p.bone >= 0 else 18.0)
			rpc("ev_feed", "%s blew up a %s  +%d" % [players[from].name, what, bonus])
			if p.bone >= 0:

				_boss_damage(from, TURRET_BLAST_DMG)
	_recalc_masks()


@rpc("any_peer", "call_remote", "reliable")
func c_hit_missile(mid: int) -> void:
	if not is_host or not host_missiles.has(mid):
		return
	var from = _sender()
	host_missiles.erase(mid)
	if players.has(from):
		players[from].score += MISSILE_BONUS
	rpc("ev_missile_gone", mid)


@rpc("any_peer", "call_remote", "reliable")
func c_missile_gone(mid: int) -> void:
	if not is_host or not host_missiles.has(mid):
		return
	host_missiles.erase(mid)
	rpc("ev_missile_gone", mid)




const BOT_NAMES = ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel", "India", "Juliet", "Kilo", "Lima", "Mike", "Nova", "Oscar"]
const BOT_SLEW = 1.7
const BOT_AIM_JITTER = 0.04
const ENEMY_SLEW = 2.1
const ENEMY_AIM_JITTER = 0.03


func _ai_state() -> Dictionary:
	return {"think": 0.0, "mode": 0, "tid": 0, "part": -1, "evade": 0.0, "evade_yaw": 0.0, "fire": 0.0, "rocket": randf_range(2.0, 6.0), "wcd": [0.0, 0.0], "wnext": 0, "send": 0.0, "roll": 0.0, "side": 1.0}


func _add_bot() -> void:
	if not is_host or players.size() >= lobby_max:
		return
	var id = -1
	while players.has(id):
		id -= 1
	var used = []
	for p in players:
		used.append(players[p].col)
	var col = 0
	while col in used:
		col += 1
	var d = {}
	for p in players:
		d[p] = [players[p].name, players[p].col]
	d[id] = ["BOT " + BOT_NAMES[(-id - 1) % BOT_NAMES.size()], col % MAX_PLAYERS]
	hostp[id] = {"alive": true, "respawn": 0.0, "protect": 3.0}
	bots[id] = _ai_state()
	rpc("ev_roster", d)
	if state == PLAYING:
		_bot_place(id, randf() * TAU)


func _remove_bot() -> void:
	if not is_host or bots.is_empty():
		return
	var id = bots.keys()[bots.size() - 1]
	bots.erase(id)
	hostp.erase(id)
	var d = {}
	for p in players:
		if p != id:
			d[p] = [players[p].name, players[p].col]
	rpc("ev_roster", d)


func _ai_place(id: int, pos: Vector3) -> void:
	var s = ships.get(id)
	if s == null:
		return
	s.position = pos
	s.yaw = atan2(pos.x, pos.z)
	s.pitch = 0.0
	s.roll = 0.0
	s.alive = true
	s.has_net = true
	s.set_wings(true, true)
	var ab = bots.get(id, enemies.get(id))
	if ab != null and ab.has("wcd"):
		ab.wcd = [0.0, 0.0]
	s.net_pos = s.position
	s.net_yaw = s.yaw
	s.net_pitch = 0.0
	s.net_roll = 0.0
	s.apply()


func _bot_place(id: int, angle: float) -> void:
	_ai_place(id, Vector3(cos(angle) * 370.0, randf_range(70.0, 130.0), sin(angle) * 370.0))
	if bots.has(id):
		bots[id].think = 0.0
		bots[id].evade = 0.0



func _enemy_place(id: int) -> void:
	var a = randf() * TAU
	_ai_place(id, Vector3(cos(a) * 300.0, randf_range(200.0, 270.0), sin(a) * 300.0))
	if enemies.has(id):
		enemies[id].think = 0.0
		enemies[id].evade = 0.0


func _host_bots(dt: float) -> void:
	for id in bots:
		if hostp.has(id) and hostp[id].alive and ships.has(id):
			if not ships[id].alive:
				# respawned: put the bot back in the arena
				ships[id].alive = true
			_ai_step(id, bots[id], dt, false)


func _host_enemies(dt: float) -> void:
	for id in enemies:
		var e = enemies[id]
		if e.alive:
			_ai_step(id, e, dt, true)
		elif ENEMY_RESPAWN >= 0.0:
			e.respawn -= dt
			if e.respawn <= 0.0:
				e.alive = true
				e.hp = ENEMY_HP
				rpc("ev_respawn", id)
				_enemy_place(id)




func _ai_step(id: int, b: Dictionary, dt: float, enemy: bool) -> void:
	var s = ships.get(id)
	if s == null:
		return
	var slew = ENEMY_SLEW if enemy else BOT_SLEW
	var jitter = ENEMY_AIM_JITTER if enemy else BOT_AIM_JITTER
	var spd = ENEMY_SPEED if enemy else BASE_SPEED
	var protected = false
	if not enemy:
		protected = hostp[id].protect > 0.0
	s.has_net = true
	s.shielded = protected

	b.think -= dt
	if b.think <= 0.0:
		b.think = randf_range(2.0, 4.0)
		b.mode = 0
		b.tid = 0
		var best_d = 100000.0
		for oid in ships:
			var ok = false
			if enemy:
				ok = hostp.has(oid) and hostp[oid].alive and (oid == my_id or ships[oid].has_net)
			elif game_mode == MODE_DM:
				ok = oid != id and players.has(oid) and hostp.has(oid) and hostp[oid].alive and (oid == my_id or ships[oid].has_net)
			else:
				ok = enemies.has(oid) and enemies[oid].alive
			if ok:

				var dd = ships[oid].position.distance_to(s.position) * randf_range(0.6, 1.4)
				if dd < best_d:
					best_d = dd
					b.tid = oid
		if not enemy and game_mode == MODE_BOSS and (b.tid == 0 or randf() < 0.5):
			var cands = []
			for i in boss.parts.size():
				if part_alive[i] and (boss.parts[i].kind != Boss.WEAK or weak_active[i]):
					cands.append(i)
			if cands.size() > 0:
				b.mode = 1
				b.part = cands[randi() % cands.size()]

	var tpos = Vector3(0, 220, 0)
	var have_target = false
	if b.mode == 1 and b.part >= 0 and part_alive[b.part]:
		tpos = boss.parts[b.part].pos
		have_target = true
	elif b.tid != 0 and ships.has(b.tid) and ships[b.tid].alive:
		var ts = ships[b.tid]
		tpos = ts.position + ts.fwd() * BASE_SPEED * (ts.position.distance_to(s.position) / LASER_SPEED)
		have_target = true
	else:
		b.think = 0.0
	var to = tpos - s.position
	var dist = to.length()
	var want_yaw = atan2(-to.x, -to.z)
	var want_pitch = clampf(asin(clampf(to.y / maxf(dist, 0.001), -1.0, 1.0)), -0.9, 0.9)


	var flat = Vector2(s.position.x, s.position.z)
	var out_yaw = atan2(-flat.x, -flat.y)
	if b.evade <= 0.0 and flat.length() < 150.0 and s.position.y < 240.0:
		b.evade = randf_range(1.5, 2.5)
		b.evade_yaw = out_yaw + randf_range(-0.7, 0.7)
	if b.evade > 0.0:
		b.evade -= dt
		want_yaw = b.evade_yaw
		want_pitch = 0.25
	for pl in pillars:
		var pd = flat - pl[0]
		if pd.length() < pl[1] + 30.0 and s.position.y < pl[2] + 10.0:
			want_yaw = atan2(-pd.x, -pd.y)
	if flat.length() > ARENA_R - 45.0:
		want_yaw = atan2(flat.x, flat.y)
	if s.position.y < 25.0:
		want_pitch = maxf(want_pitch, 0.4)
	if s.position.y > CEILING - 20.0:
		want_pitch = minf(want_pitch, -0.3)

	var ystep = clampf(wrapf(want_yaw - s.yaw, -PI, PI), -slew * dt, slew * dt)
	s.yaw += ystep
	s.pitch += clampf(want_pitch - s.pitch, -slew * dt, slew * dt)
	var lean = 0.0
	if dt > 0.0:
		lean = ystep / (slew * dt) * 0.7
	b.roll = lerpf(b.roll, lean, minf(1.0, 5.0 * dt))
	s.roll = b.roll
	s.boosting = enemy
	s.position += s.fwd() * spd * dt

	if s.position.y < 4.0:
		s.position.y = 4.0
	for sol in boss.solids:
		var dv = s.position - sol[0]
		var rr = sol[1] + SHIP_R
		if dv.length() < rr:
			s.position = sol[0] + dv.normalized() * rr
	s.apply()
	s.net_pos = s.position
	s.net_yaw = s.yaw
	s.net_pitch = s.pitch
	s.net_roll = s.roll


	b.fire -= dt
	b.rocket -= dt
	for wi in 2:
		b.wcd[wi] = maxf(0.0, b.wcd[wi] - dt)
	s.set_wings(b.wcd[0] <= 0.0, b.wcd[1] <= 0.0)
	if have_target and b.evade <= 0.0 and dist < 380.0 and not protected:
		var fwd = -s.basis.z
		if fwd.angle_to(to) < 0.14 and _los_cached("b%d" % id, s.position + fwd * 4.0, tpos):
			var dir = (fwd + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * jitter).normalized()
			if b.fire <= 0.0:
				b.fire = 0.26
				b.side = -b.side
				var mz = s.position + s.basis * Vector3(2.4 * b.side, 0.0, -2.3)
				_spawn_shot(mz, dir, id)
				rpc("bfx_shot", id, mz, dir)



			if b.rocket <= 0.0 and dist < 260.0:
				var wi = _pick_wing(b.wcd, b.wnext)
				if wi >= 0:
					b.rocket = randf_range(1.5, 3.0) if enemy else randf_range(0.3, 0.8)
					b.wcd[wi] = ROCKET_COOLDOWN
					b.wnext = 1 - wi
					s.set_wings(b.wcd[0] <= 0.0, b.wcd[1] <= 0.0)
					var rp = s.wing_point(wi)
					_spawn_shot(rp, dir, id, true)
					rpc("bfx_rocket", id, rp, dir)

	b.send -= dt
	if b.send <= 0.0:
		b.send = 1.0 / 30.0
		rpc("bst", id, s.position, s.yaw, s.pitch, s.roll, (4 if s.shielded else 0) | (1 if enemy else 0) | _wing_flags(b.wcd))




@rpc("any_peer", "call_remote", "reliable")
func c_hit_tower(i: int, dmg: int) -> void:
	if is_host:
		_apply_hit_tower(_sender(), i, dmg)


func _apply_hit_tower(from: int, i: int, dmg: int) -> void:
	if state != PLAYING or i < 0 or i >= towers.size() or tower_hp[i] <= 0 or not players.has(from):
		return
	tower_hp[i] -= clampi(dmg, 0, 1000)
	if tower_hp[i] <= 0:
		if game_mode == MODE_BOSS:
			players[from].score += TOWER_BONUS
		var tp = towers[i].part
		if tp >= 0:
			part_alive[tp] = false
			part_respawn[tp] = 100000.0
			_recalc_masks()
		rpc("ev_tower_down", i, randf() * TAU)
		if game_mode == MODE_BOSS:
			rpc("ev_feed", "%s brought down a tower  +%d" % [players[from].name, TOWER_BONUS])
		else:
			rpc("ev_feed", "%s brought down a tower" % players[from].name)


@rpc("authority", "call_local", "reliable")
func ev_tower_down(i: int, ang: float) -> void:
	if i >= 0 and i < towers.size():
		_fell_tower(i, ang, false)




func _fell_tower(i: int, ang: float, instant: bool) -> void:
	var tw = towers[i]
	if tw.down:
		return
	tw.down = true
	pillars[i][2] = 0.0
	var dir = Vector3(cos(ang), 0, sin(ang))
	var axis = Vector3.UP.cross(dir).normalized()
	tw.fall.clear()
	for k in tw.segs.size():
		tw.fall.append({"v": dir * (5.0 + 8.0 * k) + Vector3(0, 5.0, 0), "w": 0.35 + 0.24 * k, "axis": axis, "delay": 0.1 * k, "done": false, "smoke": 0.0})
	if instant:
		for step in 400:
			_tick_tower(tw, 0.033, true)
	else:
		var base: Vector3 = tw.rest[0].origin
		_fireball(Vector3(base.x, 12.0, base.z), 30.0)
		_pop(Vector3(base.x, 12.0, base.z), 22.0, Color(1, 1, 1))


func _tick_towers(dt: float) -> void:
	for tw in towers:
		if tw.down:
			_tick_tower(tw, dt, false)


func _tick_tower(tw: Dictionary, dt: float, quiet: bool) -> void:
	for k in tw.segs.size():
		var f = tw.fall[k]
		if f.done:
			continue
		if f.delay > 0.0:
			f.delay -= dt
			continue
		var seg: Node3D = tw.segs[k]
		f.v.y -= 30.0 * dt
		seg.position += f.v * dt
		seg.rotate(f.axis, f.w * dt)
		if not quiet:
			f.smoke -= dt
			if f.smoke <= 0.0:
				f.smoke = 0.08
				_puff(seg.position, 8.0, 2.0, false, true)
		if seg.position.y <= 9.0:
			seg.position.y = 9.0
			f.done = true
			if not quiet:
				_pop(seg.position, 16.0, Color(0.75, 0.7, 0.62))
				for n in 4:
					_puff(seg.position + Vector3(randf_range(-10, 10), randf_range(0, 8), randf_range(-10, 10)), 9.0, 2.6, false, true)


func _reset_towers() -> void:
	for i in towers.size():
		var tw = towers[i]
		tw.down = false
		tw.fall.clear()
		for k in tw.segs.size():
			tw.segs[k].transform = tw.rest[k]
		pillars[i][2] = tw.h
		tower_hp[i] = TOWER_HP





func _radio(id: int, lines: Array) -> void:
	if PILOT_CHATTER and comm_q.size() < 2:
		rpc("ev_comm", id, lines[randi() % lines.size()])


@rpc("authority", "call_local", "reliable")
func ev_comm(id: int, text: String) -> void:
	if state != PLAYING:
		return
	if id <= ENEMY_BASE:

		comm_q.push_front([id, text.left(80)])
		if comm_q.size() > 3:
			comm_q.resize(3)
	elif comm_q.size() < 3:
		comm_q.append([id, text.left(80)])


func _tick_comm(dt: float) -> void:
	if comm == null and comm_q.size() > 0 and state == PLAYING:
		var next = comm_q.pop_front()
		comm = {"id": next[0], "text": next[1], "t": 0.0, "dur": 1.3 + next[1].length() * 0.05, "clip": -1}
		if next[0] <= ENEMY_BASE and ace_clips.size() > 0:

			comm.clip = randi() % ace_clips.size()
			comm.dur = ACE_CLIP_FRAMES / ACE_CLIP_FPS

			if ACE_CLIP_SOUND and ace_clips[comm.clip].audio != null:
				voice.stream = ace_clips[comm.clip].audio
				voice.pitch_scale = 1.0
				voice.play()
		elif babble.size() > 0:
			voice.stream = babble[randi() % babble.size()]

			voice.pitch_scale = 0.45 if next[0] == 0 else 0.8 + 0.07 * (absi(next[0]) % 9)
			voice.play()
	if comm != null:
		comm.t += dt
		if comm.t > comm.dur or state != PLAYING:
			comm = null
			voice.stop()
		elif comm.clip < 0 and comm.t > comm.text.length() / 34.0 + 0.15 and voice.playing:
			voice.stop()




func _tick_engines(dt: float) -> void:
	if sfx_thruster == null:
		return
	var me = ships.get(my_id)
	var flying = state == PLAYING and me != null and me.alive
	if flying:
		if not thr_player.playing:
			thr_player.play()
		var k = clampf((speed - BRAKE_SPEED) / (BOOST_SPEED - BRAKE_SPEED), 0.0, 1.0)
		thr_player.pitch_scale = lerpf(thr_player.pitch_scale, lerpf(0.8, 1.4, k) + 0.2 * boost_fx, minf(1.0, 5.0 * dt))
		thr_player.volume_db = lerpf(thr_player.volume_db, lerpf(-18.0, -5.0, k) + 3.0 * boost_fx, minf(1.0, 5.0 * dt))
	elif thr_player.playing:
		thr_player.stop()
	for id in ships:
		if id == my_id:
			continue
		var sh = ships[id]
		var pl = sh.get_node_or_null("Thruster")
		if sh.visible and state == PLAYING:
			if pl == null:
				pl = AudioStreamPlayer3D.new()
				pl.name = "Thruster"
				pl.stream = sfx_thruster
				pl.unit_size = 22.0
				pl.max_distance = 260.0
				pl.volume_db = -9.0
				sh.add_child(pl)
			if not pl.playing:
				pl.play(randf() * 6.0)
			pl.pitch_scale = 1.5 if sh.boosting else 1.0
			pl.volume_db = -5.0 if sh.boosting else -9.0
		elif pl != null and pl.playing:
			pl.stop()




func _my_shield(from_point: Vector3) -> void:
	var me = ships.get(my_id)
	if me == null:
		return
	if players.has(my_id) and players[my_id].hp <= 0:

		_pop(me.position + (from_point - me.position).normalized() * 3.0, 3.5, Color(1.0, 0.7, 0.2))
		_hull_hit(me, from_point - me.position)
		return
	var d = (from_point - me.position).normalized()
	me.shield_hit(d)
	_shield_sparks(me, d)
	rpc("fx_shield", d)


@rpc("any_peer", "call_remote", "unreliable")
func fx_shield(dir: Vector3) -> void:
	var sh = ships.get(multiplayer.get_remote_sender_id())
	if sh != null and state == PLAYING:
		sh.shield_hit(dir)
		_shield_sparks(sh, dir)
		_sfx_shield(sh.position)


# deathmatch: a pilot's shot landed on another pilot; everyone shows the shield flash
@rpc("any_peer", "call_local", "unreliable")
func fx_pilot_hit(id: int, dir: Vector3) -> void:
	var sh = ships.get(id)
	if sh == null or state != PLAYING or not players.has(id):
		return
	if players[id].hp <= 0:
		# shield is down: the hit bites into the hull
		_hull_hit(sh, dir)
		return
	sh.shield_hit(dir)
	_shield_sparks(sh, dir)
	_sfx_shield(sh.position)


@rpc("authority", "call_local", "unreliable")
func ev_shield(id: int, dir: Vector3) -> void:
	var sh = ships.get(id)
	if players.has(id) and players[id].hp <= 0 and not is_host:
		return
	if sh != null and state == PLAYING:
		sh.shield_hit(dir)
		_shield_sparks(sh, dir)
		if id != my_id:
			_sfx_shield(sh.position)




func _sfx(stream: AudioStream, db: float, at = null) -> void:
	if stream == null:
		return
	var pl
	if at == null:
		pl = AudioStreamPlayer.new()
	else:
		pl = AudioStreamPlayer3D.new()
		pl.unit_size = 55.0
		pl.max_distance = 800.0
		pl.position = at
	pl.stream = stream
	pl.volume_db = db
	add_child(pl)
	pl.finished.connect(pl.queue_free)
	pl.play()





func _sfx_ignite() -> void:
	if sfx_missiles.is_empty():
		return
	var pl = AudioStreamPlayer.new()
	pl.stream = sfx_missiles[0]
	pl.pitch_scale = 0.6
	pl.volume_db = -2.0
	add_child(pl)
	pl.finished.connect(pl.queue_free)
	pl.play()


func _sfx_impact(at: Vector3) -> void:
	if impact_cd > 0.0 or sfx_impacts.is_empty():
		return
	impact_cd = 0.04
	_sfx(sfx_impacts[randi() % sfx_impacts.size()], -6.0, at)




func _tick_hit_sound(dt: float) -> void:
	impact_cd -= dt
	shield_snd_cd -= dt
	var sh_now = SHIELD_MAX
	var ar_now = ARMOR_MAX
	if players.has(my_id):
		sh_now = players[my_id].hp
		ar_now = players[my_id].ar
	if state == PLAYING:
		if ar_now < last_ar:
			if not sfx_impacts.is_empty():
				_sfx(sfx_impacts[randi() % sfx_impacts.size()], -1.0)
		elif sh_now < last_sh:
			_sfx_shield(null)
	last_sh = sh_now
	last_ar = ar_now



func _sfx_shield(at) -> void:
	if shield_snd_cd > 0.0 or sfx_shield_hits.is_empty():
		return
	shield_snd_cd = 0.12
	_sfx(sfx_shield_hits[randi() % sfx_shield_hits.size()], -2.0 if at == null else -5.0, at)


func _sfx_missile(owner_id: int, at: Vector3) -> void:
	if sfx_missiles.is_empty():
		return
	var snd = sfx_missiles[randi() % sfx_missiles.size()]
	if owner_id == my_id:
		_sfx(snd, -3.0)
	else:
		_sfx(snd, -2.0, at)



func _load_sound(res_path: String) -> AudioStream:
	var abs_path = ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var snd = AudioStreamOggVorbis.load_from_file(abs_path)
		if snd != null:
			return snd
	if ResourceLoader.exists(res_path):
		return load(res_path)
	return null




func _load_ace_clips() -> void:
	for n in [1, 2, 3]:
		var base = "res://media/ace_down_%d_v027" % n
		var tex: Texture2D = null
		var jpg = ProjectSettings.globalize_path(base + ".jpg")
		if FileAccess.file_exists(jpg):
			var img = Image.load_from_file(jpg)
			if img != null and not img.is_empty():
				tex = ImageTexture.create_from_image(img)
		if tex == null and ResourceLoader.exists(base + ".jpg"):
			tex = load(base + ".jpg")
		if tex == null:
			continue
		var snd: AudioStream = null
		var ogg = ProjectSettings.globalize_path(base + ".ogg")
		if FileAccess.file_exists(ogg):
			snd = AudioStreamOggVorbis.load_from_file(ogg)
		if snd == null and ResourceLoader.exists(base + ".ogg"):
			snd = load(base + ".ogg")
		ace_clips.append({"tex": tex, "audio": snd})




func _make_babble() -> void:
	var rate = 22050
	var rng = RandomNumberGenerator.new()
	rng.seed = 1997
	for clip in 6:
		var data = PackedByteArray()
		var total = int(rate * 2.4)
		data.resize(total * 2)
		var i = 0
		while i < total:
			var syl = int(rate * rng.randf_range(0.055, 0.11))
			var gap = int(rate * rng.randf_range(0.012, 0.04))
			if rng.randf() < 0.12:
				gap += int(rate * 0.09)
			var f0 = 170.0 * pow(2.0, rng.randf_range(0.0, 0.8))
			var f1 = f0 * rng.randf_range(2.2, 3.4)
			var bend = rng.randf_range(-0.25, 0.25)
			for k in syl:
				if i + k >= total:
					break
				var x = float(k) / float(syl)
				var tt = float(k) / float(rate)
				var f = f0 * (1.0 + bend * x)
				var sq = 1.0 if fmod(tt * f, 1.0) < 0.5 else -1.0
				var env = minf(1.0, x * 12.0) * (1.0 - x) * 1.6
				var v = (sq * 0.22 + sin(TAU * f1 * tt) * 0.16) * env
				data.encode_s16((i + k) * 2, int(clampf(v, -1.0, 1.0) * 32000.0))
			i += syl + gap
		var w = AudioStreamWAV.new()
		w.format = AudioStreamWAV.FORMAT_16_BITS
		w.mix_rate = rate
		w.stereo = false
		w.data = data
		babble.append(w)




func _load_portrait() -> void:
	var cands = []
	if arg_portrait != "":
		cands.append(arg_portrait)
	for base in [ProjectSettings.globalize_path("res://"), OS.get_executable_path().get_base_dir()]:
		for f in ["portrait.png", "portrait.jpg", "portrait.jpeg"]:
			cands.append(base.path_join(f))
	for path in cands:
		if not FileAccess.file_exists(path):
			continue
		var img = Image.load_from_file(path)
		if img == null or img.is_empty():
			continue
		img.convert(Image.FORMAT_RGB8)
		img.resize(96, 96, Image.INTERPOLATE_LANCZOS)
		my_portrait = img.save_jpg_to_buffer(0.85)
		return


func _share_portrait() -> void:
	if my_portrait.is_empty():
		return
	if not portraits.has(my_id):
		var img = Image.new()
		if img.load_jpg_from_buffer(my_portrait) == OK:
			portraits[my_id] = ImageTexture.create_from_image(img)
	rpc("c_portrait", my_portrait)


@rpc("any_peer", "call_remote", "reliable")
func c_portrait(bytes: PackedByteArray) -> void:
	var id = multiplayer.get_remote_sender_id()
	if bytes.size() > 65536 or bytes.is_empty():
		return
	var img = Image.new()
	if img.load_jpg_from_buffer(bytes) == OK:
		portraits[id] = ImageTexture.create_from_image(img)




@rpc("authority", "call_local", "reliable")
func ev_death(victim: int, killer: int, why: int) -> void:
	var s = ships.get(victim)
	if s != null:
		var was_visible = s.alive and (victim == my_id or s.has_net)
		s.alive = false
		if was_visible:
			_pop(s.position, 7.0, Color(1.0, 0.5, 0.1))
			_spawn_wreck(s, victim)
	if victim <= ENEMY_BASE:
		enemy_hp[victim] = -1
		if players.has(killer):
			_say("%s shot down a PINK ACE  +%d" % [players[killer].name, ENEMY_BONUS])
		return
	var vn = players[victim].name if players.has(victim) else "?"
	if why == 4 and players.has(killer):
		_say("%s shot down %s" % [players[killer].name, vn])
	elif killer <= ENEMY_BASE:
		_say("%s was shot down by a pink ace" % vn)
	elif why == 1:
		_say("%s was swatted by a turret" % vn)
	elif why == 2:
		_say("%s ate a missile" % vn)
	elif why == 3:
		_say("%s was vaporised by the mouth laser" % vn)
	else:
		_say("%s flew into something solid" % vn)


@rpc("authority", "call_local", "reliable")
func ev_respawn(id: int) -> void:
	var s = ships.get(id)
	if s == null:
		return
	s.alive = true
	if id == my_id:
		_place_me(randf() * TAU)
	else:
		s.has_net = false


@rpc("authority", "call_local", "reliable")
func ev_pop(pos: Vector3, size: float) -> void:
	_pop(pos, size, Color(1.0, 0.5, 0.1))
	_pop(pos, size * 0.6, Color(1, 1, 1))



@rpc("authority", "call_local", "reliable")
func ev_blast(pos: Vector3, size: float) -> void:
	if state == PLAYING:
		_fireball(pos, size)
		_pop(pos, size * 0.6, Color(1, 1, 1))


@rpc("authority", "call_local", "reliable")
func ev_feed(text: String) -> void:
	_say(text)


@rpc("authority", "call_local", "unreliable")
func ev_bolt(idx: int, dir: Vector3) -> void:
	if state != PLAYING or idx < 0 or idx >= boss.parts.size():
		return
	boss.aim_turret(idx, dir)
	_spawn_shot(boss.parts[idx].pos + dir * 9.0, dir, 0)


@rpc("authority", "call_local", "reliable")
func ev_missile(mid: int, pod: int, target: int) -> void:
	if state != PLAYING or pod < 0 or pod >= boss.parts.size():
		return
	var origin = boss.parts[pod].pos
	var n = Node3D.new()
	add_child(n)
	Lib.cyl(n, 0.0, 1.2, 3.0, 6, Vector3(0, 0, -3.0), Lib.toon(Color(0.9, 0.2, 0.15)), Vector3(-PI / 2, 0, 0))
	Lib.cyl(n, 1.2, 1.2, 5.0, 6, Vector3(0, 0, 1.0), Lib.toon(Color(0.9, 0.9, 0.9)), Vector3(PI / 2, 0, 0))
	Lib.ball(n, 1.4, Vector3(0, 0, 4.0), _glow_mat("mflame", Color(1.0, 0.6, 0.15), 4.0), 6)

	var d = Vector3.UP
	if ships.has(target):
		d = (ships[target].position - origin).normalized()
	boss.track(pod, origin + d * 100.0, 1.0)
	boss.kick(pod)
	_sfx_missile(0, origin)
	var p = origin + d * 14.0
	Lib.face(n, p, d)
	missiles[mid] = {"n": n, "p": p, "o": p, "d": d, "target": target, "life": MISSILE_LIFE, "trail": 0.0}
	if target == my_id:
		_say("MISSILE LOCK - boost to outrun it")


@rpc("authority", "call_local", "reliable")
func ev_missile_gone(mid: int) -> void:
	if not missiles.has(mid):
		return
	_fireball(missiles[mid].p, 20.0)
	missiles[mid].n.queue_free()
	missiles.erase(mid)
