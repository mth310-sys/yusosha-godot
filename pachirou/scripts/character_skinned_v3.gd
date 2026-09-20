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
		var bone_array := PackedInt32Array()
		var weight_array := PackedFloat32Array()
		for vertex in vertices:
			var pair: Array = _nearest_bones(vertex)
			bone_array.append(int(pair[0]))
			bone_array.append(int(pair[1]))
			bone_array.append(0)
			bone_array.append(0)
			weight_array.append(float(pair[2]))
			weight_array.append(1.0-float(pair[2]))
			weight_array.append(0.0)
			weight_array.append(0.0)
		arrays[Mesh.ARRAY_BONES] = bone_array
		arrays[Mesh.ARRAY_WEIGHTS] = weight_array
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return result

func _nearest_bones(vertex: Vector3) -> Array:
	var candidates: Array[String] = [
		"Hips","Spine","Chest","Head",
		"ShoulderL","UpperArmL","LowerArmL","HandL",
		"ShoulderR","UpperArmR","LowerArmR","HandR",
		"UpperLegL","LowerLegL","FootL",
		"UpperLegR","LowerLegR","FootR"
	]
	var first_name: String = "Hips"
	var second_name: String = "Spine"
	var first_dist: float = INF
	var second_dist: float = INF
	for name in candidates:
		var d: float = vertex.distance_squared_to(skeleton.get_bone_global_rest(int(bones[name])).origin)
		if d < first_dist:
			second_dist = first_dist
			second_name = first_name
			first_dist = d
			first_name = name
		elif d < second_dist:
			second_dist = d
			second_name = name
	var total: float = max(0.000001,first_dist+second_dist)
	var first_weight: float = clamp(second_dist/total,0.55,0.95)
	return [int(bones[first_name]),int(bones[second_name]),first_weight]

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
