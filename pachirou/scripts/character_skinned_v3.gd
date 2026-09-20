extends Node3D

@export var animate_walk: bool = true

# Character Base 01 v3 validation.
# Continuous skinned body + separate skinned clothing on one Skeleton3D.

var skeleton: Skeleton3D
var t: float = 0.0
var bone_root: int
var bone_arm_l: int
var bone_arm_r: int
var bone_leg_l: int
var bone_leg_r: int

func _ready() -> void:
	_build_validation_environment()
	_build_skeleton()
	_build_skinned_character()

func _build_validation_environment() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_energy = 1.05
	light.shadow_enabled = true
	add_child(light)

	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-42, 135, 0)
	fill_light.light_energy = 0.32
	fill_light.shadow_enabled = false
	add_child(fill_light)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.65
	camera.position = Vector3(1.85, 2.10, 1.85)
	camera.rotation_degrees = Vector3(-35.264, 45, 0)
	camera.current = true
	add_child(camera)

	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(3.0, 3.0)
	floor.mesh = floor_mesh
	floor.material_override = _mat(Color(0.72, 0.76, 0.82))
	add_child(floor)

func _process(delta: float) -> void:
	if not animate_walk:
		return
	t += delta
	var wave: float = sin(t * 4.0)
	skeleton.set_bone_pose_rotation(bone_arm_l, Quaternion(Vector3.RIGHT, deg_to_rad(18.0) * wave))
	skeleton.set_bone_pose_rotation(bone_arm_r, Quaternion(Vector3.RIGHT, -deg_to_rad(18.0) * wave))
	skeleton.set_bone_pose_rotation(bone_leg_l, Quaternion(Vector3.RIGHT, -deg_to_rad(12.0) * wave))
	skeleton.set_bone_pose_rotation(bone_leg_r, Quaternion(Vector3.RIGHT, deg_to_rad(12.0) * wave))

func _build_skeleton() -> void:
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	add_child(skeleton)
	bone_root = skeleton.add_bone("Root")
	bone_arm_l = skeleton.add_bone("ArmL")
	bone_arm_r = skeleton.add_bone("ArmR")
	bone_leg_l = skeleton.add_bone("LegL")
	bone_leg_r = skeleton.add_bone("LegR")
	skeleton.set_bone_parent(bone_arm_l, bone_root)
	skeleton.set_bone_parent(bone_arm_r, bone_root)
	skeleton.set_bone_parent(bone_leg_l, bone_root)
	skeleton.set_bone_parent(bone_leg_r, bone_root)
	skeleton.set_bone_rest(bone_root, Transform3D(Basis.IDENTITY, Vector3(0, 0.58, 0)))
	skeleton.set_bone_rest(bone_arm_l, Transform3D(Basis.IDENTITY, Vector3(-0.20, 0.16, 0)))
	skeleton.set_bone_rest(bone_arm_r, Transform3D(Basis.IDENTITY, Vector3(0.20, 0.16, 0)))
	skeleton.set_bone_rest(bone_leg_l, Transform3D(Basis.IDENTITY, Vector3(-0.09, -0.15, 0)))
	skeleton.set_bone_rest(bone_leg_r, Transform3D(Basis.IDENTITY, Vector3(0.09, -0.15, 0)))
	skeleton.reset_bone_poses()

func _build_skinned_character() -> void:
	var skin := Skin.new()
	for i in range(skeleton.get_bone_count()):
		skin.add_bind(i, skeleton.get_bone_global_rest(i).affine_inverse())

	var body := MeshInstance3D.new()
	body.name = "SkinnedBody"
	body.mesh = _body_mesh()
	body.skin = skin
	body.skeleton = NodePath("../Skeleton3D")
	body.material_override = _mat(Color(0.84, 0.64, 0.50))
	add_child(body)

	var shirt := MeshInstance3D.new()
	shirt.name = "SkinnedTShirt"
	shirt.mesh = _shirt_mesh()
	shirt.skin = skin
	shirt.skeleton = NodePath("../Skeleton3D")
	shirt.material_override = _mat(Color(0.96, 0.96, 0.94))
	add_child(shirt)

	var pants := MeshInstance3D.new()
	pants.name = "SkinnedPants"
	pants.mesh = _pants_mesh()
	pants.skin = skin
	pants.skeleton = NodePath("../Skeleton3D")
	pants.material_override = _mat(Color(0.10, 0.13, 0.18))
	add_child(pants)

func _body_mesh() -> ArrayMesh:
	# Continuous torso with shoulder loops. Arm weights blend from Root to Arm.
	return _build_upper_mesh(false)

func _shirt_mesh() -> ArrayMesh:
	# Same topology as the body, expanded slightly as clothing.
	return _build_upper_mesh(true)

