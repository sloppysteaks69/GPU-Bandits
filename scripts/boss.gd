extends Node3D





const Lib = preload("res://scripts/lib.gd")
const SKIN = preload("res://shaders/toon_skin.gdshader")
const MODEL = "res://models/boss_v030.glb"

const WEAK = 0
const TURRET = 1
const POD = 2
const PDC = 3

const S = 190.0
const PERIOD = 3.4
const BEAM_LEN = 900.0
const T_CHARGE = 1.0
const T_JAW = 1.7
const T_FIRE = 2.9
const T_END = 5.5
const JAW_OPEN = 0.75


const BONES = [
	["root", -1, Vector3(0, 0, 0)], ["hips", 0, Vector3(0, 0.54, -0.015)], ["spine", 1, Vector3(0, 0.62, -0.015)],
	["chest", 2, Vector3(0, 0.72, -0.015)], ["neck", 3, Vector3(0, 0.815, -0.01)], ["head", 4, Vector3(0, 0.84, -0.005)],
	["jaw", 5, Vector3(0, 0.872, 0.0)],
	["upper_l", 3, Vector3(0.135, 0.7726, -0.009)], ["fore_l", 7, Vector3(0.26, 0.7726, -0.009)], ["hand_l", 8, Vector3(0.385, 0.7726, -0.009)],
	["upper_r", 3, Vector3(-0.135, 0.7726, -0.009)], ["fore_r", 10, Vector3(-0.26, 0.7726, -0.009)], ["hand_r", 11, Vector3(-0.385, 0.7726, -0.009)],
	["thigh_l", 0, Vector3(0.056, 0.52, -0.01)], ["shin_l", 13, Vector3(0.056, 0.31, 0)], ["foot_l", 14, Vector3(0.056, 0.06, 0)],
	["thigh_r", 0, Vector3(-0.056, 0.52, -0.01)], ["shin_r", 16, Vector3(-0.056, 0.31, 0)], ["foot_r", 17, Vector3(-0.056, 0.06, 0)],
]

const KEYS = [
	[0.0, 0.55, -0.1, 0.0], [0.22, 0.88, -0.15, 0.0], [0.45, 0.3, 0.45, -0.25],
	[0.62, 0.05, 1.5, -0.55], [0.72, 0.05, 1.45, 0.2], [1.0, 0.55, -0.1, 0.0],
]
const GRIP_R = Vector3(-0.03, -0.06, 0.14)
const HANDLE = Vector3(0.6, -0.35, 0.55)
const GAP = 0.08
const ARM = 0.125
const BLADE = 0.42

var solids = []
var parts = []
var chimneys = []
var beam_on = false
var defeated = false
var defeat_k = 0.0
var furnace_top = Vector3.ZERO
var beam_origin = Vector3.ZERO
var beam_dir = Vector3.FORWARD

var bi = {}
var gb = []
var go = []
var loc = []
var skel: Skeleton3D
var skel_idx = []
var skin_mat: ShaderMaterial
var static_solids = []
var static_boxes = []
var roof_gun_i = -1
var dc_xform = Transform3D()
var dc_top_solid = -1
var dyn_solids = []
var shovel: Node3D
var load_chips: Node3D
var fly_chips = []
var fly_from = Vector3.ZERO
var furnace_mouth = Vector3.ZERO
var furnace_glow: StandardMaterial3D
var shovel_time = 0.0
var beam_t = -1.0
var beam_yaw = 0.0
var beam_pitch = 0.0
var beam_sweep = 1.0
var beam_root: Node3D
var beam_outer: MeshInstance3D
var beam_core: MeshInstance3D
var mouth_ball: MeshInstance3D
var mouth_mat: StandardMaterial3D
var talk_jaw = 0.0

const DEFORMABLE = false
const VX = 128
const VY = 128
const VZ = 32
var vox = []
var vox_dirty = {}
var dmg_layers: Array[Image] = []
var dmg_tex: ImageTexture3D
var carve_budget = 0
var steel: ShaderMaterial
var dark: ShaderMaterial


