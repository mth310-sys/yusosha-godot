extends Node3D

const GRID_SIZE: int = 14
const TILE_SIZE: float = 1.0

# Canonical 3D unit. One cell = 1.0 world unit.
# Front faces point toward +Z so the current isometric camera sees the playable face.
const BASE_W := 1.00
const BASE_D := 0.70
const BASE_H := 0.36
const BACK_Z := -0.28
const FRONT_Z := 0.18

const MACHINE_W := 0.64
const MACHINE_D := 0.34
const MACHINE_H := 0.82
const MACHINE_X := -0.10

# Accepted 2D relationship: machine front span 20.5, sand span 7.0.
const SAND_W := MACHINE_W * (7.0 / 20.5)
const SAND_D := MACHINE_D
const SAND_H := MACHINE_H * (48.0 / 54.0)
const SAND_X := MACHINE_X + MACHINE_W * 0.5 + SAND_W * 0.5

func _ready() -> void:
	_build_floor()
	_build_canonical_bay(Vector2i(6, 6))

func _build_floor() -> void:
	for z in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(TILE_SIZE, 0.04, TILE_SIZE)
			tile.mesh = mesh
			tile.position = _cell_to_world(Vector2i(x, z)) + Vector3(0.0, -0.02, 0.0)
			var material := StandardMaterial3D.new()
			var shade: float = 0.72 if (x + z) % 2 == 0 else 0.58
			material.albedo_color = Color(shade, shade, shade)
			tile.material_override = material
			$World.add_child(tile)

func _cell_to_world(cell: Vector2i) -> Vector3:
	var half: float = float(GRID_SIZE - 1) * 0.5
	return Vector3(float(cell.x) - half, 0.0, float(cell.y) - half)

func _build_canonical_bay(cell: Vector2i) -> void:
	var bay := Node3D.new()
	bay.name = "CanonicalBay"
	bay.position = _cell_to_world(cell)
	$World.add_child(bay)

	var island := Node3D.new()
	island.name = "IslandEquipment"
	bay.add_child(island)

	_box(island, "Base", Vector3(BASE_W, BASE_H, BASE_D), Vector3(0.0, BASE_H * 0.5, 0.0), Color("555b62"))
	_box(island, "BaseFrontTrim", Vector3(0.90, 0.05, 0.025), Vector3(0.0, 0.10, BASE_D * 0.5 + 0.013), Color("3d4349"))
	_box(island, "BaseTopTrim", Vector3(0.90, 0.035, 0.025), Vector3(0.0, BASE_H - 0.05, BASE_D * 0.5 + 0.013), Color("70767d"))
	_box(island, "BackBoard", Vector3(BASE_W, 1.00, 0.08), Vector3(0.0, BASE_H + 0.50, BACK_Z), Color("666d75"))
	_box(island, "BackRailL", Vector3(0.045, 0.92, 0.025), Vector3(-0.45, BASE_H + 0.50, BACK_Z + 0.052), Color("565d65"))
	_box(island, "BackRailR", Vector3(0.045, 0.92, 0.025), Vector3(0.45, BASE_H + 0.50, BACK_Z + 0.052), Color("565d65"))
	_box(island, "BackRailMid", Vector3(0.025, 0.92, 0.025), Vector3(0.0, BASE_H + 0.50, BACK_Z + 0.052), Color("515860"))

	# Keep the accepted front projection, but extend the upper equipment rearward until it physically meets the backboard.
	var upper_front_z: float = 0.17
	var upper_rear_z: float = BACK_Z + 0.04
	var upper_box_depth: float = upper_front_z - upper_rear_z
	var upper_box_z: float = (upper_front_z + upper_rear_z) * 0.5
	_box(island, "UpperBox", Vector3(BASE_W, 0.14, upper_box_depth), Vector3(0.0, 1.42, upper_box_z), Color("8d9399"))

	# Data counter remains at the accepted front edge of the upper island equipment.
	var counter_x: float = 0.0
	var counter_y: float = 1.35
	var counter_z: float = upper_front_z + 0.025
	_box(island, "DataCounter", Vector3(BASE_W * 0.76, 0.13, 0.10), Vector3(counter_x, counter_y, counter_z), Color("242a31"))
	_box(island, "CounterInset", Vector3(BASE_W * 0.70, 0.105, 0.025), Vector3(counter_x, counter_y, counter_z + 0.063), Color("4d5964"))
	_box(island, "CounterScreen", Vector3(BASE_W * 0.60, 0.075, 0.028), Vector3(counter_x, counter_y, counter_z + 0.079), Color("79b6d8"))

	var machine_slot := Node3D.new()
	machine_slot.name = "MachineSlot"
	machine_slot.position = Vector3(MACHINE_X, BASE_H, FRONT_Z)
	bay.add_child(machine_slot)
	_build_machine(machine_slot)

	var sand := Node3D.new()
	sand.name = "Sand"
	sand.position = Vector3(SAND_X, BASE_H, FRONT_Z)
	island.add_child(sand)
	_box(sand, "Cabinet", Vector3(SAND_W, SAND_H, SAND_D), Vector3(0.0, SAND_H * 0.5, 0.0), Color("676e76"))
	var sand_face: float = SAND_D * 0.5 + 0.013
	_box(sand, "FaceInset", Vector3(SAND_W * 0.70, SAND_H * 0.72, 0.025), Vector3(0.0, SAND_H * 0.51, sand_face), Color("444b53"))
	_box(sand, "Display", Vector3(SAND_W * 0.54, SAND_H * 0.18, 0.028), Vector3(0.0, SAND_H * 0.70, sand_face + 0.003), Color("20262d"))
	_box(sand, "SlotA", Vector3(SAND_W * 0.48, 0.035, 0.029), Vector3(0.0, SAND_H * 0.38, sand_face + 0.004), Color("171c21"))
	_box(sand, "SlotB", Vector3(SAND_W * 0.48, 0.035, 0.029), Vector3(0.0, SAND_H * 0.27, sand_face + 0.004), Color("171c21"))

	_build_stool(island, Vector3(MACHINE_X, 0.0, 0.92))

