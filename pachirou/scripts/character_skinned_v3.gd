extends Node3D

# Pachirou Character Generator - Stage 1
# Skeleton and joint-weight validation only. Clothing/hair are intentionally absent.

@export var animate_walk: bool = true

var skeleton: Skeleton3D
var skin: Skin
var t: float = 0.0
var bones: Dictionary = {}

func _ready() -> void:
	_build_environment()
	_build_skeleton()
	_build_skin()
	await _build_body()

func _process(delta: float) -> void:
	if not animate_walk:
		return
	t += delta
	var w: float = sin(t * 3.4)
	_pose("UpperArmL", Vector3.RIGHT, deg_to_rad(22.0) * w)
	_pose("UpperArmR", Vector3.RIGHT, -deg_to_rad(22.0) * w)
	_pose("UpperLegL", Vector3.RIGHT, -deg_to_rad(16.0) * w)
	_pose("UpperLegR", Vector3.RIGHT, deg_to_rad(16.0) * w)
	_pose("LowerLegL", Vector3.RIGHT, max(0.0, w) * deg_to_rad(18.0))
	_pose("LowerLegR", Vector3.RIGHT, max(0.0, -w) * deg_to_rad(18.0))

func _pose(name: String, axis: Vector3, angle: float) -> void:
	var idx: int = int(bones[name])
	skeleton.set_bone_pose_rotation(idx, Quaternion(axis, angle))

func _add_bone(name: String, parent: String, origin: Vector3) -> int:
	var idx: int = skeleton.add_bone(name)
	bones[name] = idx
	if parent != "":
		skeleton.set_bone_parent(idx, int(bones[parent]))
	skeleton.set_bone_rest(idx, Transform3D(Basis.IDENTITY, origin))
	return idx

func _build_skeleton() -> void:
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	add_child(skeleton)
	_add_bone("Root", "", Vector3.ZERO)
	_add_bone("Hips", "Root", Vector3(0, 0.48, 0))
	_add_bone("Spine", "Hips", Vector3(0, 0.14, 0))
	_add_bone("Chest", "Spine", Vector3(0, 0.15, 0))
	_add_bone("Head", "Chest", Vector3(0, 0.25, 0))
	_add_bone("ShoulderL", "Chest", Vector3(-0.13, 0.13, 0))
	_add_bone("UpperArmL", "ShoulderL", Vector3(-0.09, 0, 0))
	_add_bone("LowerArmL", "UpperArmL", Vector3(0, -0.16, 0))
	_add_bone("HandL", "LowerArmL", Vector3(0, -0.14, 0))
	_add_bone("ShoulderR", "Chest", Vector3(0.13, 0.13, 0))
	_add_bone("UpperArmR", "ShoulderR", Vector3(0.09, 0, 0))
	_add_bone("LowerArmR", "UpperArmR", Vector3(0, -0.16, 0))
	_add_bone("HandR", "LowerArmR", Vector3(0, -0.14, 0))
	_add_bone("UpperLegL", "Hips", Vector3(-0.08, -0.05, 0))
	_add_bone("LowerLegL", "UpperLegL", Vector3(0, -0.23, 0))
	_add_bone("FootL", "LowerLegL", Vector3(0, -0.21, 0))
	_add_bone("UpperLegR", "Hips", Vector3(0.08, -0.05, 0))
	_add_bone("LowerLegR", "UpperLegR", Vector3(0, -0.23, 0))
	_add_bone("FootR", "LowerLegR", Vector3(0, -0.21, 0))
	skeleton.reset_bone_poses()

func _build_skin() -> void:
	skin = Skin.new()
	for i in range(skeleton.get_bone_count()):
		skin.add_bind(i, skeleton.get_bone_global_rest(i).affine_inverse())

func _build_body() -> void:
	# Stage 5: use Godot CSG only as a one-time manifold body generator.
	# Intersecting volumes are boolean-unioned first, then baked and skinned.
	var csg := CSGCombiner3D.new()
	csg.name = "BaseHumanCSG"
	add_child(csg)

	_add_csg_sphere(csg,Vector3(0,0.61,0),0.18,Vector3(1.0,1.25,0.62))
	_add_csg_sphere(csg,Vector3(0,0.43,0),0.15,Vector3(1.0,0.85,0.68))
	_add_csg_cylinder(csg,Vector3(0,0.82,0),0.075,0.20,16)
	_add_csg_sphere(csg,Vector3(0,0.99,0),0.145,Vector3(1.0,0.88,0.90))

	for side in [-1.0,1.0]:
		var sx: float = float(side)
		_add_csg_sphere(csg,Vector3(sx*0.155,0.76,0),0.085,Vector3(1.0,0.90,0.85))
		_add_csg_cylinder(csg,Vector3(sx*0.205,0.585,0),0.057,0.38,14)
		_add_csg_sphere(csg,Vector3(sx*0.205,0.385,0),0.055,Vector3(0.92,0.82,0.82))
		_add_csg_cylinder(csg,Vector3(sx*0.080,0.235,0),0.071,0.43,14)
		_add_csg_sphere(csg,Vector3(sx*0.080,0.055,0.035),0.072,Vector3(0.92,0.62,1.38))

	await get_tree().process_frame
	var baked: ArrayMesh = csg.bake_static_mesh()
	if baked.get_surface_count() == 0:
		push_error("Pachirou CSG body bake returned no surfaces.")
		return
	var skinned: ArrayMesh = _skin_baked_mesh(baked)
	var body := MeshInstance3D.new()
	body.name = "BaseHumanTopology"
	body.mesh = skinned
	body.skin = skin
	body.skeleton = NodePath("../Skeleton3D")
	body.material_override = _material(Color(0.84,0.64,0.50))
	add_child(body)
	csg.queue_free()

