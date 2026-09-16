extends "res://scripts/pachirou_map.gd"

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
			_create_down_bay(unit, false)
		BayDirection.RIGHT_DOWN:
			_create_down_bay(unit, true)
		BayDirection.RIGHT_UP:
			_create_up_bay(unit, false)
		BayDirection.LEFT_UP:
			_create_up_bay(unit, true)

func _create_down_bay(unit: Node2D, face_right: bool) -> void:
	var content := Node2D.new()
	unit.add_child(content)
	var bay := Node2D.new()
	bay.position = Vector2(-UNIT_REAR_SHIFT.x, UNIT_REAR_SHIFT.y) if face_right else UNIT_REAR_SHIFT
	content.add_child(bay)
	if face_right:
		_create_down_frame_right(bay)
		_create_down_equipment_right(bay)
		_create_down_counter_right(bay)
	else:
		_create_island_frame(bay)
		_create_machine_and_sand(bay)
		_create_data_counter(bay)
	var stool_pos := Vector2(-STOOL_FRONT_OFFSET.x, STOOL_FRONT_OFFSET.y) if face_right else STOOL_FRONT_OFFSET
	_create_local_stool(content, bay.position + stool_pos)

func _create_up_bay(unit: Node2D, face_left: bool) -> void:
	var content := Node2D.new()
	unit.add_child(content)
	var bay := Node2D.new()
	bay.position = Vector2(-UNIT_REAR_SHIFT.x, -UNIT_REAR_SHIFT.y) if face_left else -UNIT_REAR_SHIFT
	content.add_child(bay)
	_create_up_frame(bay, face_left)
	_create_up_equipment(bay, face_left)
	_create_up_counter(bay, face_left)
	var stool_offset := Vector2(STOOL_FRONT_OFFSET.x, -STOOL_FRONT_OFFSET.y)
	if face_left:
		stool_offset.x = -stool_offset.x
	_create_local_stool(content, bay.position + stool_offset)

func _mx(p: Vector2) -> Vector2:
	return Vector2(-p.x, p.y)

func _my(p: Vector2) -> Vector2:
	return Vector2(p.x, -p.y)

func _create_down_frame_right(parent: Node2D) -> void:
	# Horizontal isometric mirror only; vertical height always remains screen-up.
	var floor_left := _mx(Vector2(-32.0, 0.0))
	var floor_front := _mx(Vector2(0.0, 16.0))
	var floor_back_right := _mx(Vector2(0.0, 16.0) + DEPTH_AXIS * BASE_DEPTH_RATIO)
	var top_left := _mx(_base_top_left())
	var top_front := _mx(_base_top_front())
	var top_back_left := _mx(_base_back_left())
	var top_back_right := _mx(_base_back_right())
	var up := Vector2(0.0, -BASE_HEIGHT)
	_add_poly(parent, PackedVector2Array([floor_left, floor_front, top_front, top_left]), BASE_FRONT, 0)
	_add_poly(parent, PackedVector2Array([floor_front, floor_back_right, top_back_right, top_front]), BASE_SIDE, 0)
	_add_poly(parent, PackedVector2Array([top_back_left, top_back_right, top_front, top_left]), BASE_TOP, 0)
	var board_up := Vector2(0.0, -BACKBOARD_HEIGHT)
	_add_poly(parent, PackedVector2Array([top_back_left, top_back_right, top_back_right + board_up, top_back_left + board_up]), BACKBOARD, 1)
	_add_poly(parent, _face_quad(top_back_left, top_back_right, board_up, 0.04, 0.08, 0.04, 0.96), Color("565d65"), 2)
	_add_poly(parent, _face_quad(top_back_left, top_back_right, board_up, 0.92, 0.96, 0.04, 0.96), Color("565d65"), 2)
	var box_bl := _mx(_upper_box_back_left())
	var box_br := _mx(_upper_box_back_right())
	var push := _mx(_upper_box_front_vector())
	var box_fl := box_bl + push
	var box_fr := box_br + push
	var box_up := Vector2(0.0, -UPPER_BOX_HEIGHT)
	_add_poly(parent, PackedVector2Array([box_fl, box_fr, box_fr + box_up, box_fl + box_up]), SHELF_EDGE, 20)
	_add_poly(parent, PackedVector2Array([box_bl + box_up, box_br + box_up, box_fr + box_up, box_fl + box_up]), SHELF_TOP, 20)

