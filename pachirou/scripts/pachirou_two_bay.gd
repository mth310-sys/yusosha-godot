extends "res://scripts/pachirou_map.gd"

# LEFT_DOWN is the approved source. LEFT_UP is built from the exact same calls.
# Only the two isometric horizontal axes are changed; vertical coordinates stay vertical.
const LEFT_UP_WIDTH_AXIS := Vector2(-32.0, 16.0)
const LEFT_UP_DEPTH_AXIS := Vector2(-32.0, -16.0)

func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()
	_create_locked_left_down(Vector2i(5, 6))
	_create_left_up_from_same_geometry(Vector2i(9, 7))

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

func _create_left_up_from_same_geometry(cell: Vector2i) -> void:
	var unit := Node2D.new()
	unit.name = "SameGeometry_LeftUp"
	unit.position = grid_to_world(cell)
	unit.z_index = int(unit.position.y)
	world.add_child(unit)

	# Generate an exact duplicate first.
	var bay := Node2D.new()
	bay.name = "RotatedApprovedFront"
	bay.position = UNIT_REAR_SHIFT
	unit.add_child(bay)
	_create_island_frame(bay)
	_create_machine_and_sand(bay)
	_create_data_counter(bay)
	_create_hidden_rear_surfaces(bay)

	var stool := Node2D.new()
	stool.name = "RotatedApprovedStool"
	stool.position = UNIT_REAR_SHIFT + STOOL_FRONT_OFFSET
	stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)
	unit.add_child(stool)
	_create_stool_geometry(stool)

	# Convert the exact rendered geometry. The conversion detects the two approved
	# iso ground directions (slope +1/2 and -1/2). Everything else, especially
	# vertical detail, is preserved instead of being guessed from polygon height.
	_rotate_node_exact_left(bay)
	bay.position = _rotate_ground_vector_left(UNIT_REAR_SHIFT)
	stool.position = _rotate_ground_vector_left(UNIT_REAR_SHIFT + STOOL_FRONT_OFFSET)
	_rotate_stool_ground_ellipse(stool)

func _rotate_ground_vector_left(p: Vector2) -> Vector2:
	var u: float = p.x / 64.0 + p.y / 32.0
	var v: float = p.x / 64.0 - p.y / 32.0
	return LEFT_UP_WIDTH_AXIS * u + LEFT_UP_DEPTH_AXIS * v

func _rotate_node_exact_left(node: Node) -> void:
	for child in node.get_children():
		if child is Polygon2D:
			_rotate_polygon_edges_left(child as Polygon2D)
		elif child is Node2D:
			var n2 := child as Node2D
			n2.position = _rotate_ground_vector_left(n2.position)
			_rotate_node_exact_left(n2)

func _rotate_polygon_edges_left(poly: Polygon2D) -> void:
	var pts: PackedVector2Array = poly.polygon
	if pts.size() < 2:
		return
	# Reconstruct the polygon by rotating each edge. Vertical edges remain exactly
	# vertical; the two 2:1 isometric ground slopes are quarter-turned.
	var out := PackedVector2Array()
	out.append(Vector2.ZERO)
	var cursor := Vector2.ZERO
	for i in range(1, pts.size()):
		var edge: Vector2 = pts[i] - pts[i - 1]
		cursor += _rotate_iso_edge_left(edge)
		out.append(cursor)
	# Anchor transformed polygon at the rotated location of its original first point.
	var anchor: Vector2 = _rotate_point_preserve_height(pts[0])
	for i in range(out.size()):
		out[i] += anchor
	poly.polygon = out

func _rotate_iso_edge_left(e: Vector2) -> Vector2:
	if abs(e.x) < 0.001:
		return e
	var slope: float = e.y / e.x
	# Ground width direction: (x, x/2) -> (-x, x/2)
	if abs(slope - 0.5) < 0.035:
		return Vector2(-e.x, e.y)
	# Ground depth direction: (x, -x/2) -> (x, x/2), with sign retained.
	if abs(slope + 0.5) < 0.035:
		return Vector2(e.x, -e.y)
	# Decorative vectors on a vertical face are expressed as horizontal-face span
	# plus vertical displacement. Rotate their horizontal component and preserve z.
	var horizontal_y: float = 0.5 * abs(e.x) * sign(e.y) if abs(e.y) > 0.001 else 0.0
	var vertical_y: float = e.y - horizontal_y
	var rotated_horizontal := Vector2(-e.x, horizontal_y)
	return rotated_horizontal + Vector2(0.0, vertical_y)

func _rotate_point_preserve_height(p: Vector2) -> Vector2:
	# Local polygon anchors are already relative to the bay. Keep their vertical
	# screen component and rotate only the inferred ground component conservatively.
	return Vector2(-p.x, p.y)

func _rotate_stool_ground_ellipse(stool: Node2D) -> void:
	# The stool is rotationally symmetric, so its geometry does not need a redraw;
	# only its physical ground position changes.
	pass

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
