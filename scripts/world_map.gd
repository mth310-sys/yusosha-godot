extends Node2D

const MAP_WIDTH := 50
const MAP_HEIGHT := 50
const TILE_WIDTH := 64.0
const TILE_HEIGHT := 32.0

const LAND_A := Color("789b55")
const LAND_B := Color("739450")
const GRID_COLOR := Color(0.18, 0.27, 0.13, 0.42)
const BORDER_COLOR := Color("d9e7b5")

@onready var camera: Camera2D = $Camera2D

var dragging := false
var last_mouse_position := Vector2.ZERO

func _ready() -> void:
	camera.position = Vector2(0.0, MAP_HEIGHT * TILE_HEIGHT * 0.5)
	camera.zoom = Vector2(0.72, 0.72)
	queue_redraw()

func grid_to_world(x: int, y: int) -> Vector2:
	return Vector2(
		(x - y) * TILE_WIDTH * 0.5,
		(x + y) * TILE_HEIGHT * 0.5
	)

func tile_points(x: int, y: int) -> PackedVector2Array:
	var center := grid_to_world(x, y)
	return PackedVector2Array([
		center + Vector2(0.0, -TILE_HEIGHT * 0.5),
		center + Vector2(TILE_WIDTH * 0.5, 0.0),
		center + Vector2(0.0, TILE_HEIGHT * 0.5),
		center + Vector2(-TILE_WIDTH * 0.5, 0.0)
	])

func _draw() -> void:
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var points := tile_points(x, y)
			var land_color := LAND_A if (x + y) % 2 == 0 else LAND_B
			draw_colored_polygon(points, land_color)
			draw_polyline(points + PackedVector2Array([points[0]]), GRID_COLOR, 1.0, true)

	var top := grid_to_world(0, 0) + Vector2(0.0, -TILE_HEIGHT * 0.5)
	var right := grid_to_world(MAP_WIDTH - 1, 0) + Vector2(TILE_WIDTH * 0.5, 0.0)
	var bottom := grid_to_world(MAP_WIDTH - 1, MAP_HEIGHT - 1) + Vector2(0.0, TILE_HEIGHT * 0.5)
	var left := grid_to_world(0, MAP_HEIGHT - 1) + Vector2(-TILE_WIDTH * 0.5, 0.0)
	var border := PackedVector2Array([top, right, bottom, left, top])
	draw_polyline(border, BORDER_COLOR, 3.0, true)

func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		camera.position += direction * 700.0 * delta / camera.zoom.x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
			last_mouse_position = event.position
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(camera.zoom.x * 1.12)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(camera.zoom.x / 1.12)

	elif event is InputEventMouseMotion and dragging:
		var movement: Vector2 = event.position - last_mouse_position
		camera.position -= movement / camera.zoom.x
		last_mouse_position = event.position

func _set_zoom(value: float) -> void:
	var new_zoom := clampf(value, 0.35, 2.0)
	camera.zoom = Vector2(new_zoom, new_zoom)
