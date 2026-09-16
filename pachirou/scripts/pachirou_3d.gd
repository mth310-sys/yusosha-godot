extends Node3D

const GRID_SIZE: int = 14
const TILE_SIZE: float = 1.0

enum Direction { FRONT, RIGHT, BACK, LEFT }

var occupied: Dictionary = {}

func _ready() -> void:
	_build_floor()
	# One complete bay item, shown in all four directions.
	# Every component uses the same local coordinates and rotates only with the root.
	_place_bay(Vector2i(5, 6), Direction.FRONT, true)
	_place_bay(Vector2i(8, 6), Direction.RIGHT, true)
	_place_bay(Vector2i(8, 9), Direction.BACK, true)
	_place_bay(Vector2i(5, 9), Direction.LEFT, true)

func _build_floor() -> void:
	for z in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(TILE_SIZE, 0.04, TILE_SIZE)
			tile.mesh = mesh
			tile.position = _cell_to_world(Vector2i(x, z)) + Vector3(0.0, -0.02, 0.0)
			var mat := StandardMaterial3D.new()
			var shade: float = 0.72 if (x + z) % 2 == 0 else 0.58
			mat.albedo_color = Color(shade, shade, shade)
			tile.material_override = mat
			$World.add_child(tile)

func _cell_to_world(cell: Vector2i) -> Vector3:
	var half: float = float(GRID_SIZE - 1) * 0.5
	return Vector3((float(cell.x) - half) * TILE_SIZE, 0.0, (float(cell.y) - half) * TILE_SIZE)

func _is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_SIZE and cell.y < GRID_SIZE

func _can_place(cell: Vector2i) -> bool:
	return _is_inside(cell) and not occupied.has(cell)

func _place_bay(cell: Vector2i, direction: Direction, with_machine: bool) -> Node3D:
	if not _can_place(cell):
		return null
	var bay: Node3D = _build_bay_item(with_machine)
	bay.set_meta("grid_cell", cell)
	bay.set_meta("direction", int(direction))
	bay.position = _cell_to_world(cell)
	bay.rotation_degrees.y = float(int(direction) * 90)
	bay.name = "PachislotBay_%d_%d_%d" % [cell.x, cell.y, int(direction)]
	$World.add_child(bay)
	occupied[cell] = bay
	return bay

func _move_bay(bay: Node3D, target_cell: Vector2i) -> bool:
	if bay == null or not _can_place(target_cell):
		return false
	var old_cell: Vector2i = bay.get_meta("grid_cell") as Vector2i
	occupied.erase(old_cell)
	occupied[target_cell] = bay
	bay.set_meta("grid_cell", target_cell)
	bay.position = _cell_to_world(target_cell)
	return true

func _rotate_bay_clockwise(bay: Node3D) -> void:
	if bay == null:
		return
	var next_direction: int = (int(bay.get_meta("direction")) + 1) % 4
	bay.set_meta("direction", next_direction)
	bay.rotation_degrees.y = float(next_direction * 90)

func _remove_bay(bay: Node3D) -> void:
	if bay == null:
		return
	var cell: Vector2i = bay.get_meta("grid_cell") as Vector2i
	occupied.erase(cell)
	bay.queue_free()

func _build_bay_item(with_machine: bool) -> Node3D:
	var bay := Node3D.new()
	bay.name = "PachislotBay3D"

	# The complete island/stool set is authored once in FRONT-local coordinates.
	var island := Node3D.new()
	island.name = "IslandEquipment"
	bay.add_child(island)
	_add_box(island, "IslandBase", Vector3(1.0, 0.55, 0.72), Vector3(0.0, 0.275, 0.0), Color("555b62"))
	_add_box(island, "BackBoard", Vector3(1.0, 1.05, 0.10), Vector3(0.0, 1.05, 0.31), Color("666d75"))
	_add_box(island, "UpperBox", Vector3(1.0, 0.16, 0.30), Vector3(0.0, 1.55, 0.20), Color("8d9399"))

	# Machine opening is centered; sand occupies the machine's local right side.
	# Both are children of the same bay root, so their relationship cannot change by direction.
	var machine_slot := Node3D.new()
	machine_slot.name = "MachineSlot"
	machine_slot.position = Vector3(-0.08, 0.0, -0.09)
	bay.add_child(machine_slot)
	_add_box(island, "Sand", Vector3(0.18, 0.76, 0.34), Vector3(0.39, 0.93, -0.09), Color("727982"))
	_add_box(island, "DataCounter", Vector3(0.58, 0.13, 0.16), Vector3(-0.08, 1.42, -0.24), Color("242a31"))
	_create_stool(island, Vector3(-0.08, 0.0, -0.90))

	if with_machine:
		_create_machine(machine_slot)
	return bay

func _create_machine(parent: Node3D) -> void:
	var machine := Node3D.new()
	machine.name = "PachislotMachine3D"
	parent.add_child(machine)
	_add_box(machine, "Cabinet", Vector3(0.62, 0.92, 0.42), Vector3(0.0, 1.01, 0.0), Color("242932"))
	_add_box(machine, "ReelPanel", Vector3(0.48, 0.28, 0.025), Vector3(0.0, 1.08, -0.222), Color("f2eee3"))
	_add_box(machine, "ControlDeck", Vector3(0.52, 0.13, 0.12), Vector3(0.0, 0.77, -0.21), Color("11151b"))

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
