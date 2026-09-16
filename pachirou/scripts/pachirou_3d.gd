extends Node3D

const GRID_SIZE: int = 14
const TILE_SIZE: float = 1.0

func _ready() -> void:
	_build_floor()
	_build_reference_bay(Vector2i(6, 6))

func _build_floor() -> void:
	for z in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(TILE_SIZE, 0.04, TILE_SIZE)
			tile.mesh = mesh
			tile.position = _cell_to_world(Vector2i(x, z)) + Vector3(0.0, -0.02, 0.0)
			var shade: float = 0.72 if (x + z) % 2 == 0 else 0.58
			tile.material_override = _material(Color(shade, shade, shade))
			$World.add_child(tile)

func _cell_to_world(cell: Vector2i) -> Vector3:
	var half: float = float(GRID_SIZE - 1) * 0.5
	return Vector3(float(cell.x) - half, 0.0, float(cell.y) - half)

func _build_reference_bay(cell: Vector2i) -> void:
	var bay := Node3D.new()
	bay.name = "ReferenceBay"
	bay.position = _cell_to_world(cell)
	$World.add_child(bay)

	# One canonical unit only. Nothing is rotated or duplicated until this is accepted.
	var base := Node3D.new()
	base.name = "IslandBase"
	bay.add_child(base)
	_box(base, "Body", Vector3(1.00, 0.34, 0.70), Vector3(0.0, 0.17, 0.0), Color("555b62"))
	_box(base, "Top", Vector3(1.00, 0.04, 0.70), Vector3(0.0, 0.36, 0.0), Color("8d9399"))

	var frame := Node3D.new()
	frame.name = "RearFrame"
	bay.add_child(frame)
	_box(frame, "Board", Vector3(1.00, 1.02, 0.07), Vector3(0.0, 0.87, 0.31), Color("666d75"))
	_box(frame, "LeftRail", Vector3(0.045, 1.02, 0.09), Vector3(-0.46, 0.87, 0.30), Color("565d65"))
	_box(frame, "RightRail", Vector3(0.045, 1.02, 0.09), Vector3(0.46, 0.87, 0.30), Color("565d65"))
	_box(frame, "TopEquipment", Vector3(1.00, 0.13, 0.28), Vector3(0.0, 1.42, 0.20), Color("a7adb4"))

	# Front equipment row is explicitly one row: machine then sand.
	var row := Node3D.new()
	row.name = "FrontEquipmentRow"
	row.position = Vector3(0.0, 0.38, -0.20)
	bay.add_child(row)

	var machine_slot := Node3D.new()
	machine_slot.name = "MachineSlot"
	machine_slot.position = Vector3(-0.105, 0.0, 0.0)
	row.add_child(machine_slot)
	_build_machine(machine_slot)

	var sand := Node3D.new()
	sand.name = "Sand"
	sand.position = Vector3(0.315, 0.0, 0.0)
	row.add_child(sand)
	_box(sand, "Body", Vector3(0.20, 0.76, 0.38), Vector3(0.0, 0.38, 0.0), Color("727982"))
	_box(sand, "Screen", Vector3(0.12, 0.14, 0.022), Vector3(0.0, 0.57, -0.201), Color("202a31"))
	_box(sand, "Tray", Vector3(0.13, 0.06, 0.06), Vector3(0.0, 0.27, -0.22), Color("4c535b"))

	var counter := Node3D.new()
	counter.name = "DataCounter"
	counter.position = Vector3(-0.105, 1.27, -0.25)
	bay.add_child(counter)
	_box(counter, "Body", Vector3(0.50, 0.12, 0.14), Vector3.ZERO, Color("242a31"))
	_box(counter, "Screen", Vector3(0.32, 0.055, 0.022), Vector3(0.0, 0.0, -0.081), Color("79b6d8"))

	_build_stool(bay, Vector3(-0.105, 0.0, -0.88))

func _build_machine(parent: Node3D) -> void:
	_box(parent, "Cabinet", Vector3(0.64, 0.86, 0.38), Vector3(0.0, 0.43, 0.0), Color("242932"))
	_box(parent, "TrimL", Vector3(0.045, 0.78, 0.025), Vector3(-0.285, 0.44, -0.202), Color("a7adb5"))
	_box(parent, "TrimR", Vector3(0.045, 0.78, 0.025), Vector3(0.285, 0.44, -0.202), Color("a7adb5"))
	_box(parent, "UpperPanel", Vector3(0.49, 0.13, 0.024), Vector3(0.0, 0.75, -0.202), Color("c45139"))
	_box(parent, "ReelFrame", Vector3(0.53, 0.28, 0.024), Vector3(0.0, 0.52, -0.204), Color("a7adb5"))
	for i in range(3):
		var x: float = (float(i) - 1.0) * 0.16
		_box(parent, "Reel%d" % i, Vector3(0.13, 0.20, 0.026), Vector3(x, 0.52, -0.218), Color("f2eee3"))
	_box(parent, "Deck", Vector3(0.55, 0.12, 0.10), Vector3(0.0, 0.29, -0.23), Color("11151b"))
	_box(parent, "LowerPanel", Vector3(0.46, 0.11, 0.024), Vector3(0.0, 0.11, -0.202), Color("c45139"))

func _build_stool(parent: Node3D, pos: Vector3) -> void:
	var stool := Node3D.new()
	stool.name = "RoundStool"
	stool.position = pos
	parent.add_child(stool)
	_cylinder(stool, "Base", 0.20, 0.05, Vector3(0.0, 0.025, 0.0), Color("666d75"))
	_cylinder(stool, "Post", 0.035, 0.42, Vector3(0.0, 0.235, 0.0), Color("aeb4bb"))
	_cylinder(stool, "Seat", 0.22, 0.11, Vector3(0.0, 0.50, 0.0), Color("343a42"))

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat

func _box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.material_override = _material(color)
	parent.add_child(node)

func _cylinder(parent: Node3D, node_name: String, radius: float, height: float, pos: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	node.mesh = mesh
	node.position = pos
	node.material_override = _material(color)
	parent.add_child(node)
