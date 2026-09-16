class_name PachislotBayItem
extends Node2D

enum Direction {
	LEFT_DOWN,
	LEFT_UP,
}

var cell: Vector2i = Vector2i.ZERO
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

func setup(p_cell: Vector2i, p_direction: Direction, p_renderer: Callable) -> void:
	cell = p_cell
	direction = p_direction
	renderer = p_renderer
	name = "PachislotBay_%d_%d_%s" % [cell.x, cell.y, direction_name()]

func place_on_grid(grid: IsometricGrid) -> void:
	position = grid.cell_origin(cell)
	z_index = int(position.y)

func set_cell(p_cell: Vector2i, grid: IsometricGrid) -> void:
	cell = p_cell
	place_on_grid(grid)

func set_direction(p_direction: Direction) -> void:
	direction = p_direction
	build()

func build() -> void:
	clear_visuals()
	_reset_component_transforms()
	if renderer.is_valid():
		renderer.call(self, direction)

func clear_visuals() -> void:
	_clear_visual_children(island_base)
	_clear_visual_children(back_board)
	_clear_visual_children(upper_box)
	_clear_visual_children(machine)
	_clear_visual_children(sand)
	_clear_visual_children(data_counter)
	_clear_visual_children(stool)

func direction_name() -> String:
	match direction:
		Direction.LEFT_DOWN:
			return "LEFT_DOWN"
		Direction.LEFT_UP:
			return "LEFT_UP"
	return "UNKNOWN"

func _reset_component_transforms() -> void:
	frame.position = Vector2.ZERO
	equipment.position = Vector2.ZERO
	stool.position = Vector2.ZERO
	frame.rotation = 0.0
	equipment.rotation = 0.0
	stool.rotation = 0.0
	frame.scale = Vector2.ONE
	equipment.scale = Vector2.ONE
	stool.scale = Vector2.ONE

func _clear_visual_children(parent: Node2D) -> void:
	for child in parent.get_children():
		child.queue_free()
