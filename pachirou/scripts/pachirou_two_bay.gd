extends "res://scripts/pachirou_map.gd"

const PACHISLOT_BAY_SCENE := preload("res://items/pachislot_bay.tscn")
const PACHISLOT_MACHINE_SCENE := preload("res://items/pachislot_machine.tscn")
const MACHINE_SLOT_LEFT := Vector2(-22.0, -36.15)

var placement_grid: IsometricGrid

func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	placement_grid = IsometricGrid.new(map_width, map_height, tile_width, tile_height)
	_create_floor()

	# Same completed placeable item in each logical 90-degree direction.
	# LEFT_DOWN keeps the installed-machine reference; the other three stay
	# empty so the island + stool geometry can be checked without obstruction.
	_create_bay_item(Vector2i(5, 7), PachislotBayItem.Direction.LEFT_DOWN, true)
	_create_bay_item(Vector2i(7, 6), PachislotBayItem.Direction.LEFT_UP, false)
	_create_bay_item(Vector2i(8, 8), PachislotBayItem.Direction.RIGHT_UP, false)
	_create_bay_item(Vector2i(6, 9), PachislotBayItem.Direction.RIGHT_DOWN, false)

func _create_bay_item(cell: Vector2i, direction: PachislotBayItem.Direction, with_machine: bool) -> void:
	var item := PACHISLOT_BAY_SCENE.instantiate() as PachislotBayItem
	world.add_child(item)
	if not item.setup(placement_grid, cell, direction):
		item.queue_free()
		return
	if with_machine:
		_install_standard_machine(item)

func _install_standard_machine(item: PachislotBayItem) -> void:
	var machine_item := PACHISLOT_MACHINE_SCENE.instantiate() as PachislotMachineItem
	if not item.install_machine(machine_item):
		machine_item.queue_free()
		return
	machine_item.setup("standard_a", _render_standard_machine)

func _render_standard_machine(machine_item: PachislotMachineItem) -> void:
	var machine_lb: Vector2 = MACHINE_SLOT_LEFT
	var machine_fb: Vector2 = machine_lb + MACHINE_FRONT_VECTOR
	_create_machine(machine_item, machine_lb, machine_fb, MACHINE_DEPTH)
	_create_machine_hidden_faces(machine_item, machine_lb, machine_fb)

func _create_machine_hidden_faces(parent: Node2D, fl: Vector2, fr: Vector2) -> void:
	var rl: Vector2 = fl + MACHINE_DEPTH
	var rr: Vector2 = fr + MACHINE_DEPTH
	var up := Vector2(0.0, -MACHINE_HEIGHT)
	_add_poly(parent, PackedVector2Array([rl, rr, rr + up, rl + up]), Color("343b43"), 8)
	_add_poly(parent, _face_quad(rl, rr, up, 0.10, 0.90, 0.12, 0.88), Color("292f36"), 9)
	_add_poly(parent, _face_quad(rl, rr, up, 0.18, 0.82, 0.20, 0.40), Color("3e454d"), 9)
	_add_poly(parent, _face_quad(rl, rr, up, 0.22, 0.78, 0.60, 0.66), Color("151a20"), 10)
	_add_poly(parent, _face_quad(rl, rr, up, 0.22, 0.78, 0.72, 0.78), Color("151a20"), 10)
	_add_poly(parent, _face_quad(rl, rr, up, 0.43, 0.57, 0.84, 0.89), Color("777f87"), 10)
	_add_poly(parent, PackedVector2Array([fl, rl, rl + up, fl + up]), Color("4b525a"), 8)
