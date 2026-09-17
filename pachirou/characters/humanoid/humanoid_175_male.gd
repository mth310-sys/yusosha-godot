extends Node3D
class_name Humanoid175Male

const HEIGHT_M: float = 1.75
const JOINT_RADIUS: float = 0.025
const BONE_RADIUS: float = 0.014

var skeleton: Skeleton3D
var debug_material: StandardMaterial3D

func _ready() -> void:
	_build_skeleton()
	_build_debug_skeleton()

func _build_skeleton() -> void:
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	add_child(skeleton)

	# 175 cm adult male reference rig. The soles are at y=0 and the head top is y=1.75.
	# Bone origins are joint centers; HeadTop is a measurement marker, not an animation bone.
	var root := _add_bone("Root",-1,Vector3(0.0,0.0,0.0))
	var pelvis := _add_bone("Pelvis",root,Vector3(0.0,0.98,0.0))
	var spine := _add_bone("Spine",pelvis,Vector3(0.0,0.12,0.0))
	var chest := _add_bone("Chest",spine,Vector3(0.0,0.17,0.0))
	var upper_chest := _add_bone("UpperChest",chest,Vector3(0.0,0.15,0.0))
	var neck := _add_bone("Neck",upper_chest,Vector3(0.0,0.11,0.0))
	var head := _add_bone("Head",neck,Vector3(0.0,0.10,0.0))
	_add_bone("HeadTop",head,Vector3(0.0,0.12,0.0))

	var left_shoulder := _add_bone("LeftShoulder",upper_chest,Vector3(-0.17,0.04,0.0))
	var left_upper_arm := _add_bone("LeftUpperArm",left_shoulder,Vector3(-0.08,-0.03,0.0))
	var left_forearm := _add_bone("LeftForearm",left_upper_arm,Vector3(-0.30,0.0,0.0))
	var left_hand := _add_bone("LeftHand",left_forearm,Vector3(-0.26,0.0,0.0))
	_add_bone("LeftMiddleFinger",left_hand,Vector3(-0.18,0.0,0.0))

	var right_shoulder := _add_bone("RightShoulder",upper_chest,Vector3(0.17,0.04,0.0))
	var right_upper_arm := _add_bone("RightUpperArm",right_shoulder,Vector3(0.08,-0.03,0.0))
	var right_forearm := _add_bone("RightForearm",right_upper_arm,Vector3(0.30,0.0,0.0))
	var right_hand := _add_bone("RightHand",right_forearm,Vector3(0.26,0.0,0.0))
	_add_bone("RightMiddleFinger",right_hand,Vector3(0.18,0.0,0.0))

	var left_thigh := _add_bone("LeftThigh",pelvis,Vector3(-0.09,-0.04,0.0))
	var left_shin := _add_bone("LeftShin",left_thigh,Vector3(0.0,-0.49,0.0))
	var left_ankle := _add_bone("LeftAnkle",left_shin,Vector3(0.0,-0.40,0.0))
	var left_foot := _add_bone("LeftFoot",left_ankle,Vector3(0.0,-0.05,0.07))
	_add_bone("LeftToes",left_foot,Vector3(0.0,0.0,0.18))

	var right_thigh := _add_bone("RightThigh",pelvis,Vector3(0.09,-0.04,0.0))
	var right_shin := _add_bone("RightShin",right_thigh,Vector3(0.0,-0.49,0.0))
	var right_ankle := _add_bone("RightAnkle",right_shin,Vector3(0.0,-0.40,0.0))
	var right_foot := _add_bone("RightFoot",right_ankle,Vector3(0.0,-0.05,0.07))
	_add_bone("RightToes",right_foot,Vector3(0.0,0.0,0.18))

func _add_bone(bone_name: String,parent_index: int,origin: Vector3) -> int:
	var index: int = skeleton.get_bone_count()
	skeleton.add_bone(bone_name)
	skeleton.set_bone_parent(index,parent_index)
	var rest := Transform3D.IDENTITY
	rest.origin = origin
	skeleton.set_bone_rest(index,rest)
	return index

func _build_debug_skeleton() -> void:
	debug_material = StandardMaterial3D.new()
	debug_material.albedo_color = Color(0.92,0.92,0.95,1.0)
	debug_material.roughness = 0.7
	var debug_root := Node3D.new()
	debug_root.name = "BoneDebug"
	add_child(debug_root)

	for bone_index in skeleton.get_bone_count():
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
	sphere.height = JOINT_RADIUS * 2.0
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
