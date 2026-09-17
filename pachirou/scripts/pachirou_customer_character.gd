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

	# Natural low-poly human prototype. Joint nodes remain the animation rig;
	# visible joint spheres are removed so the silhouette reads as one body.
	var pelvis := _joint(self,"Pelvis",Vector3(0.0,0.66,0.0))
	_ellipsoid(pelvis,"PelvisMesh",Vector3(0.27,0.20,0.19),Vector3.ZERO,pants)

	var waist := _joint(pelvis,"Waist",Vector3(0.0,0.10,0.0))
	_ellipsoid(waist,"Abdomen",Vector3(0.25,0.22,0.17),Vector3(0.0,0.11,0.0),shirt)
	var chest := _joint(waist,"Chest",Vector3(0.0,0.20,0.0))
	_ellipsoid(chest,"ChestMesh",Vector3(0.35,0.31,0.20),Vector3(0.0,0.145,0.0),shirt)

	var neck := _joint(chest,"Neck",Vector3(0.0,0.31,0.0))
	_cylinder(neck,"NeckMesh",0.047,0.075,Vector3(0.0,0.037,0.0),skin)
	var head := _joint(neck,"Head",Vector3(0.0,0.075,0.0))
	_ellipsoid(head,"Cranium",Vector3(0.205,0.245,0.205),Vector3(0.0,0.145,-0.005),skin)
	_ellipsoid(head,"Face",Vector3(0.175,0.205,0.155),Vector3(0.0,0.115,0.055),skin)
	_ellipsoid(head,"Hair",Vector3(0.215,0.105,0.215),Vector3(0.0,0.275,-0.012),hair)
	_sphere(head,"LeftEye",0.012,Vector3(-0.045,0.145,0.139),hair)
	_sphere(head,"RightEye",0.012,Vector3(0.045,0.145,0.139),hair)

	_build_arm(chest,"Left",-0.205)
	_build_arm(chest,"Right",0.205)
	_build_leg(pelvis,"Left",-0.078)
	_build_leg(pelvis,"Right",0.078)
	set_standing_pose()

func _build_arm(chest: Node3D,side: String,x: float) -> void:
	var shoulder := _joint(chest,side+"Shoulder",Vector3(x,0.205,0.0))
	_tapered_limb(shoulder,side+"UpperArm",0.060,0.050,0.245,Vector3(0.0,-0.1225,0.0),shirt)
	var elbow := _joint(shoulder,side+"Elbow",Vector3(0.0,-0.245,0.0))
	_tapered_limb(elbow,side+"Forearm",0.050,0.040,0.225,Vector3(0.0,-0.1125,0.0),skin)
	var wrist := _joint(elbow,side+"Wrist",Vector3(0.0,-0.225,0.0))
	_ellipsoid(wrist,side+"Hand",Vector3(0.075,0.115,0.060),Vector3(0.0,-0.057,0.01),skin)

func _build_leg(pelvis: Node3D,side: String,x: float) -> void:
	var hip := _joint(pelvis,side+"Hip",Vector3(x,-0.075,0.0))
	_tapered_limb(hip,side+"Thigh",0.082,0.066,0.355,Vector3(0.0,-0.1775,0.0),pants)
	var knee := _joint(hip,side+"Knee",Vector3(0.0,-0.355,0.0))
	_tapered_limb(knee,side+"Shin",0.065,0.050,0.345,Vector3(0.0,-0.1725,0.0),pants)
	var ankle := _joint(knee,side+"Ankle",Vector3(0.0,-0.345,0.0))
	_ellipsoid(ankle,side+"Foot",Vector3(0.125,0.075,0.245),Vector3(0.0,-0.035,0.075),shoes)

func set_standing_pose() -> void:
	var pelvis := get_node_or_null("Pelvis") as Node3D
	if pelvis != null:
		pelvis.position = Vector3(0.0,0.66,0.0)
		pelvis.rotation = Vector3.ZERO
	_reset_pose_joints()
	_set_joint_rotation("Pelvis/Waist/Chest/LeftShoulder",Vector3(0.0,0.0,deg_to_rad(-3.0)))
	_set_joint_rotation("Pelvis/Waist/Chest/RightShoulder",Vector3(0.0,0.0,deg_to_rad(3.0)))

func set_seated_pose() -> void:
	var pelvis := get_node_or_null("Pelvis") as Node3D
	if pelvis != null:
		pelvis.position = Vector3(0.0,0.51,0.0)
		pelvis.rotation = Vector3(deg_to_rad(-3.0),0.0,0.0)
	_set_joint_rotation("Pelvis/Waist",Vector3(deg_to_rad(3.0),0.0,0.0))
	_set_joint_rotation("Pelvis/Waist/Chest",Vector3(deg_to_rad(-6.0),0.0,0.0))
	_set_joint_rotation("Pelvis/LeftHip",Vector3(deg_to_rad(-86.0),0.0,0.0))
	_set_joint_rotation("Pelvis/RightHip",Vector3(deg_to_rad(-86.0),0.0,0.0))
	_set_joint_rotation("Pelvis/LeftHip/LeftKnee",Vector3(deg_to_rad(88.0),0.0,0.0))
	_set_joint_rotation("Pelvis/RightHip/RightKnee",Vector3(deg_to_rad(88.0),0.0,0.0))
	_set_joint_rotation("Pelvis/Waist/Chest/LeftShoulder",Vector3(deg_to_rad(-16.0),0.0,deg_to_rad(-4.0)))
	_set_joint_rotation("Pelvis/Waist/Chest/RightShoulder",Vector3(deg_to_rad(-16.0),0.0,deg_to_rad(4.0)))
	_set_joint_rotation("Pelvis/Waist/Chest/LeftShoulder/LeftElbow",Vector3(deg_to_rad(-62.0),0.0,0.0))
	_set_joint_rotation("Pelvis/Waist/Chest/RightShoulder/RightElbow",Vector3(deg_to_rad(-62.0),0.0,0.0))

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

func _tapered_limb(parent: Node3D,node_name: String,top_radius: float,bottom_radius: float,height: float,local_position: Vector3,material: StandardMaterial3D) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 10
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
	mesh.radial_segments = 12
	mesh.rings = 6
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
	mesh.radial_segments = 12
	mesh.rings = 6
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
	mesh.radial_segments = 10
	instance.mesh = mesh
	instance.position = local_position
	instance.material_override = material
	parent.add_child(instance)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material