func build() -> void:
	steel = Lib.toon(Color(0.24, 0.26, 0.32))
	dark = Lib.toon(Color(0.1, 0.11, 0.14))
	for i in BONES.size():
		bi[BONES[i][0]] = i
		gb.append(Basis.IDENTITY)
		go.append(BONES[i][2])
		loc.append(Basis.IDENTITY)
		skel_idx.append(-1)
	_load_body()
	_init_damage()
	_build_shovel()
	_build_pile()
	_build_furnace()
	_build_beam()


	_dyn("head", Vector3(0, 0.91, 0), 19.0)
	_dyn("chest", Vector3(-0.06, 0.75, 0), 26.0)
	_dyn("chest", Vector3(0.06, 0.75, 0), 26.0)
	_dyn("spine", Vector3(0, 0.66, 0), 26.0)
	_dyn("hips", Vector3(0, 0.57, 0), 24.0)
	for sx in [-1.0, 1.0]:
		var sfx = "_l" if sx > 0.0 else "_r"
		_dyn("thigh" + sfx, Vector3(0.056 * sx, 0.43, 0), 13.0)
		_dyn("shin" + sfx, Vector3(0.056 * sx, 0.2, 0), 12.0)
		_dyn("foot" + sfx, Vector3(0.056 * sx, 0.05, 0.02), 12.0)
		_dyn("upper" + sfx, Vector3(0.2 * sx, 0.77, 0), 11.0)
		_dyn("fore" + sfx, Vector3(0.32 * sx, 0.77, 0), 10.0)


	_part(WEAK, "hips", Vector3(-0.14, 0.59, 0.02), 8.0)
	_part(WEAK, "chest", Vector3(0, 0.765, 0.09), 9.0)
	_part(WEAK, "spine", Vector3(0, 0.69, 0.09), 9.0)
	_part(WEAK, "chest", Vector3(0, 0.74, -0.115), 10.0)
	_part(WEAK, "shin_l", Vector3(0.056, 0.31, 0.06), 8.0)
	_part(WEAK, "shin_r", Vector3(-0.056, 0.31, 0.06), 8.0)
	_part(WEAK, "hips", Vector3(0.14, 0.59, 0.02), 8.0)
	_part(WEAK, "thigh_l", Vector3(0.056, 0.43, 0.058), 8.0)

	_part(TURRET, "upper_l", Vector3(0.2, 0.83, 0), 7.0)
	_part(TURRET, "upper_r", Vector3(-0.2, 0.83, 0), 7.0)
	_part(TURRET, "thigh_l", Vector3(0.105, 0.42, 0), 7.0)
	_part(TURRET, "thigh_r", Vector3(-0.105, 0.42, 0), 7.0)
	_part(TURRET, "chest", Vector3(0.07, 0.78, -0.12), 7.0)
	_part(TURRET, "chest", Vector3(-0.07, 0.78, -0.12), 7.0)
	_part(TURRET, "fore_r", Vector3(-0.32, 0.825, 0), 7.0)
	_part(TURRET, "hips", Vector3(0, 0.56, 0.095), 7.0)

	_part(POD, "chest", Vector3(0.115, 0.855, -0.05), 9.0)
	_part(POD, "chest", Vector3(-0.115, 0.855, -0.05), 9.0)
	_part(POD, "shin_l", Vector3(0.1, 0.2, -0.02), 9.0)
	_part(POD, "shin_r", Vector3(-0.1, 0.2, -0.02), 9.0)

	_part(PDC, "chest", Vector3(0.13, 0.8, 0.075), 7.0)
	_part(PDC, "chest", Vector3(-0.13, 0.8, 0.075), 7.0)

	var roof_gun = _make_part(PDC, furnace_top, 8.0, 1.5)
	roof_gun.min_pitch = -0.3
	roof_gun_i = parts.size() - 1
	animate(0.0, 0.0, 16777215, 0)




func _load_body() -> void:
	var scene: Node = null
	var doc = GLTFDocument.new()
	var st = GLTFState.new()
	# Read the raw .glb only when running from the project folder; an exported game has it imported inside the pck.
	if not OS.has_feature("template") and doc.append_from_file(ProjectSettings.globalize_path(MODEL), st) == OK:
		scene = doc.generate_scene(st)
	if scene == null and ResourceLoader.exists(MODEL):
		var packed = load(MODEL)
		if packed != null:
			scene = packed.instantiate()
	if scene == null:
		push_error("GPU Bandits: could not load " + MODEL + " - the boss body will be invisible")
		return
	var holder = Node3D.new()
	holder.scale = Vector3.ONE * S
	add_child(holder)
	holder.add_child(scene)
	skel = _find(scene, "Skeleton3D")
	var mi = _find(scene, "MeshInstance3D")
	if mi != null:
		skin_mat = ShaderMaterial.new()
		skin_mat.shader = SKIN
		var src = mi.get_active_material(0)
		if src is BaseMaterial3D and src.albedo_texture != null:
			skin_mat.set_shader_parameter("tex", src.albedo_texture)
		mi.material_override = skin_mat

		mi.custom_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 3, 4))
	if skel != null:
		for i in BONES.size():
			skel_idx[i] = skel.find_bone(BONES[i][0])


