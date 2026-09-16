extends "res://scripts/pachirou_map.gd"

enum BayDirection {
	LEFT_DOWN,
	LEFT_UP,
	RIGHT_UP,
	RIGHT_DOWN,
}

# Direction renderer reset:
# Never transform finished Polygon2D geometry again. Each direction is rendered
# from the same physical dimensions at creation time.
func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()
	_create_complete_bay(Vector2i(5, 6), BayDirection.LEFT_DOWN)
	_create_complete_bay(Vector2i(9, 7), BayDirection.LEFT_UP)

func _create_complete_bay(cell: Vector2i, direction: BayDirection) -> void:
	var unit := Node2D.new()
	unit.name = "COMPLETE_BAY_%s" % _direction_name(direction)
	unit.position = grid_to_world(cell)
	unit.z_index = int(unit.position.y)
	world.add_child(unit)
	match direction:
		BayDirection.LEFT_DOWN:
			_render_left_down(unit)
		BayDirection.LEFT_UP:
			_render_left_up(unit)
		_:
			pass

func _render_left_down(unit: Node2D) -> void:
	var bay := Node2D.new()
	bay.name = "SolidBay"
	bay.position = UNIT_REAR_SHIFT
	unit.add_child(bay)
	_create_complete_frame(bay)
	_create_complete_equipment(bay)
	_create_bay_stool(unit, UNIT_REAR_SHIFT + STOOL_FRONT_OFFSET)

func _render_left_up(unit: Node2D) -> void:
	# LEFT_UP is a dedicated 2D isometric renderer. It does not touch or transform
	# the approved LEFT_DOWN polygons. The logical quarter-turn maps the two ground
	# axes as WIDTH -> LEFT_UP_WIDTH and DEPTH -> LEFT_UP_DEPTH; Z remains vertical.
	var bay := Node2D.new()
	bay.name = "SolidBayLeftUp"
	bay.position = _lu_ground(UNIT_REAR_SHIFT)
	unit.add_child(bay)
	_render_left_up_base_and_board(bay)
	_render_left_up_machine_and_sand(bay)
	_render_left_up_counter(bay)
	_create_bay_stool(unit, _lu_ground(UNIT_REAR_SHIFT + STOOL_FRONT_OFFSET))

# Exact 90-degree-left ground basis from the existing 64x32 diamond.
const LU_WIDTH := Vector2(-32.0, 16.0)
const LU_DEPTH := Vector2(-32.0, -16.0)

func _lu_ground(p: Vector2) -> Vector2:
	# Convert a ground-only screen vector back to approved WIDTH/DEPTH coefficients,
	# then project those same coefficients through the left-up basis.
	var u: float = p.x / 64.0 + p.y / 32.0
	var v: float = p.x / 64.0 - p.y / 32.0
	return LU_WIDTH * u + LU_DEPTH * v

