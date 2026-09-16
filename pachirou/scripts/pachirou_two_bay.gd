extends "res://scripts/pachirou_map.gd"

# Two-seat direction check only.
# LEFT_DOWN is the approved reference. LEFT_UP uses the same fixed dimensions,
# with front/side/back faces explicitly remapped for a 90-degree left turn.
func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()
	_create_left_down_reference(Vector2i(5, 6))
	_create_left_up_bay(Vector2i(9, 7))

func _create_left_down_reference(cell: Vector2i) -> void:
	var unit := Node2D.new()
	unit.name = "LEFT_DOWN_REFERENCE"
	unit.position = grid_to_world(cell)
	unit.z_index = int(unit.position.y)
	world.add_child(unit)
	var bay := Node2D.new()
	bay.position = UNIT_REAR_SHIFT
	unit.add_child(bay)
	_create_island_frame(bay)
	_create_machine_and_sand(bay)
	_create_data_counter(bay)
	var stool := Node2D.new()
	stool.position = UNIT_REAR_SHIFT + STOOL_FRONT_OFFSET
	stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)
	unit.add_child(stool)
	_create_stool_geometry(stool)

func _create_left_up_bay(cell: Vector2i) -> void:
	var unit := Node2D.new()
	unit.name = "LEFT_UP_90"
	unit.position = grid_to_world(cell)
	unit.z_index = int(unit.position.y)
	world.add_child(unit)
	var bay := Node2D.new()
	bay.position = Vector2(-UNIT_REAR_SHIFT.x, -UNIT_REAR_SHIFT.y)
	unit.add_child(bay)
	_create_left_up_frame(bay)
	_create_left_up_equipment(bay)
	_create_left_up_counter(bay)
	var stool := Node2D.new()
	stool.position = bay.position + Vector2(-STOOL_FRONT_OFFSET.x, -STOOL_FRONT_OFFSET.y)
	stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)
	unit.add_child(stool)
	_create_stool_geometry(stool)

func _mx(p: Vector2) -> Vector2:
	return Vector2(-p.x, p.y)

func _my(p: Vector2) -> Vector2:
	return Vector2(p.x, -p.y)

func _create_left_up_frame(parent: Node2D) -> void:
	# Exact 90-degree face mapping from the established 64x32 footprint.
	var a := _mx(Vector2(-32.0, 0.0))
	var b := _mx(Vector2(0.0, -16.0))
	var rear_depth := _mx(_my(DEPTH_AXIS)) * BASE_DEPTH_RATIO
	var c := b + rear_depth
	var up := Vector2(0.0, -BASE_HEIGHT)
	var ta := a + up
	var tb := b + up
	var tc := c + up
	var td := ta + rear_depth
	_add_poly(parent, PackedVector2Array([a, b, tb, ta]), BASE_FRONT, 0)
	_add_poly(parent, PackedVector2Array([b, c, tc, tb]), BASE_SIDE, 0)
	_add_poly(parent, PackedVector2Array([td, tc, tb, ta]), BASE_TOP, 0)
	# Keep the same base detailing ratios.
	_add_poly(parent, _face_quad(a, b, up, 0.04, 0.96, 0.05, 0.14), Color("3d4349"), 1)
	_add_poly(parent, _face_quad(a, b, up, 0.49, 0.51, 0.16, 0.94), Color("464c53"), 1)
	_add_poly(parent, _face_quad(a, b, up, 0.05, 0.95, 0.91, 0.955), Color("70767d"), 1)
	_add_poly(parent, _face_quad(b, c, up, 0.04, 0.96, 0.05, 0.13), Color("30363c"), 1)

	var board_left := td
	var board_right := tc
	var board_up := Vector2(0.0, -BACKBOARD_HEIGHT)
	var thickness := -rear_depth.normalized() * (DEPTH_AXIS.length() * BACKBOARD_THICKNESS_RATIO)
	_add_poly(parent, PackedVector2Array([board_left, board_right, board_right + board_up, board_left + board_up]), BACKBOARD, 1)
	_add_poly(parent, PackedVector2Array([board_right, board_right + thickness, board_right + thickness + board_up, board_right + board_up]), BACKBOARD_SIDE, 2)
	_add_poly(parent, _face_quad(board_left, board_right, board_up, 0.035, 0.075, 0.04, 0.96), Color("565d65"), 2)
	_add_poly(parent, _face_quad(board_left, board_right, board_up, 0.925, 0.965, 0.04, 0.96), Color("565d65"), 2)
	_add_poly(parent, _face_quad(board_left, board_right, board_up, 0.495, 0.505, 0.04, 0.96), Color("515860"), 2)
	_add_poly(parent, _face_quad(board_left, board_right, board_up, 0.08, 0.92, 0.915, 0.95), Color("7b8289"), 2)

	var box_bl := board_left + Vector2(0.0, -MACHINE_HEIGHT + 2.0)
	var box_br := board_right + Vector2(0.0, -MACHINE_HEIGHT + 2.0)
	var box_push := -rear_depth * UPPER_BOX_FORWARD_RATIO / BASE_DEPTH_RATIO
	var box_fl := box_bl + box_push
	var box_fr := box_br + box_push
	var box_up := Vector2(0.0, -UPPER_BOX_HEIGHT)
	_add_poly(parent, PackedVector2Array([box_fl, box_fr, box_fr + box_up, box_fl + box_up]), SHELF_EDGE, 20)
	_add_poly(parent, PackedVector2Array([box_fr, box_br, box_br + box_up, box_fr + box_up]), BACKBOARD_SIDE, 19)
	_add_poly(parent, PackedVector2Array([box_bl + box_up, box_br + box_up, box_fr + box_up, box_fl + box_up]), SHELF_TOP, 20)
	_add_poly(parent, PackedVector2Array([box_bl, box_br, box_fr, box_fl]), Color("555c64"), 19)

