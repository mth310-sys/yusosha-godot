extends Node3D

const GRID_SIZE: int = 14
const TILE_SIZE: float = 1.0

const BASE_W := 1.00
const BASE_D := 0.70
const BASE_H := 0.36
const BACK_Z := -0.28
const FRONT_Z := 0.18
const MACHINE_W := 0.64
const MACHINE_D := 0.34
const MACHINE_H := 0.82
const MACHINE_X := -0.10
const SAND_W := MACHINE_W * (7.0 / 20.5)
const SAND_D := MACHINE_D
const SAND_H := MACHINE_H * (48.0 / 54.0)
const SAND_X := MACHINE_X + MACHINE_W * 0.5 + SAND_W * 0.5

func _ready() -> void:
	_build_floor()
	# Six variants with one empty grid cell between each item.
	var cells: Array[Vector2i] = [
		Vector2i(4, 4), Vector2i(6, 4), Vector2i(8, 4),
		Vector2i(4, 7), Vector2i(6, 7), Vector2i(8, 7)
	]
	for i in range(6):
		_build_bay(cells[i], i)

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

func _palette(style: int) -> Array[Color]:
	match style:
		0: return [Color("66727d"), Color("9aa6af"), Color("29323a"), Color("e36a45"), Color("83c7e8"), Color("eee5d4")]
		1: return [Color("45515e"), Color("7f8d99"), Color("151b22"), Color("e7483e"), Color("52c8ff"), Color("fff7e8")]
		2: return [Color("6d6258"), Color("b09b7d"), Color("302820"), Color("d47a3d"), Color("8ab0a4"), Color("e7d6ae")]
		3: return [Color("8b8f91"), Color("c1c5c5"), Color("53575a"), Color("e69a72"), Color("9bd4d0"), Color("f3eadc")]
		4: return [Color("50596b"), Color("a5afc0"), Color("171b25"), Color("f05c67"), Color("73b8ff"), Color("f6f4e8")]
		_: return [Color("252936"), Color("5e6578"), Color("0d1119"), Color("ff4778"), Color("43e8ff"), Color("f5f0ff")]

func _build_bay(cell: Vector2i, style: int) -> void:
	var p := _palette(style)
	var bay := Node3D.new()
	bay.name = "Style_%d" % (style + 1)
	bay.position = _cell_to_world(cell)
	$World.add_child(bay)
	var island := Node3D.new()
	island.name = "IslandEquipment"
	bay.add_child(island)

	_box(island, "Base", Vector3(BASE_W, BASE_H, BASE_D), Vector3(0.0, BASE_H * 0.5, 0.0), p[0])
	_box(island, "BaseFrontTrim", Vector3(0.90, 0.05, 0.025), Vector3(0.0, 0.10, BASE_D * 0.5 + 0.013), p[2])
	_box(island, "BaseTopTrim", Vector3(0.90, 0.035, 0.025), Vector3(0.0, BASE_H - 0.05, BASE_D * 0.5 + 0.013), p[1])
	_box(island, "BackBoard", Vector3(BASE_W, 1.00, 0.08), Vector3(0.0, BASE_H + 0.50, BACK_Z), p[0])
	_box(island, "BackRailL", Vector3(0.045, 0.92, 0.025), Vector3(-0.45, BASE_H + 0.50, BACK_Z + 0.052), p[2])
	_box(island, "BackRailR", Vector3(0.045, 0.92, 0.025), Vector3(0.45, BASE_H + 0.50, BACK_Z + 0.052), p[2])
	_box(island, "BackRailMid", Vector3(0.025, 0.92, 0.025), Vector3(0.0, BASE_H + 0.50, BACK_Z + 0.052), p[2])

	var upper_front_z: float = 0.17
	var upper_rear_z: float = BACK_Z + 0.04
	var upper_depth: float = upper_front_z - upper_rear_z
	var upper_z: float = (upper_front_z + upper_rear_z) * 0.5
	_box(island, "UpperBox", Vector3(BASE_W, 0.14, upper_depth), Vector3(0.0, 1.42, upper_z), p[1])
	_box(island, "DataCounter", Vector3(BASE_W * 0.76, 0.13, 0.10), Vector3(0.0, 1.35, upper_front_z + 0.025), p[2])
	_box(island, "CounterScreen", Vector3(BASE_W * 0.60, 0.075, 0.028), Vector3(0.0, 1.35, upper_front_z + 0.104), p[4])

	var machine_slot := Node3D.new()
	machine_slot.name = "MachineSlot"
	machine_slot.position = Vector3(MACHINE_X, BASE_H, FRONT_Z)
	bay.add_child(machine_slot)
	_build_machine(machine_slot, p, style)

	var sand := Node3D.new()
	sand.name = "Sand"
	sand.position = Vector3(SAND_X, BASE_H, FRONT_Z)
	island.add_child(sand)
	_box(sand, "Cabinet", Vector3(SAND_W, SAND_H, SAND_D), Vector3(0.0, SAND_H * 0.5, 0.0), p[0])
	var sf: float = SAND_D * 0.5 + 0.013
	_box(sand, "Face", Vector3(SAND_W * 0.70, SAND_H * 0.72, 0.025), Vector3(0.0, SAND_H * 0.51, sf), p[2])
	_box(sand, "Display", Vector3(SAND_W * 0.54, SAND_H * 0.18, 0.028), Vector3(0.0, SAND_H * 0.70, sf + 0.003), p[4])
	_box(sand, "Slot", Vector3(SAND_W * 0.48, 0.035, 0.029), Vector3(0.0, SAND_H * 0.32, sf + 0.004), p[1])
	_build_stool(island, Vector3(MACHINE_X, 0.0, 0.92), p)

