extends Node3D

@export var build_validation_environment: bool = true

# Standalone Godot-only character pipeline validation.
# Uses ArrayMesh for authored geometry and Skeleton3D bone poses for animation.

var skeleton: Skeleton3D
var visual_root: Node3D
var forearm_l_idx: int = -1
var forearm_r_idx: int = -1
var shin_l_idx: int = -1
var shin_r_idx: int = -1
var foot_l_idx: int = -1
var foot_r_idx: int = -1
var t := 0.0

func _ready() -> void:
	if build_validation_environment:
		_build_environment()
	_build_character()

func _process(delta: float) -> void:
	t += delta
	if skeleton == null:
		return
	# Four-phase indoor walk: contact -> push-off -> swing -> landing.
	var cycle: float = fmod(t * 0.64, 1.0)
	var left_phase: float = cycle
	var right_phase: float = fmod(cycle + 0.5, 1.0)
	_apply_walk_side(1, forearm_l_idx, 3, shin_l_idx, foot_l_idx, left_phase)
	_apply_walk_side(2, forearm_r_idx, 4, shin_r_idx, foot_r_idx, right_phase)
	# Whole-body motion stays intentionally small for an indoor NPC.
	var step_wave: float = sin(cycle * TAU)
	var double_step: float = sin(cycle * TAU * 2.0)
	visual_root.position.y = double_step * 0.0025 + 0.0025
	visual_root.position.x = step_wave * 0.004
	visual_root.rotation.z = step_wave * deg_to_rad(0.8)
	visual_root.rotation.y = -step_wave * deg_to_rad(1.2)

func _apply_walk_side(arm_idx: int, forearm_idx: int, thigh_idx: int, shin_idx: int, foot_idx: int, phase: float) -> void:
	var thigh_angle: float
	var knee_angle: float
	var foot_angle: float
	var arm_angle: float
	var elbow_angle: float
	if phase < 0.25:
		# Contact: foot stays nearly level while the body passes over it.
		var u: float = phase / 0.25
		thigh_angle = lerpf(deg_to_rad(15.0), deg_to_rad(-5.0), u)
		knee_angle = lerpf(deg_to_rad(4.0), deg_to_rad(8.0), u)
		foot_angle = lerpf(deg_to_rad(-2.0), deg_to_rad(1.0), u)
	elif phase < 0.50:
		# Push-off: leg moves behind and heel begins to release.
		var u: float = (phase - 0.25) / 0.25
		thigh_angle = lerpf(deg_to_rad(-5.0), deg_to_rad(-16.0), u)
		knee_angle = lerpf(deg_to_rad(8.0), deg_to_rad(24.0), u)
		foot_angle = lerpf(deg_to_rad(1.0), deg_to_rad(8.0), u)
	elif phase < 0.75:
		# Swing: knee bends, foot clears the floor.
		var u: float = (phase - 0.50) / 0.25
		thigh_angle = lerpf(deg_to_rad(-16.0), deg_to_rad(11.0), u)
		knee_angle = lerpf(deg_to_rad(24.0), deg_to_rad(17.0), u)
		foot_angle = lerpf(deg_to_rad(8.0), deg_to_rad(-5.0), u)
	else:
		# Landing: extend the leg and flatten the sole before contact.
		var u: float = (phase - 0.75) / 0.25
		thigh_angle = lerpf(deg_to_rad(11.0), deg_to_rad(15.0), u)
		knee_angle = lerpf(deg_to_rad(17.0), deg_to_rad(4.0), u)
		foot_angle = lerpf(deg_to_rad(-5.0), deg_to_rad(-2.0), u)
	arm_angle = -thigh_angle * 1.02
	elbow_angle = deg_to_rad(15.0) + abs(arm_angle) * 0.34
	skeleton.set_bone_pose_rotation(arm_idx, Quaternion(Vector3.RIGHT, arm_angle))
	skeleton.set_bone_pose_rotation(forearm_idx, Quaternion(Vector3.RIGHT, -elbow_angle))
	skeleton.set_bone_pose_rotation(thigh_idx, Quaternion(Vector3.RIGHT, thigh_angle))
	skeleton.set_bone_pose_rotation(shin_idx, Quaternion(Vector3.RIGHT, knee_angle))
	skeleton.set_bone_pose_rotation(foot_idx, Quaternion(Vector3.RIGHT, foot_angle))

