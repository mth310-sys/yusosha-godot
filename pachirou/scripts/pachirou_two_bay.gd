extends "res://scripts/pachirou_map.gd"

const PACHISLOT_BAY_SCENE := preload("res://items/pachislot_bay.tscn")

func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()
	_create_bay_item(Vector2i(7, 6))

func _create_bay_item(cell: Vector2i) -> void:
	var item := PACHISLOT_BAY_SCENE.instantiate() as PachislotBayItem
	item.position = grid_to_world(cell)
	item.z_index = int(item.position.y)
	world.add_child(item)
	item.setup(_render_bay_item)
	item.build()

func _render_bay_item(item: PachislotBayItem) -> void:
	# All physical component roots share the approved bay origin.
	item.frame.position = UNIT_REAR_SHIFT
	item.equipment.position = UNIT_REAR_SHIFT
	item.stool.position = UNIT_REAR_SHIFT + STOOL_FRONT_OFFSET
	item.stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)

	# Frame appearance is kept exactly as the approved source for now.
	_create_island_frame(item.frame)

	# Equipment is no longer one anonymous polygon group: each physical item owns
	# its own geometry while using the exact same approved dimensions/coordinates.
	var machine_lb: Vector2 = _equipment_front_left()
	var machine_fb: Vector2 = machine_lb + MACHINE_FRONT_VECTOR
	var sand_lb: Vector2 = machine_fb
	var sand_fb: Vector2 = sand_lb + SAND_FRONT_VECTOR
	_create_machine(item.machine, machine_lb, machine_fb, MACHINE_DEPTH)
	_create_sand(item.sand, sand_lb, sand_fb, SAND_DEPTH)
	_create_data_counter(item.data_counter)
	_create_stool_geometry(item.stool)

func _create_stool_geometry(stool: Node2D) -> void:
	var seat_y: float = -38.4
	_add_poly(stool, _ellipse(Vector2(0, 0.5), 15.2, 6.4, 32), Color("4b525a"), 0)
	_add_poly(stool, _ellipse(Vector2(0, -0.8), 12.0, 4.8, 30), METAL_DARK, 1)
	_add_poly(stool, _ellipse(Vector2(0, -1.8), 9.5, 3.4, 28), METAL, 2)
	_add_poly(stool, _ellipse(Vector2(0, -2.2), 5.0, 1.9, 24), Color("d1d5d9"), 3)
	_add_poly(stool, PackedVector2Array([Vector2(-2.6, seat_y + 7.0), Vector2(2.6, seat_y + 7.0), Vector2(2.2, -4.0), Vector2(-2.2, -4.0)]), METAL_DARK, 1)
	_add_poly(stool, PackedVector2Array([Vector2(-1.5, seat_y + 6.0), Vector2(1.5, seat_y + 6.0), Vector2(1.5, -3.0), Vector2(-1.5, -3.0)]), METAL, 2)
	_add_poly(stool, _ellipse(Vector2(0, seat_y + 6.0), 5.0, 2.0, 24), METAL_DARK, 3)
	_add_poly(stool, _ellipse(Vector2(0, seat_y + 5.3), 3.7, 1.4, 22), METAL, 4)
	_add_poly(stool, _ellipse_band(Vector2(0, seat_y + 0.6), 16.0, 6.7, 5.2, 32), Color("20262d"), 4)
	_add_poly(stool, _ellipse(Vector2(0, seat_y), 16.0, 6.7, 34), SEAT_SIDE, 5)
	_add_poly(stool, _ellipse(Vector2(0, seat_y - 0.8), 14.6, 5.8, 34), SEAT_TOP, 6)
	_add_poly(stool, _ellipse(Vector2(0, seat_y - 1.2), 11.8, 4.3, 30), SEAT_INNER, 7)
