extends "res://scripts/pachirou_map.gd"

# Direction test: the approved LEFT_DOWN model is preserved as the source.
# This file now displays its 90-degree-left floor orientation (RIGHT_DOWN).
# Vertical height is never rotated or inverted.
func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()
	_create_right_down_from_approved(Vector2i(7, 6))

func _rx(p: Vector2) -> Vector2:
	return Vector2(-p.x, p.y)

func _create_right_down_from_approved(cell: Vector2i) -> void:
	var unit := Node2D.new()
	unit.name = "RightDown90Left"
	unit.position = grid_to_world(cell)
	unit.z_index = int(unit.position.y)
	world.add_child(unit)

	var bay := Node2D.new()
	bay.name = "RotatedBay"
	bay.position = _rx(UNIT_REAR_SHIFT)
	unit.add_child(bay)
	_create_rotated_frame(bay)
	_create_rotated_machine_and_sand(bay)
	_create_rotated_counter(bay)
	_create_rotated_hidden_rear(bay)

	var stool := Node2D.new()
	stool.name = "RotatedStool"
	stool.position = _rx(UNIT_REAR_SHIFT + STOOL_FRONT_OFFSET)
	stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)
	unit.add_child(stool)
	_create_stool_geometry(stool)

func _create_rotated_frame(parent: Node2D) -> void:
	var floor_left := _rx(Vector2(-32.0, 0.0))
	var floor_front := _rx(Vector2(0.0, 16.0))
	var floor_back_right := _rx(Vector2(0.0, 16.0) + DEPTH_AXIS * BASE_DEPTH_RATIO)
	var top_left := _rx(_base_top_left())
	var top_front := _rx(_base_top_front())
	var top_back_left := _rx(_base_back_left())
	var top_back_right := _rx(_base_back_right())
	var up := Vector2(0.0, -BASE_HEIGHT)
	_add_poly(parent, PackedVector2Array([floor_left, floor_front, top_front, top_left]), BASE_FRONT, 0)
	_add_poly(parent, PackedVector2Array([floor_front, floor_back_right, top_back_right, top_front]), BASE_SIDE, 0)
	_add_poly(parent, PackedVector2Array([top_back_left, top_back_right, top_front, top_left]), BASE_TOP, 0)
	var board_up := Vector2(0.0, -BACKBOARD_HEIGHT)
	_add_poly(parent, PackedVector2Array([top_back_left, top_back_right, top_back_right + board_up, top_back_left + board_up]), BACKBOARD, 1)
	var thickness := _rx(_board_thickness())
	_add_poly(parent, PackedVector2Array([top_back_right, top_back_right + thickness, top_back_right + thickness + board_up, top_back_right + board_up]), BACKBOARD_SIDE, 2)
	var box_bl := _rx(_upper_box_back_left())
	var box_br := _rx(_upper_box_back_right())
	var box_push := _rx(_upper_box_front_vector())
	var box_fl := box_bl + box_push
	var box_fr := box_br + box_push
	var box_up := Vector2(0.0, -UPPER_BOX_HEIGHT)
	_add_poly(parent, PackedVector2Array([box_fl, box_fr, box_fr + box_up, box_fl + box_up]), SHELF_EDGE, 20)
	_add_poly(parent, PackedVector2Array([box_bl + box_up, box_br + box_up, box_fr + box_up, box_fl + box_up]), SHELF_TOP, 20)

func _create_rotated_machine_and_sand(parent: Node2D) -> void:
	# Rotate each physical footprint from the approved source. Do not swap or
	# reconstruct the pair; their relationship is preserved exactly.
	var machine_lb := _rx(_equipment_front_left())
	var machine_fb := _rx(_equipment_front_left() + MACHINE_FRONT_VECTOR)
	var sand_lb := machine_fb
	var sand_fb := _rx(_equipment_front_left() + MACHINE_FRONT_VECTOR + SAND_FRONT_VECTOR)
	_create_machine(parent, machine_lb, machine_fb, _rx(MACHINE_DEPTH))
	_create_sand(parent, sand_lb, sand_fb, _rx(SAND_DEPTH))

func _create_rotated_counter(parent: Node2D) -> void:
	var box_fl := _rx(_upper_box_back_left() + _upper_box_front_vector())
	var box_fr := _rx(_upper_box_back_right() + _upper_box_front_vector())
	var span := box_fr - box_fl
	var left := box_fl + span * 0.12 + Vector2(0.0, -2.0)
	var right := box_fl + span * 0.88 + Vector2(0.0, -2.0)
	var up := Vector2(0.0, -8.0)
	var push := _rx(-DEPTH_AXIS * 0.055)
	_create_front_box(parent, left, right, up, push, COUNTER_FRONT, COUNTER_SIDE, SHELF_EDGE, 30)
	_add_poly(parent, _face_quad(left + push, right + push, up, 0.12, 0.88, 0.24, 0.72), COUNTER_SCREEN, 31)

func _create_rotated_hidden_rear(parent: Node2D) -> void:
	var machine_front_left := _rx(_equipment_front_left())
	var machine_front_right := _rx(_equipment_front_left() + MACHINE_FRONT_VECTOR)
	var machine_back_left := machine_front_left + _rx(MACHINE_DEPTH)
	var machine_back_right := machine_front_right + _rx(MACHINE_DEPTH)
	var machine_up := Vector2(0.0, -MACHINE_HEIGHT)
	_add_poly(parent, PackedVector2Array([machine_back_left, machine_back_right, machine_back_right + machine_up, machine_back_left + machine_up]), Color("343b43"), 8)
	_add_poly(parent, _face_quad(machine_back_left, machine_back_right, machine_up, 0.10, 0.90, 0.12, 0.88), Color("292f36"), 9)

	var sand_front_left := machine_front_right
	var sand_front_right := _rx(_equipment_front_left() + MACHINE_FRONT_VECTOR + SAND_FRONT_VECTOR)
	var sand_back_left := sand_front_left + _rx(SAND_DEPTH)
	var sand_back_right := sand_front_right + _rx(SAND_DEPTH)
	var sand_up := Vector2(0.0, -SAND_HEIGHT)
	_add_poly(parent, PackedVector2Array([sand_back_left, sand_back_right, sand_back_right + sand_up, sand_back_left + sand_up]), Color("59616a"), 8)
	_add_poly(parent, _face_quad(sand_back_left, sand_back_right, sand_up, 0.14, 0.86, 0.14, 0.86), Color("444b53"), 9)

	var board_left := _rx(_base_back_left() + _board_thickness())
	var board_right := _rx(_base_back_right() + _board_thickness())
	var board_up := Vector2(0.0, -BACKBOARD_HEIGHT)
	_add_poly(parent, PackedVector2Array([board_left, board_right, board_right + board_up, board_left + board_up]), Color("4d545c"), 0)

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
