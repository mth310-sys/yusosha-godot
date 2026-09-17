extends Node3D
class_name Humanoid175Male

const HEIGHT_M: float = 1.75
const JOINT_RADIUS: float = 0.018
const BONE_RADIUS: float = 0.010

var skeleton: Skeleton3D
var debug_material: StandardMaterial3D

func _ready() -> void:
	_build_clean_humanoid()
	_build_debug_skeleton()

func _build_clean_humanoid() -> void:
	# Clean rebuild. No previous generated/profile rest-pose data is reused.
	# Coordinates are absolute T-pose joint locations for a 1.75 m adult male.
	# They are converted to parent-local Skeleton3D rest transforms below.
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	add_child(skeleton)

	var points: Dictionary = {
		"Root": Vector3(0.0,0.0,0.0),
		"Hips": Vector3(0.0,0.94,0.0),
		"Spine": Vector3(0.0,1.08,0.0),
		"Chest": Vector3(0.0,1.25,0.0),
		"UpperChest": Vector3(0.0,1.39,0.0),
		"Neck": Vector3(0.0,1.51,0.0),
		"Head": Vector3(0.0,1.62,0.0),
		"HeadTop": Vector3(0.0,1.75,0.0),
		"LeftShoulder": Vector3(-0.18,1.46,0.0),
		"LeftUpperArm": Vector3(-0.24,1.44,0.0),
		"LeftLowerArm": Vector3(-0.54,1.44,0.0),
		"LeftHand": Vector3(-0.80,1.44,0.0),
		"LeftHandTip": Vector3(-0.98,1.44,0.0),
		"RightShoulder": Vector3(0.18,1.46,0.0),
		"RightUpperArm": Vector3(0.24,1.44,0.0),
		"RightLowerArm": Vector3(0.54,1.44,0.0),
		"RightHand": Vector3(0.80,1.44,0.0),
		"RightHandTip": Vector3(0.98,1.44,0.0),
		"LeftUpperLeg": Vector3(-0.09,0.91,0.0),
		"LeftLowerLeg": Vector3(-0.09,0.49,0.0),
		"LeftFoot": Vector3(-0.09,0.08,0.0),
		"LeftToes": Vector3(-0.09,0.04,0.18),
		"RightUpperLeg": Vector3(0.09,0.91,0.0),
		"RightLowerLeg": Vector3(0.09,0.49,0.0),
		"RightFoot": Vector3(0.09,0.08,0.0),
		"RightToes": Vector3(0.09,0.04,0.18)
	}

	_add_absolute_bone("Root","",points)
	_add_absolute_bone("Hips","Root",points)
	_add_absolute_bone("Spine","Hips",points)
	_add_absolute_bone("Chest","Spine",points)
	_add_absolute_bone("UpperChest","Chest",points)
	_add_absolute_bone("Neck","UpperChest",points)
	_add_absolute_bone("Head","Neck",points)
	_add_absolute_bone("HeadTop","Head",points)

	_add_absolute_bone("LeftShoulder","UpperChest",points)
	_add_absolute_bone("LeftUpperArm","LeftShoulder",points)
	_add_absolute_bone("LeftLowerArm","LeftUpperArm",points)
	_add_absolute_bone("LeftHand","LeftLowerArm",points)
	_add_absolute_bone("LeftHandTip","LeftHand",points)

	_add_absolute_bone("RightShoulder","UpperChest",points)
	_add_absolute_bone("RightUpperArm","RightShoulder",points)
	_add_absolute_bone("RightLowerArm","RightUpperArm",points)
	_add_absolute_bone("RightHand","RightLowerArm",points)
	_add_absolute_bone("RightHandTip","RightHand",points)

	_add_absolute_bone("LeftUpperLeg","Hips",points)
	_add_absolute_bone("LeftLowerLeg","LeftUpperLeg",points)
	_add_absolute_bone("LeftFoot","LeftLowerLeg",points)
	_add_absolute_bone("LeftToes","LeftFoot",points)

	_add_absolute_bone("RightUpperLeg","Hips",points)
	_add_absolute_bone("RightLowerLeg","RightUpperLeg",points)
	_add_absolute_bone("RightFoot","RightLowerLeg",points)
	_add_absolute_bone("RightToes","RightFoot",points)

func _add_absolute_bone(bone_name: String,parent_name: String,points: Dictionary) -> void:
	var bone_index: int = skeleton.get_bone_count()
	skeleton.add_bone(bone_name)
	var parent_index: int = -1
	var local_origin: Vector3 = points[bone_name] as Vector3
	if not parent_name.is_empty():
		parent_index = skeleton.find_bone(parent_name)
		var parent_origin: Vector3 = points[parent_name] as Vector3
		local_origin -= parent_origin
	skeleton.set_bone_parent(bone_index,parent_index)
	var rest := Transform3D.IDENTITY
	rest.origin = local_origin
	skeleton.set_bone_rest(bone_index,rest)

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
