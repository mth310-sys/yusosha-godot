extends "res://scripts/pachirou_map.gd"

const PACHISLOT_BAY_SCENE := preload("res://items/pachislot_bay.tscn")
const PACHISLOT_MACHINE_SCENE := preload("res://items/pachislot_machine.tscn")

const ISLAND_LOCAL_SHIFT := Vector2(6.0, -3.0)
const MACHINE_SLOT_LEFT := Vector2(-22.0, -36.15)
const SAND_SLOT_LEFT := Vector2(-1.5, -25.9)

var placement_grid: IsometricGrid

func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	placement_grid = IsometricGrid.new(map_width, map_height, tile_width, tile_height)
	_create_floor()
	# Reference, empty reference, then the same empty island set turned one
	# logical quarter-turn without changing the item's cell-origin contract.
	_create_bay_item(Vector2i(5, 7), PachislotBayItem.Direction.LEFT_DOWN, true)
	_create_bay_item(Vector2i(6, 7), PachislotBayItem.Direction.LEFT_DOWN, false)
	_create_bay_item(Vector2i(8, 7), PachislotBayItem.Direction.LEFT_UP, false)

func _create_bay_item(cell: Vector2i, direction: PachislotBayItem.Direction, with_machine: bool = false) -> void:
	var item := PACHISLOT_BAY_SCENE.instantiate() as PachislotBayItem
	world.add_child(item)
	if not item.setup(placement_grid, cell, direction, _render_bay_item):
		item.queue_free()
		return
	item.build()
	if with_machine:
		_install_standard_machine(item)

func _install_standard_machine(item: PachislotBayItem) -> void:
	var machine_item := PACHISLOT_MACHINE_SCENE.instantiate() as PachislotMachineItem
	if not item.install_machine(machine_item):
		machine_item.queue_free()
		return
	machine_item.setup("standard_a", _render_standard_machine)

func _render_bay_item(item: PachislotBayItem, direction: PachislotBayItem.Direction) -> void:
	match direction:
		PachislotBayItem.Direction.LEFT_DOWN:
			_render_left_down_island_set(item)
		PachislotBayItem.Direction.LEFT_UP:
			_render_left_up_island_set(item)

func _prepare_item_layers(item: PachislotBayItem) -> void:
	item.frame.z_index = 0
	item.machine_slot.z_index = 20
	item.equipment.z_index = 30
	item.sand.z_index = 2
	item.data_counter.z_index = 3
	item.stool.z_index = 40
	item.stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)

func _render_left_down_island_set(item: PachislotBayItem) -> void:
	item.frame.position = ISLAND_LOCAL_SHIFT
	item.equipment.position = ISLAND_LOCAL_SHIFT
	item.machine_slot.position = ISLAND_LOCAL_SHIFT
	item.stool.position = ISLAND_LOCAL_SHIFT + STOOL_FRONT_OFFSET
	_prepare_item_layers(item)
	_create_island_base_item(item.island_base)
	_create_backboard_item(item.back_board)
	_create_upper_box_item(item.upper_box)
	var sand_lb: Vector2 = SAND_SLOT_LEFT
	var sand_fb: Vector2 = sand_lb + SAND_FRONT_VECTOR
	_create_sand(item.sand, sand_lb, sand_fb, SAND_DEPTH)
	_create_sand_hidden_faces(item.sand, sand_lb, sand_fb)
	_create_data_counter(item.data_counter)
	_create_counter_hidden_faces(item.data_counter)
	_create_stool_geometry(item.stool)

func _render_left_up_island_set(item: PachislotBayItem) -> void:
	# LEFT_UP is a logical 90-degree turn. Ground vectors rotate in grid space;
	# vertical height stays screen-vertical. No Polygon2D screen rotation is used.
	var shift: Vector2 = _quarter_turn_ccw_ground(ISLAND_LOCAL_SHIFT)
	item.frame.position = shift
	item.equipment.position = shift
	item.machine_slot.position = shift
	item.stool.position = shift + _quarter_turn_ccw_ground(STOOL_FRONT_OFFSET)
	_prepare_item_layers(item)

	var front_axis := DEPTH_AXIS
	var depth_axis := -WIDTH_AXIS
	_create_directional_base(item.island_base, front_axis, depth_axis)
	_create_directional_backboard(item.back_board, front_axis, depth_axis)
	_create_directional_upper_box(item.upper_box, front_axis, depth_axis)
	_create_directional_sand(item.sand, front_axis, depth_axis)
	_create_directional_counter(item.data_counter, front_axis, depth_axis)
	_create_stool_geometry(item.stool)

