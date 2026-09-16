class_name PachislotBayItem
extends Node2D

enum Direction {
	LEFT_DOWN,
}

var direction: Direction = Direction.LEFT_DOWN
var renderer: Callable

@onready var frame: Node2D = $Frame
@onready var equipment: Node2D = $Equipment
@onready var stool: Node2D = $Stool

func setup(p_renderer: Callable) -> void:
	renderer = p_renderer
	name = "PachislotBay"

func build() -> void:
	clear_visuals()
	if renderer.is_valid():
		renderer.call(self)

func clear_visuals() -> void:
	_clear_children(frame)
	_clear_children(equipment)
	_clear_children(stool)

func _clear_children(parent: Node2D) -> void:
	for child in parent.get_children():
		child.queue_free()
