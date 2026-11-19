extends Node3D

# Energy beam for the pink aces (1.0.4), adapted from the EnergyBeam3D drop-in: three nested
# additive cylinders (outer glow / mid / white-hot core) sharing energy_beam_3d.gdshader, a
# charge orb + halo + light at the nose, a muzzle flash, and an impact burst + shockwave + light
# where the beam lands. Sizes are scaled up to this game's ships (about 3x the drop-in).
# This node only draws: main.gd moves it to the ace's nose every frame, measures where the beam
# stops and deals the damage on the host, so every machine shows the same beam.

const SHADER = preload("res://shaders/energy_beam_3d.gdshader")
const RADII = [1.8, 0.9, 0.35]
const BASE = [0.45, 0.7, 1.0]
const SCALE = 3.0

var beam_radius = 1.1
var power = 1.0   # 1.1.2 charged laser lance: brighter beam (main sets it before firing)
# 1.1.2 lightning: jagged arcs crackling off the charge ball and wrapping the beam
var arcs_on = false
var orb_size = 1.0
var _streaks = []
var _bolts = []
var _arc_mat: StandardMaterial3D
var _arc_k = 0.0
var _beam_len = 0.0
const BOLTS = 9
const BOLT_SEGS = 7
var beam_color = Color(0.6, 0.25, 1.0)

var _time = 0.0
var _beam_root: Node3D
var _layers = []
var _mats = []
var _orb: MeshInstance3D
var _halo: MeshInstance3D
var _charge_light: OmniLight3D
var _muzzle_light: OmniLight3D
var _impact: Node3D
var _impact_light: OmniLight3D
var _impact_parts: GPUParticles3D
var _muzzle_parts: GPUParticles3D
var _shock: MeshInstance3D
var _shock_mat: StandardMaterial3D
var _shock_t = 1.0
var _had_hit = false
var _fired = false
var hum: AudioStreamPlayer3D