func _add_csg_sphere(parent: Node, pos: Vector3, radius: float, shape_scale: Vector3) -> void:
	var shape := CSGSphere3D.new()
	shape.radius = radius
	shape.radial_segments = 16
	shape.rings = 8
	shape.smooth_faces = true
	shape.position = pos
	shape.scale = shape_scale
	parent.add_child(shape)

func _add_csg_cylinder(parent: Node, pos: Vector3, radius: float, height: float, sides: int) -> void:
	var shape := CSGCylinder3D.new()
	shape.radius = radius
	shape.height = height
	shape.sides = sides
	shape.smooth_faces = true
	shape.position = pos
	parent.add_child(shape)

func _skin_baked_mesh(source: ArrayMesh) -> ArrayMesh:
	var result := ArrayMesh.new()
	for surface_index in range(source.get_surface_count()):
		var arrays: Array = source.surface_get_arrays(surface_index)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var raw_indices: Variant = arrays[Mesh.ARRAY_INDEX]
		var indices := PackedInt32Array()
		if raw_indices != null:
			indices = raw_indices as PackedInt32Array
		if indices.is_empty():
			indices.resize(vertices.size())
			for vertex_index in range(vertices.size()):
				indices[vertex_index] = vertex_index
		var refined: Array = _refine_joint_topology(vertices,normals,indices)
		vertices = refined[0]
		normals = refined[1]
		indices = refined[2]
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices
		var bone_array := PackedInt32Array()
		var weight_array := PackedFloat32Array()
		for vertex in vertices:
			var influence: Array = _body_weights(vertex)
			bone_array.append(int(influence[0]))
			bone_array.append(int(influence[1]))
			bone_array.append(0)
			bone_array.append(0)
			weight_array.append(float(influence[2]))
			weight_array.append(1.0-float(influence[2]))
			weight_array.append(0.0)
			weight_array.append(0.0)
		arrays[Mesh.ARRAY_BONES] = bone_array
		arrays[Mesh.ARRAY_WEIGHTS] = weight_array
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return result

func _refine_joint_topology(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array) -> Array:
	# Split long triangles crossing deformation bands. This adds real geometry
	# around shoulder/hip/elbow/knee instead of asking one large CSG triangle to bend.
	var out_v := PackedVector3Array()
	var out_n := PackedVector3Array()
	var out_i := PackedInt32Array()
	for i in range(0,indices.size(),3):
		var ia: int = indices[i]
		var ib: int = indices[i+1]
		var ic: int = indices[i+2]
		var a: Vector3 = vertices[ia]
		var b: Vector3 = vertices[ib]
		var d: Vector3 = vertices[ic]
		var na: Vector3 = normals[ia]
		var nb: Vector3 = normals[ib]
		var nd: Vector3 = normals[ic]
		if _needs_joint_split(a,b,d):
			var ab: Vector3 = (a+b)*0.5
			var bd: Vector3 = (b+d)*0.5
			var da: Vector3 = (d+a)*0.5
			var nab: Vector3 = (na+nb).normalized()
			var nbd: Vector3 = (nb+nd).normalized()
			var nda: Vector3 = (nd+na).normalized()
			_append_triangle(out_v,out_n,out_i,a,na,ab,nab,da,nda)
			_append_triangle(out_v,out_n,out_i,ab,nab,b,nb,bd,nbd)
			_append_triangle(out_v,out_n,out_i,da,nda,bd,nbd,d,nd)
			_append_triangle(out_v,out_n,out_i,ab,nab,bd,nbd,da,nda)
		else:
			_append_triangle(out_v,out_n,out_i,a,na,b,nb,d,nd)
	return [out_v,out_n,out_i]

