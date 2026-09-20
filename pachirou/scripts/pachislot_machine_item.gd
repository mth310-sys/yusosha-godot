class_name PachislotMachineItem
extends Node2D

var machine_id: String = "standard_a"
var renderer: Callable

func setup(p_machine_id: String, p_renderer: Callable) -> void:
	machine_id = p_machine_id
	renderer = p_renderer
	name = "Machine_%s" % machine_id
	build()

func build() -> void:
	clear_visuals()
	if renderer.is_valid():
		renderer.call(self)

func clear_visuals() -> void:
	for child in get_children():
		child.queue_free()