func _build_machine(parent: Node3D) -> void:
	var machine := Node3D.new()
	machine.name = "PachislotMachine"
	parent.add_child(machine)
	_box(machine, "Cabinet", Vector3(MACHINE_W, MACHINE_H, MACHINE_D), Vector3(0.0, MACHINE_H * 0.5, 0.0), Color("242932"))
	var face: float = MACHINE_D * 0.5 + 0.013
	_box(machine, "SideTrimL", Vector3(0.045, MACHINE_H * 0.90, 0.025), Vector3(-MACHINE_W * 0.44, MACHINE_H * 0.50, face), Color("a7adb5"))
	_box(machine, "SideTrimR", Vector3(0.045, MACHINE_H * 0.90, 0.025), Vector3(MACHINE_W * 0.44, MACHINE_H * 0.50, face), Color("a7adb5"))
	_box(machine, "TopPanel", Vector3(MACHINE_W * 0.76, MACHINE_H * 0.15, 0.027), Vector3(0.0, MACHINE_H * 0.83, face + 0.002), Color("c45139"))
	_box(machine, "ReelFrame", Vector3(MACHINE_W * 0.82, MACHINE_H * 0.31, 0.028), Vector3(0.0, MACHINE_H * 0.57, face + 0.003), Color("a7adb5"))
	for i in range(3):
		var reel_x: float = (float(i) - 1.0) * MACHINE_W * 0.25
		_box(machine, "Reel%d" % i, Vector3(MACHINE_W * 0.20, MACHINE_H * 0.22, 0.030), Vector3(reel_x, MACHINE_H * 0.57, face + 0.020), Color("f2eee3"))
	_box(machine, "ControlDeck", Vector3(MACHINE_W * 0.86, MACHINE_H * 0.12, 0.11), Vector3(0.0, MACHINE_H * 0.31, face + 0.035), Color("11151b"))
	_box(machine, "LowerPanel", Vector3(MACHINE_W * 0.70, MACHINE_H * 0.13, 0.027), Vector3(0.0, MACHINE_H * 0.13, face + 0.002), Color("c45139"))

func _build_stool(parent: Node3D, pos: Vector3) -> void:
	var stool := Node3D.new()
	stool.name = "RoundStool"
	stool.position = pos
	parent.add_child(stool)
	_cylinder(stool, "Base", 0.22, 0.055, Vector3(0.0, 0.0275, 0.0), Color("4b525a"))
	_cylinder(stool, "BaseInner", 0.15, 0.035, Vector3(0.0, 0.062, 0.0), Color("aeb4bb"))
	_cylinder(stool, "Post", 0.035, 0.42, Vector3(0.0, 0.27, 0.0), Color("aeb4bb"))
	_cylinder(stool, "SeatSide", 0.22, 0.11, Vector3(0.0, 0.53, 0.0), Color("20262d"))
	_cylinder(stool, "SeatTop", 0.20, 0.045, Vector3(0.0, 0.605, 0.0), Color("4b525a"))

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