func _build_upper_mesh(clothing: bool) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var indices := PackedInt32Array()
	var torso_rings: Array[Vector3] = [
		Vector3(0.145, 0.80, 0.090),
		Vector3(0.190, 0.74, 0.100),
		Vector3(0.175, 0.62, 0.100),
		Vector3(0.160, 0.44, 0.090)
	]
	if clothing:
		torso_rings = [
			Vector3(0.158, 0.81, 0.102),
			Vector3(0.205, 0.75, 0.112),
			Vector3(0.188, 0.62, 0.112),
			Vector3(0.173, 0.43, 0.102)
		]
	_append_vertical_tube(vertices, bones, weights, indices, torso_rings, bone_root, 12)

	# Arms are proper tubes with four loops. The shoulder loop blends Root/Arm,
	# so rotation bends the surface instead of opening a gap.
	_append_arm_tube(vertices, bones, weights, indices, -1.0, clothing)
	_append_arm_tube(vertices, bones, weights, indices, 1.0, clothing)
	return _mesh(vertices, indices, bones, weights)

func _append_vertical_tube(vertices: PackedVector3Array, bones: PackedInt32Array, weights: PackedFloat32Array, indices: PackedInt32Array, rings: Array[Vector3], bone: int, segments: int) -> void:
	var base: int = vertices.size()
	for ring in rings:
		for s in range(segments):
			var angle: float = TAU * float(s) / float(segments)
			vertices.append(Vector3(cos(angle) * ring.x, ring.y, sin(angle) * ring.z))
			_append_weight(bones, weights, bone, 1.0, bone_root, 0.0)
	_connect_rings(indices, base, rings.size(), segments)

func _append_arm_tube(vertices: PackedVector3Array, bones: PackedInt32Array, weights: PackedFloat32Array, indices: PackedInt32Array, side: float, clothing: bool) -> void:
	var arm_bone: int = bone_arm_l if side < 0.0 else bone_arm_r
	var base: int = vertices.size()
	var segments: int = 10
	var shoulder_x: float = 0.190 if not clothing else 0.205
	var radius: float = 0.048 if not clothing else 0.055
	var ys: Array[float] = [0.75, 0.70, 0.60, 0.47]
	if clothing:
		ys = [0.76, 0.71, 0.66, 0.61]
	for r in range(ys.size()):
		var root_weight: float = 0.0
		if r == 0:
			root_weight = 0.70
		elif r == 1:
			root_weight = 0.35
		var arm_weight: float = 1.0 - root_weight
		var x_center: float = side * (shoulder_x + float(r) * 0.014)
		var rr: float = radius - float(r) * 0.002
		for s in range(segments):
			var angle: float = TAU * float(s) / float(segments)
			vertices.append(Vector3(x_center + cos(angle) * rr, ys[r], sin(angle) * rr))
			_append_weight(bones, weights, bone_root, root_weight, arm_bone, arm_weight)
	_connect_rings(indices, base, ys.size(), segments)

func _connect_rings(indices: PackedInt32Array, base: int, ring_count: int, segments: int) -> void:
	for r in range(ring_count - 1):
		for s in range(segments):
			var n: int = (s + 1) % segments
			var a: int = base + r * segments + s
			var b: int = base + r * segments + n
			var c0: int = base + (r + 1) * segments + s
			var d: int = base + (r + 1) * segments + n
			indices.append_array(PackedInt32Array([a, c0, b, b, c0, d]))

func _append_weight(bones: PackedInt32Array, weights: PackedFloat32Array, bone_a: int, weight_a: float, bone_b: int, weight_b: float) -> void:
	bones.append_array(PackedInt32Array([bone_a, bone_b, 0, 0]))
	weights.append_array(PackedFloat32Array([weight_a, weight_b, 0.0, 0.0]))

func _pants_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var indices := PackedInt32Array()
	var rings: Array[Vector3] = [
		Vector3(0.15,0.45,0.10),
		Vector3(0.14,0.36,0.09),
		Vector3(0.13,0.28,0.08)
	]
	_append_vertical_tube(vertices,bones,weights,indices,rings,bone_root,12)
	return _mesh(vertices,indices,bones,weights)

func _mesh(vertices: PackedVector3Array, indices: PackedInt32Array, bones: PackedInt32Array, weights: PackedFloat32Array) -> ArrayMesh:
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	for i in range(0, indices.size(), 3):
		var a: int = indices[i]
		var b: int = indices[i + 1]
		var c0: int = indices[i + 2]
		var edge1: Vector3 = vertices[b] - vertices[a]
		var edge2: Vector3 = vertices[c0] - vertices[a]
		var normal: Vector3 = edge1.cross(edge2)
		if normal.length_squared() > 0.000001:
			normal = normal.normalized()
		normals[a] += normal
		normals[b] += normal
		normals[c0] += normal
	for i in range(normals.size()):
		if normals[i].length_squared() > 0.000001:
			normals[i] = normals[i].normalized()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_BONES] = bones
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	return mat
