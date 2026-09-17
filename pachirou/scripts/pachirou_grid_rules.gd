extends Node3D
class_name PachirouGridRules

const GRID_SIZE: int = 22
const TILE_SIZE: float = 1.0
const DIRECTIONS: Array[Vector2i] = [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]

enum CellType { WALKABLE, BLOCKED, SEAT, RESERVED, ENTRANCE }

var cells: Dictionary = {}
var seats: Dictionary = {}
var layout_ready: bool = false

func _ready() -> void:
	_reset_walkable_grid()
	call_deferred("_register_current_layout")

func _reset_walkable_grid() -> void:
	cells.clear()
	seats.clear()
	for z in range(GRID_SIZE):
		for x in range(GRID_SIZE): cells[Vector2i(x,z)] = CellType.WALKABLE

func _register_current_layout() -> void:
	for wait_index in range(6): await get_tree().process_frame
	_reset_walkable_grid()
	var world := get_parent().get_node_or_null("World") as Node3D
	if world == null: return
	_register_nodes_recursive(world)
	layout_ready = true

func _register_nodes_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Node3D:
			var item := child as Node3D
			if item.has_meta("grid_cell"):
				var cell := world_to_cell(item.global_position)
				set_cell_type(cell,CellType.BLOCKED)
				_register_seat_for_item(item,cell)
			_register_nodes_recursive(item)

func _register_seat_for_item(item: Node3D,machine_cell: Vector2i) -> void:
	var stool := item.find_child("RoundStool",true,false) as Node3D
	var seat_cell: Vector2i
	var seat_position: Vector3
	if stool != null:
		seat_position = stool.global_position
		seat_cell = world_to_cell(seat_position)
	else:
		var side: String = String(item.get_meta("island_side","front"))
		seat_cell = machine_cell+Vector2i(0,1) if side == "front" else machine_cell+Vector2i(0,-1)
		seat_position = cell_to_world(seat_cell)
	if not is_inside(seat_cell): return
	cells[seat_cell] = CellType.SEAT
	seats[seat_cell] = {"machine":item,"stool":stool,"seat_position":seat_position,"occupied_by":null,"reserved_by":null}

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_SIZE and cell.y >= 0 and cell.y < GRID_SIZE

func get_cell_type(cell: Vector2i) -> CellType:
	if not is_inside(cell): return CellType.BLOCKED
	return cells.get(cell,CellType.WALKABLE) as CellType

func set_cell_type(cell: Vector2i,type: CellType) -> void:
	if is_inside(cell): cells[cell] = type

func is_walkable(cell: Vector2i) -> bool:
	var type := get_cell_type(cell)
	return type == CellType.WALKABLE or type == CellType.ENTRANCE

func can_enter_as_destination(cell: Vector2i,customer: Node = null) -> bool:
	if is_walkable(cell): return true
	if not is_seat(cell) or not seats.has(cell): return false
	var data: Dictionary = seats[cell]
	if data["occupied_by"] != null and data["occupied_by"] != customer: return false
	if data["reserved_by"] != null and data["reserved_by"] != customer: return false
	return true

func is_seat(cell: Vector2i) -> bool:
	return get_cell_type(cell) == CellType.SEAT

func world_to_cell(world_position: Vector3) -> Vector2i:
	var half: float = float(GRID_SIZE-1)*0.5
	return Vector2i(roundi(world_position.x/TILE_SIZE+half),roundi(world_position.z/TILE_SIZE+half))

func cell_to_world(cell: Vector2i) -> Vector3:
	var half: float = float(GRID_SIZE-1)*0.5
	return Vector3((float(cell.x)-half)*TILE_SIZE,0.0,(float(cell.y)-half)*TILE_SIZE)

func seat_world_position(cell: Vector2i) -> Vector3:
	if not seats.has(cell): return cell_to_world(cell)
	return seats[cell]["seat_position"] as Vector3

func available_seats() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell_variant in seats.keys():
		var cell := cell_variant as Vector2i
		var data: Dictionary = seats[cell]
		if data["occupied_by"] == null and data["reserved_by"] == null: result.append(cell)
	return result

func find_path(start: Vector2i,goal: Vector2i,customer: Node = null) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if not is_inside(start) or not is_inside(goal): return empty
	if start == goal: return [start] if can_enter_as_destination(goal,customer) else empty
	if not can_enter_as_destination(goal,customer): return empty
	var frontier: Array[Vector2i] = [start]
	var came_from: Dictionary = {start:start}
	var index: int = 0
	while index < frontier.size():
		var current: Vector2i = frontier[index]
		index += 1
		for direction in DIRECTIONS:
			var next := current+direction
			if not is_inside(next) or came_from.has(next): continue
			if next != goal and not is_walkable(next): continue
			if next == goal and not can_enter_as_destination(next,customer): continue
			came_from[next] = current
			if next == goal: return _reconstruct_path(came_from,start,goal)
			frontier.append(next)
	return empty

func _reconstruct_path(came_from: Dictionary,start: Vector2i,goal: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [goal]
	var current := goal
	while current != start:
		current = came_from[current] as Vector2i
		path.push_front(current)
	return path

func reserve_seat(cell: Vector2i,customer: Node) -> bool:
	if not seats.has(cell): return false
	var data: Dictionary = seats[cell]
	if data["occupied_by"] != null or data["reserved_by"] != null: return false
	data["reserved_by"] = customer
	seats[cell] = data
	return true

func occupy_seat(cell: Vector2i,customer: Node) -> bool:
	if not seats.has(cell): return false
	var data: Dictionary = seats[cell]
	if data["occupied_by"] != null: return false
	if data["reserved_by"] != null and data["reserved_by"] != customer: return false
	data["reserved_by"] = null
	data["occupied_by"] = customer
	seats[cell] = data
	return true

func release_seat(cell: Vector2i,customer: Node) -> void:
	if not seats.has(cell): return
	var data: Dictionary = seats[cell]
	if data["occupied_by"] == customer: data["occupied_by"] = null
	if data["reserved_by"] == customer: data["reserved_by"] = null
	seats[cell] = data

func machine_for_seat(cell: Vector2i) -> Node3D:
	if not seats.has(cell): return null
	return seats[cell]["machine"] as Node3D
