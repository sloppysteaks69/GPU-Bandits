extends Node3D



const Lib = preload("res://scripts/lib.gd")
const SHIELD = preload("res://shaders/shield.gdshader")

var alive = true
var yaw = 0.0
var pitch = 0.0
var roll = 0.0
var boosting = false
var rolling = false
var shielded = false
var has_net = false
var net_pos = Vector3.ZERO
var net_yaw = 0.0
var net_pitch = 0.0
var net_roll = 0.0
var flames = []

var flame_info = []
var exhaust: OmniLight3D
var boost_k = 0.0
var ign_t = 9.0
var was_boost = false
var shield: MeshInstance3D
var shield_mat: ShaderMaterial
var hits = []
var last_t = 0.0
var paint = []
var canard: Node3D
var fin: Node3D
var dmg_q = -1.0
var shield_k = 1.0
var col = Color.WHITE
var elite = false
var root: Node3D
var wing_msl = []
var wing_at = []
var wing_loaded = [true, true]
# 1.0.2 battle damage: soot decals with a hot glow that cools, cleared on repair
const SCORCH_MAX = 14
static var scorch_tex: ImageTexture = null
static var hot_tex: ImageTexture = null
var scorches = []
var last_scorch = -10.0


func build(c: Color, is_elite: bool = false) -> void:
	col = c
	elite = is_elite
	var hull = Lib.toon(Color(0.9, 0.92, 0.96))
	var tint = Lib.toon(c)
	var dark = Lib.toon(Color(0.2, 0.22, 0.28))
	var glass = Lib.toon(Color(0.1, 0.45, 0.65), Color(0.2, 0.9, 1.0), 0.7)
	root = Node3D.new()
	root.scale = Vector3.ONE * (1.8 if elite else 0.975)
	add_child(root)
	if elite:
		_build_ace(root)
		_wing_missiles(Vector3(3.9, -0.55, 3.4), 0.5, Color(1.0, 0.15, 0.6))
		return

	var sm = SphereMesh.new()
	sm.radius = 6.75
	sm.height = 13.5
	sm.radial_segments = 24
	sm.rings = 12
	shield = MeshInstance3D.new()
	shield.mesh = sm
	shield_mat = ShaderMaterial.new()
	shield_mat.shader = SHIELD
	shield.material_override = shield_mat
	shield.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shield.visible = false
	add_child(shield)

	Lib.cyl(root, 0.0, 1.3, 9.0, 5, Vector3(0, 0, -1.0), hull, Vector3(-PI / 2, 0, 0))
	Lib.prism(root, Vector3(12.0, 5.5, 0.35), Vector3(0, -0.2, 1.6), tint, Vector3(-PI / 2, 0, 0))
	canard = Lib.prism(root, Vector3(4.5, 1.8, 0.25), Vector3(0, 0.1, -2.6), dark, Vector3(-PI / 2, 0, 0))
	paint = [[hull, Color(0.9, 0.92, 0.96)], [tint, c]]
	var canopy = Lib.ball(root, 0.8, Vector3(0, 0.75, -0.6), glass, 6)
	canopy.scale = Vector3(0.9, 0.7, 2.0)
	for sx in [-1.0, 1.0]:
		var fn = Lib.prism(root, Vector3(2.6, 2.6, 0.25), Vector3(2.4 * sx, 1.2, 3.2), tint, Vector3(0, PI / 2, 0), 1.0)
		if sx < 0.0:
			fin = fn
		Lib.cyl(root, 0.7, 0.55, 2.6, 6, Vector3(1.3 * sx, 0, 3.6), dark, Vector3(PI / 2, 0, 0))
		var f = Lib.cyl(root, 0.0, 0.5, 2.5, 6, Vector3(1.3 * sx, 0, 6.0), Lib.glow(Color(1.0, 0.6, 0.15), 4.0), Vector3(PI / 2, 0, 0))
		flames.append(f)
	_wing_missiles(Vector3(3.3, -0.95, 2.2), 0.42, c)
	_afterburner_setup(Color(1.0, 0.6, 0.15), Color(0.62, 0.84, 1.0), Color(0.1, 0.4, 1.0))





func _afterburner_setup(cool: Color, hot: Color, plume_col: Color) -> void:
	for f in flames:
		var cm: CylinderMesh = f.mesh
		var half = cm.height * 0.5
		var plume = Lib.cyl(root, 0.0, cm.bottom_radius * 2.1, cm.height, 10, f.position, _add_mat(plume_col, 1.0), f.rotation)
		plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		plume.visible = false
		var halo = Lib.ball(root, cm.bottom_radius * 2.6, f.position - Vector3(0, 0, half), _add_mat(plume_col.lerp(Color.WHITE, 0.35)), 8)
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		halo.visible = false
		flame_info.append([f.position.z - half, half, cool, hot, plume, halo])
	exhaust = OmniLight3D.new()
	exhaust.light_color = plume_col.lerp(Color(0.5, 0.75, 1.0), 0.3)
	exhaust.omni_range = 34.0
	exhaust.light_energy = 0.0
	exhaust.shadow_enabled = false
	exhaust.position = Vector3(0, 0, 9.0)
	exhaust.visible = false
	root.add_child(exhaust)


