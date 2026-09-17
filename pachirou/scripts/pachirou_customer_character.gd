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

	# Pelvis is the anatomical root. Upper body and both legs articulate from it.
	var pelvis := _joint(self,"Pelvis",Vector3(0.0,0.57,0.0))
	_box(pelvis,"PelvisMesh",Vector3(0.30,0.16,0.20),Vector3(0.0,0.0,0.0),pants)

	var waist := _joint(pelvis,"Waist",Vector3(0.0,0.08,0.0))
	_box(waist,"WaistMesh",Vector3(0.30,0.16,0.20),Vector3(0.0,0.08,0.0),shirt)
	var chest := _joint(waist,"Chest",Vector3(0.0,0.16,0.0))
	_box(chest,"ChestMesh",Vector3(0.38,0.24,0.22),Vector3(0.0,0.12,0.0),shirt)

	var neck := _joint(chest,"Neck",Vector3(0.0,0.28,0.0))
	_box(neck,"NeckMesh",Vector3(0.10,0.08,0.10),Vector3(0.0,0.04,0.0),skin)
	var head := _joint(neck,"Head",Vector3(0.0,0.08,0.0))
	_box(head,"HeadMesh",Vector3(0.34,0.36,0.32),Vector3(0.0,0.18,0.0),skin)
	_box(head,"HairTop",Vector3(0.36,0.08,0.34),Vector3(0.0,0.37,-0.01),hair)
	_box(head,"HairBack",Vector3(0.36,0.22,0.07),Vector3(0.0,0.25,-0.17),hair)
	_box(head,"LeftEye",Vector3(0.03,0.04,0.018),Vector3(-0.07,0.21,0.169),hair)
	_box(head,"RightEye",Vector3(0.03,0.04,0.018),Vector3(0.07,0.21,0.169),hair)

	_build_arm(chest,"Left",-0.23)
	_build_arm(chest,"Right",0.23)
	_build_leg(pelvis,"Left",-0.09)
	_build_leg(pelvis,"Right",0.09)
	set_standing_pose()

func _build_arm(chest: Node3D,side: String,x: float) -> void:
	var shoulder := _joint(chest,side+"Shoulder",Vector3(x,0.21,0.0))
	_box(shoulder,side+"UpperArm",Vector3(0.10,0.22,0.11),Vector3(0.0,-0.11,0.0),shirt)
	var elbow := _joint(shoulder,side+"Elbow",Vector3(0.0,-0.22,0.0))
	_box(elbow,side+"Forearm",Vector3(0.09,0.20,0.10),Vector3(0.0,-0.10,0.0),skin)
	var wrist := _joint(elbow,side+"Wrist",Vector3(0.0,-0.20,0.0))
	_box(wrist,side+"Hand",Vector3(0.10,0.10,0.10),Vector3(0.0,-0.05,0.0),skin)

func _build_leg(pelvis: Node3D,side: String,x: float) -> void:
	var hip := _joint(pelvis,side+"Hip",Vector3(x,-0.08,0.0))
	_box(hip,side+"Thigh",Vector3(0.14,0.28,0.16),Vector3(0.0,-0.14,0.0),pants)
	var knee := _joint(hip,side+"Knee",Vector3(0.0,-0.28,0.0))
	_box(knee,side+"Shin",Vector3(0.13,0.27,0.14),Vector3(0.0,-0.135,0.0),pants)
	var ankle := _joint(knee,side+"Ankle",Vector3(0.0,-0.27,0.0))
	_box(ankle,side+"Foot",Vector3(0.14,0.09,0.24),Vector3(0.0,-0.045,0.055),shoes)

func set_standing_pose() -> void:
	var pelvis := get_node_or_null("Pelvis") as Node3D
	if pelvis != null:
		pelvis.position = Vector3(0.0,0.57,0.0)
		pelvis.rotation = Vector3.ZERO
	_set_joint_rotation("Pelvis/Waist",Vector3.ZERO)
	_set_joint_rotation("Pelvis/Waist/Chest",Vector3.ZERO)
	_set_joint_rotation("Pelvis/LeftHip",Vector3.ZERO)
	_set_joint_rotation("Pelvis/RightHip",Vector3.ZERO)
	_set_joint_rotation("Pelvis/LeftHip/LeftKnee",Vector3.ZERO)
	_set_joint_rotation("Pelvis/RightHip/RightKnee",Vector3.ZERO)
	_set_joint_rotation("Pelvis/Waist/Chest/LeftShoulder",Vector3.ZERO)
	_set_joint_rotation("Pelvis/Waist/Chest/RightShoulder",Vector3.ZERO)
	_set_joint_rotation("Pelvis/Waist/Chest/LeftShoulder/LeftElbow",Vector3.ZERO)
	_set_joint_rotation("Pelvis/Waist/Chest/RightShoulder/RightElbow",Vector3.ZERO)

func set_seated_pose() -> void:
	# Proper seated posture: pelvis lowers and tilts slightly, thighs project
	# forward, knees bend downward, torso leans mildly toward the interaction.
	var pelvis := get_node_or_null("Pelvis") as Node3D
	if pelvis != null:
		pelvis.position = Vector3(0.0,0.47,0.0)
		pelvis.rotation = Vector3(deg_to_rad(-5.0),0.0,0.0)
	_set_joint_rotation("Pelvis/Waist",Vector3(deg_to_rad(4.0),0.0,0.0))
	_set_joint_rotation("Pelvis/Waist/Chest",Vector3(deg_to_rad(-8.0),0.0,0.0))
	_set_joint_rotation("Pelvis/LeftHip",Vector3(deg_to_rad(-88.0),0.0,0.0))
	_set_joint_rotation("Pelvis/RightHip",Vector3(deg_to_rad(-88.0),0.0,0.0))
	_set_joint_rotation("Pelvis/LeftHip/LeftKnee",Vector3(deg_to_rad(92.0),0.0,0.0))
	_set_joint_rotation("Pelvis/RightHip/RightKnee",Vector3(deg_to_rad(92.0),0.0,0.0))
	_set_joint_rotation("Pelvis/Waist/Chest/LeftShoulder",Vector3(deg_to_rad(-32.0),0.0,0.0))
	_set_joint_rotation("Pelvis/Waist/Chest/RightShoulder",Vector3(deg_to_rad(-32.0),0.0,0.0))
	_set_joint_rotation("Pelvis/Waist/Chest/LeftShoulder/LeftElbow",Vector3(deg_to_rad(-55.0),0.0,0.0))
	_set_joint_rotation("Pelvis/Waist/Chest/RightShoulder/RightElbow",Vector3(deg_to_rad(-55.0),0.0,0.0))

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
