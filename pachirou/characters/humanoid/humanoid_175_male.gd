extends Node3D
class_name Humanoid175Male

const HEIGHT_M: float = 1.75
const JOINT_RADIUS: float = 0.018
const BONE_RADIUS: float = 0.010

var skeleton: Skeleton3D
var profile: SkeletonProfileHumanoid
var debug_material: StandardMaterial3D

func _ready() -> void:
	_build_from_godot_humanoid_profile()
	_build_debug_skeleton()

func _build_from_godot_humanoid_profile() -> void:
	profile = SkeletonProfileHumanoid.new()
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	add_child(skeleton)

	# Build the exact hierarchy/names/reference rests defined by Godot's
	# SkeletonProfileHumanoid instead of maintaining a hand-authored rig.
	for profile_index in range(profile.get_bone_size()):
		var bone_name: StringName = profile.get_bone_name(profile_index)
		skeleton.add_bone(String(bone_name))

	for profile_index in range(profile.get_bone_size()):
		var bone_name: StringName = profile.get_bone_name(profile_index)
		var parent_name: StringName = profile.get_bone_parent(profile_index)
		var bone_index: int = skeleton.find_bone(String(bone_name))
		var parent_index: int = -1
		if not parent_name.is_empty():
			parent_index = skeleton.find_bone(String(parent_name))
		skeleton.set_bone_parent(bone_index,parent_index)
		skeleton.set_bone_rest(bone_index,profile.get_reference_pose(profile_index))

	# SkeletonProfileHumanoid is a normalized reference rig. Scale the whole
	# reference skeleton so its measured vertical extent is exactly 1.75 m.
	_scale_rest_pose_to_height(HEIGHT_M)

func _scale_rest_pose_to_height(target_height: float) -> void:
	var min_y: float = INF
	var max_y: float = -INF
	for bone_index in range(skeleton.get_bone_count()):
		var y_value: float = skeleton.get_bone_global_rest(bone_index).origin.y
		min_y = minf(min_y,y_value)
		max_y = maxf(max_y,y_value)
	var source_height: float = max_y-min_y
	if source_height <= 0.001:
		return
	var factor: float = target_height/source_height
	for bone_index in range(skeleton.get_bone_count()):
		var rest: Transform3D = skeleton.get_bone_rest(bone_index)
		rest.origin *= factor
		skeleton.set_bone_rest(bone_index,rest)

	# Put the lowest reference joint on the floor without adding a transform
	# to Skeleton3D itself. Root is the profile's global translation bone.
	var scaled_min_y: float = INF
	for bone_index in range(skeleton.get_bone_count()):
		scaled_min_y = minf(scaled_min_y,skeleton.get_bone_global_rest(bone_index).origin.y)
	var root_index: int = skeleton.find_bone(String(profile.get_root_bone()))
	if root_index >= 0:
		var root_rest: Transform3D = skeleton.get_bone_rest(root_index)
		root_rest.origin.y -= scaled_min_y
		skeleton.set_bone_rest(root_index,root_rest)

func _build_debug_skeleton() -> void:
	debug_material = StandardMaterial3D.new()
	debug_material.albedo_color = Color(0.92,0.92,0.95,1.0)
	debug_material.roughness = 0.7
	var debug_root := Node3D.new()
	debug_root.name = "BoneDebug"
	add_child(debug_root)

	for bone_index in range(skeleton.get_bone_count()):
		var joint_position: Vector3 = skeleton.get_bone_global_rest(bone_index).origin
		_add_joint(debug_root,joint_position)
		var parent_index: int = skeleton.get_bone_parent(bone_index)
		if parent_index >= 0:
			var parent_position: Vector3 = skeleton.get_bone_global_rest(parent_index).origin
			_add_bone_segment(debug_root,parent_position,joint_position)

func _add_joint(parent: Node3D,position_value: Vector3) -> void:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = JOINT_RADIUS
	sphere.height = JOINT_RADIUS*2.0
	sphere.material = debug_material
	mesh_instance.mesh = sphere
	mesh_instance.position = position_value
	parent.add_child(mesh_instance)

func _add_bone_segment(parent: Node3D,start: Vector3,end: Vector3) -> void:
	var delta: Vector3 = end-start
	var length: float = delta.length()
	if length <= 0.001:
		return
	var mesh_instance := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = BONE_RADIUS
	cylinder.bottom_radius = BONE_RADIUS
	cylinder.height = length
	cylinder.material = debug_material
	mesh_instance.mesh = cylinder
	mesh_instance.position = (start+end)*0.5
	mesh_instance.quaternion = Quaternion(Vector3.UP,delta.normalized())
	parent.add_child(mesh_instance)