static var _glow_shader: Shader = null




func _add_mat(c: Color, along: float = 0.0) -> ShaderMaterial:
	if _glow_shader == null:
		_glow_shader = Shader.new()
		_glow_shader.code = "shader_type spatial;\nrender_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;\nuniform vec4 col : source_color = vec4(1.0, 0.5, 0.1, 1.0);\nuniform float amt = 0.0;\nuniform float along = 0.0;\nvoid fragment() {\n\tfloat face = clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);\n\tfloat v = mix(1.0, UV.y * UV.y, along);\n\tALBEDO = col.rgb * (1.0 + 1.5 * face);\n\tALPHA = clamp(amt * v * face * face, 0.0, 1.0);\n}\n"











	var m = ShaderMaterial.new()
	m.shader = _glow_shader
	m.set_shader_parameter("col", c)
	m.set_shader_parameter("along", along)
	return m





func _wing_missiles(at: Vector3, k: float, c: Color) -> void:
	var dark = Lib.toon(Color(0.2, 0.22, 0.28))
	for sx in [-1.0, 1.0]:
		var p = Vector3(at.x * sx, at.y, at.z)
		var pylon = Lib.box(root, Vector3(0.25, absf(at.y) * 0.9, 1.4), Vector3(p.x, at.y * 0.5, p.z), dark)
		pylon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var m = Node3D.new()
		m.position = p
		m.scale = Vector3.ONE * k
		root.add_child(m)
		Lib.missile_model(m, c, false)
		wing_msl.append(m)
		wing_at.append(p * root.scale)



func set_wings(left: bool, right: bool) -> void:
	wing_loaded = [left, right]
	for i in wing_msl.size():
		wing_msl[i].visible = wing_loaded[i]



func wing_point(i: int) -> Vector3:
	if i < 0 or i >= wing_at.size():
		return position
	return position + basis * wing_at[i]





func _build_ace(root: Node3D) -> void:
	var pink = Lib.toon(Color(1.0, 0.25, 0.65))
	var deep = Lib.toon(Color(0.7, 0.08, 0.42))
	var dk = Lib.toon(Color(0.16, 0.1, 0.16))
	var glass = Lib.toon(Color(0.25, 0.1, 0.3), Color(1.0, 0.5, 0.9), 0.8)
	var hot = Lib.glow(Color(1.0, 0.3, 0.75), 3.0)
	var nose = Lib.cyl(root, 0.0, 1.25, 6.5, 4, Vector3(0, 0, -7.2), pink, Vector3(-PI / 2, 0, 0))
	nose.scale = Vector3(1.2, 1.0, 0.5)
	Lib.box(root, Vector3(2.9, 1.25, 9.5), Vector3(0, 0, 0.75), pink)
	Lib.box(root, Vector3(1.6, 0.5, 7.0), Vector3(0, 0.75, 1.5), deep)
	var canopy = Lib.ball(root, 0.75, Vector3(0, 0.7, -4.4), glass, 6)
	canopy.scale = Vector3(0.85, 0.75, 2.6)
	for sx in [-1.0, 1.0]:
		var ltr = 0.0 if sx > 0.0 else 1.0
		Lib.box(root, Vector3(0.9, 1.0, 4.2), Vector3(1.75 * sx, -0.15, -1.6), deep)
		Lib.prism(root, Vector3(2.8, 2.4, 0.18), Vector3(2.75 * sx, 0.2, -2.3), deep, Vector3(-PI / 2, 0, 0), ltr)
		Lib.prism(root, Vector3(5.2, 7.5, 0.22), Vector3(4.0 * sx, 0.0, 2.2), pink, Vector3(-PI / 2, 0, 0), ltr)
		Lib.box(root, Vector3(0.3, 0.3, 1.6), Vector3(6.4 * sx, 0.0, 5.3), hot)
		Lib.prism(root, Vector3(3.2, 2.8, 0.18), Vector3(1.5 * sx, 1.7, 4.3), deep, Vector3(0.5 * sx, PI / 2, 0), 0.0)
		Lib.box(root, Vector3(0.15, 0.9, 1.8), Vector3(1.3 * sx, -0.95, 4.6), deep)
		Lib.cyl(root, 0.8, 0.7, 2.2, 6, Vector3(0.8 * sx, 0, 6.3), dk, Vector3(PI / 2, 0, 0))
		var f = Lib.cyl(root, 0.0, 0.6, 2.8, 6, Vector3(0.8 * sx, 0, 8.6), Lib.glow(Color(1.0, 0.5, 0.85), 4.0), Vector3(PI / 2, 0, 0))
		flames.append(f)
		_flag(root, Vector3(3.0 * sx, 0.13, 4.6))




