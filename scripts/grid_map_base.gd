class_name GridMapBase
extends Node2D

@export var map_width: int = 50
@export var map_height: int = 50
@export var tile_width: float = 64.0
@export var tile_height: float = 32.0

var map_data: Array = []

func build_map(default_type: String = "land") -> void:
	map_data.clear()
	for y in range(map_height):
		var row: Array = []
		for x in range(map_width):
			row.append(make_cell(default_type))
		map_data.append(row)

func make_cell(cell_type: String) -> Dictionary:
	return {
		"type": cell_type,
		"occupied": false,
		"object_id": "",
		"road_shape": ""
	}

func grid_to_world(x: int, y: int) -> Vector2:
	return Vector2(
		(x - y) * tile_width * 0.5,
		(x + y) * tile_height * 0.5
	)

func world_to_grid(world_position: Vector2) -> Vector2i:
	var gx: float = world_position.x / tile_width + world_position.y / tile_height
	var gy: float = world_position.y / tile_height - world_position.x / tile_width
	return Vector2i(floori(gx + 0.5), floori(gy + 0.5))

func is_valid_tile(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < map_width and tile.y >= 0 and tile.y < map_height

func get_cell(tile: Vector2i) -> Dictionary:
	if not is_valid_tile(tile):
		return {}
	return map_data[tile.y][tile.x]

func set_cell_type(tile: Vector2i, cell_type: String, occupied: bool = false, object_id: String = "") -> void:
	if not is_valid_tile(tile):
		return
	var cell: Dictionary = map_data[tile.y][tile.x]
	cell["type"] = cell_type
	cell["occupied"] = occupied
	cell["object_id"] = object_id

func neighbors4(tile: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var directions: Array[Vector2i] = [
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(-1, 0)
	]
	for direction in directions:
		var neighbor: Vector2i = tile + direction
		if is_valid_tile(neighbor):
			result.append(neighbor)
	return result

func tile_points(x: int, y: int) -> PackedVector2Array:
	var center: Vector2 = grid_to_world(x, y)
	return PackedVector2Array([
		center + Vector2(0.0, -tile_height * 0.5),
		center + Vector2(tile_width * 0.5, 0.0),
		center + Vector2(0.0, tile_height * 0.5),
		center + Vector2(-tile_width * 0.5, 0.0)
	])
