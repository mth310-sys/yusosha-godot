extends Node3D

func _ready() -> void:
	var humanoid_scene := load("res://characters/humanoid/humanoid_175_male.tscn") as PackedScene
	var humanoid := humanoid_scene.instantiate() as Node3D
	humanoid.name = "Male20s_175cm"
	add_child(humanoid)
