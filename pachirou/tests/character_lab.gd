extends Node3D

func _ready() -> void:
	var humanoid_scene := load("res://characters/humanoid/humanoid_175_male.tscn") as PackedScene
	var humanoid := humanoid_scene.instantiate() as Node3D
	humanoid.name = "Male20s_175cm"
	add_child(humanoid)

	var camera := get_node("Camera3D") as Camera3D
	camera.position = Vector3(2.8,1.65,3.8)
	camera.look_at(Vector3(0.0,0.88,0.0),Vector3.UP)
	camera.size = 2.2