func _create_down_equipment_right(parent: Node2D) -> void:
	# Rebuild positions instead of mirroring the completed pair: sand stays on the
	# seated player's right side.
	var left := _mx(_equipment_front_left())
	var width := _mx(MACHINE_FRONT_VECTOR)
	var sand_width := _mx(SAND_FRONT_VECTOR)
	var machine_lb := left - sand_width
	var machine_fb := machine_lb + width
	var sand_fb := machine_lb
	var sand_lb := sand_fb - sand_width
	_create_machine(parent, machine_lb, machine_fb, _mx(MACHINE_DEPTH))
	_create_sand(parent, sand_lb, sand_fb, _mx(SAND_DEPTH))

func _create_down_counter_right(parent: Node2D) -> void:
	var box_fl := _mx(_upper_box_back_left() + _upper_box_front_vector())
	var box_fr := _mx(_upper_box_back_right() + _upper_box_front_vector())
	var span := box_fr - box_fl
	var left := box_fl + span * 0.12 + Vector2(0.0, -2.0)
	var right := box_fl + span * 0.88 + Vector2(0.0, -2.0)
	var up := Vector2(0.0, -8.0)
	var push := _mx(-DEPTH_AXIS * 0.055)
	_create_front_box(parent, left, right, up, push, COUNTER_FRONT, COUNTER_SIDE, SHELF_EDGE, 30)
	var fl := left + push
	var fr := right + push
	_add_poly(parent, _face_quad(fl, fr, up, 0.12, 0.88, 0.24, 0.72), COUNTER_SCREEN, 31)

func _create_up_frame(parent: Node2D, face_left: bool) -> void:
	# True opposite floor orientation: reverse depth/front on the floor plane while
	# every vertical extrusion still uses negative screen Y.
	var a := Vector2(-32.0, 0.0)
	var b := Vector2(0.0, -16.0)
	var rear_depth := _my(DEPTH_AXIS) * BASE_DEPTH_RATIO
	var c := b + rear_depth
	if face_left:
		a = _mx(a)
		b = _mx(b)
		c = _mx(c)
	var up := Vector2(0.0, -BASE_HEIGHT)
	var ta := a + up
	var tb := b + up
	var tc := c + up
	_add_poly(parent, PackedVector2Array([a, b, tb, ta]), BASE_FRONT, 0)
	_add_poly(parent, PackedVector2Array([b, c, tc, tb]), BASE_SIDE, 0)
	_add_poly(parent, PackedVector2Array([ta, tb, tc, ta + (tc - tb)]), BASE_TOP, 0)
	var board_left := ta + rear_depth
	var board_right := tb + rear_depth
	var board_up := Vector2(0.0, -BACKBOARD_HEIGHT)
	_add_poly(parent, PackedVector2Array([board_left, board_right, board_right + board_up, board_left + board_up]), BACKBOARD, 1)
	_add_poly(parent, _face_quad(board_left, board_right, board_up, 0.08, 0.92, 0.10, 0.90), Color("565d65"), 2)
	var box_left := board_left + Vector2(0.0, -MACHINE_HEIGHT + 2.0)
	var box_right := board_right + Vector2(0.0, -MACHINE_HEIGHT + 2.0)
	var box_push := -rear_depth * 0.48
	var box_up := Vector2(0.0, -UPPER_BOX_HEIGHT)
	_add_poly(parent, PackedVector2Array([box_left + box_push, box_right + box_push, box_right + box_push + box_up, box_left + box_push + box_up]), SHELF_EDGE, 20)
	_add_poly(parent, PackedVector2Array([box_left + box_up, box_right + box_up, box_right + box_push + box_up, box_left + box_push + box_up]), SHELF_TOP, 20)