func _render_left_up_base_and_board(parent: Node2D) -> void:
	var a := Vector2(32.0, 0.0)
	var b := Vector2(0.0, 16.0)
	var depth: Vector2 = LU_DEPTH * BASE_DEPTH_RATIO
	var ra: Vector2 = a + depth
	var rb: Vector2 = b + depth
	var up := Vector2(0.0, -BASE_HEIGHT)
	# Closed base: front, both sides, rear and top.
	_add_poly(parent, PackedVector2Array([a, b, b + up, a + up]), BASE_FRONT, 0)
	_add_poly(parent, PackedVector2Array([b, rb, rb + up, b + up]), BASE_SIDE, 0)
	_add_poly(parent, PackedVector2Array([ra, a, a + up, ra + up]), Color("454b52"), -1)
	_add_poly(parent, PackedVector2Array([rb, ra, ra + up, rb + up]), Color("353b41"), -1)
	_add_poly(parent, PackedVector2Array([a + up, b + up, rb + up, ra + up]), BASE_TOP, 0)

	var board_left: Vector2 = ra + up
	var board_right: Vector2 = rb + up
	var board_up := Vector2(0.0, -BACKBOARD_HEIGHT)
	var thick: Vector2 = LU_DEPTH * BACKBOARD_THICKNESS_RATIO
	var board_rear_left: Vector2 = board_left + thick
	var board_rear_right: Vector2 = board_right + thick
	_add_poly(parent, PackedVector2Array([board_left, board_right, board_right + board_up, board_left + board_up]), BACKBOARD, 1)
	_add_poly(parent, PackedVector2Array([board_rear_left, board_left, board_left + board_up, board_rear_left + board_up]), BACKBOARD_SIDE, 1)
	_add_poly(parent, PackedVector2Array([board_rear_left, board_rear_right, board_rear_right + board_up, board_rear_left + board_up]), Color("4d545c"), 0)
	_add_poly(parent, PackedVector2Array([board_left + board_up, board_right + board_up, board_rear_right + board_up, board_rear_left + board_up]), Color("747b82"), 2)

	# Upper equipment box uses the same existing height and forward ratio.
	var box_bl: Vector2 = board_left + Vector2(0.0, -MACHINE_HEIGHT + 2.0)
	var box_br: Vector2 = board_right + Vector2(0.0, -MACHINE_HEIGHT + 2.0)
	var push: Vector2 = -LU_DEPTH * UPPER_BOX_FORWARD_RATIO
	var box_fl: Vector2 = box_bl + push
	var box_fr: Vector2 = box_br + push
	var box_up := Vector2(0.0, -UPPER_BOX_HEIGHT)
	_add_poly(parent, PackedVector2Array([box_fl, box_fr, box_fr + box_up, box_fl + box_up]), SHELF_EDGE, 20)
	_add_poly(parent, PackedVector2Array([box_bl, box_fl, box_fl + box_up, box_bl + box_up]), Color("5c636b"), 19)
	_add_poly(parent, PackedVector2Array([box_bl + box_up, box_br + box_up, box_fr + box_up, box_fl + box_up]), SHELF_TOP, 20)
	_add_poly(parent, PackedVector2Array([box_bl, box_br, box_br + box_up, box_bl + box_up]), Color("4b525a"), 18)

func _render_left_up_machine_and_sand(parent: Node2D) -> void:
	# Same approved widths/depths/heights; only the ground axes change direction.
	var base_left: Vector2 = Vector2(32.0, 0.0) + LU_DEPTH * BASE_DEPTH_RATIO + Vector2(0.0, -BASE_HEIGHT)
	var base_right: Vector2 = Vector2(0.0, 16.0) + LU_DEPTH * BASE_DEPTH_RATIO + Vector2(0.0, -BASE_HEIGHT)
	var front_push: Vector2 = -LU_DEPTH * (BACKBOARD_THICKNESS_RATIO + 0.02)
	var equipment_left: Vector2 = base_left + (base_right - base_left) * 0.08 + front_push
	var machine_width: Vector2 = LU_WIDTH * (MACHINE_FRONT_VECTOR.length() / WIDTH_AXIS.length())
	var sand_width: Vector2 = LU_WIDTH * (SAND_FRONT_VECTOR.length() / WIDTH_AXIS.length())
	var machine_depth: Vector2 = LU_DEPTH * (MACHINE_DEPTH.length() / DEPTH_AXIS.length())
	var sand_depth: Vector2 = LU_DEPTH * (SAND_DEPTH.length() / DEPTH_AXIS.length())
	_create_lu_box(parent, equipment_left, machine_width, machine_depth, MACHINE_HEIGHT, Color("3f464d"), Color("4b525a"), 8)
	_create_lu_machine_front(parent, equipment_left, machine_width, MACHINE_HEIGHT)
	var sand_left: Vector2 = equipment_left + machine_width
	_create_lu_box(parent, sand_left, sand_width, sand_depth, SAND_HEIGHT, Color("59616a"), Color("676e76"), 8)
	_create_lu_sand_front(parent, sand_left, sand_width, SAND_HEIGHT)