func _find(n: Node, cls: String) -> Node:
	if n.is_class(cls):
		return n
	for c in n.get_children():
		var r = _find(c, cls)
		if r != null:
			return r
	return null


func _dyn(bone: String, bp: Vector3, r: float) -> void:
	dyn_solids.append([bi[bone], bp, r])


func _chip(parent: Node, pos: Vector3, rot: Vector3, k: float = 1.0) -> Node3D:
	var n = Node3D.new()
	n.position = pos
	n.rotation = rot
	n.scale = Vector3.ONE * k
	parent.add_child(n)
	Lib.box(n, Vector3(8, 1.4, 8), Vector3.ZERO, Lib.toon(Color(0.1, 0.35, 0.2)))
	Lib.box(n, Vector3(5, 0.8, 5), Vector3(0, 1.0, 0), Lib.toon(Color(0.75, 0.77, 0.8)))
	Lib.box(n, Vector3(8.4, 0.5, 8.4), Vector3(0, -0.6, 0), Lib.toon(Color(0.95, 0.75, 0.2)))
	return n


func _build_shovel() -> void:

	shovel = Node3D.new()
	add_child(shovel)
	var wood = Lib.toon(Color(0.55, 0.36, 0.18))
	var blade = Lib.toon(Color(0.85, 0.2, 0.15))
	var edge = Lib.toon(Color(0.75, 0.78, 0.82))
	var hl = (BLADE + 0.05) * S
	Lib.cyl(shovel, 2.2, 2.2, hl, 6, Vector3(0, 0, -hl * 0.5 + 0.05 * S), wood, Vector3(PI / 2, 0, 0))
	Lib.box(shovel, Vector3(12, 3, 3), Vector3(0, 0, 0.05 * S + 4.0), wood)
	Lib.box(shovel, Vector3(3, 3, 6), Vector3(-5, 0, 0.05 * S + 1.0), wood)
	Lib.box(shovel, Vector3(3, 3, 6), Vector3(5, 0, 0.05 * S + 1.0), wood)
	var bz = -BLADE * S
	Lib.box(shovel, Vector3(40, 2.5, 30), Vector3(0, -2, bz - 12), blade)
	Lib.box(shovel, Vector3(40, 12, 2.5), Vector3(0, 4, bz + 3), blade)
	Lib.box(shovel, Vector3(2.5, 8, 30), Vector3(-19.5, 2, bz - 12), blade)
	Lib.box(shovel, Vector3(2.5, 8, 30), Vector3(19.5, 2, bz - 12), blade)
	Lib.box(shovel, Vector3(41, 1.5, 3), Vector3(0, -2, bz - 27.5), edge)
	load_chips = Node3D.new()
	load_chips.position = Vector3(0, 1, bz - 12)
	shovel.add_child(load_chips)
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	for i in 9:
		_chip(load_chips, Vector3(rng.randf_range(-13, 13), rng.randf_range(0, 5), rng.randf_range(-9, 9)), Vector3(rng.randf_range(-0.5, 0.5), rng.randf() * TAU, rng.randf_range(-0.5, 0.5)))
	for i in 9:
		var c = _chip(self, Vector3.ZERO, Vector3.ZERO)
		c.visible = false
		fly_chips.append([c, Vector3(rng.randf_range(-10, 10), rng.randf_range(-6, 6), rng.randf_range(-10, 10)), rng.randf() * TAU])


func _build_pile() -> void:
	var c = Vector3(58, 0, 55)
	Lib.cyl(self, 0.0, 55.0, 75.0, 9, c + Vector3(0, 37.5, 0), Lib.toon_hole(Color(0.12, 0.25, 0.2)))
	var rng = RandomNumberGenerator.new()
	rng.seed = 11
	for i in 80:
		var a = rng.randf() * TAU
		var r = 55.0 * sqrt(rng.randf())
		var p = c + Vector3(cos(a) * r, 75.0 * (1.0 - r / 55.0) + 1.5, sin(a) * r)
		_chip(self, p, Vector3(rng.randf_range(-0.7, 0.7), rng.randf() * TAU, rng.randf_range(-0.7, 0.7)), rng.randf_range(0.9, 1.5))
	static_solids.append([c + Vector3(0, 18, 0), 42.0])


