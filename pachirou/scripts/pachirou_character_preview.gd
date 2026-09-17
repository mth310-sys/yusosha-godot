extends Node3D

const CHARACTER_HEIGHT: float = 1.20

func _ready() -> void:
	_build_customer()

func _build_customer() -> void:
	# First proportion test only: 1.20 high, chunky 3-head management-game silhouette.
	# Place it in an open aisle so machine/island geometry remains untouched.
	position = Vector3(-3.5, 0.0, 1.5)

	var skin := _material(Color(0.92, 0.72, 0.56))
	var hair := _material(Color(0.12, 0.10, 0.09))
	var shirt := _material(Color(0.20, 0.52, 0.72))
	var pants := _material(Color(0.16, 0.19, 0.24))
	var shoes := _material(Color(0.08, 0.08, 0.09))

	# Feet / legs.
	_box("LeftShoe", Vector3(0.14, 0.07, 0.22), Vector3(-0.09, 0.035, 0.025), shoes)
	_box("RightShoe", Vector3(0.14, 0.07, 0.22), Vector3(0.09, 0.035, 0.025), shoes)
	_box("LeftLeg", Vector3(0.13, 0.30, 0.14), Vector3(-0.09, 0.22, 0.0), pants)
	_box("RightLeg", Vector3(0.13, 0.30, 0.14), Vector3(0.09, 0.22, 0.0), pants)

	# Compact body and arms.
	_box("Body", Vector3(0.38, 0.38, 0.22), Vector3(0.0, 0.56, 0.0), shirt)
	_box("LeftArm", Vector3(0.10, 0.34, 0.12), Vector3(-0.245, 0.55, 0.0), skin)
	_box("RightArm", Vector3(0.10, 0.34, 0.12), Vector3(0.245, 0.55, 0.0), skin)

	# Large readable head: total character height = 1.20.
	_box("Head", Vector3(0.42, 0.40, 0.38), Vector3(0.0, 0.96, 0.0), skin)
	_box("HairTop", Vector3(0.44, 0.10, 0.40), Vector3(0.0, 1.155, -0.01), hair)
	_box("HairBack", Vector3(0.44, 0.24, 0.08), Vector3(0.0, 1.04, -0.19), hair)

	# Minimal face cues toward +Z.
	_box("LeftEye", Vector3(0.035, 0.045, 0.018), Vector3(-0.085, 1.00, 0.198), hair)
	_box("RightEye", Vector3(0.035, 0.045, 0.018), Vector3(0.085, 1.00, 0.198), hair)

func _box(node_name: String, size: Vector3, local_position: Vector3, material: StandardMaterial3D) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.material_override = material
	add_child(mesh_instance)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material
