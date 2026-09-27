extends Node2D

const MAP_WIDTH := 50
const MAP_HEIGHT := 50
const TILE_WIDTH := 64.0
const TILE_HEIGHT := 32.0

const LAND_A := Color("789b55")
const LAND_B := Color("739450")
const GRID_COLOR := Color(0.18, 0.27, 0.13, 0.42)
const BORDER_COLOR := Color("d9e7b5")
const HOVER_COLOR := Color(1.0, 1.0, 1.0, 0.22)
const SELECT_COLOR := Color(1.0, 0.78, 0.18, 0.48)

@onready var camera: Camera2D = $Camera2D
@onready var tile_info: Label = $UI/TilePanel/Margin/Text

var dragging := false
var last_mouse_position := Vector2.ZERO
var hovered_tile := Vector2i(-1, -1)
var selected_tile := Vector2i(-1, -1)
var map_data: Array = []

func _ready() -> void:
	_build_map_data()
	camera.position = Vector2(0.0, MAP_HEIGHT * TILE_HEIGHT * 0.5)
	camera.zoom = Vector2(0.72, 0.72)
	_update_tile_info()
	queue_redraw()

func _build_map_data() -> void:
	map_data.clear()
	for y in range(MAP_HEIGHT):
		var row: Array = []
		for x in range(MAP_WIDTH):
			row.append({
				"type": "land",
				"occupied": false,
				"object_id": ""
			})
		map_data.append(row)

func grid_to_world(x: int, y: int) -> Vector2:
	return Vector2(
		(x - y) * TILE_WIDTH * 0.5,
		(x + y) * TILE_HEIGHT * 0.5
	)

func world_to_grid(world_position: Vector2) -> Vector2i:
	var gx := world_position.x / TILE_WIDTH + world_position.y / TILE_HEIGHT
	var gy := world_position.y / TILE_HEIGHT - world_position.x / TILE_WIDTH
	return Vector2i(floori(gx + 0.5), floori(gy + 0.5))

func is_valid_tile(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < MAP_WIDTH and tile.y >= 0 and tile.y < MAP_HEIGHT

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

	if is_valid_tile(hovered_tile) and hovered_tile != selected_tile:
		draw_colored_polygon(tile_points(hovered_tile.x, hovered_tile.y), HOVER_COLOR)

	if is_valid_tile(selected_tile):
		var selected_points := tile_points(selected_tile.x, selected_tile.y)
		draw_colored_polygon(selected_points, SELECT_COLOR)
		draw_polyline(selected_points + PackedVector2Array([selected_points[0]]), Color.WHITE, 2.0, true)

	var top := grid_to_world(0, 0) + Vector2(0.0, -TILE_HEIGHT * 0.5)
	var right := grid_to_world(MAP_WIDTH - 1, 0) + Vector2(TILE_WIDTH * 0.5, 0.0)
	var bottom := grid_to_world(MAP_WIDTH - 1, MAP_HEIGHT - 1) + Vector2(0.0, TILE_HEIGHT * 0.5)
	var left := grid_to_world(0, MAP_HEIGHT - 1) + Vector2(-TILE_WIDTH * 0.5, 0.0)
	draw_polyline(PackedVector2Array([top, right, bottom, left, top]), BORDER_COLOR, 3.0, true)

func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		camera.position += direction * 700.0 * delta / camera.zoom.x
	_refresh_hover()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
			last_mouse_position = event.position
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var tile := _tile_under_mouse()
			if is_valid_tile(tile):
				selected_tile = tile
				_update_tile_info()
				queue_redraw()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(camera.zoom.x * 1.12)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(camera.zoom.x / 1.12)

	elif event is InputEventMouseMotion:
		if dragging:
			var movement: Vector2 = event.position - last_mouse_position
			camera.position -= movement / camera.zoom.x
			last_mouse_position = event.position
		_refresh_hover()

func _tile_under_mouse() -> Vector2i:
	return world_to_grid(get_global_mouse_position())

func _refresh_hover() -> void:
	var new_hover := _tile_under_mouse()
	if not is_valid_tile(new_hover):
		new_hover = Vector2i(-1, -1)
	if new_hover != hovered_tile:
		hovered_tile = new_hover
		_update_tile_info()
		queue_redraw()

func _update_tile_info() -> void:
	if is_valid_tile(selected_tile):
		var cell: Dictionary = map_data[selected_tile.y][selected_tile.x]
		tile_info.text = "選択マス: (%d, %d)\n種別: %s / 使用中: %s" % [
			selected_tile.x,
			selected_tile.y,
			cell["type"],
			"はい" if cell["occupied"] else "いいえ"
		]
	elif is_valid_tile(hovered_tile):
		tile_info.text = "カーソル: (%d, %d)\n左クリックで選択" % [hovered_tile.x, hovered_tile.y]
	else:
		tile_info.text = "マスを選択してください\n左クリック: 選択"

func _set_zoom(value: float) -> void:
	var new_zoom := clampf(value, 0.35, 2.0)
	camera.zoom = Vector2(new_zoom, new_zoom)
	_refresh_hover()
