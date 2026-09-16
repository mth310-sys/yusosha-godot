extends Node3D

const TILE_SIZE: float = 1.0
const GRID_SIZE: int = 18

func _ready() -> void:
	_build_floor_details()

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
