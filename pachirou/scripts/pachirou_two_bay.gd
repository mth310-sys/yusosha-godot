extends "res://scripts/pachirou_map.gd"

func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()

	var bay_cells: Array[Vector2i] = [Vector2i(6, 4), Vector2i(7, 4)]
	for cell: Vector2i in bay_cells:
		_create_island_bay(cell)
		_create_stool(cell)
