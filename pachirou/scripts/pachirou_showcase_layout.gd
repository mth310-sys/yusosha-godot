extends Node3D

const GRID_SIZE: int = 18
const TILE_SIZE: float = 1.0
const GROUP_GAP_CELLS: int = 1
const EMPTY_ROWS_BETWEEN: int = 3
const ROW_STEP_CELLS: int = EMPTY_ROWS_BETWEEN + 1
const EXPECTED_STYLE_COUNT: int = 18
const START_CELL_X: int = 2
const START_CELL_Z: int = 4

func _ready() -> void:
	call_deferred("_arrange_showcase")

func _arrange_showcase() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var world := get_parent().get_node_or_null("World") as Node3D
	if world == null: return
	_remove_old_pairs(world)
	var by_style: Dictionary = {}
	_collect_style_roots(world,by_style)
	if by_style.size() < EXPECTED_STYLE_COUNT:
		push_warning("ShowcaseLayout: expected 18 source styles, found %d" % by_style.size())
		return
	for style_number in range(1,EXPECTED_STYLE_COUNT+1):
		if not by_style.has(style_number): return
		var source := by_style[style_number] as Node3D
		var row: int = (style_number-1)/6
		var index_in_row: int = (style_number-1)%6
		var group: int = index_in_row/3
		var index_in_group: int = index_in_row%3
		var first_cell_x: int = START_CELL_X+group*(6+GROUP_GAP_CELLS)+index_in_group*2
		var cell_z: int = START_CELL_Z+row*ROW_STEP_CELLS
		_remove_top_discs(source)
		_place_on_cell(source,Vector2i(first_cell_x,cell_z),row)
		var pair := source.duplicate() as Node3D
		pair.name = "ShowcasePair_%02d" % style_number
		world.add_child(pair)
		_remove_top_discs(pair)
		_place_on_cell(pair,Vector2i(first_cell_x+1,cell_z),row)

func _remove_top_discs(node: Node) -> void:
	for child in node.get_children():
		if String(child.name) == "ClayHeader":
			child.free()
		else:
			_remove_top_discs(child)

func _collect_style_roots(node: Node,by_style: Dictionary) -> void:
	for child in node.get_children():
		if child is Node3D:
			var child_3d := child as Node3D
			var number: int = _style_number(child_3d)
			if number > 0 and not by_style.has(number): by_style[number] = child_3d
			else: _collect_style_roots(child_3d,by_style)

func _style_number(node: Node3D) -> int:
	var node_name := String(node.name)
	if node_name.begins_with("Style_") and not node_name.contains("_Pair"):
		var suffix := node_name.trim_prefix("Style_")
		if suffix.is_valid_int(): return int(suffix)
	if node_name.begins_with("ExtraStyle_") and not node_name.contains("_Pair"):
		var suffix := node_name.trim_prefix("ExtraStyle_")
		if suffix.is_valid_int(): return 12+int(suffix)
	return -1

func _remove_old_pairs(node: Node) -> void:
	for child in node.get_children():
		if String(child.name).begins_with("ShowcasePair_"): child.queue_free()
		else: _remove_old_pairs(child)

func _cell_to_world(cell: Vector2i) -> Vector3:
	var half: float = float(GRID_SIZE-1)*0.5
	return Vector3((float(cell.x)-half)*TILE_SIZE,0.0,(float(cell.y)-half)*TILE_SIZE)

func _place_on_cell(node: Node3D,cell: Vector2i,row: int) -> void:
	if cell.x < 0 or cell.x >= GRID_SIZE or cell.y < 0 or cell.y >= GRID_SIZE:
		push_warning("ShowcaseLayout: cell outside map: %s" % cell)
		return
	node.global_position = _cell_to_world(cell)
	node.global_rotation_degrees = Vector3.ZERO
	node.set_meta("grid_cell",cell)
	node.set_meta("showcase_row",row)
