extends "res://scripts/pachirou_map.gd"

const PACHISLOT_BAY_SCENE := preload("res://items/pachislot_bay.tscn")

func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()
	_create_bay_item(Vector2i(6, 7), PachislotBayItem.Direction.LEFT_DOWN)
	_create_bay_item(Vector2i(8, 7), PachislotBayItem.Direction.LEFT_UP)

func _create_bay_item(cell: Vector2i, direction: PachislotBayItem.Direction) -> void:
	var item := PACHISLOT_BAY_SCENE.instantiate() as PachislotBayItem
	item.position = grid_to_world(cell)
	item.z_index = int(item.position.y)
	world.add_child(item)
	item.setup(direction, _render_bay_item)
	item.build()

func _render_bay_item(item: PachislotBayItem, direction: PachislotBayItem.Direction) -> void:
	match direction:
		PachislotBayItem.Direction.LEFT_DOWN:
			_render_left_down_item(item)
		PachislotBayItem.Direction.LEFT_UP:
			_render_left_up_item(item)

func _render_left_down_item(item: PachislotBayItem) -> void:
	item.frame.position = UNIT_REAR_SHIFT
	item.equipment.position = UNIT_REAR_SHIFT
	item.stool.position = UNIT_REAR_SHIFT + STOOL_FRONT_OFFSET
	item.stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)
	_create_island_base_item(item.island_base)
	_create_backboard_item(item.back_board)
	_create_upper_box_item(item.upper_box)
	var machine_lb: Vector2 = _equipment_front_left()
	var machine_fb: Vector2 = machine_lb + MACHINE_FRONT_VECTOR
	var sand_lb: Vector2 = machine_fb
	var sand_fb: Vector2 = sand_lb + SAND_FRONT_VECTOR
	_create_machine(item.machine, machine_lb, machine_fb, MACHINE_DEPTH)
	_create_machine_hidden_faces(item.machine, machine_lb, machine_fb)
	_create_sand(item.sand, sand_lb, sand_fb, SAND_DEPTH)
	_create_sand_hidden_faces(item.sand, sand_lb, sand_fb)
	_create_data_counter(item.data_counter)
	_create_counter_hidden_faces(item.data_counter)
	_create_stool_geometry(item.stool)

func _render_left_up_item(item: PachislotBayItem) -> void:
	# Stay in the same grid cell and move the base toward the visual rear
	# (upper-right on the current isometric floor), not toward upper-left.
	item.frame.position = DEPTH_AXIS * (1.0 - BASE_DEPTH_RATIO)
	_create_left_up_island_base(item.island_base)

func _create_left_up_island_base(parent: Node2D) -> void:
	var floor_left := Vector2(32.0, 0.0)
	var floor_front := Vector2(0.0, 16.0)
	var depth := Vector2(-DEPTH_AXIS.x, DEPTH_AXIS.y) * BASE_DEPTH_RATIO
	var rear_left: Vector2 = floor_left + depth
	var rear_right: Vector2 = floor_front + depth
	var up := Vector2(0.0, -BASE_HEIGHT)
	var top_left: Vector2 = floor_left + up
	var top_front: Vector2 = floor_front + up
	var top_rear_left: Vector2 = rear_left + up
	var top_rear_right: Vector2 = rear_right + up
	_add_poly(parent, PackedVector2Array([floor_left, floor_front, top_front, top_left]), BASE_FRONT, 0)
	_add_poly(parent, PackedVector2Array([rear_left, floor_left, top_left, top_rear_left]), BASE_SIDE, 0)
	_add_poly(parent, PackedVector2Array([top_rear_right, top_rear_left, top_left, top_front]), BASE_TOP, 0)
	_add_poly(parent, _face_quad(floor_left, floor_front, up, 0.04, 0.96, 0.05, 0.14), Color("3d4349"), 1)
	_add_poly(parent, _face_quad(floor_left, floor_front, up, 0.49, 0.51, 0.16, 0.94), Color("464c53"), 1)
	_add_poly(parent, _face_quad(floor_left, floor_front, up, 0.05, 0.95, 0.91, 0.955), Color("70767d"), 1)
	_add_poly(parent, _face_quad(rear_left, floor_left, up, 0.04, 0.96, 0.05, 0.13), Color("30363c"), 1)
	_add_poly(parent, PackedVector2Array([rear_right, rear_left, top_rear_left, top_rear_right]), Color("353b41"), -2)
	_add_poly(parent, PackedVector2Array([floor_front, rear_right, top_rear_right, top_front]), Color("454b52"), -2)

func _create_island_base_item(parent: Node2D) -> void:
	var floor_left := Vector2(-32.0, 0.0)
	var floor_front := Vector2(0.0, 16.0)
	var depth: Vector2 = DEPTH_AXIS * BASE_DEPTH_RATIO
	var rear_left: Vector2 = floor_left + depth
	var rear_right: Vector2 = floor_front + depth
	var top_left: Vector2 = _base_top_left()
	var top_front: Vector2 = _base_top_front()
	var top_rear_left: Vector2 = _base_back_left()
	var top_rear_right: Vector2 = _base_back_right()
	var up := Vector2(0.0, -BASE_HEIGHT)
	_add_poly(parent, PackedVector2Array([floor_left, floor_front, top_front, top_left]), BASE_FRONT, 0)
	_add_poly(parent, PackedVector2Array([floor_front, rear_right, top_rear_right, top_front]), BASE_SIDE, 0)
	_add_poly(parent, PackedVector2Array([top_rear_left, top_rear_right, top_front, top_left]), BASE_TOP, 0)
	_add_poly(parent, _face_quad(floor_left, floor_front, up, 0.04, 0.96, 0.05, 0.14), Color("3d4349"), 1)
	_add_poly(parent, _face_quad(floor_left, floor_front, up, 0.49, 0.51, 0.16, 0.94), Color("464c53"), 1)
	_add_poly(parent, _face_quad(floor_left, floor_front, up, 0.05, 0.95, 0.91, 0.955), Color("70767d"), 1)
	_add_poly(parent, _face_quad(floor_front, rear_right, up, 0.04, 0.96, 0.05, 0.13), Color("30363c"), 1)
	_add_poly(parent, PackedVector2Array([rear_left, rear_right, top_rear_right, top_rear_left]), Color("353b41"), -2)
	_add_poly(parent, PackedVector2Array([floor_left, rear_left, top_rear_left, top_left]), Color("454b52"), -2)

