extends "res://scripts/pachirou_map.gd"

# Keep the approved LEFT_DOWN bay unchanged and show a separate LEFT_UP bay.
func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()
	_create_locked_left_down(Vector2i(5, 6))
	_create_left_up_test(Vector2i(9, 7))

func _create_locked_left_down(cell: Vector2i) -> void:
	var unit := Node2D.new()
	unit.name = "LockedLeftDownBay"
	unit.position = grid_to_world(cell)
	unit.z_index = int(unit.position.y)
	world.add_child(unit)
	var bay := Node2D.new()
	bay.name = "ApprovedFront"
	bay.position = UNIT_REAR_SHIFT
	unit.add_child(bay)
	_create_island_frame(bay)
	_create_machine_and_sand(bay)
	_create_data_counter(bay)
	_create_hidden_rear_surfaces(bay)
	var stool := Node2D.new()
	stool.name = "ApprovedStool"
	stool.position = UNIT_REAR_SHIFT + STOOL_FRONT_OFFSET
	stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)
	unit.add_child(stool)
	_create_stool_geometry(stool)

# LEFT_DOWN -> 90 degrees left -> LEFT_UP.
# This is deliberately a separate model; the approved source above is untouched.
func _create_left_up_test(cell: Vector2i) -> void:
	var unit := Node2D.new()
	unit.name = "LeftUp90"
	unit.position = grid_to_world(cell)
	unit.z_index = int(unit.position.y)
	world.add_child(unit)
	var bay := Node2D.new()
	bay.name = "LeftUpBay"
	bay.position = Vector2(-UNIT_REAR_SHIFT.x, -UNIT_REAR_SHIFT.y)
	unit.add_child(bay)
	_create_left_up_frame(bay)
	_create_left_up_equipment(bay)
	_create_left_up_counter(bay)
	var stool := Node2D.new()
	stool.name = "LeftUpStool"
	stool.position = bay.position + Vector2(-STOOL_FRONT_OFFSET.x, -STOOL_FRONT_OFFSET.y)
	stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)
	unit.add_child(stool)
	_create_stool_geometry(stool)

func _create_left_up_frame(parent: Node2D) -> void:
	var floor_left := Vector2(32.0, 0.0)
	var floor_front := Vector2(0.0, -16.0)
	var rear_depth := Vector2(-DEPTH_AXIS.x, DEPTH_AXIS.y) * BASE_DEPTH_RATIO
	var floor_back := floor_front + rear_depth
	var up := Vector2(0.0, -BASE_HEIGHT)
	var top_left := floor_left + up
	var top_front := floor_front + up
	var top_back_left := floor_left + rear_depth + up
	var top_back_right := floor_back + up
	_add_poly(parent, PackedVector2Array([floor_left, floor_front, top_front, top_left]), BASE_FRONT, 0)
	_add_poly(parent, PackedVector2Array([floor_front, floor_back, top_back_right, top_front]), BASE_SIDE, 0)
	_add_poly(parent, PackedVector2Array([top_back_left, top_back_right, top_front, top_left]), BASE_TOP, 0)
	var board_up := Vector2(0.0, -BACKBOARD_HEIGHT)
	_add_poly(parent, PackedVector2Array([top_back_left, top_back_right, top_back_right + board_up, top_back_left + board_up]), BACKBOARD, 1)
	_add_poly(parent, _face_quad(top_back_left, top_back_right, board_up, 0.07, 0.11, 0.06, 0.94), Color("565d65"), 2)
	_add_poly(parent, _face_quad(top_back_left, top_back_right, board_up, 0.89, 0.93, 0.06, 0.94), Color("565d65"), 2)
	var box_left := top_back_left + Vector2(0.0, -MACHINE_HEIGHT + 2.0)
	var box_right := top_back_right + Vector2(0.0, -MACHINE_HEIGHT + 2.0)
	var box_push := -rear_depth * 0.48
	var box_up := Vector2(0.0, -UPPER_BOX_HEIGHT)
	_add_poly(parent, PackedVector2Array([box_left + box_push, box_right + box_push, box_right + box_push + box_up, box_left + box_push + box_up]), SHELF_EDGE, 20)
	_add_poly(parent, PackedVector2Array([box_left + box_up, box_right + box_up, box_right + box_push + box_up, box_left + box_push + box_up]), SHELF_TOP, 20)

func _create_left_up_equipment(parent: Node2D) -> void:
	# LEFT_UP shows the physical rear of the same machine/sand pair.
	var machine_lb := Vector2(24.0, -BASE_HEIGHT - 4.0)
	var machine_width := Vector2(-MACHINE_FRONT_VECTOR.x, MACHINE_FRONT_VECTOR.y)
	var sand_width := Vector2(-SAND_FRONT_VECTOR.x, SAND_FRONT_VECTOR.y)
	var depth := Vector2(-MACHINE_DEPTH.x, -MACHINE_DEPTH.y)
	var sand_depth := Vector2(-SAND_DEPTH.x, -SAND_DEPTH.y)
	var machine_fb := machine_lb + machine_width
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

