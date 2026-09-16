class_name PachislotBayItem
extends "res://scripts/pachirou_map.gd"

enum Direction {
	LEFT_DOWN,
	LEFT_UP,
	RIGHT_UP,
	RIGHT_DOWN,
}

const ISLAND_LOCAL_SHIFT := Vector2(6.0, -3.0)
const SAND_SLOT_LEFT := Vector2(-1.5, -25.9)

var cell: Vector2i = Vector2i.ZERO
var direction: Direction = Direction.LEFT_DOWN
var footprint: Array[Vector2i] = [Vector2i.ZERO]
var grid: IsometricGrid
var installed_machine: PachislotMachineItem

@onready var frame: Node2D = $Frame
@onready var island_base: Node2D = $Frame/IslandBase
@onready var back_board: Node2D = $Frame/BackBoard
@onready var upper_box: Node2D = $Frame/UpperBox
@onready var equipment: Node2D = $Equipment
@onready var sand: Node2D = $Equipment/Sand
@onready var data_counter: Node2D = $Equipment/DataCounter
@onready var machine_slot: Node2D = $MachineSlot
@onready var stool: Node2D = $Stool

func _ready() -> void:
	pass

func setup(p_grid: IsometricGrid, p_cell: Vector2i, p_direction: Direction) -> bool:
	grid = p_grid
	if not grid.place(self, p_cell, footprint, _grid_direction(p_direction)):
		return false
	cell = p_cell
	direction = p_direction
	_apply_grid_position()
	_update_name()
	build()
	return true

func move_to(p_cell: Vector2i) -> bool:
	if grid == null or not grid.move(self, p_cell, footprint, _grid_direction(direction)):
		return false
	cell = p_cell
	_apply_grid_position()
	_update_name()
	return true

func rotate_to(p_direction: Direction) -> bool:
	if grid == null or not grid.rotate(self, cell, footprint, _grid_direction(p_direction)):
		return false
	direction = p_direction
	_update_name()
	build()
	return true

func rotate_clockwise() -> bool:
	var next_direction: Direction = ((int(direction) + 1) % 4) as Direction
	return rotate_to(next_direction)

func install_machine(machine_item: PachislotMachineItem) -> bool:
	if machine_item == null or installed_machine != null:
		return false
	installed_machine = machine_item
	machine_slot.add_child(machine_item)
	machine_item.position = Vector2.ZERO
	return true

func remove_machine() -> PachislotMachineItem:
	var machine_item: PachislotMachineItem = installed_machine
	if machine_item == null:
		return null
	machine_slot.remove_child(machine_item)
	installed_machine = null
	return machine_item

func has_machine() -> bool:
	return installed_machine != null

func remove_from_grid() -> void:
	if grid != null:
		grid.remove(self)

func occupied_cells() -> Array[Vector2i]:
	if grid == null:
		return []
	return grid.footprint_cells(cell, footprint, _grid_direction(direction))

func build() -> void:
	clear_visuals()
	_reset_component_transforms()
	_build_canonical_left_down()
	if direction != Direction.LEFT_DOWN:
		_apply_isometric_direction()

func _build_canonical_left_down() -> void:
	frame.position = ISLAND_LOCAL_SHIFT
	equipment.position = ISLAND_LOCAL_SHIFT
	machine_slot.position = ISLAND_LOCAL_SHIFT
	stool.position = ISLAND_LOCAL_SHIFT + STOOL_FRONT_OFFSET
	stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)
	frame.z_index = 0
	machine_slot.z_index = 20
	equipment.z_index = 30
	sand.z_index = 2
	data_counter.z_index = 3
	stool.z_index = 40
	_create_island_frame(frame)
	var sand_lb: Vector2 = SAND_SLOT_LEFT
	var sand_fb: Vector2 = sand_lb + SAND_FRONT_VECTOR
	_create_sand(sand, sand_lb, sand_fb, SAND_DEPTH)
	_create_data_counter(data_counter)
	_create_stool_geometry(stool)

func _apply_isometric_direction() -> void:
	# Keep every vertical screen-space height vertical. Only the ground/contact
	# coordinate of each completed polygon point is quarter-turned in grid space.
	# For each Polygon2D we use its lowest screen point as the local ground line;
	# the vertical delta above that line is preserved exactly.
	_transform_node_ground(frame)
	_transform_node_ground(equipment)
	_transform_node_ground(stool)
	machine_slot.position = _turn_ground(machine_slot.position)

func _transform_node_ground(node: Node2D) -> void:
	node.position = _turn_ground(node.position)
	_transform_polygon_descendants(node)

func _transform_polygon_descendants(node: Node) -> void:
	for child in node.get_children():
		if child is Polygon2D:
			var poly := child as Polygon2D
			poly.polygon = _turn_polygon_preserve_vertical(poly.polygon)
		else:
			_transform_polygon_descendants(child)

