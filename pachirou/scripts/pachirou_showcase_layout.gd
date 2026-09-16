extends Node3D

const GRID_SIZE: int = 18
const TILE_SIZE: float = 1.0
const GROUP_GAP_CELLS: int = 1
const EXPECTED_STYLE_COUNT: int = 18
const START_CELL_X: int = 2
const ISLAND_FRONT_ROWS: Array[int] = [2,7,12]
# Island base depth is 0.70 in a 1.00-deep map cell. Every unit is aligned to
# the BACK edge of its own cell according to the direction it faces.
const UNIT_DEPTH: float = 0.70
const REAR_EDGE_OFFSET: float = (TILE_SIZE-UNIT_DEPTH)*0.5

func _ready() -> void:
	call_deferred("_arrange_showcase")

func _arrange_showcase() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var world := get_parent().get_node_or_null("World") as Node3D
	if world == null: return
	_remove_layout_duplicates(world)
	_remove_clay_discs(world)
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
		var front_z: int = ISLAND_FRONT_ROWS[row]
		var back_z: int = front_z-1
		_remove_clay_discs(source)
		_place_front(source,Vector2i(first_cell_x,front_z),row)
		var front_pair := source.duplicate() as Node3D
		front_pair.name = "ShowcasePair_%02d" % style_number
		world.add_child(front_pair)
		_remove_clay_discs(front_pair)
		_place_front(front_pair,Vector2i(first_cell_x+1,front_z),row)
		var back_a := source.duplicate() as Node3D
		back_a.name = "ShowcaseBack_%02d_A" % style_number
		world.add_child(back_a)
		_remove_clay_discs(back_a)
		_rotate_then_snap_back(back_a,Vector2i(first_cell_x,back_z),row)
		var back_b := source.duplicate() as Node3D
		back_b.name = "ShowcaseBack_%02d_B" % style_number
		world.add_child(back_b)
		_remove_clay_discs(back_b)
		_rotate_then_snap_back(back_b,Vector2i(first_cell_x+1,back_z),row)

func _remove_clay_discs(node: Node) -> void:
	for child in node.get_children():
		var child_name := String(child.name)
		if child_name == "ClayTop" or child_name == "ClayHeader": child.free()
		else: _remove_clay_discs(child)

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

func _remove_layout_duplicates(node: Node) -> void:
	for child in node.get_children():
		var child_name := String(child.name)
		if child_name.begins_with("ShowcasePair_") or child_name.begins_with("ShowcaseReverse_") or child_name.begins_with("ShowcaseBack_"):
			child.queue_free()
		else: _remove_layout_duplicates(child)

func _cell_to_world(cell: Vector2i) -> Vector3:
	var half: float = float(GRID_SIZE-1)*0.5
	return Vector3((float(cell.x)-half)*TILE_SIZE,0.0,(float(cell.y)-half)*TILE_SIZE)

func _place_front(node: Node3D,cell: Vector2i,row: int) -> void:
	if not _cell_is_valid(cell): return
	node.global_rotation_degrees = Vector3.ZERO
	var snapped_position := _cell_to_world(cell)
	# 0-degree units face +Z, so their rear is -Z: align them to the -Z edge.
	snapped_position.z -= REAR_EDGE_OFFSET
	node.global_position = snapped_position
	_set_grid_meta(node,cell,row,"front")

func _rotate_then_snap_back(node: Node3D,cell: Vector2i,row: int) -> void:
	if not _cell_is_valid(cell): return
	node.global_rotation_degrees = Vector3(0.0,180.0,0.0)
	var snapped_position := _cell_to_world(cell)
	# 180-degree units face -Z, so their rear is +Z: align them to the +Z edge.
	snapped_position.z += REAR_EDGE_OFFSET
	node.global_position = snapped_position
	_set_grid_meta(node,cell,row,"back")

func _cell_is_valid(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= GRID_SIZE or cell.y < 0 or cell.y >= GRID_SIZE:
		push_warning("ShowcaseLayout: cell outside map: %s" % cell)
		return false
	return true

func _set_grid_meta(node: Node3D,cell: Vector2i,row: int,side: String) -> void:
	node.set_meta("grid_cell",cell)
	node.set_meta("showcase_row",row)
	node.set_meta("island_side",side)