func _quarter_turn_ccw_ground(p: Vector2) -> Vector2:
	return Vector2(-2.0 * p.y, p.x * 0.5)

func _directional_base_points(front_axis: Vector2, depth_axis: Vector2) -> Array[Vector2]:
	var left: Vector2 = -front_axis * 0.5
	var front: Vector2 = front_axis * 0.5
	var depth: Vector2 = depth_axis * BASE_DEPTH_RATIO
	return [left, front, left + depth, front + depth]

func _create_directional_base(parent: Node2D, front_axis: Vector2, depth_axis: Vector2) -> void:
	var p := _directional_base_points(front_axis, depth_axis)
	var fl: Vector2 = p[0]
	var fr: Vector2 = p[1]
	var rl: Vector2 = p[2]
	var rr: Vector2 = p[3]
	var up := Vector2(0.0, -BASE_HEIGHT)
	_add_poly(parent, PackedVector2Array([fl, fr, fr + up, fl + up]), BASE_FRONT, 0)
	_add_poly(parent, PackedVector2Array([fr, rr, rr + up, fr + up]), BASE_SIDE, 0)
	_add_poly(parent, PackedVector2Array([rl + up, rr + up, fr + up, fl + up]), BASE_TOP, 0)
	_add_poly(parent, _face_quad(fl, fr, up, 0.04, 0.96, 0.05, 0.14), Color("3d4349"), 1)
	_add_poly(parent, _face_quad(fl, fr, up, 0.49, 0.51, 0.16, 0.94), Color("464c53"), 1)
	_add_poly(parent, _face_quad(fl, fr, up, 0.05, 0.95, 0.91, 0.955), Color("70767d"), 1)
	_add_poly(parent, PackedVector2Array([rl, rr, rr + up, rl + up]), Color("353b41"), -2)
	_add_poly(parent, PackedVector2Array([fl, rl, rl + up, fl + up]), Color("454b52"), -2)

func _directional_board_front(front_axis: Vector2, depth_axis: Vector2) -> Array[Vector2]:
	var p := _directional_base_points(front_axis, depth_axis)
	var up_base := Vector2(0.0, -BASE_HEIGHT)
	var board_push: Vector2 = -depth_axis * BACKBOARD_THICKNESS_RATIO
	return [p[2] + up_base + board_push, p[3] + up_base + board_push]

func _create_directional_backboard(parent: Node2D, front_axis: Vector2, depth_axis: Vector2) -> void:
	var b := _directional_board_front(front_axis, depth_axis)
	var fl: Vector2 = b[0]
	var fr: Vector2 = b[1]
	var thickness: Vector2 = -depth_axis * BACKBOARD_THICKNESS_RATIO
	var up := Vector2(0.0, -BACKBOARD_HEIGHT)
	_add_poly(parent, PackedVector2Array([fl, fr, fr + up, fl + up]), BACKBOARD, 1)
	_add_poly(parent, PackedVector2Array([fr, fr + thickness, fr + thickness + up, fr + up]), BACKBOARD_SIDE, 2)
	_add_poly(parent, _face_quad(fl, fr, up, 0.035, 0.075, 0.04, 0.96), Color("565d65"), 2)
	_add_poly(parent, _face_quad(fl, fr, up, 0.925, 0.965, 0.04, 0.96), Color("565d65"), 2)
	_add_poly(parent, _face_quad(fl, fr, up, 0.495, 0.505, 0.04, 0.96), Color("515860"), 2)
	_add_poly(parent, _face_quad(fl, fr, up, 0.08, 0.92, 0.915, 0.95), Color("7b8289"), 2)