func _up_equipment_left(face_left: bool) -> Vector2:
	var p := Vector2(-24.0, -BASE_HEIGHT - 4.0)
	return _mx(p) if face_left else p

func _create_up_equipment(parent: Node2D, face_left: bool) -> void:
	var width := _my(MACHINE_FRONT_VECTOR)
	var sand_width := _my(SAND_FRONT_VECTOR)
	var depth := _my(MACHINE_DEPTH)
	var sand_depth := _my(SAND_DEPTH)
	var start := _up_equipment_left(face_left)
	if face_left:
		width = _mx(width)
		sand_width = _mx(sand_width)
		depth = _mx(depth)
		sand_depth = _mx(sand_depth)
	# Back-view ordering is derived from player-right sand placement, not from a
	# screen-side guess.
	var machine_lb := start
	var machine_fb := machine_lb + width
	var sand_lb := machine_fb
	var sand_fb := sand_lb + sand_width
	_create_machine_back(parent, machine_lb, machine_fb, depth)
	_create_sand_back(parent, sand_lb, sand_fb, sand_depth)

func _create_machine_back(parent: Node2D, lb: Vector2, fb: Vector2, depth: Vector2) -> void:
	var up := Vector2(0.0, -MACHINE_HEIGHT)
	_add_poly(parent, PackedVector2Array([lb, fb, fb + up, lb + up]), Color("343b43"), 10)
	_add_poly(parent, PackedVector2Array([fb, fb + depth, fb + depth + up, fb + up]), Color("242a31"), 10)
	_add_poly(parent, PackedVector2Array([lb + depth + up, fb + depth + up, fb + up, lb + up]), Color("626972"), 10)
	_add_poly(parent, _face_quad(lb, fb, up, 0.12, 0.88, 0.56, 0.88), Color("272d34"), 11)
	_add_poly(parent, _face_quad(lb, fb, up, 0.20, 0.80, 0.67, 0.72), Color("11161b"), 12)
	_add_poly(parent, _face_quad(lb, fb, up, 0.20, 0.80, 0.77, 0.82), Color("11161b"), 12)
	_add_poly(parent, _face_quad(lb, fb, up, 0.17, 0.83, 0.12, 0.38), Color("2a3037"), 11)

func _create_sand_back(parent: Node2D, lb: Vector2, fb: Vector2, depth: Vector2) -> void:
	var up := Vector2(0.0, -SAND_HEIGHT)
	_add_poly(parent, PackedVector2Array([lb, fb, fb + up, lb + up]), Color("59616a"), 10)
	_add_poly(parent, PackedVector2Array([fb, fb + depth, fb + depth + up, fb + up]), Color("3d444c"), 10)
	_add_poly(parent, PackedVector2Array([lb + depth + up, fb + depth + up, fb + up, lb + up]), Color("858b92"), 10)
	_add_poly(parent, _face_quad(lb, fb, up, 0.18, 0.82, 0.58, 0.83), Color("3a4149"), 11)

func _create_up_counter(parent: Node2D, face_left: bool) -> void:
	var left := Vector2(-22.0, -BASE_HEIGHT - MACHINE_HEIGHT - 6.0)
	var right := Vector2(0.0, -BASE_HEIGHT - MACHINE_HEIGHT - 17.0)
	if face_left:
		left = _mx(left)
		right = _mx(right)
	var up := Vector2(0.0, -8.0)
	var push := Vector2(5.0, 2.5)
	if face_left:
		push = _mx(push)
	_create_front_box(parent, left, right, up, push, Color("353c44"), Color("242a30"), SHELF_EDGE, 30)
	_add_poly(parent, _face_quad(left + push, right + push, up, 0.12, 0.88, 0.24, 0.72), Color("20262d"), 31)

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