func _build_environment() -> void:
	# Match Pachirou hall presentation so character proportions are judged
	# under the same orthographic camera and lighting conditions.
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.shadow_enabled = true
	light.light_energy = 1.05
	add_child(light)

	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-42, 135, 0)
	fill_light.light_energy = 0.32
	fill_light.shadow_enabled = false
	add_child(fill_light)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.6
	camera.position = Vector3(1.85, 2.10, 1.85)
	camera.rotation_degrees = Vector3(-35.264, 45, 0)
	camera.current = true
	add_child(camera)

	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(4, 4)
	floor.mesh = floor_mesh
	floor.material_override = _material(Color(0.72, 0.76, 0.82))
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
	forearm_l_idx = skeleton.add_bone("ForearmL")
	forearm_r_idx = skeleton.add_bone("ForearmR")
	shin_l_idx = skeleton.add_bone("ShinL")
	shin_r_idx = skeleton.add_bone("ShinR")
	foot_l_idx = skeleton.add_bone("FootL")
	foot_r_idx = skeleton.add_bone("FootR")
	skeleton.set_bone_parent(arm_l, root)
	skeleton.set_bone_parent(arm_r, root)
	skeleton.set_bone_parent(leg_l, root)
	skeleton.set_bone_parent(leg_r, root)
	skeleton.set_bone_parent(forearm_l_idx, arm_l)
	skeleton.set_bone_parent(forearm_r_idx, arm_r)
	skeleton.set_bone_parent(shin_l_idx, leg_l)
	skeleton.set_bone_parent(shin_r_idx, leg_r)
	skeleton.set_bone_parent(foot_l_idx, shin_l_idx)
	skeleton.set_bone_parent(foot_r_idx, shin_r_idx)
	# BoneAttachment3D follows the bone GLOBAL pose. Child bones therefore use
	# local offsets from Root, while Root carries the character's body height.
	skeleton.set_bone_rest(root, Transform3D(Basis.IDENTITY, Vector3(0, 0.58, 0)))
	skeleton.set_bone_rest(arm_l, Transform3D(Basis.IDENTITY, Vector3(-0.226, 0.136, 0)))
	skeleton.set_bone_rest(arm_r, Transform3D(Basis.IDENTITY, Vector3(0.226, 0.136, 0)))
	skeleton.set_bone_rest(leg_l, Transform3D(Basis.IDENTITY, Vector3(-0.112, -0.15, 0)))
	skeleton.set_bone_rest(leg_r, Transform3D(Basis.IDENTITY, Vector3(0.112, -0.15, 0)))
	skeleton.set_bone_rest(forearm_l_idx, Transform3D(Basis.IDENTITY, Vector3(0, -0.17, 0)))
	skeleton.set_bone_rest(forearm_r_idx, Transform3D(Basis.IDENTITY, Vector3(0, -0.17, 0)))
	skeleton.set_bone_rest(shin_l_idx, Transform3D(Basis.IDENTITY, Vector3(0, -0.18, 0)))
	skeleton.set_bone_rest(shin_r_idx, Transform3D(Basis.IDENTITY, Vector3(0, -0.18, 0)))
	skeleton.set_bone_rest(foot_l_idx, Transform3D(Basis.IDENTITY, Vector3(0, -0.17, 0.045)))
	skeleton.set_bone_rest(foot_r_idx, Transform3D(Basis.IDENTITY, Vector3(0, -0.17, 0.045)))
	skeleton.reset_bone_poses()

	# Character Base 01 v2: fixed 3.7-head stylized human.
	# Stable authored primitives replace the experimental loft topology.
	_add_ellipsoid("Head", Vector3(0, 0.985, 0), Vector3(0.158, 0.172, 0.148), Color(0.84, 0.64, 0.50))
	_add_ellipsoid("Neck", Vector3(0, 0.835, -0.005), Vector3(0.060, 0.065, 0.058), Color(0.84, 0.64, 0.50))
	_add_collar()
	_add_hair_v2()
	_add_face_v2()
	_add_fixed_part("ShirtBody", Vector3(0, 0.665, 0), _shirt_mesh(), Color(0.96, 0.96, 0.94))
	_add_fixed_part("PantsHip", Vector3(0, 0.455, 0), _pants_hip_mesh(), Color(0.10, 0.13, 0.18))
	_add_upper_arm("UpperArmL", arm_l)
	_add_upper_arm("UpperArmR", arm_r)
	_add_forearm("ForearmLMesh", forearm_l_idx)
	_add_forearm("ForearmRMesh", forearm_r_idx)
	_add_hand("HandL", forearm_l_idx, Vector3(0, -0.155, 0))
	_add_hand("HandR", forearm_r_idx, Vector3(0, -0.155, 0))
	_add_thigh("ThighL", leg_l)
	_add_thigh("ThighR", leg_r)
	_add_shin("ShinLMesh", shin_l_idx)
	_add_shin("ShinRMesh", shin_r_idx)
	_add_shoe_to_bone("ShoeL", foot_l_idx, Vector3(0, -0.015, 0.050))
	_add_shoe_to_bone("ShoeR", foot_r_idx, Vector3(0, -0.015, 0.050))

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
		# Strong T silhouette: narrow neck, broad shoulder shelf, quick taper
		# at the armpits, then an almost vertical torso.
		Vector3(0.116, 0.225, 0.098),
		Vector3(0.190, 0.205, 0.110),
		Vector3(0.242, 0.172, 0.122),
		Vector3(0.246, 0.145, 0.126),
		Vector3(0.218, 0.105, 0.128),
		Vector3(0.184, 0.055, 0.126),
		Vector3(0.174, -0.050, 0.120),
		Vector3(0.166, -0.190, 0.114),
		Vector3(0.168, -0.220, 0.116)
	], 16)

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

