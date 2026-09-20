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
	# First proof: torso + both full arms are one continuous weighted surface.
	var verts := PackedVector3Array([
		Vector3(-0.15,0.78,0.09), Vector3(0.15,0.78,0.09),
		Vector3(-0.16,0.43,0.09), Vector3(0.16,0.43,0.09),
		Vector3(-0.15,0.78,-0.09), Vector3(0.15,0.78,-0.09),
		Vector3(-0.16,0.43,-0.09), Vector3(0.16,0.43,-0.09),
		Vector3(-0.20,0.74,0.055), Vector3(-0.24,0.54,0.045), Vector3(-0.22,0.36,0.04),
		Vector3(-0.20,0.74,-0.055), Vector3(-0.24,0.54,-0.045), Vector3(-0.22,0.36,-0.04),
		Vector3(0.20,0.74,0.055), Vector3(0.24,0.54,0.045), Vector3(0.22,0.36,0.04),
		Vector3(0.20,0.74,-0.055), Vector3(0.24,0.54,-0.045), Vector3(0.22,0.36,-0.04)
	])
	var idx := PackedInt32Array([
		0,2,1,1,2,3, 5,7,4,4,7,6, 0,4,2,2,4,6, 1,3,5,5,3,7,
		0,8,4,4,8,11, 8,9,11,11,9,12, 9,10,12,12,10,13,
		1,5,14,14,5,17, 14,17,15,15,17,18, 15,18,16,16,18,19
	])
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	for i in range(verts.size()):
		var b: int = bone_root
		if i >= 8 and i <= 13:
			b = bone_arm_l
		elif i >= 14:
			b = bone_arm_r
		bones.append_array(PackedInt32Array([b,0,0,0]))
		weights.append_array(PackedFloat32Array([1.0,0.0,0.0,0.0]))
	return _mesh(verts, idx, bones, weights)

func _shirt_mesh() -> ArrayMesh:
	# Clothing is a separate weighted mesh using the exact same skeleton.
	var verts := PackedVector3Array([
		Vector3(-0.18,0.80,0.105),Vector3(0.18,0.80,0.105),
		Vector3(-0.17,0.44,0.105),Vector3(0.17,0.44,0.105),
		Vector3(-0.18,0.80,-0.105),Vector3(0.18,0.80,-0.105),
		Vector3(-0.17,0.44,-0.105),Vector3(0.17,0.44,-0.105),
		Vector3(-0.22,0.76,0.065),Vector3(-0.23,0.66,0.06),
		Vector3(-0.22,0.76,-0.065),Vector3(-0.23,0.66,-0.06),
		Vector3(0.22,0.76,0.065),Vector3(0.23,0.66,0.06),
		Vector3(0.22,0.76,-0.065),Vector3(0.23,0.66,-0.06)
	])
	var idx := PackedInt32Array([
		0,2,1,1,2,3, 5,7,4,4,7,6, 0,4,2,2,4,6, 1,3,5,5,3,7,
		0,8,4,4,8,10, 8,9,10,10,9,11,
		1,5,12,12,5,14, 12,14,13,13,14,15
	])
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	for i in range(verts.size()):
		var b: int = bone_root
		if i >= 8 and i <= 11:
			b = bone_arm_l
		elif i >= 12:
			b = bone_arm_r
		bones.append_array(PackedInt32Array([b,0,0,0]))
		weights.append_array(PackedFloat32Array([1.0,0.0,0.0,0.0]))
	return _mesh(verts, idx, bones, weights)

func _pants_mesh() -> ArrayMesh:
	var verts := PackedVector3Array([
		Vector3(-0.15,0.45,0.10),Vector3(0.15,0.45,0.10),Vector3(-0.13,0.28,0.08),Vector3(0.13,0.28,0.08),
		Vector3(-0.15,0.45,-0.10),Vector3(0.15,0.45,-0.10),Vector3(-0.13,0.28,-0.08),Vector3(0.13,0.28,-0.08)
	])
	var idx := PackedInt32Array([0,2,1,1,2,3,5,7,4,4,7,6,0,4,2,2,4,6,1,3,5,5,3,7])
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	for i in range(verts.size()):
		bones.append_array(PackedInt32Array([bone_root,0,0,0]))
		weights.append_array(PackedFloat32Array([1.0,0.0,0.0,0.0]))
	return _mesh(verts,idx,bones,weights)

func _mesh(vertices: PackedVector3Array, indices: PackedInt32Array, bones: PackedInt32Array, weights: PackedFloat32Array) -> ArrayMesh:
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	for i in range(0, indices.size(), 3):
		var a: int = indices[i]
		var b: int = indices[i+1]
		var c: int = indices[i+2]
		var n: Vector3 = (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a]).normalized()
		normals[a] += n
		normals[b] += n
		normals[c] += n
	for i in range(normals.size()):
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
