extends Node3D

const TILE_SIZE: float = 1.0
const GRID_SIZE: int = 18

func _ready() -> void:
	_build_floor_details()
	call_deferred("_remove_counter_overlaps")

func _remove_counter_overlaps() -> void:
	# ClayTop sits in the data-counter sightline on the clay/toy machine.
	# Remove the generated part entirely so the equipment-mounted counter stays readable.
	await get_tree().process_frame
	await get_tree().process_frame
	var world := get_parent().get_node_or_null("World")
	if world != null:
		_remove_named_recursive(world,"ClayTop")

func _remove_named_recursive(node: Node,target_name: String) -> void:
	for child in node.get_children():
		if String(child.name) == target_name:
			child.queue_free()
		else:
			_remove_named_recursive(child,target_name)

func _build_floor_details() -> void:
	# Keep only subtle grid joints. Old fixed-position machine pads were prototype decoration
	# and no longer belong to the grid-snapped placement system.
	var joint_color := Color("b8bdc2")
	for i in range(GRID_SIZE + 1):
		var p: float = float(i) - float(GRID_SIZE) * 0.5
		_box("JointX%d" % i,Vector3(float(GRID_SIZE),0.006,0.012),Vector3(0,0.012,p),joint_color,0.0,0.72)
		_box("JointZ%d" % i,Vector3(0.012,0.006,float(GRID_SIZE)),Vector3(p,0.012,0),joint_color,0.0,0.72)

func _box(node_name: String,size: Vector3,pos: Vector3,color: Color,metallic: float,roughness: float) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	node.material_override = mat
	add_child(node)
