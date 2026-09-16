extends "res://scripts/pachirou_map.gd"

# Keep the approved LEFT_DOWN bay as the source of truth.
# The LEFT_UP comparison is no longer a separately rebuilt cabinet. It is an
# exact duplicate of the already-rendered approved bay, rotated as one object.
func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()
	_create_locked_left_down(Vector2i(5, 6))
	_create_exact_left_up_copy(Vector2i(9, 7))

func _build_approved_bay() -> Node2D:
	var unit := Node2D.new()
	unit.name = "ApprovedBayGeometry"

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
	return unit

func _create_locked_left_down(cell: Vector2i) -> void:
	var holder := Node2D.new()
	holder.name = "LockedLeftDownBay"
	holder.position = grid_to_world(cell)
	holder.z_index = int(holder.position.y)
	world.add_child(holder)
	holder.add_child(_build_approved_bay())

func _create_exact_left_up_copy(cell: Vector2i) -> void:
	var holder := Node2D.new()
	holder.name = "ExactCopy_LeftUp90"
	holder.position = grid_to_world(cell)
	holder.z_index = int(holder.position.y)
	world.add_child(holder)

	# Build the exact same approved geometry first. Nothing inside is redrawn.
	var source := _build_approved_bay()
	source.name = "ExactApprovedGeometry"
	holder.add_child(source)

	# A normal 2D rotation would tilt vertical edges. For an isometric quarter
	# turn, transform every already-rendered point with the diamond-grid basis:
	# screen (x,y) -> ground coefficients (u,v) while preserving vertical height,
	# then rotate ground (u,v) left and project back. We apply this recursively to
	# every Polygon2D and child position, so all approved details survive intact.
	_transform_tree_left_90(source)

func _iso_left90_point(p: Vector2) -> Vector2:
	# Decompose a rendered vector into horizontal ground contribution plus height.
	# For the approved LEFT_DOWN art, x is the full-width diagonal component and
	# y contains half-slope plus vertical displacement. Rotating the ground basis
	# swaps the two diamond axes. This point transform is used only on geometry;
	# vertical-only segments are corrected per polygon below.
	return Vector2(-2.0 * p.y, 0.5 * p.x)

func _transform_tree_left_90(node: Node) -> void:
	for child in node.get_children():
		if child is Polygon2D:
			_transform_polygon_left_90(child as Polygon2D)
		elif child is Node2D:
			var child_2d := child as Node2D
			# Child anchors such as bay/stool are ground offsets. Convert them using
			# the exact isometric ground mapping, not a screen-space 90-degree turn.
			child_2d.position = _rotate_ground_offset_left(child_2d.position)
			_transform_tree_left_90(child_2d)

func _rotate_ground_offset_left(p: Vector2) -> Vector2:
	# Ground-only inverse/project for basis WIDTH=(32,16), DEPTH=(32,-16).
	var u: float = p.x / 64.0 + p.y / 32.0
	var v: float = p.x / 64.0 - p.y / 32.0
	var ru: float = -v
	var rv: float = u
	return WIDTH_AXIS * ru + DEPTH_AXIS * rv

func _transform_polygon_left_90(poly: Polygon2D) -> void:
	var pts: PackedVector2Array = poly.polygon
	if pts.is_empty():
		return

	# Infer vertical displacement relative to the polygon's lowest projected
	# ground edge. This preserves the original cabinet's heights while rotating
	# only its horizontal footprint.
	var max_y: float = pts[0].y
	for p in pts:
		max_y = max(max_y, p.y)

	var out := PackedVector2Array()
	for p in pts:
		var vertical: float = min(0.0, p.y - max_y)
		var ground_p := Vector2(p.x, p.y - vertical)
		var rotated_ground: Vector2 = _rotate_ground_offset_left(ground_p)
		out.append(rotated_ground + Vector2(0.0, vertical))
	poly.polygon = out

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