func _build_furnace() -> void:
	var f = Node3D.new()
	f.position = Vector3(185, 0, -92)
	f.rotation.y = atan2(-185.0, 92.0)
	add_child(f)
	var wall = Lib.toon_hole(Color(0.2, 0.22, 0.27))
	var band = Lib.toon_hole(Color(0.1, 0.3, 0.35))
	Lib.box(f, Vector3(90, 170, 90), Vector3(0, 85, 0), wall)
	for i in 11:
		Lib.box(f, Vector3(92, 2, 92), Vector3(0, 12.0 + 14.0 * i, 0), band)
	var led_g = Lib.glow(Color(0.3, 1.0, 0.4), 2.5)
	var led_b = Lib.glow(Color(0.2, 0.8, 1.0), 2.5)
	for row in 10:
		for col in 8:
			var p = Vector3(-35.0 + 10.0 * col, 19.0 + 14.0 * row, 45.4)
			if absf(p.x) < 32.0 and p.y > 85.0 and p.y < 145.0:
				continue
			Lib.box(f, Vector3(4, 2.5, 1), p, led_g if (row + col) % 3 != 0 else led_b)
			Lib.box(f, Vector3(4, 2.5, 1), Vector3(p.x, p.y, -45.4), led_b if (row + col) % 3 != 0 else led_g)
	Lib.box(f, Vector3(60, 50, 6), Vector3(0, 115, 43.5), dark)
	furnace_glow = Lib.glow(Color(1.0, 0.45, 0.1), 4.0)
	Lib.box(f, Vector3(48, 38, 4), Vector3(0, 115, 45.5), furnace_glow)
	for sx in [-1.0, 1.0]:
		Lib.cyl(f, 8.0, 10.0, 50.0, 6, Vector3(26.0 * sx, 195, -18), wall)
		Lib.cyl(f, 10.0, 10.0, 5.0, 6, Vector3(26.0 * sx, 221, -18), band)
		chimneys.append(f.transform * Vector3(26.0 * sx, 228, -18))
	var lab = Label3D.new()
	lab.text = "DATACENTER"
	lab.font_size = 150
	lab.pixel_size = 0.085
	lab.outline_size = 0
	lab.modulate = Color(0.9, 0.95, 1.0)
	lab.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	lab.position = Vector3(0, 158, 45.8)
	f.add_child(lab)
	dc_xform = f.transform
	furnace_mouth = f.transform * Vector3(0, 115, 46)
	furnace_top = f.transform * Vector3(0, 178, 22)
	static_solids.append([f.transform * Vector3(0, 45, 0), 55.0])
	static_solids.append([f.transform * Vector3(0, 120, 0), 55.0])
	dc_top_solid = static_solids.size()
	static_solids.append([f.transform * Vector3(0, 175, 0), 45.0])


	static_boxes.append([(f.transform * Transform3D(Basis(), Vector3(0, 85, 0))).affine_inverse(), Vector3(46, 85, 46)])
	for sx in [-1.0, 1.0]:
		static_boxes.append([(f.transform * Transform3D(Basis(), Vector3(26.0 * sx, 197, -18))).affine_inverse(), Vector3(10, 27, 10)])


func _build_beam() -> void:
	mouth_mat = Lib.glow(Color(1.0, 0.15, 0.1), 0.0)
	mouth_ball = Lib.ball(self, 1.0, Vector3.ZERO, mouth_mat, 8)
	beam_root = Node3D.new()
	beam_root.visible = false
	add_child(beam_root)
	var cm = CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 1.0
	cm.radial_segments = 8
	cm.rings = 1
	beam_outer = MeshInstance3D.new()
	beam_outer.mesh = cm
	beam_outer.material_override = Lib.glow(Color(1.0, 0.1, 0.15), 5.0)
	beam_outer.rotation.x = PI / 2
	beam_outer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam_root.add_child(beam_outer)
	beam_core = MeshInstance3D.new()
	beam_core.mesh = cm
	beam_core.material_override = Lib.glow(Color(1.0, 0.95, 0.9), 6.0)
	beam_core.rotation.x = PI / 2
	beam_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam_root.add_child(beam_core)


func _part(kind: int, bone: String, bp: Vector3, r: float) -> void:
	var p = _make_part(kind, bp * S, r, 1.0)
	p.bone = bi[bone]
	p.bp = bp



func add_static_part(kind: int, pos: Vector3, r: float, size: float) -> void:
	_make_part(kind, pos, r, size)