func _create_backboard_item(parent: Node2D) -> void:
	var fl: Vector2 = _base_back_left()
	var fr: Vector2 = _base_back_right()
	var thickness: Vector2 = _board_thickness()
	var rl: Vector2 = fl + thickness
	var rr: Vector2 = fr + thickness
	var up := Vector2(0.0, -BACKBOARD_HEIGHT)
	_add_poly(parent, PackedVector2Array([fl, fr, fr + up, fl + up]), BACKBOARD, 1)
	_add_poly(parent, PackedVector2Array([fr, rr, rr + up, fr + up]), BACKBOARD_SIDE, 2)
	_add_poly(parent, _face_quad(fl, fr, up, 0.035, 0.075, 0.04, 0.96), Color("565d65"), 2)
	_add_poly(parent, _face_quad(fl, fr, up, 0.925, 0.965, 0.04, 0.96), Color("565d65"), 2)
	_add_poly(parent, _face_quad(fl, fr, up, 0.495, 0.505, 0.04, 0.96), Color("515860"), 2)
	_add_poly(parent, _face_quad(fl, fr, up, 0.08, 0.92, 0.915, 0.95), Color("7b8289"), 2)
	_add_poly(parent, PackedVector2Array([rl, rr, rr + up, rl + up]), Color("4d545c"), 0)
	_add_poly(parent, PackedVector2Array([fl, rl, rl + up, fl + up]), BACKBOARD_SIDE, 0)
	_add_poly(parent, PackedVector2Array([fl + up, fr + up, rr + up, rl + up]), Color("747b82"), 1)

func _create_upper_box_item(parent: Node2D) -> void:
	var bl: Vector2 = _upper_box_back_left()
	var br: Vector2 = _upper_box_back_right()
	var push: Vector2 = _upper_box_front_vector()
	var fl: Vector2 = bl + push
	var fr: Vector2 = br + push
	var up := Vector2(0.0, -UPPER_BOX_HEIGHT)
	_add_poly(parent, PackedVector2Array([fl, fr, fr + up, fl + up]), SHELF_EDGE, 20)
	_add_poly(parent, PackedVector2Array([fr, br, br + up, fr + up]), BACKBOARD_SIDE, 19)
	_add_poly(parent, PackedVector2Array([bl + up, br + up, fr + up, fl + up]), SHELF_TOP, 20)
	_add_poly(parent, PackedVector2Array([bl, br, fr, fl]), Color("555c64"), 19)
	_add_poly(parent, PackedVector2Array([bl, br, br + up, bl + up]), Color("4b525a"), 18)
	_add_poly(parent, PackedVector2Array([bl, fl, fl + up, bl + up]), Color("5c636b"), 18)

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

func _create_sand_hidden_faces(parent: Node2D, fl: Vector2, fr: Vector2) -> void:
	var rl: Vector2 = fl + SAND_DEPTH
	var rr: Vector2 = fr + SAND_DEPTH
	var up := Vector2(0.0, -SAND_HEIGHT)
	_add_poly(parent, PackedVector2Array([rl, rr, rr + up, rl + up]), Color("59616a"), 8)
	_add_poly(parent, _face_quad(rl, rr, up, 0.14, 0.86, 0.14, 0.86), Color("444b53"), 9)
	_add_poly(parent, _face_quad(rl, rr, up, 0.24, 0.76, 0.60, 0.66), Color("171c21"), 10)
	_add_poly(parent, _face_quad(rl, rr, up, 0.24, 0.76, 0.72, 0.78), Color("171c21"), 10)
	_add_poly(parent, PackedVector2Array([fl, rl, rl + up, fl + up]), Color("676e76"), 8)

func _create_counter_hidden_faces(parent: Node2D) -> void:
	var box_fl: Vector2 = _upper_box_back_left() + _upper_box_front_vector()
	var box_fr: Vector2 = _upper_box_back_right() + _upper_box_front_vector()
	var span: Vector2 = box_fr - box_fl
	var fl: Vector2 = box_fl + span * 0.12 + Vector2(0.0, -2.0)
	var fr: Vector2 = box_fl + span * 0.88 + Vector2(0.0, -2.0)
	var depth: Vector2 = DEPTH_AXIS * 0.055
	var rl: Vector2 = fl + depth
	var rr: Vector2 = fr + depth
	var up := Vector2(0.0, -8.0)
	_add_poly(parent, PackedVector2Array([rl, rr, rr + up, rl + up]), Color("353c44"), 28)
	_add_poly(parent, _face_quad(rl, rr, up, 0.12, 0.88, 0.24, 0.72), Color("20262d"), 29)
	_add_poly(parent, PackedVector2Array([fl, rl, rl + up, fl + up]), Color("242a30"), 28)

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
