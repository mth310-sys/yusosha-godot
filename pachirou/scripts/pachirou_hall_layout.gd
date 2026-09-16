extends Node3D

const MACHINES_PER_SIDE: int = 6
const ISLAND_COUNT: int = 3
const X_SPACING: float = 1.00
const SIDE_OFFSET: float = 0.30
const ISLAND_Z: Array[float] = [-4.8,0.0,4.8]

func _ready() -> void:
	call_deferred("_build_hall_layout")

func _build_hall_layout() -> void:
	await get_tree().process_frame
	var world := get_parent().get_node_or_null("World")
	if world == null: return
	var source_sets: Array[Array] = [[],[],[]]
	for child in world.get_children():
		if child is Node3D and (child.name.begins_with("Style_") or child.name.begins_with("ExtraStyle_")):
			var bay := child as Node3D
			var row: int = _source_row(bay)
			if row >= 0: source_sets[row].append(bay)
	for row in range(ISLAND_COUNT):
		source_sets[row].sort_custom(func(a: Node3D,b: Node3D) -> bool: return a.global_position.x < b.global_position.x)
		if source_sets[row].size() < MACHINES_PER_SIDE: continue
		var island_root := Node3D.new()
		island_root.name = "DoubleSidedIsland_%d"%(row+1)
		world.add_child(island_root)
		_build_shared_spine(island_root,row)
		for i in range(MACHINES_PER_SIDE):
			var front := source_sets[row][i] as Node3D
			_reparent_keep_transform(front,island_root)
			_place_bay(front,row,i,false)
			var back := front.duplicate() as Node3D
			back.name = front.name+"_Reverse"
			island_root.add_child(back)
			_place_bay(back,row,i,true)

func _source_row(bay: Node3D) -> int:
	if bay.name.begins_with("ExtraStyle_"): return 2
	var number: int = int(bay.name.trim_prefix("Style_"))
	if number >= 1 and number <= 6: return 0
	if number >= 7 and number <= 12: return 1
	return -1

func _place_bay(bay: Node3D,island_index: int,slot: int,reversed: bool) -> void:
	var x0: float = -float(MACHINES_PER_SIDE-1)*X_SPACING*0.5
	var z_center: float = ISLAND_Z[island_index]
	bay.position = Vector3(x0+float(slot)*X_SPACING,0.0,z_center+(SIDE_OFFSET if reversed else -SIDE_OFFSET))
	bay.rotation_degrees = Vector3(0.0,180.0 if reversed else 0.0,0.0)
	bay.set_meta("hall_island",island_index)
	bay.set_meta("hall_side",1 if reversed else 0)
	var equipment := bay.get_node_or_null("IslandEquipment") as Node3D
	if equipment != null:
		# The common spine replaces the visually duplicated rear wall. Keep machine-side equipment intact.
		var backboard := equipment.get_node_or_null("BackBoard") as Node3D
		if backboard != null: backboard.visible = false
		equipment.set_meta("counter_type",island_index)

func _build_shared_spine(parent: Node3D,island_index: int) -> void:
	var z: float = ISLAND_Z[island_index]
	var length: float = float(MACHINES_PER_SIDE)*X_SPACING
	var body_color: Color = [Color("46545a"),Color("41484f"),Color("4b4655")][island_index]
	var trim_color: Color = [Color("9aa8aa"),Color("89949d"),Color("9a8fa5")][island_index]
	_box(parent,"SharedBase",Vector3(length,0.34,0.62),Vector3(0,0.17,z),body_color)
	_box(parent,"SharedBackPanel",Vector3(length,0.92,0.12),Vector3(0,0.82,z),body_color.darkened(0.16))
	_box(parent,"SharedTopRail",Vector3(length+0.08,0.07,0.22),Vector3(0,1.315,z),trim_color)
	_box(parent,"SharedBottomTrim",Vector3(length+0.06,0.055,0.66),Vector3(0,0.37,z),trim_color.darkened(0.15))
	# Vertical seams retain the modular six-machine construction while reading as one continuous island.
	for i in range(MACHINES_PER_SIDE+1):
		var x: float = -length*0.5+float(i)*X_SPACING
		_box(parent,"SpineSeam_%d"%i,Vector3(0.025,0.88,0.128),Vector3(x,0.82,z),trim_color.darkened(0.30))
	# End caps close both ends of the island instead of exposing individual bay backs.
	_box(parent,"EndCapL",Vector3(0.14,1.28,0.78),Vector3(-length*0.5-0.07,0.64,z),body_color.darkened(0.08))
	_box(parent,"EndCapR",Vector3(0.14,1.28,0.78),Vector3(length*0.5+0.07,0.64,z),body_color.darkened(0.08))

func _reparent_keep_transform(node: Node3D,new_parent: Node3D) -> void:
	var transform_before := node.global_transform
	node.reparent(new_parent)
	node.global_transform = transform_before

func _box(parent: Node3D,node_name: String,size: Vector3,pos: Vector3,color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new(); mesh.size = size; mesh_instance.mesh = mesh
	mesh_instance.position = pos
	var mat := StandardMaterial3D.new(); mat.albedo_color = color; mat.metallic = 0.18; mat.roughness = 0.58
	mesh_instance.material_override = mat
	parent.add_child(mesh_instance)
