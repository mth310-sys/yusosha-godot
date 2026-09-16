extends Node3D

const GRID_SIZE: int = 14
const TILE_SIZE: float = 1.0

enum Direction { FRONT, RIGHT, BACK, LEFT }

# Clean 3D restart. Dimensions are physical/local; no 2D screen-coordinate conversion.
const BASE_W := 1.00
const BASE_D := 0.72
const BASE_H := 0.34
const MACHINE_W := 0.62
const MACHINE_D := 0.38
const MACHINE_H := 0.86
const SAND_W := 0.20
const SAND_D := 0.38
const SAND_H := 0.76
const FRONT_Z := -0.22
const MACHINE_X := -0.10
const SAND_X := MACHINE_X + MACHINE_W * 0.5 + SAND_W * 0.5

var occupied: Dictionary = {}

func _ready() -> void:
	_build_floor()
	# First establish one correct canonical item. Other directions are the same item rotated.
	_place_bay(Vector2i(6, 6), Direction.FRONT, true)
	_place_bay(Vector2i(8, 6), Direction.RIGHT, true)
	_place_bay(Vector2i(8, 8), Direction.BACK, true)
	_place_bay(Vector2i(6, 8), Direction.LEFT, true)

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
	var half := float(GRID_SIZE - 1) * 0.5
	return Vector3(float(cell.x) - half, 0.0, float(cell.y) - half)

func _place_bay(cell: Vector2i, direction: Direction, with_machine: bool) -> Node3D:
	if cell.x < 0 or cell.y < 0 or cell.x >= GRID_SIZE or cell.y >= GRID_SIZE or occupied.has(cell):
		return null
	var bay := _build_bay_item(with_machine)
	bay.position = _cell_to_world(cell)
	bay.rotation_degrees.y = float(int(direction) * 90)
	bay.set_meta("grid_cell", cell)
	bay.set_meta("direction", int(direction))
	$World.add_child(bay)
	occupied[cell] = bay
	return bay

func _build_bay_item(with_machine: bool) -> Node3D:
	var bay := Node3D.new()
	bay.name = "PachislotBay3D"

	# Island equipment + stool = one placeable item.
	var island := Node3D.new()
	island.name = "IslandEquipment"
	bay.add_child(island)

	# Low island base. Equipment stands on this top surface.
	_box(island, "Base", Vector3(BASE_W, BASE_H, BASE_D), Vector3(0.0, BASE_H * 0.5, 0.0), Color("555b62"))
	_box(island, "BaseTop", Vector3(BASE_W, 0.045, BASE_D), Vector3(0.0, BASE_H + 0.0225, 0.0), Color("8d9399"))

	# Rear structure is behind the equipment, never beside it.
	_box(island, "BackBoard", Vector3(BASE_W, 1.08, 0.075), Vector3(0.0, BASE_H + 0.54, 0.315), Color("666d75"))
	_box(island, "BackFrameL", Vector3(0.045, 1.08, 0.09), Vector3(-0.455, BASE_H + 0.54, 0.305), Color("565d65"))
	_box(island, "BackFrameR", Vector3(0.045, 1.08, 0.09), Vector3(0.455, BASE_H + 0.54, 0.305), Color("565d65"))
	_box(island, "UpperShelf", Vector3(BASE_W, 0.12, 0.28), Vector3(0.0, 1.44, 0.20), Color("a7adb4"))

	# Machine slot is a separate item mount.
	var machine_slot := Node3D.new()
	machine_slot.name = "MachineSlot"
	machine_slot.position = Vector3(MACHINE_X, BASE_H, FRONT_Z)
	bay.add_child(machine_slot)
	if with_machine:
		_build_machine(machine_slot)

	# Sand is island equipment. It shares the machine's front plane and depth.
	# Its left side directly touches the machine's right side.
	_box(island, "Sand", Vector3(SAND_W, SAND_H, SAND_D), Vector3(SAND_X, BASE_H + SAND_H * 0.5, FRONT_Z), Color("727982"))
	var sand_face_z := FRONT_Z - SAND_D * 0.5 - 0.011
	_box(island, "SandScreen", Vector3(0.12, 0.15, 0.022), Vector3(SAND_X, BASE_H + 0.56, sand_face_z), Color("202a31"))
	_box(island, "SandSlot1", Vector3(0.11, 0.028, 0.023), Vector3(SAND_X, BASE_H + 0.34, sand_face_z), Color("171c21"))
	_box(island, "SandSlot2", Vector3(0.11, 0.028, 0.023), Vector3(SAND_X, BASE_H + 0.25, sand_face_z), Color("171c21"))

	# Data counter above the machine, attached to island equipment.
	_box(island, "Counter", Vector3(0.52, 0.12, 0.15), Vector3(MACHINE_X, 1.34, -0.24), Color("242a31"))
	_box(island, "CounterScreen", Vector3(0.34, 0.055, 0.022), Vector3(MACHINE_X, 1.34, -0.326), Color("79b6d8"))

	_build_stool(island, Vector3(MACHINE_X, 0.0, -0.88))
	return bay

func _build_machine(parent: Node3D) -> void:
	var machine := Node3D.new()
	machine.name = "PachislotMachine3D"
	parent.add_child(machine)
	_box(machine, "Cabinet", Vector3(MACHINE_W, MACHINE_H, MACHINE_D), Vector3(0.0, MACHINE_H * 0.5, 0.0), Color("242932"))
	var face_z := -MACHINE_D * 0.5 - 0.011
	_box(machine, "TopPanel", Vector3(0.48, 0.13, 0.022), Vector3(0.0, 0.76, face_z), Color("c45139"))
	_box(machine, "ReelFrame", Vector3(0.52, 0.29, 0.024), Vector3(0.0, 0.52, face_z - 0.002), Color("a7adb5"))
	for i in range(3):
		var x := (float(i) - 1.0) * 0.16
		_box(machine, "Reel%d" % i, Vector3(0.13, 0.21, 0.025), Vector3(x, 0.52, face_z - 0.016), Color("f2eee3"))
	_box(machine, "Control", Vector3(0.54, 0.12, 0.10), Vector3(0.0, 0.28, -0.23), Color("11151b"))
	_box(machine, "LowerPanel", Vector3(0.45, 0.11, 0.023), Vector3(0.0, 0.10, face_z), Color("c45139"))

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