func _flag(root: Node3D, at: Vector3) -> void:
	var w = 3.0
	var h = 2.0
	Lib.box(root, Vector3(w, 0.04, h), at, Lib.toon(Color(0.87, 0.16, 0.06)))
	var gold = Lib.glow(Color(1.0, 0.87, 0.0), 1.1)
	gold.cull_mode = BaseMaterial3D.CULL_DISABLED
	var big = Vector2(5, 5)
	var stars = [[big, 3.0], [Vector2(10, 2), 1.0], [Vector2(12, 4), 1.0], [Vector2(12, 7), 1.0], [Vector2(10, 9), 1.0]]
	for st in stars:
		var g: Vector2 = st[0]
		var mi = MeshInstance3D.new()
		mi.mesh = _star_mesh(st[1] / 30.0 * w)
		mi.material_override = gold
		mi.position = at + Vector3((g.x / 30.0 - 0.5) * w, 0.035, (g.y / 20.0 - 0.5) * h)
		if g != big:
			var to_big = big - g
			mi.rotation.y = atan2(-to_big.x, -to_big.y)
		root.add_child(mi)



func _star_mesh(rad: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rim = []
	for k in 10:
		var a = TAU * k / 10.0
		var rr = rad if k % 2 == 0 else rad * 0.382
		rim.append(Vector3(sin(a) * rr, 0, -cos(a) * rr))
	for k in 10:
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(rim[k])
		st.add_vertex(rim[(k + 1) % 10])
	return st.commit()


func apply() -> void:
	basis = Basis.from_euler(Vector3(pitch, yaw, roll))


func fwd() -> Vector3:
	return -Basis.from_euler(Vector3(pitch, yaw, 0.0)).z


func tick_remote(dt: float) -> void:
	if not has_net:
		return
	var k = minf(1.0, dt * 14.0)
	position = position.lerp(net_pos, k)
	yaw = lerp_angle(yaw, net_yaw, k)
	pitch = lerp_angle(pitch, net_pitch, k)
	roll = lerp_angle(roll, net_roll, k)
	apply()


func tick_fx(t: float) -> void:
	var dt = clampf(t - last_t, 0.0, 0.1)
	last_t = t
	for sc in scorches:
		var k = clampf((t - sc[1]) / 2.5, 0.0, 1.0)
		sc[0].emission_energy = 5.0 * (1.0 - k) * (1.0 - k)
	if boosting and not was_boost:
		ign_t = 0.0
	was_boost = boosting
	ign_t += dt
	boost_k = move_toward(boost_k, 1.0 if boosting else 0.0, dt * (7.0 if boosting else 2.5))
	var ign = maxf(0.0, 1.0 - ign_t / 0.4)
	var fl = 0.15 * sin(t * 40.0) + 0.12 * sin(t * 71.0 + 1.3) * boost_k
	var k = 1.0 + 2.0 * boost_k + 1.2 * ign + fl
	var wide = 1.0 + 0.3 * boost_k + 0.4 * ign
	for i in flames.size():
		var f = flames[i]
		if flame_info.size() <= i:

			f.scale = Vector3(1.0, (2.2 if boosting else 1.0) + 0.15 * sin(t * 40.0), 1.0)
			continue
		f.scale = Vector3(wide, k, wide)
		var fi = flame_info[i]
		f.position.z = fi[0] + fi[1] * k
		var fm: StandardMaterial3D = f.material_override
		fm.emission = fi[2].lerp(fi[3], minf(1.0, boost_k * 3.0))
		fm.emission_energy_multiplier = 4.0 + 6.0 * boost_k + 6.0 * ign
		var on = boost_k > 0.01
		var plume: MeshInstance3D = fi[4]
		var halo: MeshInstance3D = fi[5]
		plume.visible = on
		halo.visible = on
		if on:
			var pk = 1.0 + 5.3 * boost_k + 2.7 * ign + 0.7 * sin(t * 53.0 + i) * boost_k
			var pw = 1.0 + 0.6 * ign + 0.12 * sin(t * 37.0 + i * 2.0)
			plume.scale = Vector3(pw, pk, pw)
			plume.position.z = fi[0] + fi[1] * pk
			plume.material_override.set_shader_parameter("amt", 0.9 * boost_k + 0.6 * ign)
			halo.scale = Vector3.ONE * (0.8 + 0.4 * boost_k + 1.8 * ign + 0.1 * sin(t * 61.0 + i))
			halo.material_override.set_shader_parameter("amt", 0.7 * boost_k + 0.8 * ign)
	if exhaust != null:
		exhaust.visible = boost_k > 0.01
		exhaust.light_energy = 5.0 * boost_k + 8.0 * ign + 0.8 * sin(t * 47.0) * boost_k
	if not hits.is_empty():
		var i = hits.size() - 1
		while i >= 0:
			hits[i][1] += dt
			if hits[i][1] >= 0.9:
				hits.remove_at(i)
			i -= 1
		_push_hits()




func set_damage(d: float) -> void:
	var q = snappedf(clampf(d, 0.0, 1.0), 0.1)
	if q == dmg_q or paint.is_empty():
		return
	dmg_q = q
	if q <= 0.0:
		clear_scorch()
	for pm in paint:
		var clean: Color = pm[1]
		pm[0].set_shader_parameter("albedo", clean.lerp(Color(0.11, 0.1, 0.09), q * 0.8))
	if canard != null:
		canard.visible = q < 0.5
	if fin != null:
		fin.visible = q < 0.8




# A hit got through the shield: stick a soot mark on the hull where it landed.
func add_scorch(world_dir: Vector3, t: float) -> void:
	if root == null or world_dir.length() < 0.001:
		return
	last_scorch = t
	var ld = (basis.inverse() * world_dir).normalized()
	var dec = Decal.new()
	dec.texture_albedo = _scorch_texture()
	dec.texture_emission = _hot_texture()
	dec.emission_energy = 5.0
	var w = randf_range(1.6, 2.8) * (1.8 if elite else 1.0)
	dec.size = Vector3(w, 6.0, w)
	dec.upper_fade = 0.2
	dec.lower_fade = 0.2
	dec.albedo_mix = 0.92
	# a decal projects along its own -Y, so point +Y outward from the hull
	var y = ld
	var x = y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z = x.cross(y).normalized()
	dec.transform = Transform3D(Basis(x, y, z).rotated(y, randf() * TAU), ld * 2.6)
	add_child(dec)
	scorches.append([dec, t])
	while scorches.size() > SCORCH_MAX:
		scorches[0][0].queue_free()
		scorches.pop_front()


func clear_scorch() -> void:
	for sc in scorches:
		sc[0].queue_free()
	scorches.clear()


static func _scorch_texture() -> ImageTexture:
	if scorch_tex == null:
		var noise = FastNoiseLite.new()
		noise.frequency = 0.09
		var img = Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
		for py in 64:
			for px in 64:
				var d = Vector2(px - 31.5, py - 31.5).length() / 31.5
				var n = noise.get_noise_2d(px, py) * 0.5 + 0.5
				var a = clampf((1.0 - d) * 1.6 * (0.55 + 0.6 * n), 0.0, 0.95)
				var c = lerpf(0.02, 0.12, n)
				img.set_pixel(px, py, Color(c, c * 0.95, c * 0.9, a))
		scorch_tex = ImageTexture.create_from_image(img)
	return scorch_tex


static func _hot_texture() -> ImageTexture:
	if hot_tex == null:
		var img = Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
		for py in 32:
			for px in 32:
				var d = Vector2(px - 15.5, py - 15.5).length() / 15.5
				var k = clampf(1.0 - d * 2.2, 0.0, 1.0)
				img.set_pixel(px, py, Color(1.0 * k, 0.42 * k, 0.08 * k, 1.0))
		hot_tex = ImageTexture.create_from_image(img)
	return hot_tex


func set_shield(k: float) -> void:
	if shield == null:
		return
	k = clampf(k, 0.0, 1.0)
	if absf(k - shield_k) < 0.005:
		return
	shield_k = k
	shield_mat.set_shader_parameter("strength", k)
	_shield_vis()


func _shield_vis() -> void:
	shield.visible = not hits.is_empty() or (shield_k > 0.0 and shield_k < 0.35)



func shield_hit(world_dir: Vector3) -> void:
	if shield == null or world_dir.length() < 0.001:
		return
	hits.append([(basis.inverse() * world_dir).normalized(), 0.0])
	if hits.size() > 4:
		hits.pop_front()
	_push_hits()


func _push_hits() -> void:
	var arr = PackedVector4Array()
	for i in 4:
		if i < hits.size():
			var d: Vector3 = hits[i][0]
			arr.append(Vector4(d.x, d.y, d.z, hits[i][1]))
		else:
			arr.append(Vector4(0, 1, 0, -1.0))
	shield_mat.set_shader_parameter("hits", arr)
	_shield_vis()
