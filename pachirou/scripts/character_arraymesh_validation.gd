extends Node3D

# Standalone Godot-only character pipeline validation.
# Uses ArrayMesh for authored geometry and Skeleton3D bone poses for animation.

var skeleton: Skeleton3D
var visual_root: Node3D
var t := 0.0

func _ready() -> void:
	_build_environment()
	_build_character()

func _process(delta: float) -> void:
	t += delta
	if skeleton == null:
		return
	var swing := sin(t * 4.0) * deg_to_rad(24.0)
	skeleton.set_bone_pose_rotation(1, Quaternion(Vector3.RIGHT, swing))
	skeleton.set_bone_pose_rotation(2, Quaternion(Vector3.RIGHT, -swing))
	skeleton.set_bone_pose_rotation(3, Quaternion(Vector3.RIGHT, -swing))
	skeleton.set_bone_pose_rotation(4, Quaternion(Vector3.RIGHT, swing))
	visual_root.position.y = abs(sin(t * 4.0)) * 0.012

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.14, 0.17)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.92, 1.0)
	env.ambient_light_energy = 0.75
	world.environment = env
	add_child(world)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.shadow_enabled = true
	add_child(light)

	var camera := Camera3D.new()
	camera.position = Vector3(2.6, 1.9, 3.0)
	camera.look_at_from_position(camera.position, Vector3(0, 0.58, 0))
	add_child(camera)

	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(4, 4)
	floor.mesh = floor_mesh
	floor.material_override = _material(Color(0.26, 0.28, 0.31))
	add_child(floor)

func _build_character() -> void:
	visual_root = Node3D.new()
	visual_root.name = "ProceduralCharacter"
	add_child(visual_root)

	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	visual_root.add_child(skeleton)

	var root := skeleton.add_bone("Root")
	var arm_l: int = skeleton.add_bone("ArmL")
	var arm_r: int = skeleton.add_bone("ArmR")
	var leg_l: int = skeleton.add_bone("LegL")
	var leg_r: int = skeleton.add_bone("LegR")
	skeleton.set_bone_parent(arm_l, root)
	skeleton.set_bone_parent(arm_r, root)
	skeleton.set_bone_parent(leg_l, root)
	skeleton.set_bone_parent(leg_r, root)
	# BoneAttachment3D follows the bone GLOBAL pose. Child bones therefore use
	# local offsets from Root, while Root carries the character's body height.
	skeleton.set_bone_rest(root, Transform3D(Basis.IDENTITY, Vector3(0, 0.58, 0)))
	skeleton.set_bone_rest(arm_l, Transform3D(Basis.IDENTITY, Vector3(-0.255, 0.18, 0)))
	skeleton.set_bone_rest(arm_r, Transform3D(Basis.IDENTITY, Vector3(0.255, 0.18, 0)))
	skeleton.set_bone_rest(leg_l, Transform3D(Basis.IDENTITY, Vector3(-0.105, -0.19, 0)))
	skeleton.set_bone_rest(leg_r, Transform3D(Basis.IDENTITY, Vector3(0.105, -0.19, 0)))
	skeleton.reset_bone_poses()

	# Character Base 01: young male / about three heads tall.
	_add_ellipsoid("Head", Vector3(0, 0.945, 0), Vector3(0.225, 0.190, 0.205), Color(0.84, 0.64, 0.50))
	_add_hair()
	_add_face()
	# Shirt and pants are independent meshes so they can become replaceable modules.
	_add_ellipsoid("Shirt", Vector3(0, 0.615, 0), Vector3(0.205, 0.245, 0.135), Color(0.96, 0.96, 0.94))
	_add_ellipsoid("PantsHip", Vector3(0, 0.405, 0), Vector3(0.175, 0.105, 0.125), Color(0.10, 0.13, 0.18))
	_add_limb("ArmLMesh", arm_l, Vector3(0, -0.155, 0), 0.058, 0.31, Color(0.84, 0.64, 0.50))
	_add_limb("ArmRMesh", arm_r, Vector3(0, -0.155, 0), 0.058, 0.31, Color(0.84, 0.64, 0.50))
	_add_hand("HandL", arm_l, Vector3(0, -0.335, 0))
	_add_hand("HandR", arm_r, Vector3(0, -0.335, 0))
	_add_limb("LegLMesh", leg_l, Vector3(0, -0.155, 0), 0.073, 0.31, Color(0.10, 0.13, 0.18))
	_add_limb("LegRMesh", leg_r, Vector3(0, -0.155, 0), 0.073, 0.31, Color(0.10, 0.13, 0.18))
	_add_shoe_to_bone("ShoeL", leg_l, Vector3(0, -0.335, 0.055))
	_add_shoe_to_bone("ShoeR", leg_r, Vector3(0, -0.335, 0.055))

