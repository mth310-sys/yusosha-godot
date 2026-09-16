extends Node3D

const GRID_SIZE: int = 14
const TILE_SIZE: float = 1.0

enum Direction { FRONT, RIGHT, BACK, LEFT }

# Accepted one-unit proportions from 386f229.
# 2D: WIDTH_AXIS=32, machine=20.5, sand=7.0. They are contiguous on the same front plane.
const UNIT_WIDTH: float = 1.0
const UNIT_DEPTH: float = 0.70
const BASE_HEIGHT: float = 0.56
const MACHINE_WIDTH: float = 20.5 / 32.0
const SAND_WIDTH: float = 7.0 / 32.0
const EQUIPMENT_WIDTH: float = MACHINE_WIDTH + SAND_WIDTH
const SIDE_MARGIN: float = (UNIT_WIDTH - EQUIPMENT_WIDTH) * 0.5
const MACHINE_X: float = -UNIT_WIDTH * 0.5 + SIDE_MARGIN + MACHINE_WIDTH * 0.5
const SAND_X: float = -UNIT_WIDTH * 0.5 + SIDE_MARGIN + MACHINE_WIDTH + SAND_WIDTH * 0.5
const EQUIPMENT_Z: float = -0.20
const MACHINE_DEPTH: float = 0.42
const SAND_DEPTH: float = 0.42
const MACHINE_HEIGHT: float = 0.86
const SAND_HEIGHT: float = MACHINE_HEIGHT * 48.0 / 54.0

var occupied: Dictionary = {}

func _ready() -> void:
	_build_floor()
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
	var island := Node3D.new()
	island.name = "IslandEquipment"
	bay.add_child(island)

	# Island frame from the accepted unit: low base, rear board, upper equipment.
	_add_box(island, "IslandBase", Vector3(UNIT_WIDTH, BASE_HEIGHT, UNIT_DEPTH), Vector3(0.0, BASE_HEIGHT * 0.5, 0.0), Color("555b62"))
	_add_box(island, "BackBoard", Vector3(UNIT_WIDTH, 1.02, 0.09), Vector3(0.0, BASE_HEIGHT + 0.51, 0.30), Color("666d75"))
	_add_box(island, "UpperBox", Vector3(UNIT_WIDTH, 0.16, 0.30), Vector3(0.0, 1.52, 0.19), Color("8d9399"))

	# Exact accepted front composition: [machine][sand], no gap, same front/depth plane.
	var machine_slot := Node3D.new()
	machine_slot.name = "MachineSlot"
	machine_slot.position = Vector3(MACHINE_X, 0.0, EQUIPMENT_Z)
	bay.add_child(machine_slot)
	if with_machine:
		_create_machine(machine_slot)

	_add_box(island, "SandCabinet", Vector3(SAND_WIDTH, SAND_HEIGHT, SAND_DEPTH), Vector3(SAND_X, BASE_HEIGHT + SAND_HEIGHT * 0.5, EQUIPMENT_Z), Color("727982"))
	# Sand face details make the narrow cabinet unambiguous in every direction.
	var sand_front_z: float = EQUIPMENT_Z - SAND_DEPTH * 0.5 - 0.013
	_add_box(island, "SandScreen", Vector3(SAND_WIDTH * 0.62, SAND_HEIGHT * 0.17, 0.025), Vector3(SAND_X, BASE_HEIGHT + SAND_HEIGHT * 0.73, sand_front_z), Color("202a31"))
	_add_box(island, "SandSlotA", Vector3(SAND_WIDTH * 0.52, 0.035, 0.026), Vector3(SAND_X, BASE_HEIGHT + SAND_HEIGHT * 0.43, sand_front_z - 0.001), Color("171c21"))
	_add_box(island, "SandSlotB", Vector3(SAND_WIDTH * 0.52, 0.035, 0.026), Vector3(SAND_X, BASE_HEIGHT + SAND_HEIGHT * 0.31, sand_front_z - 0.001), Color("171c21"))

	# Counter belongs to the island and sits above the machine area.
	_add_box(island, "DataCounter", Vector3(MACHINE_WIDTH * 0.76, 0.13, 0.16), Vector3(MACHINE_X, 1.43, -0.25), Color("242a31"))
	_add_box(island, "CounterScreen", Vector3(MACHINE_WIDTH * 0.55, 0.065, 0.025), Vector3(MACHINE_X, 1.43, -0.343), Color("79b6d8"))
	_create_stool(island, Vector3(MACHINE_X, 0.0, -0.90))
	return bay

func _create_machine(parent: Node3D) -> void:
	var machine := Node3D.new()
	machine.name = "PachislotMachine3D"
	parent.add_child(machine)
	_add_box(machine, "Cabinet", Vector3(MACHINE_WIDTH, MACHINE_HEIGHT, MACHINE_DEPTH), Vector3(0.0, BASE_HEIGHT + MACHINE_HEIGHT * 0.5, 0.0), Color("242932"))
	var front_z: float = -MACHINE_DEPTH * 0.5 - 0.013
	_add_box(machine, "UpperPanel", Vector3(MACHINE_WIDTH * 0.78, MACHINE_HEIGHT * 0.16, 0.025), Vector3(0.0, BASE_HEIGHT + MACHINE_HEIGHT * 0.84, front_z), Color("c45139"))
	_add_box(machine, "ReelFrame", Vector3(MACHINE_WIDTH * 0.86, MACHINE_HEIGHT * 0.32, 0.026), Vector3(0.0, BASE_HEIGHT + MACHINE_HEIGHT * 0.57, front_z - 0.002), Color("a7adb5"))
	for i in range(3):
		var reel_x: float = (float(i) - 1.0) * MACHINE_WIDTH * 0.25
		_add_box(machine, "Reel%d" % i, Vector3(MACHINE_WIDTH * 0.20, MACHINE_HEIGHT * 0.23, 0.028), Vector3(reel_x, BASE_HEIGHT + MACHINE_HEIGHT * 0.57, front_z - 0.018), Color("f2eee3"))
	_add_box(machine, "ControlDeck", Vector3(MACHINE_WIDTH * 0.88, MACHINE_HEIGHT * 0.13, 0.10), Vector3(0.0, BASE_HEIGHT + MACHINE_HEIGHT * 0.31, -MACHINE_DEPTH * 0.5 - 0.04), Color("11151b"))
	_add_box(machine, "LowerPanel", Vector3(MACHINE_WIDTH * 0.72, MACHINE_HEIGHT * 0.13, 0.026), Vector3(0.0, BASE_HEIGHT + MACHINE_HEIGHT * 0.13, front_z), Color("c45139"))

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
