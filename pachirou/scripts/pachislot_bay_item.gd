class_name PachislotBayItem
extends Node2D

enum Direction {
	LEFT_DOWN,
	LEFT_UP,
	RIGHT_UP,
	RIGHT_DOWN,
}

var direction: Direction = Direction.LEFT_DOWN
var renderer: Callable

func setup(p_direction: Direction, p_renderer: Callable) -> void:
	direction = p_direction
	renderer = p_renderer
	name = "PachislotBay_%s" % direction_name()

func build() -> void:
	if renderer.is_valid():
		renderer.call(self, direction)

func direction_name() -> String:
	match direction:
		Direction.LEFT_DOWN:
			return "LEFT_DOWN"
		Direction.LEFT_UP:
			return "LEFT_UP"
		Direction.RIGHT_UP:
			return "RIGHT_UP"
		Direction.RIGHT_DOWN:
			return "RIGHT_DOWN"
	return "UNKNOWN"