func _add_limb(label: String, bone_idx: int, local_center: Vector3, radius: float, height: float, color: Color) -> void:
	var attachment := BoneAttachment3D.new()
	attachment.name = label + "Attachment"
	attachment.bone_name = skeleton.get_bone_name(bone_idx)
	skeleton.add_child(attachment)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	mesh_instance.position = local_center
	mesh_instance.mesh = _ellipsoid_mesh(Vector3(radius, height * 0.5, radius), 10, 6)
	mesh_instance.material_override = _material(color)
	attachment.add_child(mesh_instance)

func _add_ellipsoid(label: String, center: Vector3, radii: Vector3, color: Color) -> void:
	var m := MeshInstance3D.new()
	m.name = label
	m.position = center
	m.mesh = _ellipsoid_mesh(radii, 16, 10)
	m.material_override = _material(color)
	visual_root.add_child(m)

func _add_hair() -> void:
	var m := MeshInstance3D.new()
	m.name = "Hair"
	m.position = Vector3(0, 1.018, -0.012)
	m.mesh = _ellipsoid_mesh(Vector3(0.229, 0.142, 0.209), 20, 10, 0.0, PI * 0.64)
	m.material_override = _material(Color(0.16, 0.10, 0.07))
	visual_root.add_child(m)

func _add_face() -> void:
	# Base face specification: tiny black dot eyes only.
	for x in [-0.072, 0.072]:
		var eye := MeshInstance3D.new()
		eye.name = "EyeL" if x < 0.0 else "EyeR"
		eye.position = Vector3(x, 0.965, 0.198)
		eye.mesh = _ellipsoid_mesh(Vector3(0.012, 0.015, 0.008), 10, 6)
		eye.material_override = _material(Color(0.025, 0.025, 0.025))
		visual_root.add_child(eye)

func _add_hand(label: String, bone_idx: int, local_center: Vector3) -> void:
	var attachment := BoneAttachment3D.new()
	attachment.name = label + "Attachment"
	attachment.bone_name = skeleton.get_bone_name(bone_idx)
	skeleton.add_child(attachment)
	var hand := MeshInstance3D.new()
	hand.name = label
	hand.position = local_center
	hand.mesh = _ellipsoid_mesh(Vector3(0.067, 0.073, 0.058), 10, 6)
	hand.material_override = _material(Color(0.84, 0.64, 0.50))
	attachment.add_child(hand)

func _add_shoe_to_bone(label: String, bone_idx: int, local_center: Vector3) -> void:
	var attachment := BoneAttachment3D.new()
	attachment.name = label + "Attachment"
	attachment.bone_name = skeleton.get_bone_name(bone_idx)
	skeleton.add_child(attachment)
	var m := MeshInstance3D.new()
	m.name = label
	m.position = local_center
	m.mesh = _rounded_shoe_mesh()
	m.material_override = _material(Color(0.97, 0.97, 0.95))
	attachment.add_child(m)

func _ellipsoid_mesh(radii: Vector3, radial: int, rings: int, phi_min: float = 0.0, phi_max: float = PI) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for y in range(rings + 1):
		var phi: float = lerpf(phi_min, phi_max, float(y) / float(rings))
		for x in range(radial + 1):
			var theta := TAU * float(x) / float(radial)
			var unit := Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta))
			vertices.append(Vector3(unit.x * radii.x, unit.y * radii.y, unit.z * radii.z))
			normals.append(Vector3(unit.x / radii.x, unit.y / radii.y, unit.z / radii.z).normalized())
	for y in range(rings):
		for x in range(radial):
			var a := y * (radial + 1) + x
			var b := a + radial + 1
			indices.append_array(PackedInt32Array([a, b, a + 1, a + 1, b, b + 1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _rounded_shoe_mesh() -> ArrayMesh:
	# Low-cut sneaker: scaled ellipsoid gives a softer silhouette than a box.
	return _ellipsoid_mesh(Vector3(0.082, 0.047, 0.125), 12, 6)

func _box_mesh(size: Vector3) -> ArrayMesh:
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var hz := size.z * 0.5
	var v := PackedVector3Array([
		Vector3(-hx,-hy,-hz), Vector3(hx,-hy,-hz), Vector3(hx,hy,-hz), Vector3(-hx,hy,-hz),
		Vector3(-hx,-hy,hz), Vector3(hx,-hy,hz), Vector3(hx,hy,hz), Vector3(-hx,hy,hz)
	])
	var idx := PackedInt32Array([
		0,2,1, 0,3,2, 4,5,6, 4,6,7,
		0,1,5, 0,5,4, 3,7,6, 3,6,2,
		1,2,6, 1,6,5, 0,4,7, 0,7,3
	])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	return mat
