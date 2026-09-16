class_name PachislotBayItem
extends Node2D

enum Direction {
	LEFT_DOWN,
}

var direction: Direction = Direction.LEFT_DOWN
var renderer: Callable

@onready var frame: Node2D = $Frame
@onready var island_base: Node2D = $Frame/IslandBase
@onready var back_board: Node2D = $Frame/BackBoard
@onready var upper_box: Node2D = $Frame/UpperBox
@onready var equipment: Node2D = $Equipment
@onready var machine: Node2D = $Equipment/Machine
@onready var sand: Node2D = $Equipment/Sand
@onready var data_counter: Node2D = $Equipment/DataCounter
@onready var stool: Node2D = $Stool

func setup(p_renderer: Callable) -> void:
	renderer = p_renderer
	name = "PachislotBay"

func build() -> void:
	clear_visuals()
	if renderer.is_valid():
		renderer.call(self)

func clear_visuals() -> void:
	_clear_visual_children(island_base)
	_clear_visual_children(back_board)
	_clear_visual_children(upper_box)
	_clear_visual_children(machine)
	_clear_visual_children(sand)
	_clear_visual_children(data_counter)
	_clear_visual_children(stool)

func _clear_visual_children(parent: Node2D) -> void:
	for child in parent.get_children():
		child.queue_free()
