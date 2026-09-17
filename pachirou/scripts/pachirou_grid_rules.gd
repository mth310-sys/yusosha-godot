extends Node3D
class_name PachirouGridRules

const GRID_SIZE: int = 22
const TILE_SIZE: float = 1.0

enum CellType { WALKABLE, BLOCKED, SEAT, RESERVED, ENTRANCE }

var cells: Dictionary = {}
var seats: Dictionary = {}

func _ready() -> void:
	_reset_walkable_grid()
	call_deferred("_register_current_layout")

func _reset_walkable_grid() -> void:
	cells.clear()
	for z in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			cells[Vector2i(x,z)] = CellType.WALKABLE

func _register_current_layout() -> void:
	await get_tree().process_frame
	var world := get_parent().get_node_or_null("World") as Node3D
	if world == null: return
	_register_nodes_recursive(world)

func _register_nodes_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Node3D:
			var item := child as Node3D
			if item.has_meta("grid_cell"):
				var cell_variant: Variant = item.get_meta("grid_cell")
				if cell_variant is Vector2i:
					var cell := cell_variant as Vector2i
					set_cell_type(cell,CellType.BLOCKED)
					_register_seat_for_item(item,cell)
			_register_nodes_recursive(item)

func _register_seat_for_item(item: Node3D,machine_cell: Vector2i) -> void:
	var side: String = String(item.get_meta("island_side","front"))
	var seat_cell := machine_cell+Vector2i(0,1) if side == "front" else machine_cell+Vector2i(0,-1)
	if not is_inside(seat_cell): return
	# A seat is a destination, not a normal through-route.
	cells[seat_cell] = CellType.SEAT
	seats[seat_cell] = {
		"machine": item,
		"occupied_by": null,
		"reserved_by": null
	}

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_SIZE and cell.y >= 0 and cell.y < GRID_SIZE

func get_cell_type(cell: Vector2i) -> CellType:
	if not is_inside(cell): return CellType.BLOCKED
	return cells.get(cell,CellType.WALKABLE) as CellType

func set_cell_type(cell: Vector2i,type: CellType) -> void:
	if is_inside(cell): cells[cell] = type

func is_walkable(cell: Vector2i) -> bool:
	return get_cell_type(cell) == CellType.WALKABLE or get_cell_type(cell) == CellType.ENTRANCE

func is_seat(cell: Vector2i) -> bool:
	return get_cell_type(cell) == CellType.SEAT

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
