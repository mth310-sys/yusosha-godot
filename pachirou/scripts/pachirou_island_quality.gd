extends Node3D

const STOOL_HEIGHT_SCALE: float = 0.82

func _ready() -> void:
	call_deferred("_upgrade_all")

func _upgrade_all() -> void:
	await get_tree().process_frame
	var world := get_parent().get_node_or_null("World")
	if world == null:
		world = get_parent()
	_upgrade_recursive(world)

func _upgrade_recursive(node: Node) -> void:
	if node is Node3D and node.name == "IslandEquipment":
		_upgrade_island(node as Node3D)
	for child in node.get_children():
		_upgrade_recursive(child)

func _upgrade_island(island: Node3D) -> void:
	if island.has_node("QualityUpgrade"):
		return
	var rig := Node3D.new()
	rig.name = "QualityUpgrade"
	island.add_child(rig)
	var body := Color("53636d")
	var dark := Color("202a31")
	var metal := Color("9ba8af")
	var trim := Color("c6d0d5")
	var cyan := Color("62d9ee")

	_box(rig,"UpperSupportL",Vector3(0.075,0.30,0.075),Vector3(-0.445,1.255,-0.255),body,0.32,0.38)
	_box(rig,"UpperSupportR",Vector3(0.075,0.30,0.075),Vector3(0.445,1.255,-0.255),body,0.32,0.38)
	_box(rig,"UpperCrossBeam",Vector3(0.93,0.065,0.085),Vector3(0,1.365,-0.255),dark,0.42,0.30)
	_box(rig,"SupportCapL",Vector3(0.105,0.055,0.12),Vector3(-0.445,1.405,-0.225),metal,0.65,0.22)
	_box(rig,"SupportCapR",Vector3(0.105,0.055,0.12),Vector3(0.445,1.405,-0.225),metal,0.65,0.22)
	_box(rig,"BackEdgeL",Vector3(0.035,0.94,0.035),Vector3(-0.485,0.86,-0.225),dark,0.48,0.30)
	_box(rig,"BackEdgeR",Vector3(0.035,0.94,0.035),Vector3(0.485,0.86,-0.225),dark,0.48,0.30)
	_box(rig,"BackLowerRail",Vector3(0.94,0.045,0.040),Vector3(0,0.405,-0.225),metal,0.62,0.25)
	_box(rig,"UpperFrontFascia",Vector3(0.94,0.075,0.035),Vector3(0,1.425,0.188),dark,0.38,0.28)
	_box(rig,"UpperFrontTrim",Vector3(0.82,0.022,0.018),Vector3(0,1.426,0.210),trim,0.70,0.20)
	_emissive_box(rig,"UpperStatusLine",Vector3(0.66,0.018,0.012),Vector3(0,1.426,0.222),cyan)
	_box(rig,"ToeKick",Vector3(0.91,0.065,0.035),Vector3(0,0.055,0.365),dark,0.25,0.42)
	_box(rig,"BaseCornerL",Vector3(0.055,0.30,0.045),Vector3(-0.475,0.19,0.365),metal,0.55,0.28)
	_box(rig,"BaseCornerR",Vector3(0.055,0.30,0.045),Vector3(0.475,0.19,0.365),metal,0.55,0.28)
	_box(rig,"BaseTopSeam",Vector3(0.94,0.022,0.040),Vector3(0,0.355,0.365),trim,0.58,0.24)
	_box(rig,"CounterBezel",Vector3(0.70,0.105,0.025),Vector3(0,1.35,0.292),dark,0.30,0.25)
	_box(rig,"CounterGlass",Vector3(0.57,0.063,0.014),Vector3(0,1.35,0.309),Color("19343d"),0.05,0.12)
	for i in range(3):
		_emissive_box(rig,"CounterLamp%d"%i,Vector3(0.025,0.014,0.010),Vector3(-0.055+float(i)*0.055,1.350,0.320),Color("6fe8ff") if i != 1 else Color("ffd65a"))

	var sand := island.get_node_or_null("Sand") as Node3D
	if sand != null:
		_box(sand,"QualityTopCap",Vector3(0.205,0.035,0.35),Vector3(0,0.745,0),metal,0.52,0.26)
		_box(sand,"QualityLowerTrim",Vector3(0.19,0.035,0.028),Vector3(0,0.13,0.190),dark,0.32,0.32)

	# Keep the stool footprint/target point unchanged; only lower its physical height.
	# 0.55 seat center becomes about 0.45, matching the 1.20-high customer better.
	var stool := island.get_node_or_null("RoundStool") as Node3D
	if stool != null:
		stool.scale.y = STOOL_HEIGHT_SCALE
		_cylinder(stool,"SeatRim",0.235,0.025,Vector3(0,0.505,0),metal)
		_cylinder(stool,"FootRing",0.145,0.018,Vector3(0,0.19,0),metal)

func _box(parent: Node3D,node_name: String,size: Vector3,pos: Vector3,color: Color,metallic: float,roughness: float) -> void:
	var n := MeshInstance3D.new()
	n.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.position = pos
	n.material_override = _material(color,metallic,roughness)
	parent.add_child(n)

func _emissive_box(parent: Node3D,node_name: String,size: Vector3,pos: Vector3,color: Color) -> void:
	var n := MeshInstance3D.new()
	n.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.position = pos
	var mat := _material(color.darkened(0.18),0.08,0.24)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.8
	n.material_override = mat
	parent.add_child(n)

func _cylinder(parent: Node3D,node_name: String,radius: float,height: float,pos: Vector3,color: Color) -> void:
	var n := MeshInstance3D.new()
	n.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	n.mesh = mesh
	n.position = pos
	n.material_override = _material(color,0.72,0.22)
	parent.add_child(n)

func _material(color: Color,metallic: float,roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	return mat