func _turn_polygon_preserve_vertical(points: PackedVector2Array) -> PackedVector2Array:
	if points.is_empty():
		return points
	var ground_y: float = points[0].y
	for point in points:
		ground_y = maxf(ground_y, point.y)
	var turned := PackedVector2Array()
	for point in points:
		var vertical_height: float = ground_y - point.y
		var ground_point := Vector2(point.x, ground_y)
		var turned_ground: Vector2 = _turn_ground(ground_point)
		turned.append(turned_ground + Vector2(0.0, -vertical_height))
	return turned

func _turn_ground(point: Vector2) -> Vector2:
	var result: Vector2 = point
	for i in range(int(direction)):
		result = Vector2(-2.0 * result.y, result.x * 0.5)
	return result

func _create_stool_geometry(parent: Node2D) -> void:
	var seat_y: float = -38.4
	_add_poly(parent, _ellipse(Vector2(0, 0.5), 15.2, 6.4, 32), Color("4b525a"), 0)
	_add_poly(parent, _ellipse(Vector2(0, -0.8), 12.0, 4.8, 30), METAL_DARK, 1)
	_add_poly(parent, _ellipse(Vector2(0, -1.8), 9.5, 3.4, 28), METAL, 2)
	_add_poly(parent, _ellipse(Vector2(0, -2.2), 5.0, 1.9, 24), Color("d1d5d9"), 3)
	_add_poly(parent, PackedVector2Array([Vector2(-2.6, seat_y + 7.0), Vector2(2.6, seat_y + 7.0), Vector2(2.2, -4.0), Vector2(-2.2, -4.0)]), METAL_DARK, 1)
	_add_poly(parent, PackedVector2Array([Vector2(-1.5, seat_y + 6.0), Vector2(1.5, seat_y + 6.0), Vector2(1.5, -3.0), Vector2(-1.5, -3.0)]), METAL, 2)
	_add_poly(parent, _ellipse(Vector2(0, seat_y + 6.0), 5.0, 2.0, 24), METAL_DARK, 3)
	_add_poly(parent, _ellipse(Vector2(0, seat_y + 5.3), 3.7, 1.4, 22), METAL, 4)
	_add_poly(parent, _ellipse_band(Vector2(0, seat_y + 0.6), 16.0, 6.7, 5.2, 32), Color("20262d"), 4)
	_add_poly(parent, _ellipse(Vector2(0, seat_y), 16.0, 6.7, 34), SEAT_SIDE, 5)
	_add_poly(parent, _ellipse(Vector2(0, seat_y - 0.8), 14.6, 5.8, 34), SEAT_TOP, 6)
	_add_poly(parent, _ellipse(Vector2(0, seat_y - 1.2), 11.8, 4.3, 30), SEAT_INNER, 7)
	_add_poly(parent, _ellipse(Vector2(-1.2, seat_y - 2.0), 7.8, 2.2, 26), Color("59616b"), 8)

func clear_visuals() -> void:
	_clear_visual_children(island_base)
	_clear_visual_children(back_board)
	_clear_visual_children(upper_box)
	_clear_visual_children(sand)
	_clear_visual_children(data_counter)
	_clear_visual_children(stool)
	for child in frame.get_children():
		if child is Polygon2D:
			child.queue_free()

func direction_name() -> String:
	match direction:
		Direction.LEFT_DOWN: return "LEFT_DOWN"
		Direction.LEFT_UP: return "LEFT_UP"
		Direction.RIGHT_UP: return "RIGHT_UP"
		Direction.RIGHT_DOWN: return "RIGHT_DOWN"
	return "UNKNOWN"

func _apply_grid_position() -> void:
	position = grid.cell_origin(cell)
	z_index = int(position.y)

func _update_name() -> void:
	name = "PachislotBay_%d_%d_%s" % [cell.x, cell.y, direction_name()]

func _grid_direction(p_direction: Direction) -> IsometricGrid.Direction:
	return p_direction as IsometricGrid.Direction

func _reset_component_transforms() -> void:
	rotation = 0.0
	frame.position = Vector2.ZERO
	equipment.position = Vector2.ZERO
	machine_slot.position = Vector2.ZERO
	stool.position = Vector2.ZERO
	frame.rotation = 0.0
	equipment.rotation = 0.0
	machine_slot.rotation = 0.0
	stool.rotation = 0.0
	frame.scale = Vector2.ONE
	equipment.scale = Vector2.ONE
	machine_slot.scale = Vector2.ONE
	stool.scale = Vector2.ONE

func _clear_visual_children(parent: Node2D) -> void:
	for child in parent.get_children():
		child.queue_free()