func _create_left_up_counter(parent: Node2D) -> void:
	var left := Vector2(22.0, -BASE_HEIGHT - MACHINE_HEIGHT - 6.0)
	var right := Vector2(0.0, -BASE_HEIGHT - MACHINE_HEIGHT - 17.0)
	var up := Vector2(0.0, -8.0)
	var push := Vector2(-5.0, 2.5)
	_create_front_box(parent, left, right, up, push, Color("353c44"), Color("242a30"), SHELF_EDGE, 30)
	_add_poly(parent, _face_quad(left + push, right + push, up, 0.12, 0.88, 0.24, 0.72), Color("20262d"), 31)

func _create_hidden_rear_surfaces(parent: Node2D) -> void:
	_create_machine_hidden_back(parent)
	_create_sand_hidden_back(parent)
	_create_counter_hidden_back(parent)
	_create_island_hidden_back(parent)

func _create_machine_hidden_back(parent: Node2D) -> void:
	var front_left: Vector2 = _equipment_front_left()
	var front_right: Vector2 = front_left + MACHINE_FRONT_VECTOR
	var back_left: Vector2 = front_left + MACHINE_DEPTH
	var back_right: Vector2 = front_right + MACHINE_DEPTH
	var up := Vector2(0.0, -MACHINE_HEIGHT)
	_add_poly(parent, PackedVector2Array([back_left, back_right, back_right + up, back_left + up]), Color("343b43"), 8)
	_add_poly(parent, _face_quad(back_left, back_right, up, 0.10, 0.90, 0.12, 0.88), Color("292f36"), 9)
	_add_poly(parent, _face_quad(back_left, back_right, up, 0.18, 0.82, 0.20, 0.40), Color("3e454d"), 9)
	_add_poly(parent, _face_quad(back_left, back_right, up, 0.22, 0.78, 0.60, 0.66), Color("151a20"), 10)
	_add_poly(parent, _face_quad(back_left, back_right, up, 0.22, 0.78, 0.72, 0.78), Color("151a20"), 10)
	_add_poly(parent, _face_quad(back_left, back_right, up, 0.43, 0.57, 0.84, 0.89), Color("777f87"), 10)

func _create_sand_hidden_back(parent: Node2D) -> void:
	var machine_front_right: Vector2 = _equipment_front_left() + MACHINE_FRONT_VECTOR
	var front_left: Vector2 = machine_front_right
	var front_right: Vector2 = front_left + SAND_FRONT_VECTOR
	var back_left: Vector2 = front_left + SAND_DEPTH
	var back_right: Vector2 = front_right + SAND_DEPTH
	var up := Vector2(0.0, -SAND_HEIGHT)
	_add_poly(parent, PackedVector2Array([back_left, back_right, back_right + up, back_left + up]), Color("59616a"), 8)
	_add_poly(parent, _face_quad(back_left, back_right, up, 0.14, 0.86, 0.14, 0.86), Color("444b53"), 9)
	_add_poly(parent, _face_quad(back_left, back_right, up, 0.24, 0.76, 0.60, 0.66), Color("171c21"), 10)
	_add_poly(parent, _face_quad(back_left, back_right, up, 0.24, 0.76, 0.72, 0.78), Color("171c21"), 10)

func _create_counter_hidden_back(parent: Node2D) -> void:
	var box_fl: Vector2 = _upper_box_back_left() + _upper_box_front_vector()
	var box_fr: Vector2 = _upper_box_back_right() + _upper_box_front_vector()
	var span: Vector2 = box_fr - box_fl
	var front_left: Vector2 = box_fl + span * 0.12 + Vector2(0.0, -2.0)
	var front_right: Vector2 = box_fl + span * 0.88 + Vector2(0.0, -2.0)
	var rear_push: Vector2 = DEPTH_AXIS * 0.055
	var back_left: Vector2 = front_left + rear_push
	var back_right: Vector2 = front_right + rear_push
	var up := Vector2(0.0, -8.0)
	_add_poly(parent, PackedVector2Array([back_left, back_right, back_right + up, back_left + up]), Color("353c44"), 28)
	_add_poly(parent, _face_quad(back_left, back_right, up, 0.12, 0.88, 0.24, 0.72), Color("20262d"), 29)

func _create_island_hidden_back(parent: Node2D) -> void:
	var board_left: Vector2 = _base_back_left() + _board_thickness()
	var board_right: Vector2 = _base_back_right() + _board_thickness()
	var board_up := Vector2(0.0, -BACKBOARD_HEIGHT)
	_add_poly(parent, PackedVector2Array([board_left, board_right, board_right + board_up, board_left + board_up]), Color("4d545c"), 0)
	_add_poly(parent, _face_quad(board_left, board_right, board_up, 0.07, 0.11, 0.06, 0.94), Color("60676f"), 1)
	_add_poly(parent, _face_quad(board_left, board_right, board_up, 0.89, 0.93, 0.06, 0.94), Color("60676f"), 1)
	_add_poly(parent, _face_quad(board_left, board_right, board_up, 0.16, 0.84, 0.18, 0.22), Color("3f464e"), 1)
	_add_poly(parent, _face_quad(board_left, board_right, board_up, 0.16, 0.84, 0.76, 0.80), Color("3f464e"), 1)

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
