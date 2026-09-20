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
	var swing := sin(t * 4.0) * deg_to_rad(18.0)
	skeleton.set_bone_pose_rotation(1, Quaternion(Vector3.RIGHT, swing))
	skeleton.set_bone_pose_rotation(2, Quaternion(Vector3.RIGHT, -swing))
	skeleton.set_bone_pose_rotation(3, Quaternion(Vector3.RIGHT, -swing))
	skeleton.set_bone_pose_rotation(4, Quaternion(Vector3.RIGHT, swing))
	visual_root.position.y = abs(sin(t * 4.0)) * 0.008

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
	skeleton.set_bone_rest(arm_l, Transform3D(Basis.IDENTITY, Vector3(-0.205, 0.17, 0)))
	skeleton.set_bone_rest(arm_r, Transform3D(Basis.IDENTITY, Vector3(0.205, 0.17, 0)))
	skeleton.set_bone_rest(leg_l, Transform3D(Basis.IDENTITY, Vector3(-0.100, -0.15, 0)))
	skeleton.set_bone_rest(leg_r, Transform3D(Basis.IDENTITY, Vector3(0.100, -0.15, 0)))
	skeleton.reset_bone_poses()

	# Character Base 01 v2: fixed 3.7-head stylized human.
	# Stable authored primitives replace the experimental loft topology.
	_add_ellipsoid("Head", Vector3(0, 0.985, 0), Vector3(0.158, 0.172, 0.148), Color(0.84, 0.64, 0.50))
	_add_ellipsoid("Neck", Vector3(0, 0.835, -0.005), Vector3(0.060, 0.065, 0.058), Color(0.84, 0.64, 0.50))
	_add_collar()
	_add_hair_v2()
	_add_face_v2()
	_add_fixed_part("ShirtBody", Vector3(0, 0.665, 0), _shirt_mesh(), Color(0.96, 0.96, 0.94))
	_add_ellipsoid("ShoulderL", Vector3(-0.158, 0.748, 0), Vector3(0.064, 0.082, 0.092), Color(0.96, 0.96, 0.94))
	_add_ellipsoid("ShoulderR", Vector3(0.158, 0.748, 0), Vector3(0.064, 0.082, 0.092), Color(0.96, 0.96, 0.94))
	_add_fixed_part("PantsHip", Vector3(0, 0.455, 0), _pants_hip_mesh(), Color(0.10, 0.13, 0.18))
	_add_arm("ArmLMesh", arm_l)
	_add_arm("ArmRMesh", arm_r)
	_add_sleeve("SleeveL", arm_l, Vector3(0, -0.055, 0))
	_add_sleeve("SleeveR", arm_r, Vector3(0, -0.055, 0))
	_add_hand("HandL", arm_l, Vector3(0, -0.320, 0))
	_add_hand("HandR", arm_r, Vector3(0, -0.320, 0))
	_add_trouser_leg("TrouserLegL", leg_l)
	_add_trouser_leg("TrouserLegR", leg_r)
	_add_shoe_to_bone("ShoeL", leg_l, Vector3(0, -0.365, 0.045))
	_add_shoe_to_bone("ShoeR", leg_r, Vector3(0, -0.365, 0.045))

func _add_fixed_part(label: String, center: Vector3, mesh: ArrayMesh, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	mesh_instance.position = center
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color)
	visual_root.add_child(mesh_instance)

func _shirt_mesh() -> ArrayMesh:
	# Fixed convex T-shirt torso: narrower waist/hem, broader chest.
	return _fixed_ring_mesh([
		Vector3(0.155, 0.215, 0.105),
		Vector3(0.190, 0.145, 0.125),
		Vector3(0.178, 0.020, 0.124),
		Vector3(0.164, -0.190, 0.114),
		Vector3(0.168, -0.220, 0.116)
	], 12)

func _pants_hip_mesh() -> ArrayMesh:
	# Compact pelvis volume with a flatter waist and tapered lower edge.
	return _fixed_ring_mesh([
		Vector3(0.142, 0.095, 0.102),
		Vector3(0.145, 0.035, 0.108),
		Vector3(0.122, -0.075, 0.094),
		Vector3(0.094, -0.105, 0.082)
	], 12)

