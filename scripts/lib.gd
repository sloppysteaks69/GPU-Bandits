extends RefCounted


const TOON = preload("res://shaders/toon.gdshader")
const TOON_HOLE = preload("res://shaders/toon_hole.gdshader")


static var hole_mats: Array = []


static func toon(col: Color, emit: Color = Color(0, 0, 0), power: float = 0.0) -> ShaderMaterial:
	var m = ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("albedo", col)
	m.set_shader_parameter("emit", emit)
	m.set_shader_parameter("emit_power", power)
	return m


static func toon_hole(col: Color) -> ShaderMaterial:
	var m = ShaderMaterial.new()
	m.shader = TOON_HOLE
	m.set_shader_parameter("albedo", col)
	hole_mats.append(m)
	return m


static func glow(col: Color, energy: float = 3.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(0, 0, 0)
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	return m


static func _mi(parent: Node, mesh: Mesh, pos: Vector3, mat: Material, rot: Vector3) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func box(parent: Node, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m = BoxMesh.new()
	m.size = size
	return _mi(parent, m, pos, mat, rot)


static func cyl(parent: Node, r_top: float, r_bot: float, h: float, segs: int, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m = CylinderMesh.new()
	m.top_radius = r_top
	m.bottom_radius = r_bot
	m.height = h
	m.radial_segments = segs
	m.rings = 1
	return _mi(parent, m, pos, mat, rot)


static func prism(parent: Node, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, ltr: float = 0.5) -> MeshInstance3D:
	var m = PrismMesh.new()
	m.size = size
	m.left_to_right = ltr
	return _mi(parent, m, pos, mat, rot)


static func ball(parent: Node, r: float, pos: Vector3, mat: Material, segs: int = 8) -> MeshInstance3D:
	var m = SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segs
	m.rings = max(2, segs / 2)
	return _mi(parent, m, pos, mat, Vector3.ZERO)




static var _flame_mat: Material = null


static func missile_model(n: Node3D, col: Color, flame: bool) -> void:
	cyl(n, 0.0, 0.9, 2.4, 6, Vector3(0, 0, -2.6), toon(col), Vector3(-PI / 2, 0, 0))
	cyl(n, 0.9, 0.9, 4.0, 6, Vector3(0, 0, 0.6), toon(Color(0.9, 0.9, 0.92)), Vector3(PI / 2, 0, 0))
	box(n, Vector3(3.4, 0.2, 1.4), Vector3(0, 0, 2.2), toon(col))
	box(n, Vector3(0.2, 3.4, 1.4), Vector3(0, 0, 2.2), toon(col))
	if flame:
		if _flame_mat == null:
			_flame_mat = glow(Color(1.0, 0.6, 0.15), 4.0)
		ball(n, 1.3, Vector3(0, 0, 3.6), _flame_mat, 6)



static func seg_sphere(p0: Vector3, p1: Vector3, c: Vector3, r: float) -> bool:
	var d = p1 - p0
	var len2 = d.length_squared()
	var k = 0.0
	if len2 > 1.0e-06:
		k = clampf((c - p0).dot(d) / len2, 0.0, 1.0)
	return (p0 + d * k).distance_squared_to(c) <= r * r




static func seg_box(p0: Vector3, p1: Vector3, inv: Transform3D, half: Vector3) -> bool:
	var a = inv * p0
	var b = inv * p1
	var d = b - a
	var t0 = 0.0
	var t1 = 1.0
	for ax in 3:
		if absf(d[ax]) < 1.0e-06:
			if absf(a[ax]) > half[ax]:
				return false
		else:
			var u = (-half[ax] - a[ax]) / d[ax]
			var v = (half[ax] - a[ax]) / d[ax]
			if u > v:
				var w = u
				u = v
				v = w
			t0 = maxf(t0, u)
			t1 = minf(t1, v)
			if t0 > t1:
				return false
	return true



static func face(n: Node3D, pos: Vector3, dir: Vector3) -> void:
	var d = dir.normalized()
	var up = Vector3.UP
	if absf(d.dot(up)) > 0.98:
		up = Vector3.RIGHT
	n.transform = Transform3D(Basis.looking_at(d, up), pos)
