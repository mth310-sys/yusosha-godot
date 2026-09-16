extends "res://scripts/pachirou_map.gd"

# Four player-facing directions. Down directions show the player-facing front;
# up directions show the cabinet/sand backs from the fixed isometric camera.
enum BayDirection {
	LEFT_DOWN,
	RIGHT_DOWN,
	RIGHT_UP,
	LEFT_UP,
}

func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()

	_create_direction_test(Vector2i(4, 4), BayDirection.LEFT_DOWN)
	_create_direction_test(Vector2i(9, 4), BayDirection.RIGHT_DOWN)
	_create_direction_test(Vector2i(9, 9), BayDirection.RIGHT_UP)
	_create_direction_test(Vector2i(4, 9), BayDirection.LEFT_UP)

func _create_direction_test(cell: Vector2i, direction: BayDirection) -> void:
	var unit := Node2D.new()
	unit.name = "Direction_%s" % BayDirection.keys()[direction]
	unit.position = grid_to_world(cell)
	unit.z_index = int(unit.position.y)
	world.add_child(unit)

	match direction:
		BayDirection.LEFT_DOWN:
			_create_front_bay(unit, false)
		BayDirection.RIGHT_DOWN:
			_create_front_bay(unit, true)
		BayDirection.RIGHT_UP:
			_create_rear_bay(unit, false)
		BayDirection.LEFT_UP:
			_create_rear_bay(unit, true)

func _create_front_bay(unit: Node2D, mirror_x: bool) -> void:
	var content := Node2D.new()
	content.name = "FrontBay"
	unit.add_child(content)
	if mirror_x:
		content.scale = Vector2(-1.0, 1.0)

	var bay := Node2D.new()
	bay.position = UNIT_REAR_SHIFT
	content.add_child(bay)
	_create_island_frame(bay)
	_create_machine_and_sand(bay)
	_create_data_counter(bay)
	_create_local_stool(content, UNIT_REAR_SHIFT + STOOL_FRONT_OFFSET)

func _create_rear_bay(unit: Node2D, mirror_x: bool) -> void:
	var content := Node2D.new()
	content.name = "RearBay"
	unit.add_child(content)
	if mirror_x:
		content.scale = Vector2(-1.0, 1.0)

	# Keep screen-up vertical geometry intact. Only the horizontal isometric
	# orientation is mirrored; no Y-scale inversion is used anywhere.
	var bay := Node2D.new()
	bay.position = UNIT_REAR_SHIFT
	content.add_child(bay)
	_create_rear_frame(bay)
	_create_rear_machine_and_sand(bay)
	_create_rear_counter(bay)

	# For an up-facing player, the stool is on the opposite floor side.
	_create_local_stool(content, UNIT_REAR_SHIFT - STOOL_FRONT_OFFSET)

func _create_rear_frame(parent: Node2D) -> void:
	# Rear-view carcass: same physical footprint, with the visible rear service
	# face instead of reusing/flipping the player-facing artwork vertically.
	var floor_left := Vector2(-32.0, 0.0)
	var floor_front := Vector2(0.0, 16.0)
	var floor_back_right: Vector2 = floor_front + DEPTH_AXIS * BASE_DEPTH_RATIO
	var top_left: Vector2 = _base_top_left()
	var top_front: Vector2 = _base_top_front()
	var top_back_left: Vector2 = _base_back_left()
	var top_back_right: Vector2 = _base_back_right()
	var base_up := Vector2(0.0, -BASE_HEIGHT)
	_add_poly(parent, PackedVector2Array([floor_left, floor_front, top_front, top_left]), BASE_FRONT, 0)
	_add_poly(parent, PackedVector2Array([floor_front, floor_back_right, top_back_right, top_front]), BASE_SIDE, 0)
	_add_poly(parent, PackedVector2Array([top_back_left, top_back_right, top_front, top_left]), BASE_TOP, 0)
	_add_poly(parent, _face_quad(floor_left, floor_front, base_up, 0.08, 0.92, 0.08, 0.16), Color("3d4349"), 1)
	_add_poly(parent, _face_quad(floor_left, floor_front, base_up, 0.14, 0.86, 0.28, 0.78), Color("464c53"), 1)

	var board_up := Vector2(0.0, -BACKBOARD_HEIGHT)
	_add_poly(parent, PackedVector2Array([top_back_left, top_back_right, top_back_right + board_up, top_back_left + board_up]), BACKBOARD, 1)
	_add_poly(parent, _face_quad(top_back_left, top_back_right, board_up, 0.08, 0.92, 0.10, 0.90), Color("565d65"), 2)
	_add_poly(parent, _face_quad(top_back_left, top_back_right, board_up, 0.16, 0.84, 0.18, 0.82), Color("60676f"), 2)

	var box_bl: Vector2 = _upper_box_back_left()
	var box_br: Vector2 = _upper_box_back_right()
	var box_push: Vector2 = _upper_box_front_vector()
	var box_fl: Vector2 = box_bl + box_push
	var box_fr: Vector2 = box_br + box_push
	var box_up := Vector2(0.0, -UPPER_BOX_HEIGHT)
	_add_poly(parent, PackedVector2Array([box_fl, box_fr, box_fr + box_up, box_fl + box_up]), SHELF_EDGE, 20)
	_add_poly(parent, PackedVector2Array([box_bl + box_up, box_br + box_up, box_fr + box_up, box_fl + box_up]), SHELF_TOP, 20)