func _build_machine(parent: Node3D, p: Array[Color], style: int) -> void:
	_box(parent, "Cabinet", Vector3(MACHINE_W, MACHINE_H, MACHINE_D), Vector3(0.0, MACHINE_H * 0.5, 0.0), p[2])
	var face: float = MACHINE_D * 0.5 + 0.013
	var trim: float = 0.05 if style == 0 or style == 4 else 0.035
	_box(parent, "TrimL", Vector3(trim, MACHINE_H * 0.90, 0.025), Vector3(-MACHINE_W * 0.44, MACHINE_H * 0.50, face), p[1])
	_box(parent, "TrimR", Vector3(trim, MACHINE_H * 0.90, 0.025), Vector3(MACHINE_W * 0.44, MACHINE_H * 0.50, face), p[1])
	_box(parent, "TopPanel", Vector3(MACHINE_W * 0.76, MACHINE_H * 0.15, 0.027), Vector3(0.0, MACHINE_H * 0.83, face + 0.002), p[3])
	_box(parent, "ReelFrame", Vector3(MACHINE_W * 0.82, MACHINE_H * 0.31, 0.028), Vector3(0.0, MACHINE_H * 0.57, face + 0.003), p[1])
	for i in range(3):
		var reel_x: float = (float(i) - 1.0) * MACHINE_W * 0.25
		_box(parent, "Reel%d" % i, Vector3(MACHINE_W * 0.20, MACHINE_H * 0.22, 0.030), Vector3(reel_x, MACHINE_H * 0.57, face + 0.020), p[5])
	_box(parent, "Control", Vector3(MACHINE_W * 0.86, MACHINE_H * 0.12, 0.11), Vector3(0.0, MACHINE_H * 0.31, face + 0.035), p[2])
	_box(parent, "LowerPanel", Vector3(MACHINE_W * 0.70, MACHINE_H * 0.13, 0.027), Vector3(0.0, MACHINE_H * 0.13, face + 0.002), p[3])

func _build_stool(parent: Node3D, pos: Vector3, p: Array[Color]) -> void:
	var stool := Node3D.new()
	stool.name = "RoundStool"
	stool.position = pos
	parent.add_child(stool)
	_cylinder(stool, "Base", 0.22, 0.055, Vector3(0.0, 0.0275, 0.0), p[0])
	_cylinder(stool, "Post", 0.035, 0.42, Vector3(0.0, 0.27, 0.0), p[1])
	_cylinder(stool, "Seat", 0.22, 0.11, Vector3(0.0, 0.55, 0.0), p[2])

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material

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