func _make_part(kind: int, pos: Vector3, r: float, size: float) -> Dictionary:
	var node = Node3D.new()
	node.position = pos
	add_child(node)
	var body = Node3D.new()
	body.scale = Vector3.ONE * size
	node.add_child(body)
	var p = {"kind": kind, "pos": pos, "r": r, "node": node, "mat": null, "pivot": null, "spinner": null, "spin": 0.0, "bone": -1, "bp": Vector3.ZERO, "min_pitch": -PI / 2.0}
	if kind == WEAK:
		var mat = Lib.toon(Color(0.16, 0.17, 0.2), Color(1.0, 0.1, 0.05), 0.0)
		Lib.ball(body, r, Vector3.ZERO, mat, 8)
		p.mat = mat
	else:
		var pivot = Node3D.new()
		body.add_child(pivot)
		p.pivot = pivot
		if kind == TURRET:
			Lib.ball(body, 5.3, Vector3.ZERO, steel, 6)
			Lib.box(pivot, Vector3(2.2, 2.2, 13.0), Vector3(0, 0, -6.5), dark)
			Lib.box(pivot, Vector3(3.0, 3.0, 2.0), Vector3(0, 0, -13.0), Lib.toon(Color(0.8, 0.2, 0.15)))
		elif kind == PDC:

			var armour = Lib.toon(Color(0.33, 0.35, 0.38))
			Lib.cyl(body, 5.0, 6.0, 4.0, 8, Vector3(0, -2.5, 0), dark)
			Lib.box(pivot, Vector3(8.0, 6.0, 9.0), Vector3(0, 1.0, 1.0), armour)
			Lib.box(pivot, Vector3(2.0, 2.0, 2.5), Vector3(3.0, 4.6, -1.5), Lib.glow(Color(1.0, 0.75, 0.25), 2.0))
			var pdc_spin = Node3D.new()
			pdc_spin.position = Vector3(0, 0.5, -4.5)
			pivot.add_child(pdc_spin)
			Lib.cyl(pdc_spin, 1.5, 1.5, 3.0, 6, Vector3(0, 0, 0), dark, Vector3(PI / 2, 0, 0))
			for k in 5:
				var pa = TAU * k / 5.0
				Lib.cyl(pdc_spin, 0.38, 0.38, 11.0, 5, Vector3(cos(pa) * 0.95, sin(pa) * 0.95, -5.0), steel, Vector3(PI / 2, 0, 0))
			p.spinner = pdc_spin
		else:

			var olive = Lib.toon(Color(0.42, 0.45, 0.25))
			Lib.ball(body, 5.5, Vector3.ZERO, steel, 6)
			Lib.box(pivot, Vector3(11, 3, 5), Vector3(0, 0, 0), dark)
			Lib.box(pivot, Vector3(1.5, 7, 6), Vector3(-5.5, 0, -2), dark)
			Lib.box(pivot, Vector3(1.5, 7, 6), Vector3(5.5, 0, -2), dark)
			var spinner = Node3D.new()
			spinner.position = Vector3(0, 0, -4)
			pivot.add_child(spinner)
			Lib.cyl(spinner, 4.6, 4.6, 9.0, 6, Vector3(0, 0, 0), olive, Vector3(PI / 2, 0, 0))
			for k in 6:
				var a = TAU * k / 6.0
				var o = Vector3(cos(a) * 2.9, sin(a) * 2.9, 0)
				Lib.cyl(spinner, 1.15, 1.15, 10.0, 6, o + Vector3(0, 0, -0.6), dark, Vector3(PI / 2, 0, 0))
				Lib.ball(spinner, 1.0, o + Vector3(0, 0, -5.4), Lib.glow(Color(1.0, 0.2, 0.1), 2.5), 6)
			p.spinner = spinner
		var out = Vector3(pos.x, 0, pos.z)
		if out.length() < 0.01:
			out = Vector3(0, 1, 0.01)
		aim(p, out)
	parts.append(p)
	return p



func track(i: int, tpos: Vector3, dt: float) -> void:
	var p = parts[i]
	if p.pivot == null:
		return
	var d = tpos - p.pos
	if d.length() < 0.5:
		return
	d = d.normalized()
	d = clamp_pitch(i, d)
	var want = Basis.looking_at(d, Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT)
	var rate = 9.0 if p.kind == PDC else 5.0
	p.pivot.basis = p.pivot.basis.orthonormalized().slerp(want, minf(1.0, rate * dt))




func below_mount(i: int, d: Vector3) -> bool:
	return d.normalized().y < sin(parts[i].get("min_pitch", -PI / 2.0)) - 0.001


func clamp_pitch(i: int, d: Vector3) -> Vector3:
	var mp: float = parts[i].get("min_pitch", -PI / 2.0)
	if d.y >= sin(mp):
		return d
	var flat = Vector3(d.x, 0.0, d.z)
	if flat.length() < 0.001:
		flat = Vector3(0, 0, -1)
	return (flat.normalized() * cos(mp) + Vector3(0, sin(mp), 0)).normalized()


func muzzle_dir(i: int) -> Vector3:
	var p = parts[i]
	if p.pivot == null:
		return Vector3.FORWARD
	return -p.pivot.global_transform.basis.z.normalized()



