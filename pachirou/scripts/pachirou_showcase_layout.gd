extends Node3D

const MACHINE_PITCH: float = 1.02
const GROUP_GAP_SLOTS: int = 1
const ROW_STEP: float = 4.0
const EXPECTED_STYLE_COUNT: int = 18

func _ready() -> void:
	call_deferred("_arrange_showcase")

func _arrange_showcase() -> void:
	# Builders create the first 12 and ExtraSix creates the last 6 deferred.
	# Wait long enough for both branches to exist before collecting them recursively.
	await get_tree().process_frame
	await get_tree().process_frame
	var world := get_parent().get_node_or_null("World") as Node3D
	if world == null:
		return
	# Remove only duplicates previously created by this layout script.
	_remove_old_pairs(world)
	var by_style: Dictionary = {}
	_collect_style_roots(world,by_style)
	if by_style.size() < EXPECTED_STYLE_COUNT:
		push_warning("ShowcaseLayout: expected 18 source styles, found %d" % by_style.size())
		return
	# Requested layout:
	# row 0: styles 1-3 x2, one empty slot, styles 4-6 x2
	# row 1: styles 7-9 x2, one empty slot, styles 10-12 x2
	# row 2: styles 13-15 x2, one empty slot, styles 16-18 x2
	# Rows are separated by two empty grid rows.
	for style_number in range(1,EXPECTED_STYLE_COUNT+1):
		if not by_style.has(style_number):
			push_warning("ShowcaseLayout: missing style %d" % style_number)
			return
		var source := by_style[style_number] as Node3D
		var row: int = (style_number-1)/6
		var index_in_row: int = (style_number-1)%6
		var group: int = index_in_row/3
		var index_in_group: int = index_in_row%3
		var first_slot: int = group*(6+GROUP_GAP_SLOTS)+index_in_group*2
		_place(source,first_slot,row)
		var pair := source.duplicate() as Node3D
		pair.name = "ShowcasePair_%02d" % style_number
		world.add_child(pair)
		_place(pair,first_slot+1,row)

func _collect_style_roots(node: Node,by_style: Dictionary) -> void:
	for child in node.get_children():
		if child is Node3D:
			var child_3d := child as Node3D
			var number: int = _style_number(child_3d)
			if number > 0 and not by_style.has(number):
				by_style[number] = child_3d
			else:
				_collect_style_roots(child_3d,by_style)

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
		if String(child.name).begins_with("ShowcasePair_"):
			child.queue_free()
		else:
			_remove_old_pairs(child)

func _place(node: Node3D,slot: int,row: int) -> void:
	# 13 occupied/empty slots across: 6 machines + gap + 6 machines.
	var total_span: float = 12.0*MACHINE_PITCH
	var x: float = -total_span*0.5+float(slot)*MACHINE_PITCH
	var z: float = -4.0+float(row)*ROW_STEP
	node.global_position = Vector3(x,0.0,z)
	node.global_rotation_degrees = Vector3.ZERO
	node.set_meta("showcase_row",row)
