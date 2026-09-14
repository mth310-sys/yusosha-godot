extends "res://scripts/pachirou_map.gd"

const REAR_SIDE_OFFSET := DEPTH_AXIS * 1.35

func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()

	# Front side: nine finished player-facing bays.
	var bay_cells: Array[Vector2i] = []
	for x in range(2, 11):
		bay_cells.append(Vector2i(x, 5))

	for cell: Vector2i in bay_cells:
		_create_island_bay(cell)
		_create_stool(cell)

	for i in range(bay_cells.size() - 1):
		_mask_inner_right_frame(bay_cells[i], Vector2.ZERO)

	# Rear side: the opposite nine machines are viewed from behind from this camera.
	# This keeps the fixed isometric viewpoint physically coherent instead of showing
	# a second row of front panels facing the same direction.
	for cell: Vector2i in bay_cells:
		_create_rear_island_bay(cell)
		_create_rear_stool(cell)

	for i in range(bay_cells.size() - 1):
		_mask_inner_right_frame(bay_cells[i], REAR_SIDE_OFFSET)

func _create_rear_island_bay(cell: Vector2i) -> void:
	var bay := Node2D.new()
	bay.name = "RearIslandBay"
	bay.position = grid_to_world(cell) + UNIT_REAR_SHIFT + REAR_SIDE_OFFSET
	bay.z_index = int(bay.position.y)
	world.add_child(bay)
	_create_island_frame(bay)
	_create_rear_machine_and_sand(bay)
	_create_rear_data_counter(bay)

func _create_rear_machine_and_sand(parent: Node2D) -> void:
	var machine_lb: Vector2 = _equipment_front_left()
	var machine_fb: Vector2 = machine_lb + MACHINE_FRONT_VECTOR
	var sand_lb: Vector2 = machine_fb
	var sand_fb: Vector2 = sand_lb + SAND_FRONT_VECTOR
	_create_machine_back(parent, machine_lb, machine_fb, MACHINE_DEPTH)
	_create_sand_back(parent, sand_lb, sand_fb, SAND_DEPTH)

func _create_machine_back(parent: Node2D, lb: Vector2, fb: Vector2, depth: Vector2) -> void:
	var up := Vector2(0, -MACHINE_HEIGHT)
	_add_poly(parent, PackedVector2Array([lb, fb, fb + up, lb + up]), Color("343b43"), 10)
	_add_poly(parent, PackedVector2Array([fb, fb + depth, fb + depth + up, fb + up]), Color("242a31"), 10)
	_add_poly(parent, PackedVector2Array([lb + depth + up, fb + depth + up, fb + up, lb + up]), Color("626972"), 10)
	# Rear service panel, vents and lower access cover.
	_add_poly(parent, _face_quad(lb, fb, up, 0.12, 0.88, 0.57, 0.88), Color("272d34"), 11)
	_add_poly(parent, _face_quad(lb, fb, up, 0.20, 0.80, 0.68, 0.72), Color("11161b"), 12)
	_add_poly(parent, _face_quad(lb, fb, up, 0.20, 0.80, 0.77, 0.81), Color("11161b"), 12)
	_add_poly(parent, _face_quad(lb, fb, up, 0.17, 0.83, 0.12, 0.38), Color("2a3037"), 11)
	_add_poly(parent, _face_quad(lb, fb, up, 0.43, 0.57, 0.19, 0.24), Color("798089"), 12)

func _create_sand_back(parent: Node2D, lb: Vector2, fb: Vector2, depth: Vector2) -> void:
	var up := Vector2(0, -SAND_HEIGHT)
	_add_poly(parent, PackedVector2Array([lb, fb, fb + up, lb + up]), Color("59616a"), 10)
	_add_poly(parent, PackedVector2Array([fb, fb + depth, fb + depth + up, fb + up]), Color("3d444c"), 10)
	_add_poly(parent, PackedVector2Array([lb + depth + up, fb + depth + up, fb + up, lb + up]), Color("858b92"), 10)
	_add_poly(parent, _face_quad(lb, fb, up, 0.18, 0.82, 0.58, 0.83), Color("3a4149"), 11)
	_add_poly(parent, _face_quad(lb, fb, up, 0.25, 0.75, 0.66, 0.70), Color("151a20"), 12)
	_add_poly(parent, _face_quad(lb, fb, up, 0.20, 0.80, 0.16, 0.36), Color("454c54"), 11)

func _create_rear_data_counter(parent: Node2D) -> void:
	var box_fl: Vector2 = _upper_box_back_left() + _upper_box_front_vector()
	var box_fr: Vector2 = _upper_box_back_right() + _upper_box_front_vector()
	var box_front_vector: Vector2 = box_fr - box_fl
	var counter_left: Vector2 = box_fl + box_front_vector * 0.12 + Vector2(0, -2.0)
	var counter_right: Vector2 = box_fl + box_front_vector * 0.88 + Vector2(0, -2.0)
	var counter_up := Vector2(0, -8.0)
	var counter_push: Vector2 = -DEPTH_AXIS * 0.055
	_create_front_box(parent, counter_left, counter_right, counter_up, counter_push, Color("353c44"), Color("242a30"), SHELF_EDGE, 30)
	var face_left: Vector2 = counter_left + counter_push
	var face_right: Vector2 = counter_right + counter_push
	_add_poly(parent, _face_quad(face_left, face_right, counter_up, 0.12, 0.88, 0.24, 0.72), Color("20262d"), 31)

func _create_rear_stool(cell: Vector2i) -> void:
	# Reuse the approved stool model, then place it on the opposite player side.
	_create_stool(cell)
	var stool: Node2D = world.get_child(world.get_child_count() - 1) as Node2D
	stool.name = "RearStool"
	stool.position = grid_to_world(cell) + UNIT_REAR_SHIFT + REAR_SIDE_OFFSET - STOOL_FRONT_OFFSET
	stool.z_index = int(stool.position.y)

func _mask_inner_right_frame(cell: Vector2i, row_offset: Vector2) -> void:
	var mask := Node2D.new()
	mask.name = "SharedCenterFrameMask"
	mask.position = grid_to_world(cell) + UNIT_REAR_SHIFT + row_offset
	mask.z_index = int(mask.position.y)
	world.add_child(mask)

	var board_up := Vector2(0, -BACKBOARD_HEIGHT)
	_add_poly(
		mask,
		_face_quad(_base_back_left(), _base_back_right(), board_up, 0.90, 0.995, 0.03, 0.97),
		BACKBOARD,
		3
	)