func _create_lu_box(parent: Node2D, fl: Vector2, width: Vector2, depth: Vector2, height: float, front_color: Color, side_color: Color, z: int) -> void:
	var fr: Vector2 = fl + width
	var rl: Vector2 = fl + depth
	var rr: Vector2 = fr + depth
	var up := Vector2(0.0, -height)
	_add_poly(parent, PackedVector2Array([fl, fr, fr + up, fl + up]), front_color, z)
	_add_poly(parent, PackedVector2Array([fr, rr, rr + up, fr + up]), side_color, z)
	_add_poly(parent, PackedVector2Array([rl, fl, fl + up, rl + up]), side_color.darkened(0.12), z - 1)
	_add_poly(parent, PackedVector2Array([rl, rr, rr + up, rl + up]), front_color.darkened(0.15), z - 1)
	_add_poly(parent, PackedVector2Array([fl + up, fr + up, rr + up, rl + up]), side_color.lightened(0.08), z + 1)

func _create_lu_machine_front(parent: Node2D, fl: Vector2, width: Vector2, height: float) -> void:
	var fr: Vector2 = fl + width
	var up := Vector2(0.0, -height)
	_add_poly(parent, _face_quad(fl, fr, up, 0.10, 0.90, 0.10, 0.32), Color("20262c"), 12)
	_add_poly(parent, _face_quad(fl, fr, up, 0.17, 0.83, 0.35, 0.64), Color("f2f0df"), 13)
	_add_poly(parent, _face_quad(fl, fr, up, 0.20, 0.80, 0.39, 0.60), Color("ffffff"), 14)
	_add_poly(parent, _face_quad(fl, fr, up, 0.13, 0.87, 0.69, 0.80), Color("161b20"), 13)
	_add_poly(parent, _face_quad(fl, fr, up, 0.24, 0.76, 0.72, 0.77), Color("e53935"), 14)

func _create_lu_sand_front(parent: Node2D, fl: Vector2, width: Vector2, height: float) -> void:
	var fr: Vector2 = fl + width
	var up := Vector2(0.0, -height)
	_add_poly(parent, _face_quad(fl, fr, up, 0.12, 0.88, 0.12, 0.28), Color("11161b"), 13)
	_add_poly(parent, _face_quad(fl, fr, up, 0.20, 0.80, 0.36, 0.43), Color("d7dde1"), 14)
	_add_poly(parent, _face_quad(fl, fr, up, 0.20, 0.80, 0.54, 0.61), Color("1d2329"), 14)

func _render_left_up_counter(parent: Node2D) -> void:
	var base_left: Vector2 = Vector2(32.0, 0.0) + LU_DEPTH * BASE_DEPTH_RATIO + Vector2(0.0, -BASE_HEIGHT)
	var base_right: Vector2 = Vector2(0.0, 16.0) + LU_DEPTH * BASE_DEPTH_RATIO + Vector2(0.0, -BASE_HEIGHT)
	var span: Vector2 = base_right - base_left
	var fl: Vector2 = base_left + span * 0.18 + Vector2(0.0, -MACHINE_HEIGHT - 7.0)
	var fr: Vector2 = base_left + span * 0.82 + Vector2(0.0, -MACHINE_HEIGHT - 7.0)
	var up := Vector2(0.0, -8.0)
	var depth: Vector2 = LU_DEPTH * 0.055
	var rl: Vector2 = fl + depth
	var rr: Vector2 = fr + depth
	_add_poly(parent, PackedVector2Array([fl, fr, fr + up, fl + up]), Color("20262d"), 28)
	_add_poly(parent, PackedVector2Array([fr, rr, rr + up, fr + up]), Color("353c44"), 28)
	_add_poly(parent, _face_quad(fl, fr, up, 0.12, 0.88, 0.24, 0.72), Color("67d7e5"), 29)

func _create_bay_stool(unit: Node2D, position: Vector2) -> void:
	var stool := Node2D.new()
	stool.name = "Stool"
	stool.position = position
	stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)
	unit.add_child(stool)
	_create_stool_geometry(stool)

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