func _create_rear_machine_and_sand(parent: Node2D) -> void:
	var machine_lb: Vector2 = _equipment_front_left()
	var machine_fb: Vector2 = machine_lb + MACHINE_FRONT_VECTOR
	var sand_lb: Vector2 = machine_fb
	var sand_fb: Vector2 = sand_lb + SAND_FRONT_VECTOR
	_create_machine_back(parent, machine_lb, machine_fb, MACHINE_DEPTH)
	_create_sand_back(parent, sand_lb, sand_fb, SAND_DEPTH)

func _create_machine_back(parent: Node2D, lb: Vector2, fb: Vector2, depth: Vector2) -> void:
	var up := Vector2(0.0, -MACHINE_HEIGHT)
	_add_poly(parent, PackedVector2Array([lb, fb, fb + up, lb + up]), Color("343b43"), 10)
	_add_poly(parent, PackedVector2Array([fb, fb + depth, fb + depth + up, fb + up]), Color("242a31"), 10)
	_add_poly(parent, PackedVector2Array([lb + depth + up, fb + depth + up, fb + up, lb + up]), Color("626972"), 10)
	_add_poly(parent, _face_quad(lb, fb, up, 0.12, 0.88, 0.56, 0.88), Color("272d34"), 11)
	_add_poly(parent, _face_quad(lb, fb, up, 0.20, 0.80, 0.67, 0.72), Color("11161b"), 12)
	_add_poly(parent, _face_quad(lb, fb, up, 0.20, 0.80, 0.77, 0.82), Color("11161b"), 12)
	_add_poly(parent, _face_quad(lb, fb, up, 0.17, 0.83, 0.12, 0.38), Color("2a3037"), 11)
	_add_poly(parent, _face_quad(lb, fb, up, 0.43, 0.57, 0.19, 0.24), Color("798089"), 12)

func _create_sand_back(parent: Node2D, lb: Vector2, fb: Vector2, depth: Vector2) -> void:
	var up := Vector2(0.0, -SAND_HEIGHT)
	_add_poly(parent, PackedVector2Array([lb, fb, fb + up, lb + up]), Color("59616a"), 10)
	_add_poly(parent, PackedVector2Array([fb, fb + depth, fb + depth + up, fb + up]), Color("3d444c"), 10)
	_add_poly(parent, PackedVector2Array([lb + depth + up, fb + depth + up, fb + up, lb + up]), Color("858b92"), 10)
	_add_poly(parent, _face_quad(lb, fb, up, 0.18, 0.82, 0.58, 0.83), Color("3a4149"), 11)
	_add_poly(parent, _face_quad(lb, fb, up, 0.25, 0.75, 0.66, 0.70), Color("151a20"), 12)
	_add_poly(parent, _face_quad(lb, fb, up, 0.20, 0.80, 0.16, 0.36), Color("454c54"), 11)

func _create_rear_counter(parent: Node2D) -> void:
	var box_fl: Vector2 = _upper_box_back_left() + _upper_box_front_vector()
	var box_fr: Vector2 = _upper_box_back_right() + _upper_box_front_vector()
	var span: Vector2 = box_fr - box_fl
	var left: Vector2 = box_fl + span * 0.12 + Vector2(0.0, -2.0)
	var right: Vector2 = box_fl + span * 0.88 + Vector2(0.0, -2.0)
	var up := Vector2(0.0, -8.0)
	var push: Vector2 = -DEPTH_AXIS * 0.055
	_create_front_box(parent, left, right, up, push, Color("353c44"), Color("242a30"), SHELF_EDGE, 30)
	var face_left: Vector2 = left + push
	var face_right: Vector2 = right + push
	_add_poly(parent, _face_quad(face_left, face_right, up, 0.12, 0.88, 0.24, 0.72), Color("20262d"), 31)

func _create_local_stool(parent: Node2D, position: Vector2) -> void:
	var stool := Node2D.new()
	stool.name = "Stool"
	stool.position = position
	stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)
	parent.add_child(stool)
	_create_stool_geometry(stool)

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
	_add_poly(stool, _ellipse(Vector2(-1.2, seat_y - 2.0), 7.8, 2.2, 26), Color("59616b"), 8)
