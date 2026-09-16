extends "res://scripts/pachirou_map.gd"

enum BayDirection {
	LEFT_DOWN,
	LEFT_UP,
	RIGHT_UP,
	RIGHT_DOWN,
}

# Direction is now part of the bay API. This commit intentionally renders only
# the approved LEFT_DOWN orientation; no guessed rotated geometry is introduced.
func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()
	_create_complete_bay(Vector2i(7, 6), BayDirection.LEFT_DOWN)

func _create_complete_bay(cell: Vector2i, direction: BayDirection) -> void:
	var unit := Node2D.new()
	unit.name = "COMPLETE_BAY_%s" % _direction_name(direction)
	unit.position = grid_to_world(cell)
	unit.z_index = int(unit.position.y)
	world.add_child(unit)

	var bay := Node2D.new()
	bay.name = "SolidBay"
	bay.position = UNIT_REAR_SHIFT
	unit.add_child(bay)

	# One complete physical definition. Direction-specific projection will be
	# applied at this boundary, never by rebuilding individual equipment pieces.
	_create_complete_frame(bay)
	_create_complete_equipment(bay)

	var stool := Node2D.new()
	stool.name = "Stool"
	stool.position = UNIT_REAR_SHIFT + STOOL_FRONT_OFFSET
	stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)
	unit.add_child(stool)
	_create_stool_geometry(stool)

	_apply_direction(unit, direction)

func _apply_direction(unit: Node2D, direction: BayDirection) -> void:
	match direction:
		BayDirection.LEFT_DOWN:
			# Approved source orientation: exact existing render, no transform.
			pass
		BayDirection.LEFT_UP:
			# Reserved for the first verified quarter-turn projection.
			pass
		BayDirection.RIGHT_UP:
			pass
		BayDirection.RIGHT_DOWN:
			pass

func _direction_name(direction: BayDirection) -> String:
	match direction:
		BayDirection.LEFT_DOWN:
			return "LEFT_DOWN"
		BayDirection.LEFT_UP:
			return "LEFT_UP"
		BayDirection.RIGHT_UP:
			return "RIGHT_UP"
		BayDirection.RIGHT_DOWN:
			return "RIGHT_DOWN"
	return "UNKNOWN"

func _create_complete_frame(parent: Node2D) -> void:
	_create_island_frame(parent)
	_create_base_hidden_faces(parent)
	_create_backboard_hidden_faces(parent)
	_create_upper_box_hidden_faces(parent)

func _create_complete_equipment(parent: Node2D) -> void:
	_create_machine_and_sand(parent)
	_create_data_counter(parent)
	_create_machine_hidden_faces(parent)
	_create_sand_hidden_faces(parent)
	_create_counter_hidden_faces(parent)

func _create_machine_hidden_faces(parent: Node2D) -> void:
	var fl: Vector2 = _equipment_front_left()
	var fr: Vector2 = fl + MACHINE_FRONT_VECTOR
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

func _create_sand_hidden_faces(parent: Node2D) -> void:
	var fl: Vector2 = _equipment_front_left() + MACHINE_FRONT_VECTOR
	var fr: Vector2 = fl + SAND_FRONT_VECTOR
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

func _create_backboard_hidden_faces(parent: Node2D) -> void:
	var front_left: Vector2 = _base_back_left()
	var front_right: Vector2 = _base_back_right()
	var thickness: Vector2 = _board_thickness()
	var rear_left: Vector2 = front_left + thickness
	var rear_right: Vector2 = front_right + thickness
	var up := Vector2(0.0, -BACKBOARD_HEIGHT)
	_add_poly(parent, PackedVector2Array([rear_left, rear_right, rear_right + up, rear_left + up]), Color("4d545c"), 0)
	_add_poly(parent, _face_quad(rear_left, rear_right, up, 0.07, 0.11, 0.06, 0.94), Color("60676f"), 1)
	_add_poly(parent, _face_quad(rear_left, rear_right, up, 0.89, 0.93, 0.06, 0.94), Color("60676f"), 1)
	_add_poly(parent, _face_quad(rear_left, rear_right, up, 0.16, 0.84, 0.18, 0.22), Color("3f464e"), 1)
	_add_poly(parent, _face_quad(rear_left, rear_right, up, 0.16, 0.84, 0.76, 0.80), Color("3f464e"), 1)
	_add_poly(parent, PackedVector2Array([front_left, rear_left, rear_left + up, front_left + up]), BACKBOARD_SIDE, 1)
	_add_poly(parent, PackedVector2Array([front_left + up, front_right + up, rear_right + up, rear_left + up]), Color("747b82"), 2)

func _create_base_hidden_faces(parent: Node2D) -> void:
	var floor_left := Vector2(-32.0, 0.0)
	var floor_front := Vector2(0.0, 16.0)
	var rear_depth: Vector2 = DEPTH_AXIS * BASE_DEPTH_RATIO
	var rear_left: Vector2 = floor_left + rear_depth
	var rear_right: Vector2 = floor_front + rear_depth
	var up := Vector2(0.0, -BASE_HEIGHT)
	_add_poly(parent, PackedVector2Array([rear_left, rear_right, rear_right + up, rear_left + up]), Color("353b41"), -1)
	_add_poly(parent, PackedVector2Array([floor_left, rear_left, rear_left + up, floor_left + up]), Color("454b52"), -1)

func _create_upper_box_hidden_faces(parent: Node2D) -> void:
	var bl: Vector2 = _upper_box_back_left()
	var br: Vector2 = _upper_box_back_right()
	var push: Vector2 = _upper_box_front_vector()
	var fl: Vector2 = bl + push
	var up := Vector2(0.0, -UPPER_BOX_HEIGHT)
	_add_poly(parent, PackedVector2Array([bl, br, br + up, bl + up]), Color("4b525a"), 18)
	_add_poly(parent, PackedVector2Array([bl, fl, fl + up, bl + up]), Color("5c636b"), 19)

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