func build(sound: AudioStream) -> void:
	var cyl = CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 1.0
	cyl.radial_segments = 24
	cyl.rings = 1
	_beam_root = Node3D.new()
	_beam_root.visible = false
	add_child(_beam_root)
	var cols = [beam_color, beam_color.lightened(0.35), Color.WHITE]
	for i in 3:
		var mat = ShaderMaterial.new()
		mat.shader = SHADER
		mat.set_shader_parameter("beam_color", cols[i])
		mat.set_shader_parameter("intensity", BASE[i])
		var mi = MeshInstance3D.new()
		mi.mesh = cyl
		mi.material_override = mat
		mi.rotation_degrees = Vector3(-90, 0, 0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_beam_root.add_child(mi)
		_layers.append(mi)
		_mats.append(mat)

	_orb = _glow_sphere(0.4 * SCALE, Color.WHITE, beam_color, 3.0, false)
	_orb.visible = false
	add_child(_orb)
	_halo = _glow_sphere(0.4 * SCALE, Color(beam_color, 0.3), beam_color, 0.0, true)
	_halo.visible = false
	add_child(_halo)
	_charge_light = _light(beam_color, 12.0 * SCALE)
	add_child(_charge_light)
	_muzzle_light = _light(beam_color, 14.0 * SCALE)
	add_child(_muzzle_light)

	_impact = Node3D.new()
	_impact.visible = false
	add_child(_impact)
	_impact_light = _light(Color(0.9, 0.8, 1.0), 16.0 * SCALE)
	_impact.add_child(_impact_light)
	_impact_parts = _burst(64, Color(0.85, 0.75, 1.0), 0.6, 6.0 * SCALE, 18.0 * SCALE)
	_impact.add_child(_impact_parts)
	_shock_mat = StandardMaterial3D.new()
	_shock_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shock_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shock_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_shock_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_shock_mat.albedo_color = Color(beam_color, 0.0)
	var sm = SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 24
	sm.rings = 12
	_shock = MeshInstance3D.new()
	_shock.mesh = sm
	_shock.material_override = _shock_mat
	_shock.visible = false
	_impact.add_child(_shock)
	_muzzle_parts = _burst(24, Color.WHITE, 0.3, 4.0 * SCALE, 10.0 * SCALE)
	add_child(_muzzle_parts)

	if sound != null:
		hum = AudioStreamPlayer3D.new()
		hum.stream = sound
		hum.volume_db = -2.0
		hum.unit_size = 55.0
		hum.max_distance = 700.0
		add_child(hum)


func enable_arcs(col: Color) -> void:
	arcs_on = true
	_arc_mat = StandardMaterial3D.new()
	_arc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_arc_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_arc_mat.albedo_color = col
	_arc_mat.emission_enabled = true
	_arc_mat.emission = col
	_arc_mat.emission_energy_multiplier = 4.0
	var bm = BoxMesh.new()
	bm.size = Vector3.ONE
	for b in BOLTS:
		var segs = []
		for i in BOLT_SEGS:
			var mi = MeshInstance3D.new()
			mi.mesh = bm
			mi.material_override = _arc_mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.visible = false
			add_child(mi)
			segs.append(mi)
		_bolts.append(segs)
	# red-hot streaks that race down the inside of the beam
	var sm = SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 10
	sm.rings = 5
	var red = StandardMaterial3D.new()
	red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	red.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	red.albedo_color = Color(1.0, 0.15, 0.2)
	for i in 6:
		var st = MeshInstance3D.new()
		st.mesh = sm
		st.material_override = red
		st.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		st.visible = false
		add_child(st)
		_streaks.append(st)


# Redraws every bolt along a fresh random jagged path. Before firing they shoot out of the ball;
# while firing, every other bolt instead runs down the beam, twisting around it.
func _update_arcs(orb_r: float) -> void:
	if not arcs_on:
		return
	for b in BOLTS:
		var segs = _bolts[b]
		var show = randf() < 0.25 + 0.75 * _arc_k
		if not show:
			for mi in segs:
				mi.visible = false
			continue
		var pts = []
		if _beam_len > 0.0 and b % 3 != 2:
			# a loop of lightning that leaps off the beam and lands back on it further along
			var z0 = -randf() * _beam_len * 0.85
			var span = minf(_beam_len - absf(z0), (10.0 + 25.0 * _arc_k) * randf_range(0.5, 1.0))
			var ang = randf() * TAU
			var out = (2.0 + 7.0 * _arc_k) * randf_range(0.5, 1.0)
			for i in BOLT_SEGS + 1:
				var f = float(i) / BOLT_SEGS
				var a = ang + randf_range(-0.35, 0.35)
				var rr = beam_radius + sin(f * PI) * out
				pts.append(Vector3(cos(a) * rr, sin(a) * rr, z0 - span * f) + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * out * 0.12)
		else:
			var dir = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-0.4, 0.8)).normalized()
			var reach = orb_r * 1.2 + (2.0 + 9.0 * _arc_k) * randf_range(0.5, 1.0)
			var side = dir.cross(Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT).normalized()
			var up = dir.cross(side)
			for i in BOLT_SEGS + 1:
				var f = float(i) / BOLT_SEGS
				var p = dir * (orb_r * 0.8 + reach * f)
				if i > 0:
					p += (side * randf_range(-1, 1) + up * randf_range(-1, 1)) * reach * 0.13
				pts.append(p)
		var w = 0.08 + 0.16 * _arc_k
		for i in BOLT_SEGS:
			var a: Vector3 = pts[i]
			var c: Vector3 = pts[i + 1]
			var d = c - a
			var mi = segs[i]
			if d.length() < 0.01:
				mi.visible = false
				continue
			mi.visible = true
			mi.basis = Basis.looking_at(d.normalized(), Vector3.UP if absf(d.normalized().y) < 0.95 else Vector3.RIGHT)
			mi.scale = Vector3(w, w, d.length())
			mi.position = (a + c) * 0.5


# Charging: k goes 0 -> 1 over the telegraph.
func show_charge(k: float, dt: float) -> void:
	_tick(dt)
	_arc_k = clampf(k, 0.0, 1.0)
	_update_arcs(0.4 * SCALE * (0.2 + k * 1.1) * orb_size)
	_orb.visible = true
	_halo.visible = true
	var pulse = 1.0 + sin(_time * 30.0) * 0.08 * k
	_orb.scale = Vector3.ONE * (0.2 + k * 1.1) * pulse * orb_size
	_halo.scale = Vector3.ONE * (1.5 + k * 2.0) * orb_size
	_charge_light.light_energy = k * 4.0