func _directional_upper_box_points(front_axis: Vector2, depth_axis: Vector2) -> Array[Vector2]:
	var b := _directional_board_front(front_axis, depth_axis)
	var rise := Vector2(0.0, -MACHINE_HEIGHT + 2.0)
	var bl: Vector2 = b[0] + rise
	var br: Vector2 = b[1] + rise
	var push: Vector2 = -depth_axis * UPPER_BOX_FORWARD_RATIO
	return [bl, br, bl + push, br + push]

func _create_directional_upper_box(parent: Node2D, front_axis: Vector2, depth_axis: Vector2) -> void:
	var p := _directional_upper_box_points(front_axis, depth_axis)
	var bl: Vector2 = p[0]
	var br: Vector2 = p[1]
	var fl: Vector2 = p[2]
	var fr: Vector2 = p[3]
	var up := Vector2(0.0, -UPPER_BOX_HEIGHT)
	_add_poly(parent, PackedVector2Array([fl, fr, fr + up, fl + up]), SHELF_EDGE, 20)
	_add_poly(parent, PackedVector2Array([fr, br, br + up, fr + up]), BACKBOARD_SIDE, 19)
	_add_poly(parent, PackedVector2Array([bl + up, br + up, fr + up, fl + up]), SHELF_TOP, 20)

func _directional_equipment_left(front_axis: Vector2, depth_axis: Vector2) -> Vector2:
	var ratio: float = (MACHINE_FRONT_VECTOR.x + SAND_FRONT_VECTOR.x) / WIDTH_AXIS.x
	var margin: float = (1.0 - ratio) * 0.5
	var base_left: Vector2 = -front_axis * 0.5 + Vector2(0.0, -BASE_HEIGHT)
	return base_left + front_axis * margin + depth_axis * 0.08

func _create_directional_sand(parent: Node2D, front_axis: Vector2, depth_axis: Vector2) -> void:
	var unit_front: Vector2 = front_axis.normalized() * SAND_FRONT_VECTOR.length()
	var machine_front: Vector2 = front_axis.normalized() * MACHINE_FRONT_VECTOR.length()
	var lb: Vector2 = _directional_equipment_left(front_axis, depth_axis) + machine_front
	var fb: Vector2 = lb + unit_front
	var depth: Vector2 = depth_axis.normalized() * SAND_DEPTH.length()
	_create_sand(parent, lb, fb, depth)
	var rl: Vector2 = lb + depth
	var rr: Vector2 = fb + depth
	var up := Vector2(0.0, -SAND_HEIGHT)
	_add_poly(parent, PackedVector2Array([rl, rr, rr + up, rl + up]), Color("59616a"), 8)

func _create_directional_counter(parent: Node2D, front_axis: Vector2, depth_axis: Vector2) -> void:
	var p := _directional_upper_box_points(front_axis, depth_axis)
	var fl: Vector2 = p[2]
	var fr: Vector2 = p[3]
	var span: Vector2 = fr - fl
	var left: Vector2 = fl + span * 0.12 + Vector2(0.0, -2.0)
	var right: Vector2 = fl + span * 0.88 + Vector2(0.0, -2.0)
	var up := Vector2(0.0, -8.0)
	var push: Vector2 = -depth_axis * 0.055
	_create_front_box(parent, left, right, up, push, COUNTER_FRONT, COUNTER_SIDE, SHELF_EDGE, 30)
	var face_left: Vector2 = left + push
	var face_right: Vector2 = right + push
	_add_poly(parent, _face_quad(face_left, face_right, up, 0.075, 0.925, 0.12, 0.86), Color("4d5964"), 32)
	_add_poly(parent, _face_quad(face_left, face_right, up, 0.105, 0.895, 0.18, 0.78), COUNTER_SCREEN, 33)

func _render_standard_machine(machine_item: PachislotMachineItem) -> void:
	var machine_lb: Vector2 = MACHINE_SLOT_LEFT
	var machine_fb: Vector2 = machine_lb + MACHINE_FRONT_VECTOR
	_create_machine(machine_item, machine_lb, machine_fb, MACHINE_DEPTH)
	_create_machine_hidden_faces(machine_item, machine_lb, machine_fb)

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
