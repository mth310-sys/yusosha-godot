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
	return _build_connected_upper(false)

func _shirt_mesh() -> ArrayMesh:
	return _build_connected_upper(true)

func _build_connected_upper(clothing: bool) -> ArrayMesh:
	# One connected surface: torso front/back and both arms share the same
	# shoulder boundary vertices. There is no separate arm tube to split away.
	var vertices := PackedVector3Array()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var indices := PackedInt32Array()
	var z: float = 0.095 if not clothing else 0.108
	var x_waist: float = 0.155 if not clothing else 0.168
	var x_chest: float = 0.180 if not clothing else 0.195
	var x_shoulder: float = 0.225 if not clothing else 0.240
	var x_arm: float = 0.270 if not clothing else 0.285
	var y_top: float = 0.80 if not clothing else 0.81
	var y_shoulder: float = 0.74 if not clothing else 0.75
	var y_armpit: float = 0.64 if not clothing else 0.65
	var y_hem: float = 0.44 if not clothing else 0.43
	var y_arm_end: float = 0.43 if not clothing else 0.60

	# Each side is a 2D outline extruded front/back. Shoulder and arm vertices
	# belong to the same indexed surface as the chest.
	var front: Array[Vector3] = [
		Vector3(-x_chest,y_top,z), Vector3(x_chest,y_top,z),
		Vector3(-x_shoulder,y_shoulder,z), Vector3(x_shoulder,y_shoulder,z),
		Vector3(-x_arm,y_armpit,z), Vector3(x_arm,y_armpit,z),
		Vector3(-x_arm,y_arm_end,z), Vector3(x_arm,y_arm_end,z),
		Vector3(-x_chest,y_armpit,z), Vector3(x_chest,y_armpit,z),
		Vector3(-x_waist,y_hem,z), Vector3(x_waist,y_hem,z)
	]
	for p in front:
		vertices.append(p)
	var count: int = front.size()
	for p in front:
		vertices.append(Vector3(p.x,p.y,-z))

	# Front/back topology. Central torso and shoulder wedges are connected to
	# the arm strips using shared indices.
	var front_tris := PackedInt32Array([
		0,8,1, 1,8,9,
		0,2,8, 1,9,3,
		2,4,8, 3,9,5,
		4,6,8, 5,9,7,
		8,10,9, 9,10,11
	])
	for i in range(0,front_tris.size(),3):
		indices.append_array(PackedInt32Array([front_tris[i],front_tris[i+1],front_tris[i+2]]))
		indices.append_array(PackedInt32Array([count+front_tris[i+2],count+front_tris[i+1],count+front_tris[i]]))

	# Close the silhouette around the outside boundary.
	var boundary := PackedInt32Array([0,1,3,5,7,9,11,10,8,6,4,2])
	for i in range(boundary.size()):
		var n: int = (i+1)%boundary.size()
		var fa: int = boundary[i]
		var fb: int = boundary[n]
		var ba: int = count+fa
		var bb: int = count+fb
		indices.append_array(PackedInt32Array([fa,ba,fb,fb,ba,bb]))

	for i in range(vertices.size()):
		var local: int = i % count
		if local == 2 or local == 3:
			var arm_bone: int = bone_arm_l if local == 2 else bone_arm_r
			_append_weight(bones,weights,bone_root,0.75,arm_bone,0.25)
		elif local == 4 or local == 6:
			_append_weight(bones,weights,bone_root,0.25,bone_arm_l,0.75)
		elif local == 5 or local == 7:
			_append_weight(bones,weights,bone_root,0.25,bone_arm_r,0.75)
		else:
			_append_weight(bones,weights,bone_root,1.0,bone_root,0.0)
	return _mesh(vertices,indices,bones,weights)

func _append_vertical_tube(vertices: PackedVector3Array, bones: PackedInt32Array, weights: PackedFloat32Array, indices: PackedInt32Array, rings: Array[Vector3], bone: int, segments: int) -> void:
	var base: int = vertices.size()
	for ring in rings:
		for s in range(segments):
			var angle: float = TAU * float(s) / float(segments)
			vertices.append(Vector3(cos(angle)*ring.x,ring.y,sin(angle)*ring.z))
			_append_weight(bones,weights,bone,1.0,bone_root,0.0)
	for r in range(rings.size()-1):
		for s in range(segments):
			var n: int = (s+1)%segments
			var v0: int = base+r*segments+s
			var v1: int = base+r*segments+n
			var v2: int = base+(r+1)*segments+s
			var v3: int = base+(r+1)*segments+n
			indices.append_array(PackedInt32Array([v0,v2,v1,v1,v2,v3]))

func _append_weight(bones: PackedInt32Array, weights: PackedFloat32Array, bone_a: int, weight_a: float, bone_b: int, weight_b: float) -> void:
	bones.append_array(PackedInt32Array([bone_a,bone_b,0,0]))
	weights.append_array(PackedFloat32Array([weight_a,weight_b,0.0,0.0]))

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