# Firing: remaining goes 1 -> 0; length is where the beam stops; hit = it landed on something.
func show_fire(remaining: float, length: float, hit: bool, dt: float) -> void:
	_tick(dt)
	if not _fired:
		_fired = true
		_orb.visible = false
		_halo.visible = false
		_charge_light.light_energy = 0.0
		_beam_root.visible = true
		_muzzle_light.light_energy = 6.0 * power
		_muzzle_parts.restart()
		_muzzle_parts.emitting = true
		if hum != null:
			hum.play()
	for i in _mats.size():
		_mats[i].set_shader_parameter("intensity", BASE[i] * remaining * power)
		_mats[i].set_shader_parameter("uv_scale", length / (8.0 * SCALE))
		var r = beam_radius * RADII[i]
		_layers[i].scale = Vector3(r, length, r)
		_layers[i].position = Vector3(0, 0, -length * 0.5)
	_beam_len = length
	_arc_k = clampf(power / 2.6, 0.3, 1.0) * remaining
	_update_arcs(beam_radius)
	for i in _streaks.size():
		var st = _streaks[i]
		st.visible = remaining > 0.05 and length > 10.0
		if st.visible:
			var z = fmod(_time * 160.0 + i * length / _streaks.size(), length)
			st.position = Vector3(sin(_time * 7.0 + i) * beam_radius * 0.3, cos(_time * 5.0 + i * 2.0) * beam_radius * 0.3, -z)
			st.scale = Vector3(beam_radius * 0.55, beam_radius * 0.35, 2.5 + beam_radius * 3.0)
	if hit:
		_impact.position = Vector3(0, 0, -length)
		if not _had_hit:
			_had_hit = true
			_impact.visible = true
			_impact_light.light_energy = 8.0
			_impact_parts.restart()
			_impact_parts.emitting = true
			_shock.visible = true
			_shock_t = 0.0
	else:
		_had_hit = false
		_impact.visible = _shock_t < 1.0
	_muzzle_light.light_energy = maxf(_muzzle_light.light_energy - dt * 30.0, 0.0)
	_impact_light.light_energy = maxf(_impact_light.light_energy - dt * 40.0, 0.0)
	if _shock_t < 1.0:
		_shock_t = minf(_shock_t + dt / 0.35, 1.0)
		_shock.scale = Vector3.ONE * (0.3 + _shock_t * 4.0) * SCALE
		_shock_mat.albedo_color = Color(beam_color, 0.7 * (1.0 - _shock_t))
		if _shock_t >= 1.0:
			_shock.visible = false


func _tick(dt: float) -> void:
	_time += dt
	for m in _mats:
		m.set_shader_parameter("time", _time)


func _light(col: Color, rng: float) -> OmniLight3D:
	var l = OmniLight3D.new()
	l.light_color = col
	l.omni_range = rng
	l.light_energy = 0.0
	l.shadow_enabled = false
	return l


func _glow_sphere(radius: float, albedo: Color, emission: Color, energy: float, transparent: bool) -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 32
	mesh.rings = 16
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = albedo
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	if energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = energy
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _burst(amount: int, color: Color, lifetime: float, vmin: float, vmax: float) -> GPUParticles3D:
	var p = GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = true
	p.explosiveness = 0.92
	p.emitting = false
	p.visibility_aabb = AABB(Vector3(-60, -60, -60), Vector3(120, 120, 120))
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.3 * SCALE
	mat.direction = Vector3.ZERO
	mat.spread = 180.0
	mat.initial_velocity_min = vmin
	mat.initial_velocity_max = vmax
	mat.gravity = Vector3.ZERO
	mat.damping_min = 4.0 * SCALE
	mat.damping_max = 8.0 * SCALE
	mat.scale_min = 1.0
	mat.scale_max = 3.0
	mat.color = color
	p.process_material = mat
	var spark = SphereMesh.new()
	spark.radius = 0.12 * SCALE
	spark.height = 0.24 * SCALE
	spark.radial_segments = 8
	spark.rings = 4
	var sm = StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.vertex_color_use_as_albedo = true
	spark.material = sm
	p.draw_pass_1 = spark
	return p
