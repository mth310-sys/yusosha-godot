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

	# Human-proportion prototype. The skeleton remains procedural, but the
	# visible body uses rounded volumes so joint placement can be judged clearly.
	var pelvis := _joint(self,"Pelvis",Vector3(0.0,0.62,0.0))
	_ellipsoid(pelvis,"PelvisMesh",Vector3(0.28,0.18,0.20),Vector3.ZERO,pants)

	var waist := _joint(pelvis,"Waist",Vector3(0.0,0.10,0.0))
	_ellipsoid(waist,"WaistMesh",Vector3(0.25,0.20,0.18),Vector3(0.0,0.10,0.0),shirt)
	var chest := _joint(waist,"Chest",Vector3(0.0,0.20,0.0))
	_ellipsoid(chest,"ChestMesh",Vector3(0.36,0.30,0.21),Vector3(0.0,0.15,0.0),shirt)

	var neck := _joint(chest,"Neck",Vector3(0.0,0.32,0.0))
	_cylinder(neck,"NeckMesh",0.055,0.10,Vector3(0.0,0.05,0.0),skin)
	var head := _joint(neck,"Head",Vector3(0.0,0.10,0.0))
	_ellipsoid(head,"HeadMesh",Vector3(0.24,0.30,0.25),Vector3(0.0,0.15,0.0),skin)
	_ellipsoid(head,"HairCap",Vector3(0.25,0.12,0.26),Vector3(0.0,0.285,-0.01),hair)
	_sphere(head,"LeftEye",0.018,Vector3(-0.052,0.17,0.122),hair)
	_sphere(head,"RightEye",0.018,Vector3(0.052,0.17,0.122),hair)

	_build_arm(chest,"Left",-0.215)
	_build_arm(chest,"Right",0.215)
	_build_leg(pelvis,"Left",-0.085)
	_build_leg(pelvis,"Right",0.085)
	set_standing_pose()

func _build_arm(chest: Node3D,side: String,x: float) -> void:
	var shoulder := _joint(chest,side+"Shoulder",Vector3(x,0.23,0.0))
	_sphere(shoulder,side+"ShoulderJoint",0.065,Vector3.ZERO,shirt)
	_capsule(shoulder,side+"UpperArm",0.055,0.24,Vector3(0.0,-0.12,0.0),shirt)
	var elbow := _joint(shoulder,side+"Elbow",Vector3(0.0,-0.24,0.0))
	_sphere(elbow,side+"ElbowJoint",0.052,Vector3.ZERO,skin)
	_capsule(elbow,side+"Forearm",0.048,0.22,Vector3(0.0,-0.11,0.0),skin)
	var wrist := _joint(elbow,side+"Wrist",Vector3(0.0,-0.22,0.0))
	_ellipsoid(wrist,side+"Hand",Vector3(0.09,0.13,0.07),Vector3(0.0,-0.065,0.0),skin)

func _build_leg(pelvis: Node3D,side: String,x: float) -> void:
	var hip := _joint(pelvis,side+"Hip",Vector3(x,-0.07,0.0))
	_sphere(hip,side+"HipJoint",0.075,Vector3.ZERO,pants)
	_capsule(hip,side+"Thigh",0.075,0.34,Vector3(0.0,-0.17,0.0),pants)
	var knee := _joint(hip,side+"Knee",Vector3(0.0,-0.34,0.0))
	_sphere(knee,side+"KneeJoint",0.065,Vector3.ZERO,pants)
	_capsule(knee,side+"Shin",0.060,0.34,Vector3(0.0,-0.17,0.0),pants)
	var ankle := _joint(knee,side+"Ankle",Vector3(0.0,-0.34,0.0))
	_sphere(ankle,side+"AnkleJoint",0.045,Vector3.ZERO,shoes)
	_ellipsoid(ankle,side+"Foot",Vector3(0.13,0.08,0.25),Vector3(0.0,-0.035,0.075),shoes)

func set_standing_pose() -> void:
	var pelvis := get_node_or_null("Pelvis") as Node3D
	if pelvis != null:
		pelvis.position = Vector3(0.0,0.62,0.0)
		pelvis.rotation = Vector3.ZERO
	_reset_pose_joints()

func set_seated_pose() -> void:
	var pelvis := get_node_or_null("Pelvis") as Node3D
	if pelvis != null:
		pelvis.position = Vector3(0.0,0.50,0.0)
		pelvis.rotation = Vector3(deg_to_rad(-4.0),0.0,0.0)
	_set_joint_rotation("Pelvis/Waist",Vector3(deg_to_rad(3.0),0.0,0.0))
	_set_joint_rotation("Pelvis/Waist/Chest",Vector3(deg_to_rad(-7.0),0.0,0.0))
	_set_joint_rotation("Pelvis/LeftHip",Vector3(deg_to_rad(-88.0),0.0,0.0))
	_set_joint_rotation("Pelvis/RightHip",Vector3(deg_to_rad(-88.0),0.0,0.0))
	_set_joint_rotation("Pelvis/LeftHip/LeftKnee",Vector3(deg_to_rad(92.0),0.0,0.0))
	_set_joint_rotation("Pelvis/RightHip/RightKnee",Vector3(deg_to_rad(92.0),0.0,0.0))
	_set_joint_rotation("Pelvis/Waist/Chest/LeftShoulder",Vector3(deg_to_rad(-18.0),0.0,deg_to_rad(-5.0)))
	_set_joint_rotation("Pelvis/Waist/Chest/RightShoulder",Vector3(deg_to_rad(-18.0),0.0,deg_to_rad(5.0)))
	_set_joint_rotation("Pelvis/Waist/Chest/LeftShoulder/LeftElbow",Vector3(deg_to_rad(-55.0),0.0,0.0))
	_set_joint_rotation("Pelvis/Waist/Chest/RightShoulder/RightElbow",Vector3(deg_to_rad(-55.0),0.0,0.0))

func _reset_pose_joints() -> void:
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

func _set_joint_rotation(path: String,value: Vector3) -> void:
	var joint := get_node_or_null(path) as Node3D
	if joint != null: joint.rotation = value

func _joint(parent: Node3D,node_name: String,local_position: Vector3) -> Node3D:
	var joint := Node3D.new()
	joint.name = node_name
	joint.position = local_position
	parent.add_child(joint)
	return joint

func _capsule(parent: Node3D,node_name: String,radius: float,height: float,local_position: Vector3,material: StandardMaterial3D) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	instance.mesh = mesh
	instance.position = local_position
	instance.material_override = material
	parent.add_child(instance)

func _sphere(parent: Node3D,node_name: String,radius: float,local_position: Vector3,material: StandardMaterial3D) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2.0
	instance.mesh = mesh
	instance.position = local_position
	instance.material_override = material
	parent.add_child(instance)

func _ellipsoid(parent: Node3D,node_name: String,size: Vector3,local_position: Vector3,material: StandardMaterial3D) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	instance.mesh = mesh
	instance.scale = size
	instance.position = local_position
	instance.material_override = material
	parent.add_child(instance)

func _cylinder(parent: Node3D,node_name: String,radius: float,height: float,local_position: Vector3,material: StandardMaterial3D) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	instance.mesh = mesh
	instance.position = local_position
	instance.material_override = material
	parent.add_child(instance)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material