func _fixed_ring_mesh(rings: Array[Vector3], radial_segments: int) -> ArrayMesh:
	# Vector3 = x radius, local y, z radius. Fixed topology, no silhouette sweep.
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for ring_data in rings:
		for s in range(radial_segments):
			var angle: float = TAU * float(s) / float(radial_segments)
			var ca: float = cos(angle)
			var sa: float = sin(angle)
			vertices.append(Vector3(ca * ring_data.x, ring_data.y, sa * ring_data.z))
			normals.append(Vector3(ca / ring_data.x, 0.0, sa / ring_data.z).normalized())
	for r in range(rings.size() - 1):
		for s in range(radial_segments):
			var n: int = (s + 1) % radial_segments
			var a: int = r * radial_segments + s
			var b: int = r * radial_segments + n
			var c0: int = (r + 1) * radial_segments + s
			var d: int = (r + 1) * radial_segments + n
			indices.append_array(PackedInt32Array([a, c0, b, b, c0, d]))
	# Close top and bottom with center fans.
	var top_center: int = vertices.size()
	vertices.append(Vector3(0, rings[0].y, 0))
	normals.append(Vector3.UP)
	var bottom_center: int = vertices.size()
	vertices.append(Vector3(0, rings[rings.size() - 1].y, 0))
	normals.append(Vector3.DOWN)
	for s in range(radial_segments):
		var n: int = (s + 1) % radial_segments
		indices.append_array(PackedInt32Array([top_center, s, n]))
		var last: int = (rings.size() - 1) * radial_segments
		indices.append_array(PackedInt32Array([bottom_center, last + n, last + s]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _add_loft_part(label: String, center: Vector3, silhouette: Array[Vector3], color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	mesh_instance.position = center
	mesh_instance.mesh = _loft_mesh(silhouette, 10)
	mesh_instance.material_override = _material(color)
	visual_root.add_child(mesh_instance)

func _loft_mesh(silhouette: Array[Vector3], depth_segments: int) -> ArrayMesh:
	# Rounded closed volume. The previous sweep used a single strip across a
	# closed 2D silhouette, which still folded across the face/body.
	# Instead create front/back copies and bevel them through intermediate depth.
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var rows: int = silhouette.size()
	var layers: int = depth_segments + 1
	for d in range(layers):
		var t: float = float(d) / float(depth_segments)
		var angle: float = -PI * 0.5 + PI * t
		var z_factor: float = sin(angle)
		var edge_factor: float = 0.88 + 0.12 * abs(z_factor)
		for s in silhouette:
			vertices.append(Vector3(s.x * edge_factor, s.y, s.z * z_factor))
	# Connect each depth layer around the CLOSED silhouette perimeter.
	for d in range(depth_segments):
		for i in range(rows):
			var j: int = (i + 1) % rows
			var a: int = d * rows + i
			var b: int = d * rows + j
			var c0: int = (d + 1) * rows + i
			var d0: int = (d + 1) * rows + j
			indices.append_array(PackedInt32Array([a, c0, b, b, c0, d0]))
	# Cap front and back using center vertices and perimeter fans.
	var back_center: int = vertices.size()
	vertices.append(Vector3.ZERO)
	var front_center: int = vertices.size()
	vertices.append(Vector3.ZERO)
	for i in range(rows):
		var j: int = (i + 1) % rows
		indices.append_array(PackedInt32Array([back_center, j, i]))
		var fi: int = depth_segments * rows + i
		var fj: int = depth_segments * rows + j
		indices.append_array(PackedInt32Array([front_center, fi, fj]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _add_section_part(label: String, center: Vector3, sections: Array[Vector3], color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	mesh_instance.position = center
	mesh_instance.mesh = _section_mesh(sections)
	mesh_instance.material_override = _material(color)
	visual_root.add_child(mesh_instance)

func _section_mesh(sections: Array[Vector3]) -> ArrayMesh:
	# Each Vector3 stores x silhouette, y height and z half-depth.
	# Front/back surfaces no longer share one constant depth.
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var count: int = sections.size()
	for s in sections:
		vertices.append(Vector3(s.x, s.y, s.z))
	for s in sections:
		vertices.append(Vector3(s.x, s.y, -s.z))
	for i in range(1, count - 1):
		indices.append_array(PackedInt32Array([0, i, i + 1]))
		indices.append_array(PackedInt32Array([count, count + i + 1, count + i]))
	for i in range(count):
		var j: int = (i + 1) % count
		indices.append_array(PackedInt32Array([i, count + i, j, j, count + i, count + j]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _add_profile_part(label: String, center: Vector3, profile: Array[Vector2], depth: float, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	mesh_instance.position = center
	mesh_instance.mesh = _extruded_profile_mesh(profile, depth)
	mesh_instance.material_override = _material(color)
	visual_root.add_child(mesh_instance)

func _extruded_profile_mesh(profile: Array[Vector2], depth: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var half_depth := depth * 0.5
	var count := profile.size()
	# Front and back vertices.
	for p in profile:
		vertices.append(Vector3(p.x, p.y, half_depth))
	for p in profile:
		vertices.append(Vector3(p.x, p.y, -half_depth))
	# Convex profile fan faces.
	for i in range(1, count - 1):
		indices.append_array(PackedInt32Array([0, i, i + 1]))
		indices.append_array(PackedInt32Array([count, count + i + 1, count + i]))
	# Side wall.
	for i in range(count):
		var j := (i + 1) % count
		indices.append_array(PackedInt32Array([i, count + i, j, j, count + i, count + j]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _add_arm(label: String, bone_idx: int) -> void:
	var attachment := BoneAttachment3D.new()
	attachment.name = label + "Attachment"
	attachment.bone_name = skeleton.get_bone_name(bone_idx)
	skeleton.add_child(attachment)
	var arm := MeshInstance3D.new()
	arm.name = label
	arm.position = Vector3(0, -0.185, 0)
	arm.mesh = _fixed_ring_mesh([
		Vector3(0.052, 0.145, 0.050),
		Vector3(0.050, 0.075, 0.048),
		Vector3(0.045, 0.005, 0.044),
		Vector3(0.042, -0.070, 0.041),
		Vector3(0.038, -0.145, 0.038)
	], 10)
	arm.material_override = _material(Color(0.84, 0.64, 0.50))
	attachment.add_child(arm)

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

func _add_hair_v2() -> void:
	var hair_color := Color(0.16, 0.10, 0.07)
	# Main cap follows the skull; smaller pieces define a short-hair outline.
	_add_ellipsoid("HairCrown", Vector3(0, 1.096, -0.020), Vector3(0.158, 0.088, 0.148), hair_color)
	_add_ellipsoid("HairBack", Vector3(0, 1.038, -0.120), Vector3(0.137, 0.084, 0.046), hair_color)
	_add_ellipsoid("TempleL", Vector3(-0.137, 1.045, -0.005), Vector3(0.030, 0.060, 0.078), hair_color)
	_add_ellipsoid("TempleR", Vector3(0.137, 1.045, -0.005), Vector3(0.030, 0.060, 0.078), hair_color)
	_add_ellipsoid("FringeL", Vector3(-0.050, 1.058, 0.130), Vector3(0.060, 0.023, 0.018), hair_color)
	_add_ellipsoid("FringeR", Vector3(0.055, 1.064, 0.130), Vector3(0.064, 0.021, 0.018), hair_color)

func _add_collar() -> void:
	var collar := MeshInstance3D.new()
	collar.name = "CrewNeck"
	collar.position = Vector3(0, 0.825, 0.052)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.052
	torus.outer_radius = 0.068
	torus.rings = 12
	torus.ring_segments = 8
	collar.mesh = torus
	collar.scale = Vector3(1.0, 0.55, 0.72)
	collar.material_override = _material(Color(0.82, 0.82, 0.80))
	visual_root.add_child(collar)

func _add_face_v2() -> void:
	for x in [-0.057, 0.057]:
		var eye := MeshInstance3D.new()
		eye.name = "EyeL" if x < 0.0 else "EyeR"
		eye.position = Vector3(x, 0.995, 0.151)
		eye.mesh = _ellipsoid_mesh(Vector3(0.010, 0.013, 0.007), 10, 6)
		eye.material_override = _material(Color(0.025, 0.025, 0.025))
		visual_root.add_child(eye)

func _add_sleeve(label: String, bone_idx: int, local_center: Vector3) -> void:
	var attachment := BoneAttachment3D.new()
	attachment.name = label + "Attachment"
	attachment.bone_name = skeleton.get_bone_name(bone_idx)
	skeleton.add_child(attachment)
	var sleeve := MeshInstance3D.new()
	sleeve.name = label
	sleeve.position = local_center
	sleeve.mesh = _ellipsoid_mesh(Vector3(0.061, 0.092, 0.060), 10, 6)
	sleeve.material_override = _material(Color(0.96, 0.96, 0.94))
	attachment.add_child(sleeve)

func _add_hair() -> void:
	_add_loft_part("Hair", Vector3(0, 1.055, -0.018), [
		Vector3(-0.19, 0.075, 0.14), Vector3(-0.15, 0.13, 0.175),
		Vector3(-0.06, 0.16, 0.205), Vector3(0.05, 0.158, 0.215),
		Vector3(0.15, 0.115, 0.205), Vector3(0.205, 0.035, 0.18),
		Vector3(0.19, -0.045, 0.155), Vector3(0.09, -0.075, 0.135),
		Vector3(-0.07, -0.07, 0.14), Vector3(-0.18, -0.025, 0.145)
	], Color(0.16, 0.10, 0.07))

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
	hand.mesh = _ellipsoid_mesh(Vector3(0.058, 0.065, 0.052), 10, 6)
	hand.material_override = _material(Color(0.84, 0.64, 0.50))
	attachment.add_child(hand)
	var thumb := MeshInstance3D.new()
	thumb.name = label + "Thumb"
	var thumb_x: float = 0.044 if label.ends_with("L") else -0.044
	thumb.position = local_center + Vector3(thumb_x, 0.004, 0.010)
	var thumb_angle: float = -28.0 if label.ends_with("L") else 28.0
	thumb.rotation_degrees = Vector3(0, 0, thumb_angle)
	thumb.mesh = _ellipsoid_mesh(Vector3(0.021, 0.034, 0.020), 8, 5)
	thumb.material_override = _material(Color(0.84, 0.64, 0.50))
	attachment.add_child(thumb)

func _add_trouser_leg(label: String, bone_idx: int) -> void:
	var attachment := BoneAttachment3D.new()
	attachment.name = label + "Attachment"
	attachment.bone_name = skeleton.get_bone_name(bone_idx)
	skeleton.add_child(attachment)
	var trouser := MeshInstance3D.new()
	trouser.name = label
	trouser.position = Vector3(0, -0.165, 0)
	trouser.mesh = _fixed_ring_mesh([
		Vector3(0.078, 0.165, 0.075),
		Vector3(0.073, 0.080, 0.070),
		Vector3(0.066, -0.025, 0.064),
		Vector3(0.058, -0.165, 0.058)
	], 10)
	trouser.material_override = _material(Color(0.10, 0.13, 0.18))
	attachment.add_child(trouser)

func _add_upper_leg(label: String, bone_idx: int) -> void:
	var attachment := BoneAttachment3D.new()
	attachment.name = label + "Attachment"
	attachment.bone_name = skeleton.get_bone_name(bone_idx)
	skeleton.add_child(attachment)
	var upper_leg := MeshInstance3D.new()
	upper_leg.name = label
	upper_leg.position = Vector3(0, -0.055, 0)
	upper_leg.mesh = _ellipsoid_mesh(Vector3(0.070, 0.095, 0.068), 10, 6)
	upper_leg.material_override = _material(Color(0.10, 0.13, 0.18))
	attachment.add_child(upper_leg)

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
	return _fixed_ring_mesh([
		Vector3(0.060, 0.038, 0.092),
		Vector3(0.069, 0.018, 0.112),
		Vector3(0.066, -0.018, 0.118),
		Vector3(0.058, -0.038, 0.105)
	], 12)

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
