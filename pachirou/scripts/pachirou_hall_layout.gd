extends Node3D

const MACHINES_PER_SIDE: int = 6
const ISLAND_COUNT: int = 3
const X_SPACING: float = 1.02
const SIDE_OFFSET: float = 0.39
const ISLAND_Z: Array[float] = [-5.0, 0.0, 5.0]

func _ready() -> void:
	call_deferred("_build_hall_layout")

func _build_hall_layout() -> void:
	# Main and ExtraSix create the 18 showcase bays during their _ready calls.
	# Reuse those as the three style sets, then mirror each set to form a true back-to-back island.
	await get_tree().process_frame
	var world := get_parent().get_node_or_null("World")
	if world == null:
		return
	var source_sets: Array[Array] = [[],[],[]]
	for child in world.get_children():
		if child is Node3D and (child.name.begins_with("Style_") or child.name.begins_with("ExtraStyle_")):
			var bay := child as Node3D
			var source_row: int = _source_row(bay)
			if source_row >= 0:
				source_sets[source_row].append(bay)
	for row in range(ISLAND_COUNT):
		source_sets[row].sort_custom(func(a: Node3D,b: Node3D) -> bool: return a.global_position.x < b.global_position.x)
		if source_sets[row].size() < MACHINES_PER_SIDE:
			continue
		for i in range(MACHINES_PER_SIDE):
			var front := source_sets[row][i] as Node3D
			_place_bay(front,row,i,false)
			var back := front.duplicate() as Node3D
			back.name = front.name+"_Reverse"
			world.add_child(back)
			_place_bay(back,row,i,true)

func _source_row(bay: Node3D) -> int:
	if bay.name.begins_with("ExtraStyle_"):
		return 2
	# Original Style_1..6 and Style_7..12 are the first two sets.
	var number_text: String = bay.name.trim_prefix("Style_")
	var number: int = int(number_text)
	if number >= 1 and number <= 6:
		return 0
	if number >= 7 and number <= 12:
		return 1
	return -1

func _place_bay(bay: Node3D,island_index: int,slot: int,reversed: bool) -> void:
	var x0: float = -float(MACHINES_PER_SIDE-1)*X_SPACING*0.5
	var z_center: float = ISLAND_Z[island_index]
	bay.position = Vector3(x0+float(slot)*X_SPACING,0.0,z_center+(SIDE_OFFSET if reversed else -SIDE_OFFSET))
	bay.rotation_degrees = Vector3(0.0,180.0 if reversed else 0.0,0.0)
	bay.set_meta("hall_island",island_index)
	bay.set_meta("hall_side",1 if reversed else 0)
	var equipment := bay.get_node_or_null("IslandEquipment")
	if equipment != null:
		equipment.set_meta("counter_type",island_index)
