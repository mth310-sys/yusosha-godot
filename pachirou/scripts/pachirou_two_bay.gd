extends "res://scripts/pachirou_map.gd"

# Geometry reset.
# Keep one approved LEFT_DOWN bay only. Complete the hidden physical faces first;
# no rotation/direction-specific approximation is allowed in this stage.
func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()
	_create_complete_left_down(Vector2i(7, 6))

func _create_complete_left_down(cell: Vector2i) -> void:
	var unit := Node2D.new()
	unit.name = "COMPLETE_LEFT_DOWN"
	unit.position = grid_to_world(cell)
	unit.z_index = int(unit.position.y)
	world.add_child(unit)

	var bay := Node2D.new()
	bay.name = "Bay"
	bay.position = UNIT_REAR_SHIFT
	unit.add_child(bay)

	# Approved visible geometry. These are the source-of-truth dimensions.
	_create_island_frame(bay)
	_create_machine_and_sand(bay)
	_create_data_counter(bay)

	# Complete the same physical objects on the hidden side using only existing
	# front/depth/height vectors. No guessed dimensions are introduced here.
	_create_machine_rear_face(bay)
	_create_sand_rear_face(bay)
	_create_counter_rear_face(bay)
	_create_backboard_rear_face(bay)

	var stool := Node2D.new()
	stool.name = "Stool"
	stool.position = UNIT_REAR_SHIFT + STOOL_FRONT_OFFSET
	stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)
	unit.add_child(stool)
	_create_stool_geometry(stool)

func _create_machine_rear_face(parent: Node2D) -> void:
	var front_left: Vector2 = _equipment_front_left()
	var front_right: Vector2 = front_left + MACHINE_FRONT_VECTOR
	var rear_left: Vector2 = front_left + MACHINE_DEPTH
	var rear_right: Vector2 = front_right + MACHINE_DEPTH
	var up := Vector2(0.0, -MACHINE_HEIGHT)

	# Rear service panel: same width, same depth endpoint, same height.
	_add_poly(parent, PackedVector2Array([rear_left, rear_right, rear_right + up, rear_left + up]), Color("343b43"), 8)
	_add_poly(parent, _face_quad(rear_left, rear_right, up, 0.10, 0.90, 0.12, 0.88), Color("292f36"), 9)
	_add_poly(parent, _face_quad(rear_left, rear_right, up, 0.18, 0.82, 0.20, 0.40), Color("3e454d"), 9)
	_add_poly(parent, _face_quad(rear_left, rear_right, up, 0.22, 0.78, 0.60, 0.66), Color("151a20"), 10)
	_add_poly(parent, _face_quad(rear_left, rear_right, up, 0.22, 0.78, 0.72, 0.78), Color("151a20"), 10)
	_add_poly(parent, _face_quad(rear_left, rear_right, up, 0.43, 0.57, 0.84, 0.89), Color("777f87"), 10)

func _create_sand_rear_face(parent: Node2D) -> void:
	var front_left: Vector2 = _equipment_front_left() + MACHINE_FRONT_VECTOR
	var front_right: Vector2 = front_left + SAND_FRONT_VECTOR
	var rear_left: Vector2 = front_left + SAND_DEPTH
	var rear_right: Vector2 = front_right + SAND_DEPTH
	var up := Vector2(0.0, -SAND_HEIGHT)

	_add_poly(parent, PackedVector2Array([rear_left, rear_right, rear_right + up, rear_left + up]), Color("59616a"), 8)
	_add_poly(parent, _face_quad(rear_left, rear_right, up, 0.14, 0.86, 0.14, 0.86), Color("444b53"), 9)
	_add_poly(parent, _face_quad(rear_left, rear_right, up, 0.24, 0.76, 0.60, 0.66), Color("171c21"), 10)
	_add_poly(parent, _face_quad(rear_left, rear_right, up, 0.24, 0.76, 0.72, 0.78), Color("171c21"), 10)

func _create_counter_rear_face(parent: Node2D) -> void:
	# Counter rear plane is derived from the existing upper-box span and depth axis.
	var box_front_left: Vector2 = _upper_box_back_left() + _upper_box_front_vector()
	var box_front_right: Vector2 = _upper_box_back_right() + _upper_box_front_vector()
	var span: Vector2 = box_front_right - box_front_left
	var front_left: Vector2 = box_front_left + span * 0.12 + Vector2(0.0, -2.0)
	var front_right: Vector2 = box_front_left + span * 0.88 + Vector2(0.0, -2.0)
	var rear_push: Vector2 = DEPTH_AXIS * 0.055
	var rear_left: Vector2 = front_left + rear_push
	var rear_right: Vector2 = front_right + rear_push
	var up := Vector2(0.0, -8.0)
	_add_poly(parent, PackedVector2Array([rear_left, rear_right, rear_right + up, rear_left + up]), Color("353c44"), 28)
	_add_poly(parent, _face_quad(rear_left, rear_right, up, 0.12, 0.88, 0.24, 0.72), Color("20262d"), 29)

func _create_backboard_rear_face(parent: Node2D) -> void:
	# The approved frame already defines the front plane and board thickness.
	# This closes the opposite plane at exactly that existing thickness.
	var rear_left: Vector2 = _base_back_left() + _board_thickness()
	var rear_right: Vector2 = _base_back_right() + _board_thickness()
	var up := Vector2(0.0, -BACKBOARD_HEIGHT)
	_add_poly(parent, PackedVector2Array([rear_left, rear_right, rear_right + up, rear_left + up]), Color("4d545c"), 0)
	_add_poly(parent, _face_quad(rear_left, rear_right, up, 0.07, 0.11, 0.06, 0.94), Color("60676f"), 1)
	_add_poly(parent, _face_quad(rear_left, rear_right, up, 0.89, 0.93, 0.06, 0.94), Color("60676f"), 1)
	_add_poly(parent, _face_quad(rear_left, rear_right, up, 0.16, 0.84, 0.18, 0.22), Color("3f464e"), 1)
	_add_poly(parent, _face_quad(rear_left, rear_right, up, 0.16, 0.84, 0.76, 0.80), Color("3f464e"), 1)

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