func _add_bone_part(label: String, bone_idx: int, center: Vector3, mesh: ArrayMesh, color: Color) -> void:
	var attachment := BoneAttachment3D.new()
	attachment.name = label + "Attachment"
	attachment.bone_name = skeleton.get_bone_name(bone_idx)
	skeleton.add_child(attachment)
	var part := MeshInstance3D.new()
	part.name = label
	part.position = center
	part.mesh = mesh
	part.material_override = _material(color)
	attachment.add_child(part)

func _add_upper_arm(label: String, bone_idx: int) -> void:
	# One continuous arm silhouette: the upper section is shirt fabric and the
	# lower section is skin. No separate sleeve object or shoulder ring.
	_add_bone_part(label + "Sleeve", bone_idx, Vector3(0, -0.035, 0), _fixed_ring_mesh([
		# Wider top disappears beneath the shirt shoulder, then tapers to arm.
		Vector3(0.062, 0.045, 0.055),
		Vector3(0.054, 0.012, 0.050),
		Vector3(0.047, -0.045, 0.045)
	], 14), Color(0.96, 0.96, 0.94))
	_add_bone_part(label + "Skin", bone_idx, Vector3(0, -0.125, 0), _fixed_ring_mesh([
		Vector3(0.047, 0.045, 0.045),
		Vector3(0.045, 0.0, 0.044),
		Vector3(0.043, -0.045, 0.042)
	], 14), Color(0.84, 0.64, 0.50))

func _add_forearm(label: String, bone_idx: int) -> void:
	_add_bone_part(label, bone_idx, Vector3(0, -0.075, 0), _fixed_ring_mesh([
		Vector3(0.044, 0.070, 0.043), Vector3(0.041, 0.0, 0.040), Vector3(0.037, -0.070, 0.037)
	], 10), Color(0.84, 0.64, 0.50))

func _add_thigh(label: String, bone_idx: int) -> void:
	_add_bone_part(label, bone_idx, Vector3(0, -0.090, 0), _fixed_ring_mesh([
		Vector3(0.078, 0.085, 0.075), Vector3(0.073, 0.0, 0.070), Vector3(0.067, -0.085, 0.064)
	], 10), Color(0.10, 0.13, 0.18))

func _add_shin(label: String, bone_idx: int) -> void:
	_add_bone_part(label, bone_idx, Vector3(0, -0.085, 0), _fixed_ring_mesh([
		Vector3(0.066, 0.080, 0.063), Vector3(0.061, 0.0, 0.060), Vector3(0.056, -0.080, 0.056)
	], 10), Color(0.10, 0.13, 0.18))

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
	_add_ellipsoid("HairCrown", Vector3(0, 1.091, -0.014), Vector3(0.148, 0.080, 0.137), hair_color)
	_add_ellipsoid("HairBack", Vector3(0, 1.038, -0.112), Vector3(0.119, 0.073, 0.038), hair_color)
	_add_ellipsoid("TempleL", Vector3(-0.132, 1.044, -0.002), Vector3(0.025, 0.052, 0.066), hair_color)
	_add_ellipsoid("TempleR", Vector3(0.132, 1.044, -0.002), Vector3(0.025, 0.052, 0.066), hair_color)
	_add_ellipsoid("FringeL", Vector3(-0.064, 1.061, 0.126), Vector3(0.044, 0.026, 0.017), hair_color)
	_add_ellipsoid("FringeC", Vector3(-0.006, 1.052, 0.134), Vector3(0.038, 0.031, 0.016), hair_color)
	_add_ellipsoid("FringeR", Vector3(0.052, 1.066, 0.127), Vector3(0.041, 0.024, 0.017), hair_color)

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
	hand.mesh = _ellipsoid_mesh(Vector3(0.050, 0.058, 0.046), 10, 6)
	hand.material_override = _material(Color(0.84, 0.64, 0.50))
	attachment.add_child(hand)
	var thumb := MeshInstance3D.new()
	thumb.name = label + "Thumb"
	var thumb_x: float = 0.038 if label.ends_with("L") else -0.044
	thumb.position = local_center + Vector3(thumb_x, 0.004, 0.010)
	var thumb_angle: float = -28.0 if label.ends_with("L") else 28.0
	thumb.rotation_degrees = Vector3(0, 0, thumb_angle)
	thumb.mesh = _ellipsoid_mesh(Vector3(0.018, 0.029, 0.017), 8, 5)
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
		Vector3(0.056, 0.030, 0.086),
		Vector3(0.061, 0.014, 0.105),
		Vector3(0.060, -0.014, 0.110),
		Vector3(0.055, -0.030, 0.101)
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