func kick(i: int) -> void:
	parts[i].spin = 1.0


func aim(p: Dictionary, dir: Vector3) -> void:
	if p.pivot == null:
		return
	var d = dir.normalized()
	p.pivot.basis = Basis.looking_at(d, Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT)


func aim_turret(i: int, dir: Vector3) -> void:
	aim(parts[i], dir)




func start_beam(yaw: float, pitch: float, sweep: float) -> void:
	beam_t = 0.0
	beam_yaw = yaw
	beam_pitch = pitch
	beam_sweep = sweep




func _init_damage() -> void:
	if not DEFORMABLE or skin_mat == null:
		return
	for z in VZ:
		var bytes = PackedByteArray()
		bytes.resize(VX * VY)
		bytes.fill(0)
		vox.append(bytes)
		dmg_layers.append(Image.create_from_data(VX, VY, false, Image.FORMAT_L8, bytes))
	dmg_tex = ImageTexture3D.new()
	if dmg_tex.create(Image.FORMAT_L8, VX, VY, VZ, false, dmg_layers) == OK:
		skin_mat.set_shader_parameter("dmg", dmg_tex)
		skin_mat.set_shader_parameter("dmg_on", 1.0)
	else:
		dmg_tex = null


func reset_damage() -> void:
	if dmg_tex == null:
		return
	for z in VZ:
		vox[z].fill(0)
		vox_dirty[z] = true




func carve(p: Vector3, dir: Vector3, radius: float, length: float) -> void:
	if dmg_tex == null or carve_budget <= 0:
		return
	carve_budget -= 1


	var pm = p / S
	var best = -1
	var best_d = 1000000.0
	for ds in dyn_solids:
		var c: Vector3 = go[ds[0]] + gb[ds[0]] * (ds[1] - BONES[ds[0]][2])
		var d = pm.distance_to(c) - ds[2] / S
		if d < best_d:
			best_d = d
			best = ds[0]
	if best < 0 or best_d > 0.12:
		return
	var inv: Basis = gb[best].inverse()
	var a: Vector3 = BONES[best][2] + inv * (pm - go[best])
	var bd: Vector3 = (inv * dir).normalized()
	var steps = int(length / 1.5)
	for k in steps + 1:
		_stamp(a + bd * (k * 1.5 / S), radius / S)


func _stamp(c: Vector3, r: float) -> void:
	var fx = (c.x + 0.5) * VX
	var fy = c.y * VY
	var fz = (c.z + 0.25) * 2.0 * VZ
	var rx = maxf(r * VX, 0.8)
	var ry = maxf(r * VY, 0.8)
	var rz = maxf(r * 2.0 * VZ, 0.8)
	for iz in range(maxi(0, int(floor(fz - rz))), mini(VZ - 1, int(ceil(fz + rz))) + 1):
		var dz = (iz + 0.5 - fz) / rz
		var layer: PackedByteArray = vox[iz]
		var touched = false
		for iy in range(maxi(0, int(floor(fy - ry))), mini(VY - 1, int(ceil(fy + ry))) + 1):
			var dy = (iy + 0.5 - fy) / ry
			for ix in range(maxi(0, int(floor(fx - rx))), mini(VX - 1, int(ceil(fx + rx))) + 1):
				var dx = (ix + 0.5 - fx) / rx
				if dx * dx + dy * dy + dz * dz <= 1.0:
					layer[iy * VX + ix] = 255
					touched = true
		if touched:
			vox[iz] = layer
			vox_dirty[iz] = true


func _flush_damage() -> void:
	carve_budget = 30
	if dmg_tex == null or vox_dirty.is_empty():
		return
	for z in vox_dirty:
		dmg_layers[z] = Image.create_from_data(VX, VY, false, Image.FORMAT_L8, vox[z])
	vox_dirty.clear()
	dmg_tex.update(dmg_layers)




func _keys(u: float) -> Array:
	for i in KEYS.size() - 1:
		var a = KEYS[i]
		var b = KEYS[i + 1]
		if u <= b[0]:
			var k = smoothstep(a[0], b[0], u)
			return [lerpf(a[1], b[1], k), lerpf(a[2], b[2], k), lerpf(a[3], b[3], k)]
	return [KEYS[0][1], KEYS[0][2], KEYS[0][3]]


func _arm_basis(dir: Vector3, side: float, up: Vector3) -> Basis:
	var x = dir * side
	var z = x.cross(up).normalized()
	return Basis(x, z.cross(x), z)




