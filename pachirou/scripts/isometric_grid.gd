class_name IsometricGrid
extends RefCounted

enum Direction {
	LEFT_DOWN,
	LEFT_UP,
	RIGHT_UP,
	RIGHT_DOWN,
}

var width: int
var height: int
var tile_width: float
var tile_height: float
var _occupants: Dictionary = {}

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

func rotate_offset(offset: Vector2i, direction: Direction) -> Vector2i:
	match direction:
		Direction.LEFT_DOWN:
			return offset
		Direction.LEFT_UP:
			return Vector2i(offset.y, -offset.x)
		Direction.RIGHT_UP:
			return Vector2i(-offset.x, -offset.y)
		Direction.RIGHT_DOWN:
			return Vector2i(-offset.y, offset.x)
	return offset

func footprint_cells(origin: Vector2i, footprint: Array[Vector2i], direction: Direction) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset: Vector2i in footprint:
		cells.append(origin + rotate_offset(offset, direction))
	return cells

func can_place(item: Object, origin: Vector2i, footprint: Array[Vector2i], direction: Direction) -> bool:
	for cell: Vector2i in footprint_cells(origin, footprint, direction):
		if not contains(cell):
			return false
		var occupant: Variant = _occupants.get(cell)
		if occupant != null and occupant != item:
			return false
	return true

func place(item: Object, origin: Vector2i, footprint: Array[Vector2i], direction: Direction) -> bool:
	if not can_place(item, origin, footprint, direction):
		return false
	remove(item)
	for cell: Vector2i in footprint_cells(origin, footprint, direction):
		_occupants[cell] = item
	return true

func move(item: Object, origin: Vector2i, footprint: Array[Vector2i], direction: Direction) -> bool:
	return place(item, origin, footprint, direction)

func rotate(item: Object, origin: Vector2i, footprint: Array[Vector2i], direction: Direction) -> bool:
	return place(item, origin, footprint, direction)

func remove(item: Object) -> void:
	var cells_to_clear: Array[Vector2i] = []
	for cell: Variant in _occupants.keys():
		if _occupants[cell] == item:
			cells_to_clear.append(cell as Vector2i)
	for cell: Vector2i in cells_to_clear:
		_occupants.erase(cell)

func occupant_at(cell: Vector2i) -> Object:
	var occupant: Variant = _occupants.get(cell)
	return occupant as Object

func is_occupied(cell: Vector2i) -> bool:
	return _occupants.has(cell)