func _create_left_up_equipment(parent: Node2D) -> void:
	# Same machine/sand widths, depths and heights. This view exposes their backs.
	var width := _mx(_my(MACHINE_FRONT_VECTOR))
	var sand_width := _mx(_my(SAND_FRONT_VECTOR))
	var depth := _mx(_my(MACHINE_DEPTH))
	var sand_depth := _mx(_my(SAND_DEPTH))
	var machine_lb := _mx(Vector2(-24.0, -BASE_HEIGHT - 4.0))
	var machine_fb := machine_lb + width
	var sand_lb := machine_fb
	var sand_fb := sand_lb + sand_width
	_create_machine_back(parent, machine_lb, machine_fb, depth)
	_create_sand_back(parent, sand_lb, sand_fb, sand_depth)

func _create_machine_back(parent: Node2D, lb: Vector2, fb: Vector2, depth: Vector2) -> void:
	var up := Vector2(0.0, -MACHINE_HEIGHT)
	_add_poly(parent, PackedVector2Array([lb, fb, fb + up, lb + up]), Color("343b43"), 10)
	_add_poly(parent, PackedVector2Array([fb, fb + depth, fb + depth + up, fb + up]), MACHINE_SIDE, 10)
	_add_poly(parent, PackedVector2Array([lb + depth + up, fb + depth + up, fb + up, lb + up]), MACHINE_TOP, 10)
	_add_poly(parent, _face_quad(lb, fb, up, 0.17, 0.83, 0.12, 0.38), Color("2a3037"), 11)
	_add_poly(parent, _face_quad(lb, fb, up, 0.12, 0.88, 0.56, 0.88), Color("272d34"), 11)
	_add_poly(parent, _face_quad(lb, fb, up, 0.20, 0.80, 0.67, 0.72), Color("11161b"), 12)
	_add_poly(parent, _face_quad(lb, fb, up, 0.20, 0.80, 0.77, 0.82), Color("11161b"), 12)

func _create_sand_back(parent: Node2D, lb: Vector2, fb: Vector2, depth: Vector2) -> void:
	var up := Vector2(0.0, -SAND_HEIGHT)
	_add_poly(parent, PackedVector2Array([lb, fb, fb + up, lb + up]), Color("59616a"), 10)
	_add_poly(parent, PackedVector2Array([fb, fb + depth, fb + depth + up, fb + up]), SAND_SIDE, 10)
	_add_poly(parent, PackedVector2Array([lb + depth + up, fb + depth + up, fb + up, lb + up]), SAND_TOP, 10)
	_add_poly(parent, _face_quad(lb, fb, up, 0.18, 0.82, 0.58, 0.83), Color("3a4149"), 11)

func _create_left_up_counter(parent: Node2D) -> void:
	var left := _mx(Vector2(-22.0, -BASE_HEIGHT - MACHINE_HEIGHT - 6.0))
	var right := _mx(Vector2(0.0, -BASE_HEIGHT - MACHINE_HEIGHT - 17.0))
	var up := Vector2(0.0, -8.0)
	var push := _mx(Vector2(5.0, 2.5))
	_create_front_box(parent, left, right, up, push, Color("353c44"), Color("242a30"), SHELF_EDGE, 30)
	_add_poly(parent, _face_quad(left + push, right + push, up, 0.12, 0.88, 0.24, 0.72), Color("20262d"), 31)

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
