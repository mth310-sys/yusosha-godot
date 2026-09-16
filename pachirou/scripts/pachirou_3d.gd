extends Node3D

const GRID_SIZE := 14
const TILE_SIZE := 1.0

func _ready() -> void:
	_build_floor()
	_create_bay(Vector3(-1.5, 0.0, 0.0), 0.0, true)
	_create_bay(Vector3(1.5, 0.0, 0.0), 90.0, false)

func _build_floor() -> void:
	for z in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(TILE_SIZE, 0.04, TILE_SIZE)
			tile.mesh = mesh
			tile.position = Vector3(float(x) - 6.5, -0.02, float(z) - 6.5)
			var mat := StandardMaterial3D.new()
			var shade := 0.72 if (x + z) % 2 == 0 else 0.58
			mat.albedo_color = Color(shade, shade, shade)
			tile.material_override = mat
			$World.add_child(tile)

func _create_bay(pos: Vector3, yaw_degrees: float, with_machine: bool) -> void:
	var bay := Node3D.new()
	bay.name = "PachislotBay3D"
	bay.position = pos
	bay.rotation_degrees.y = yaw_degrees
	$World.add_child(bay)

	_add_box(bay, "IslandBase", Vector3(1.0, 0.55, 0.72), Vector3(0.0, 0.275, 0.0), Color("555b62"))
	_add_box(bay, "BackBoard", Vector3(1.0, 1.05, 0.10), Vector3(0.0, 1.05, 0.31), Color("666d75"))
	_add_box(bay, "UpperBox", Vector3(1.0, 0.16, 0.30), Vector3(0.0, 1.55, 0.20), Color("8d9399"))
	_add_box(bay, "Sand", Vector3(0.20, 0.76, 0.36), Vector3(0.38, 0.93, -0.08), Color("727982"))
	_add_box(bay, "DataCounter", Vector3(0.58, 0.13, 0.16), Vector3(0.0, 1.42, -0.02), Color("242a31"))
	_create_stool(bay, Vector3(0.0, 0.0, -0.88))

	var machine_slot := Node3D.new()
	machine_slot.name = "MachineSlot"
	bay.add_child(machine_slot)
	if with_machine:
		_create_machine(machine_slot)

func _create_machine(parent: Node3D) -> void:
	var machine := Node3D.new()
	machine.name = "PachislotMachine3D"
	parent.add_child(machine)
	_add_box(machine, "Cabinet", Vector3(0.62, 0.92, 0.42), Vector3(-0.08, 1.01, -0.09), Color("242932"))
	_add_box(machine, "ReelPanel", Vector3(0.48, 0.28, 0.025), Vector3(-0.08, 1.08, -0.312), Color("f2eee3"))
	_add_box(machine, "ControlDeck", Vector3(0.52, 0.13, 0.12), Vector3(-0.08, 0.77, -0.30), Color("11151b"))

func _create_stool(parent: Node3D, pos: Vector3) -> void:
	var stool := Node3D.new()
	stool.name = "RoundStool"
	stool.position = pos
	parent.add_child(stool)
	_add_cylinder(stool, "Base", 0.23, 0.06, Vector3(0.0, 0.03, 0.0), Color("666d75"))
	_add_cylinder(stool, "Post", 0.045, 0.50, Vector3(0.0, 0.28, 0.0), Color("aeb4bb"))
	_add_cylinder(stool, "Seat", 0.25, 0.12, Vector3(0.0, 0.59, 0.0), Color("343a42"))

func _add_box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	node.material_override = mat
	parent.add_child(node)

func _add_cylinder(parent: Node3D, node_name: String, radius: float, height: float, pos: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	node.mesh = mesh
	node.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	node.material_override = mat
	parent.add_child(node)