func _needs_joint_split(a: Vector3, b: Vector3, c: Vector3) -> bool:
	var center: Vector3 = (a+b+c)/3.0
	var max_edge: float = max(a.distance_to(b),max(b.distance_to(c),c.distance_to(a)))
	if max_edge < 0.055:
		return false
	var ax: float = abs(center.x)
	var shoulder_zone: bool = center.y > 0.67 and center.y < 0.80 and ax > 0.12
	var elbow_zone: bool = center.y > 0.48 and center.y < 0.60 and ax > 0.16
	var hip_zone: bool = center.y > 0.34 and center.y < 0.46 and ax < 0.16
	var knee_zone: bool = center.y > 0.17 and center.y < 0.29 and ax < 0.15
	return shoulder_zone or elbow_zone or hip_zone or knee_zone

func _append_triangle(v: PackedVector3Array, n: PackedVector3Array, idx: PackedInt32Array, a: Vector3, na: Vector3, b: Vector3, nb: Vector3, c: Vector3, nc: Vector3) -> void:
	var base: int = v.size()
	v.append(a)
	v.append(b)
	v.append(c)
	n.append(na)
	n.append(nb)
	n.append(nc)
	idx.append(base)
	idx.append(base+1)
	idx.append(base+2)

func _weight_pair(a: String, b: String, wa: float) -> Array:
	return [int(bones[a]),int(bones[b]),clamp(wa,0.0,1.0)]

func _body_weights(v: Vector3) -> Array:
	# Anatomical zones prevent unrelated nearby bones from stealing vertices.
	var side_left: bool = v.x < 0.0
	var upper_arm: String = "UpperArmL" if side_left else "UpperArmR"
	var lower_arm: String = "LowerArmL" if side_left else "LowerArmR"
	var hand: String = "HandL" if side_left else "HandR"
	var shoulder: String = "ShoulderL" if side_left else "ShoulderR"
	var upper_leg: String = "UpperLegL" if side_left else "UpperLegR"
	var lower_leg: String = "LowerLegL" if side_left else "LowerLegR"
	var foot: String = "FootL" if side_left else "FootR"
	var ax: float = abs(v.x)

	# Head and neck.
	if v.y >= 0.86:
		return _weight_pair("Head","Chest",0.96)
	if v.y >= 0.79 and ax < 0.105:
		var neck_t: float = inverse_lerp(0.79,0.86,v.y)
		return _weight_pair("Chest","Head",1.0-neck_t*0.72)

	# Arms: shoulder blend -> upper arm -> elbow blend -> forearm -> hand.
	if ax >= 0.145 and v.y >= 0.34:
		if v.y >= 0.70:
			var shoulder_t: float = clamp(inverse_lerp(0.145,0.235,ax),0.0,1.0)
			return _weight_pair("Chest",shoulder,1.0-shoulder_t*0.78)
		if v.y >= 0.57:
			return _weight_pair(upper_arm,shoulder,0.88)
		if v.y >= 0.49:
			var elbow_t: float = inverse_lerp(0.49,0.57,v.y)
			return _weight_pair(lower_arm,upper_arm,1.0-elbow_t)
		if v.y >= 0.40:
			return _weight_pair(lower_arm,hand,0.88)
		return _weight_pair(hand,lower_arm,0.94)

	# Pelvis and legs: each side stays on its own leg chain.
	if v.y <= 0.45:
		if v.y >= 0.36:
			var hip_t: float = clamp(inverse_lerp(0.035,0.135,ax),0.0,1.0)
			return _weight_pair("Hips",upper_leg,1.0-hip_t*0.72)
		if v.y >= 0.27:
			return _weight_pair(upper_leg,"Hips",0.90)
		if v.y >= 0.19:
			var knee_t: float = inverse_lerp(0.19,0.27,v.y)
			return _weight_pair(lower_leg,upper_leg,1.0-knee_t)
		if v.y >= 0.075:
			return _weight_pair(lower_leg,foot,0.90)
		return _weight_pair(foot,lower_leg,0.97)

	# Torso vertical gradient.
	if v.y >= 0.70:
		return _weight_pair("Chest","Spine",0.90)
	if v.y >= 0.58:
		var chest_t: float = inverse_lerp(0.58,0.70,v.y)
		return _weight_pair("Spine","Chest",1.0-chest_t)
	if v.y >= 0.49:
		return _weight_pair("Spine","Hips",0.82)
	var hips_t: float = inverse_lerp(0.45,0.49,v.y)
	return _weight_pair("Hips","Spine",1.0-hips_t*0.45)

func _build_environment() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-35,0)
	light.light_energy = 1.05
	light.shadow_enabled = true
	add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-42,135,0)
	fill.light_energy = 0.32
	add_child(fill)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.45
	camera.position = Vector3(1.85,2.10,1.85)
	camera.rotation_degrees = Vector3(-35.264,45,0)
	camera.current = true
	add_child(camera)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(3,3)
	floor.mesh = plane
	floor.material_override = _material(Color(0.72,0.76,0.82))
	add_child(floor)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	return mat