func _solve(bend: float, twist: float, tilt: float, head_yaw: float, head_pitch: float, jaw: float) -> Array:
	for i in loc.size():
		loc[i] = Basis.IDENTITY
	loc[bi["hips"]] = Basis(Vector3.RIGHT, bend * 0.5)
	loc[bi["spine"]] = Basis(Vector3.UP, twist * 0.5) * Basis(Vector3.RIGHT, bend * 0.3)
	loc[bi["chest"]] = Basis(Vector3.UP, twist * 0.5) * Basis(Vector3.RIGHT, bend * 0.2)
	loc[bi["neck"]] = Basis(Vector3.UP, head_yaw * 0.4) * Basis(Vector3.RIGHT, -bend * 0.5 + head_pitch * 0.4)
	loc[bi["head"]] = Basis(Vector3.UP, head_yaw * 0.6) * Basis(Vector3.RIGHT, head_pitch * 0.6)
	loc[bi["jaw"]] = Basis(Vector3.RIGHT, jaw)
	_fk()
	var c = bi["chest"]
	var cb: Basis = gb[c]
	var d = cb * (Basis(Vector3.RIGHT, tilt) * HANDLE.normalized())
	var gr = go[c] + cb * GRIP_R
	var gl = gr + d * GAP
	for side in [1.0, -1.0]:
		var sfx = "_l" if side > 0.0 else "_r"
		var u = bi["upper" + sfx]
		var f = bi["fore" + sfx]
		var h = bi["hand" + sfx]
		var tgt = gl if side > 0.0 else gr
		var sh: Vector3 = go[u]
		var v = tgt - sh
		var dist = minf(v.length(), 2.0 * ARM - 0.0001)
		var n = v.normalized()
		var pole = cb * Vector3(0.6 * side, -0.8, -0.2)
		var perp = (pole - n * pole.dot(n)).normalized()
		var ca = dist / (2.0 * ARM)
		var sa = sqrt(maxf(0.0, 1.0 - ca * ca))
		var elbow = sh + (n * ca + perp * sa) * ARM
		var wrist = sh + n * dist
		var bu = _arm_basis((elbow - sh).normalized(), side, cb.y)
		var bf = _arm_basis((wrist - elbow).normalized(), side, cb.y)
		loc[u] = cb.inverse() * bu
		loc[f] = bu.inverse() * bf
		gb[u] = bu
		go[f] = elbow
		gb[f] = bf
		go[h] = wrist
		gb[h] = bf
	if skel != null:
		for i in BONES.size():
			if skel_idx[i] >= 0:
				skel.set_bone_pose_rotation(skel_idx[i], loc[i].orthonormalized().get_rotation_quaternion())
	return [gr, d]


# Camera spot for the Mecha Huang comm card: just in front of his face, locked to the head bone.
func face_cam() -> Transform3D:
	var hd = bi["head"]
	var eye = global_transform * _on_bone(hd, Vector3(0.1, 0.92, 0.5))
	var at = global_transform * _on_bone(hd, Vector3(0.0, 0.9, 0.0))
	var up = (global_transform.basis * (gb[hd] * Vector3.UP)).normalized()
	return Transform3D(Basis.looking_at(at - eye, up), eye)


func _fk() -> void:
	for i in BONES.size():
		var p = BONES[i][1]
		if p < 0:
			gb[i] = loc[i]
			go[i] = BONES[i][2]
		else:
			gb[i] = gb[p] * loc[i]
			go[i] = go[p] + gb[p] * (BONES[i][2] - BONES[p][2])



func _on_bone(b: int, bp: Vector3) -> Vector3:
	return (go[b] + gb[b] * (bp - BONES[b][2])) * S


