extends Node3D

const TILE_SIZE: float = 1.0
const GRID_SIZE: int = 18

func _ready() -> void:
	_build_floor_details()
	_build_machine_pads()

func _build_floor_details() -> void:
	# Subtle tile joints make the 3D map readable without overpowering the machines.
	var joint_color := Color("b8bdc2")
	for i in range(GRID_SIZE + 1):
		var p: float = float(i) - float(GRID_SIZE) * 0.5
		_box("JointX%d" % i, Vector3(float(GRID_SIZE),0.006,0.012), Vector3(0,0.012,p), joint_color,0.0,0.72)
		_box("JointZ%d" % i, Vector3(0.012,0.006,float(GRID_SIZE)), Vector3(p,0.012,0), joint_color,0.0,0.72)

func _build_machine_pads() -> void:
	# The three showcase rows get a restrained dark plinth/shadow strip so silhouettes read at every zoom level.
	for row_z in [2.0,4.0,6.0]:
		for x in [3.0,5.0,7.0,9.0,11.0,13.0]:
			var world_x: float = x - 8.5
			var world_z: float = row_z - 8.5
			_box("Pad_%d_%d" % [int(x),int(row_z)],Vector3(0.92,0.014,0.68),Vector3(world_x,0.022,world_z),Color("5c6267"),0.08,0.62)

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
