extends "res://scripts/pachirou_map.gd"

func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()

	var bay_cells: Array[Vector2i] = [
		Vector2i(6, 4),
		Vector2i(7, 4),
		Vector2i(8, 4),
	]
	for cell: Vector2i in bay_cells:
		_create_island_bay(cell)
		_create_stool(cell)

	# Every internal joint keeps only the next bay's left frame. Mask the
	# preceding bay's right frame so three or more bays still read as one island.
	for i in range(bay_cells.size() - 1):
		_mask_inner_right_frame(bay_cells[i])

func _mask_inner_right_frame(cell: Vector2i) -> void:
	var mask := Node2D.new()
	mask.name = "SharedCenterFrameMask"
	mask.position = grid_to_world(cell) + UNIT_REAR_SHIFT
	mask.z_index = int(mask.position.y)
	world.add_child(mask)

	var board_up := Vector2(0, -BACKBOARD_HEIGHT)
	_add_poly(
		mask,
		_face_quad(_base_back_left(), _base_back_right(), board_up, 0.90, 0.995, 0.03, 0.97),
		BACKBOARD,
		3
	)
