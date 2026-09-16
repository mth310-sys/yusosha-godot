extends "res://scripts/pachirou_map.gd"

# Four player-facing directions for one approved bay model.
# The current finished artwork is the LEFT_DOWN reference orientation.
enum BayDirection {
	LEFT_DOWN,
	RIGHT_DOWN,
	RIGHT_UP,
	LEFT_UP,
}

func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()

	# Validate all four directions before rebuilding a long double-sided island.
	_create_oriented_bay(Vector2i(4, 4), BayDirection.LEFT_DOWN)
	_create_oriented_bay(Vector2i(9, 4), BayDirection.RIGHT_DOWN)
	_create_oriented_bay(Vector2i(9, 9), BayDirection.RIGHT_UP)
	_create_oriented_bay(Vector2i(4, 9), BayDirection.LEFT_UP)

func _create_oriented_bay(cell: Vector2i, direction: BayDirection) -> void:
	var unit := Node2D.new()
	unit.name = "OrientedBay_%s" % BayDirection.keys()[direction]
	unit.position = grid_to_world(cell)
	unit.z_index = int(unit.position.y)
	world.add_child(unit)

	# Build the already-approved bay at local origin, then transform the complete
	# unit. This keeps machine/sand/counter/stool relationships identical in all
	# directions instead of maintaining four separate copies of the artwork.
	var content := Node2D.new()
	content.name = "BayContent"
	unit.add_child(content)

	_create_local_bay(content)

	match direction:
		BayDirection.LEFT_DOWN:
			pass
		BayDirection.RIGHT_DOWN:
			# Mirror across screen Y: swaps the two lower isometric directions.
			content.scale = Vector2(-1.0, 1.0)
		BayDirection.RIGHT_UP:
			# Opposite player direction.
			content.scale = Vector2(-1.0, -1.0)
		BayDirection.LEFT_UP:
			# Mirror across screen X: swaps the two upper isometric directions.
			content.scale = Vector2(1.0, -1.0)

func _create_local_bay(parent: Node2D) -> void:
	var bay := Node2D.new()
	bay.name = "IslandBay"
	bay.position = UNIT_REAR_SHIFT
	parent.add_child(bay)
	_create_island_frame(bay)
	_create_machine_and_sand(bay)
	_create_data_counter(bay)

	# Build the approved stool directly under the same transform so its player
	# position rotates/mirrors together with the cabinet and sand.
	var stool := Node2D.new()
	stool.name = "Stool"
	stool.position = UNIT_REAR_SHIFT + STOOL_FRONT_OFFSET
	stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)
	parent.add_child(stool)
	_create_stool_geometry(stool)

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
	_add_poly(stool, _ellipse(Vector2(-1.2, seat_y - 2.0), 7.8, 2.2, 26), Color("59616b"), 8)
