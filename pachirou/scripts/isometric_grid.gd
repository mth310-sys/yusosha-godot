class_name IsometricGrid
extends RefCounted

var width: int
var height: int
var tile_width: float
var tile_height: float

func _init(p_width: int, p_height: int, p_tile_width: float, p_tile_height: float) -> void:
	width = p_width
	height = p_height
	tile_width = p_tile_width
	tile_height = p_tile_height

func cell_origin(cell: Vector2i) -> Vector2:
	var cx: float = (float(width) - 1.0) * 0.5
	var cy: float = (float(height) - 1.0) * 0.5
	var gx: float = float(cell.x) - cx
	var gy: float = float(cell.y) - cy
	return Vector2((gx - gy) * tile_width * 0.5, (gx + gy) * tile_height * 0.5)

func cell_vertices_local() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-tile_width * 0.5, 0.0),
		Vector2(0.0, -tile_height * 0.5),
		Vector2(tile_width * 0.5, 0.0),
		Vector2(0.0, tile_height * 0.5),
	])

func contains(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height
