extends Node3D

const MACHINE_PITCH: float = 1.02
const GROUP_GAP: float = 1.0
const ROW_GAP: float = 3.0

func _ready() -> void:
	call_deferred("_arrange_showcase")

func _arrange_showcase() -> void:
	await get_tree().process_frame
	var world := get_parent().get_node_or_null("World")
	if world == null:
		return
	var styles: Array[Node3D] = []
	for child in world.get_children():
		if child is Node3D and (child.name.begins_with("Style_") or child.name.begins_with("ExtraStyle_")):
			styles.append(child as Node3D)
	styles.sort_custom(func(a: Node3D,b: Node3D) -> bool: return _style_number(a) < _style_number(b))
	if styles.size() < 18:
		return
	# 18 styles -> six groups of three styles. Each style is shown twice side-by-side.
	# Two groups per row, one empty machine-width between groups, and two empty rows between showcase rows.
	for style_index in range(18):
		var source := styles[style_index]
		var group_index: int = style_index / 3
		var row: int = group_index / 2
		var group_in_row: int = group_index % 2
		var within_group: int = style_index % 3
		var base_slot: int = group_in_row * 7 + within_group * 2
		_place(source,base_slot,row)
		var duplicate := source.duplicate() as Node3D
		duplicate.name = source.name+"_Pair"
		world.add_child(duplicate)
		_place(duplicate,base_slot+1,row)

func _style_number(node: Node3D) -> int:
	if node.name.begins_with("ExtraStyle_"):
		return 13+int(node.name.trim_prefix("ExtraStyle_"))
	return int(node.name.trim_prefix("Style_"))

func _place(node: Node3D,slot: int,row: int) -> void:
	var total_width: float = 13.0*MACHINE_PITCH
	var x: float = -total_width*0.5+float(slot)*MACHINE_PITCH
	var z: float = -3.0+float(row)*ROW_GAP
	node.position = Vector3(x,0.0,z)
	node.rotation_degrees = Vector3.ZERO
	node.set_meta("showcase_row",row)
