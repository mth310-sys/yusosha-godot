extends Node3D

const CHARACTER_HEIGHT: float = 1.20

func _ready() -> void:
	# Character-development waiting area: keep both prototypes off the active islands.
	name = "Eita"
	position = Vector3(-7.0,0.0,-7.0)
	_build_customer(self)

	var bita := Node3D.new()
	bita.name = "Bita"
	bita.position = Vector3(0.8,0.0,0.0)
	add_child(bita)
	_build_customer(bita)

func _build_customer(root: Node3D) -> void:
	var skin := _material(Color(0.92,0.72,0.56))
	var hair := _material(Color(0.12,0.10,0.09))
	var shirt := _material(Color(0.20,0.52,0.72))
	var pants := _material(Color(0.16,0.19,0.24))
	var shoes := _material(Color(0.08,0.08,0.09))
	_box(root,"LeftShoe",Vector3(0.14,0.07,0.22),Vector3(-0.09,0.035,0.025),shoes)
	_box(root,"RightShoe",Vector3(0.14,0.07,0.22),Vector3(0.09,0.035,0.025),shoes)
	_box(root,"LeftLeg",Vector3(0.13,0.30,0.14),Vector3(-0.09,0.22,0.0),pants)
	_box(root,"RightLeg",Vector3(0.13,0.30,0.14),Vector3(0.09,0.22,0.0),pants)
	_box(root,"Body",Vector3(0.38,0.38,0.22),Vector3(0.0,0.56,0.0),shirt)
	_box(root,"LeftArm",Vector3(0.10,0.34,0.12),Vector3(-0.245,0.55,0.0),skin)
	_box(root,"RightArm",Vector3(0.10,0.34,0.12),Vector3(0.245,0.55,0.0),skin)
	_box(root,"Head",Vector3(0.42,0.40,0.38),Vector3(0.0,0.96,0.0),skin)
	_box(root,"HairTop",Vector3(0.44,0.10,0.40),Vector3(0.0,1.155,-0.01),hair)
	_box(root,"HairBack",Vector3(0.44,0.24,0.08),Vector3(0.0,1.04,-0.19),hair)
	_box(root,"LeftEye",Vector3(0.035,0.045,0.018),Vector3(-0.085,1.00,0.198),hair)
	_box(root,"RightEye",Vector3(0.035,0.045,0.018),Vector3(0.085,1.00,0.198),hair)

func _box(root: Node3D,node_name: String,size: Vector3,local_position: Vector3,material: StandardMaterial3D) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.material_override = material
	root.add_child(mesh_instance)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material
