extends Node3D
class_name PachirouCustomerCharacter

var skin: StandardMaterial3D
var hair: StandardMaterial3D
var shirt: StandardMaterial3D
var pants: StandardMaterial3D
var shoes: StandardMaterial3D

func build() -> void:
	skin = _material(Color(0.92,0.72,0.56))
	hair = _material(Color(0.12,0.10,0.09))
	shirt = _material(Color(0.20,0.52,0.72))
	pants = _material(Color(0.16,0.19,0.24))
	shoes = _material(Color(0.08,0.08,0.09))

	var hip := _joint(self,"Hip",Vector3(0.0,0.43,0.0))
	_box(hip,"Pelvis",Vector3(0.28,0.14,0.20),Vector3(0.0,0.07,0.0),pants)

	var torso := _joint(hip,"Torso",Vector3(0.0,0.14,0.0))
	_box(torso,"Body",Vector3(0.38,0.38,0.22),Vector3(0.0,0.19,0.0),shirt)
	var neck := _joint(torso,"Neck",Vector3(0.0,0.40,0.0))
	var head_joint := _joint(neck,"HeadJoint",Vector3.ZERO)
	_box(head_joint,"Head",Vector3(0.42,0.40,0.38),Vector3(0.0,0.20,0.0),skin)
	_box(head_joint,"HairTop",Vector3(0.44,0.10,0.40),Vector3(0.0,0.395,-0.01),hair)
	_box(head_joint,"HairBack",Vector3(0.44,0.24,0.08),Vector3(0.0,0.28,-0.19),hair)
	_box(head_joint,"LeftEye",Vector3(0.035,0.045,0.018),Vector3(-0.085,0.24,0.198),hair)
	_box(head_joint,"RightEye",Vector3(0.035,0.045,0.018),Vector3(0.085,0.24,0.198),hair)

	_build_arm(torso,"Left",-0.245)
	_build_arm(torso,"Right",0.245)
	_build_leg(hip,"Left",-0.09)
	_build_leg(hip,"Right",0.09)

func _build_arm(torso: Node3D,side: String,x: float) -> void:
	var shoulder := _joint(torso,side+"Shoulder",Vector3(x,0.34,0.0))
	_box(shoulder,side+"UpperArm",Vector3(0.10,0.18,0.12),Vector3(0.0,-0.09,0.0),skin)
	var elbow := _joint(shoulder,side+"Elbow",Vector3(0.0,-0.18,0.0))
	_box(elbow,side+"Forearm",Vector3(0.10,0.17,0.12),Vector3(0.0,-0.085,0.0),skin)

func _build_leg(hip: Node3D,side: String,x: float) -> void:
	var hip_joint := _joint(hip,side+"HipJoint",Vector3(x,0.0,0.0))
	_box(hip_joint,side+"Thigh",Vector3(0.13,0.18,0.14),Vector3(0.0,-0.09,0.0),pants)
	var knee := _joint(hip_joint,side+"Knee",Vector3(0.0,-0.18,0.0))
	_box(knee,side+"Shin",Vector3(0.13,0.18,0.14),Vector3(0.0,-0.09,0.0),pants)
	var ankle := _joint(knee,side+"Ankle",Vector3(0.0,-0.18,0.0))
	_box(ankle,side+"Foot",Vector3(0.14,0.07,0.22),Vector3(0.0,-0.035,0.04),shoes)

func set_standing_pose() -> void:
	rotation = Vector3.ZERO
	_set_joint_rotation("Hip/LeftHipJoint",Vector3.ZERO)
	_set_joint_rotation("Hip/RightHipJoint",Vector3.ZERO)
	_set_joint_rotation("Hip/LeftHipJoint/LeftKnee",Vector3.ZERO)
	_set_joint_rotation("Hip/RightHipJoint/RightKnee",Vector3.ZERO)
	_set_joint_rotation("Hip/Torso/LeftShoulder",Vector3.ZERO)
	_set_joint_rotation("Hip/Torso/RightShoulder",Vector3.ZERO)

func set_seated_pose() -> void:
	# Local +Z is the character's forward direction.
	_set_joint_rotation("Hip/LeftHipJoint",Vector3(deg_to_rad(-88.0),0.0,0.0))
	_set_joint_rotation("Hip/RightHipJoint",Vector3(deg_to_rad(-88.0),0.0,0.0))
	_set_joint_rotation("Hip/LeftHipJoint/LeftKnee",Vector3(deg_to_rad(88.0),0.0,0.0))
	_set_joint_rotation("Hip/RightHipJoint/RightKnee",Vector3(deg_to_rad(88.0),0.0,0.0))
	_set_joint_rotation("Hip/Torso/LeftShoulder",Vector3(deg_to_rad(-28.0),0.0,0.0))
	_set_joint_rotation("Hip/Torso/RightShoulder",Vector3(deg_to_rad(-28.0),0.0,0.0))

func _set_joint_rotation(path: String,value: Vector3) -> void:
	var joint := get_node_or_null(path) as Node3D
	if joint != null: joint.rotation = value

func _joint(parent: Node3D,node_name: String,local_position: Vector3) -> Node3D:
	var joint := Node3D.new()
	joint.name = node_name
	joint.position = local_position
	parent.add_child(joint)
	return joint

func _box(parent: Node3D,node_name: String,size: Vector3,local_position: Vector3,material: StandardMaterial3D) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material