func animate(t: float, dt: float, alive_mask: int, active_mask: int) -> void:
	_flush_damage()

	var k = 0.0
	var jaw = 0.0
	var charge = 0.0
	var firing = false
	var yaw_now = beam_yaw
	if beam_t >= 0.0:
		beam_t += dt
		k = smoothstep(0.0, T_CHARGE, beam_t) * (1.0 - smoothstep(T_END, T_END + 1.0, beam_t))
		charge = clampf((beam_t - T_JAW) / (T_FIRE - T_JAW), 0.0, 1.0)
		firing = beam_t >= T_FIRE and beam_t < T_END

		jaw = JAW_OPEN * smoothstep(T_CHARGE, T_JAW, beam_t) * (1.0 - smoothstep(T_END, T_END + 0.6, beam_t))
		var sweep_k = clampf((beam_t - T_FIRE) / (T_END - T_FIRE), 0.0, 1.0)
		yaw_now = beam_yaw + beam_sweep * (sweep_k - 0.5) * 0.7
		if beam_t > T_END + 1.0:
			beam_t = -1.0
	elif not defeated:
		shovel_time += dt
	var u = fmod(shovel_time, PERIOD) / PERIOD
	var key = _keys(u)
	var body_tw = clampf(yaw_now * 0.5, -1.0, 1.0)
	var head_yaw = clampf(yaw_now - body_tw, -1.3, 1.3)

	defeat_k = lerpf(defeat_k, 1.0 if defeated else 0.0, minf(1.0, 1.5 * dt))
	if defeated:
		beam_t = -1.0
		firing = false
		charge = 0.0
		k = 0.0
	var p_bend = lerpf(lerpf(key[0], 0.05, k), 1.2, defeat_k)
	var p_twist = lerpf(lerpf(key[1], body_tw, k), 0.15, defeat_k)
	var p_tilt = lerpf(lerpf(key[2], -0.3, k), 0.5, defeat_k)
	var p_hpitch = lerpf(-beam_pitch * k, 0.6, defeat_k)
	var sol = _solve(p_bend, p_twist, p_tilt, head_yaw * k, p_hpitch, lerpf(maxf(jaw, talk_jaw), 0.5, defeat_k))
	var gr: Vector3 = sol[0]
	var d: Vector3 = sol[1]
	var cb: Basis = gb[bi["chest"]]


	shovel.transform = Transform3D(Basis.looking_at(d, cb.y), gr * S)
	var tip = (gr + d * BLADE) * S
	var carrying = u > 0.2 and u < 0.62
	load_chips.visible = carrying
	if u < 0.62:
		fly_from = tip + Vector3(0, 4, 0)
	var flying = u >= 0.62 and u < 0.9 and k < 0.5
	var ft = (u - 0.62) / 0.28
	for fc in fly_chips:
		fc[0].visible = flying
		if flying:
			fc[0].position = fly_from.lerp(furnace_mouth, ft) + Vector3(0, sin(ft * PI) * 26.0, 0) + fc[1] * (1.0 - ft * 0.6)
			fc[0].rotation = Vector3(ft * 9.0 + fc[2], fc[2], ft * 6.0)
	furnace_glow.emission_energy_multiplier = 3.5 + 1.5 * sin(t * 11.0) + (3.0 if (u > 0.85 or u < 0.05) else 0.0)


	solids = static_solids.duplicate()
	for ds in dyn_solids:
		solids.append([_on_bone(ds[0], ds[1]), ds[2]])
	var pulse = 0.5 + 0.5 * sin(t * 9.0)
	for i in parts.size():
		var p = parts[i]
		if p.bone >= 0:
			p.pos = _on_bone(p.bone, p.bp)
			p.node.position = p.pos
		if p.spinner != null:
			p.spin = maxf(0.0, p.spin - dt * 0.7)
			p.spinner.rotation.z += dt * (1.2 + 16.0 * p.spin)
		if p.kind == WEAK:
			var on = (active_mask & (1 << i)) != 0
			p.mat.set_shader_parameter("albedo", Color(0.9, 0.1, 0.1) if on else Color(0.16, 0.17, 0.2))
			p.mat.set_shader_parameter("emit_power", (1.5 + 2.5 * pulse) if on else 0.0)
			p.node.scale = Vector3.ONE * ((1.0 + 0.12 * pulse) if on else 0.8)
		else:
			p.node.visible = (alive_mask & (1 << i)) != 0


	var hd = bi["head"]
	var mouth = _on_bone(hd, Vector3(0, 0.845, 0.03))
	beam_origin = _on_bone(hd, Vector3(0, 0.856, 0.07))
	beam_dir = (gb[hd] * Vector3(0, 0, 1)).normalized()
	mouth_ball.position = mouth
	mouth_ball.scale = Vector3.ONE * (5.5 + 5.0 * charge + (2.0 * pulse if firing else 0.0))
	mouth_mat.emission_energy_multiplier = 8.0 * charge
	beam_on = firing
	beam_root.visible = charge > 0.0 and beam_t >= 0.0 and beam_t < T_END
	if beam_root.visible:
		Lib.face(beam_root, beam_origin, beam_dir)
		var rad = 0.5
		if firing:
			rad = 9.0 + 1.5 * sin(t * 40.0)
		beam_outer.position = Vector3(0, 0, -BEAM_LEN * 0.5)
		beam_outer.scale = Vector3(rad, BEAM_LEN, rad)
		beam_core.visible = firing
		beam_core.position = Vector3(0, 0, -BEAM_LEN * 0.5)
		beam_core.scale = Vector3(rad * 0.45, BEAM_LEN + 1.0, rad * 0.45)
