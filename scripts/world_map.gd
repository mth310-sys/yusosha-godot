extends GridMapBase

const LAND_A := Color("789b55")
const LAND_B := Color("739450")
const GRID_COLOR := Color(0.18, 0.27, 0.13, 0.42)
const BORDER_COLOR := Color("d9e7b5")
const HOVER_COLOR := Color(1.0, 1.0, 1.0, 0.22)
const SELECT_COLOR := Color(1.0, 0.78, 0.18, 0.48)
const ROAD_COLOR := Color("4b5058")
const ROAD_GRID_COLOR := Color(0.72, 0.74, 0.78, 0.45)
const ROAD_MARK_COLOR := Color(0.95, 0.82, 0.30, 0.92)

@onready var camera: Camera2D = $Camera2D
@onready var tile_info: Label = $UI/TilePanel/Margin/Text
@onready var mode_info: Label = $UI/ModePanel/Margin/Text

var dragging := false
var last_mouse_position := Vector2.ZERO
var hovered_tile := Vector2i(-1, -1)
var selected_tile := Vector2i(-1, -1)
var road_mode := false
var painting_road := false
var demolition_mode := false
var demolishing := false

func _ready() -> void:
	build_map("land")
	camera.position = Vector2(0.0, map_height * tile_height * 0.5)
	camera.zoom = Vector2(0.72, 0.72)
	_update_tile_info()
	_update_mode_info()
	queue_redraw()

func _draw() -> void:
	for y in range(map_height):
		for x in range(map_width):
			var points: PackedVector2Array = tile_points(x, y)
			var cell: Dictionary = map_data[y][x]
			var tile_color: Color = ROAD_COLOR if cell["type"] == "road" else (LAND_A if (x + y) % 2 == 0 else LAND_B)
			var line_color: Color = ROAD_GRID_COLOR if cell["type"] == "road" else GRID_COLOR
			draw_colored_polygon(points, tile_color)
			draw_polyline(points + PackedVector2Array([points[0]]), line_color, 1.0, true)
			if cell["type"] == "road":
				_draw_road_connections(Vector2i(x, y))

	if is_valid_tile(hovered_tile) and hovered_tile != selected_tile:
		draw_colored_polygon(tile_points(hovered_tile.x, hovered_tile.y), HOVER_COLOR)
	if is_valid_tile(selected_tile):
		var selected_points: PackedVector2Array = tile_points(selected_tile.x, selected_tile.y)
		draw_colored_polygon(selected_points, SELECT_COLOR)
		draw_polyline(selected_points + PackedVector2Array([selected_points[0]]), Color.WHITE, 2.0, true)

	var top: Vector2 = grid_to_world(0, 0) + Vector2(0.0, -tile_height * 0.5)
	var right: Vector2 = grid_to_world(map_width - 1, 0) + Vector2(tile_width * 0.5, 0.0)
	var bottom: Vector2 = grid_to_world(map_width - 1, map_height - 1) + Vector2(0.0, tile_height * 0.5)
	var left: Vector2 = grid_to_world(0, map_height - 1) + Vector2(-tile_width * 0.5, 0.0)
	draw_polyline(PackedVector2Array([top, right, bottom, left, top]), BORDER_COLOR, 3.0, true)

func _is_road(tile: Vector2i) -> bool:
	return is_valid_tile(tile) and map_data[tile.y][tile.x]["type"] == "road"

func _road_connections(tile: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var directions: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	for direction in directions:
		if _is_road(tile + direction):
			result.append(direction)
	return result

func _road_shape(tile: Vector2i) -> String:
	var connections: Array[Vector2i] = _road_connections(tile)
	var count: int = connections.size()
	if count == 0:
		return "isolated"
	if count == 1:
		return "dead_end"
	if count == 4:
		return "cross"
	if count == 3:
		return "t_junction"
	if connections[0] + connections[1] == Vector2i.ZERO:
		return "straight"
	return "corner"

func _draw_road_connections(tile: Vector2i) -> void:
	var center: Vector2 = grid_to_world(tile.x, tile.y)
	var connections: Array[Vector2i] = _road_connections(tile)
	if connections.is_empty():
		draw_circle(center, 3.5, ROAD_MARK_COLOR)
		return
	for direction in connections:
		var neighbor_center: Vector2 = grid_to_world(tile.x + direction.x, tile.y + direction.y)
		draw_line(center, center.lerp(neighbor_center, 0.5), ROAD_MARK_COLOR, 2.2, true)
	draw_circle(center, 2.8, ROAD_MARK_COLOR)

func _process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		camera.position += direction * 700.0 * delta / camera.zoom.x
	_refresh_hover()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			road_mode = true
			demolition_mode = false
			painting_road = false
			demolishing = false
			_update_mode_info()
			_update_tile_info()
			queue_redraw()
			return
		if event.keycode == KEY_X:
			demolition_mode = true
			road_mode = false
			painting_road = false
			demolishing = false
			_update_mode_info()
			_update_tile_info()
			queue_redraw()
			return
		if event.keycode == KEY_ESCAPE:
			road_mode = false
			demolition_mode = false
			painting_road = false
			demolishing = false
			_update_mode_info()
			_update_tile_info()
			queue_redraw()
			return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
			last_mouse_position = event.position
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if road_mode:
				painting_road = event.pressed
				if event.pressed:
					_paint_road(_tile_under_mouse())
			elif demolition_mode:
				demolishing = event.pressed
				if event.pressed:
					_demolish_road(_tile_under_mouse())
			elif event.pressed:
				var tile: Vector2i = _tile_under_mouse()
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
		elif road_mode and painting_road:
			_paint_road(_tile_under_mouse())
		elif demolition_mode and demolishing:
			_demolish_road(_tile_under_mouse())
		_refresh_hover()

func _paint_road(tile: Vector2i) -> void:
	if not is_valid_tile(tile):
		return
	var cell: Dictionary = map_data[tile.y][tile.x]
	if cell["type"] == "road":
		return
	cell["type"] = "road"
	cell["occupied"] = true
	cell["object_id"] = "road"
	_update_road_shapes_around(tile)
	selected_tile = tile
	_update_tile_info()
	queue_redraw()

func _demolish_road(tile: Vector2i) -> void:
	if not _is_road(tile):
		return
	var cell: Dictionary = map_data[tile.y][tile.x]
	cell["type"] = "land"
	cell["occupied"] = false
	cell["object_id"] = ""
	cell["road_shape"] = ""
	_update_road_shapes_around(tile)
	selected_tile = tile
	_update_tile_info()
	queue_redraw()

func _update_road_shapes_around(tile: Vector2i) -> void:
	var affected: Array[Vector2i] = [
		tile,
		tile + Vector2i(0, -1),
		tile + Vector2i(1, 0),
		tile + Vector2i(0, 1),
		tile + Vector2i(-1, 0)
	]
	for current in affected:
		if _is_road(current):
			map_data[current.y][current.x]["road_shape"] = _road_shape(current)

func _update_mode_info() -> void:
	if road_mode:
		mode_info.text = "道路モード: ON\n左クリック/ドラッグ: 敷設 / X: 撤去 / Esc: 終了"
	elif demolition_mode:
		mode_info.text = "撤去モード: ON\n左クリック/ドラッグ: 道路撤去 / R: 敷設 / Esc: 終了"
	else:
		mode_info.text = "通常モード\nR: 道路敷設 / X: 道路撤去"

func _tile_under_mouse() -> Vector2i:
	return world_to_grid(get_global_mouse_position())

func _refresh_hover() -> void:
	var new_hover: Vector2i = _tile_under_mouse()
	if not is_valid_tile(new_hover):
		new_hover = Vector2i(-1, -1)
	if new_hover != hovered_tile:
		hovered_tile = new_hover
		_update_tile_info()
		queue_redraw()

func _update_tile_info() -> void:
	if is_valid_tile(selected_tile):
		var cell: Dictionary = map_data[selected_tile.y][selected_tile.x]
		if cell["type"] == "road":
			tile_info.text = "選択マス: (%d, %d)\n種別: road / 形状: %s" % [selected_tile.x, selected_tile.y, cell.get("road_shape", _road_shape(selected_tile))]
		else:
			tile_info.text = "選択マス: (%d, %d)\n種別: %s / 使用中: %s" % [selected_tile.x, selected_tile.y, cell["type"], "はい" if cell["occupied"] else "いいえ"]
	elif is_valid_tile(hovered_tile):
		if road_mode:
			tile_info.text = "カーソル: (%d, %d)\n道路を敷設できます" % [hovered_tile.x, hovered_tile.y]
		elif demolition_mode:
			tile_info.text = "カーソル: (%d, %d)\n道路を撤去できます" % [hovered_tile.x, hovered_tile.y]
		else:
			tile_info.text = "カーソル: (%d, %d)\n左クリックで選択" % [hovered_tile.x, hovered_tile.y]
	else:
		if road_mode:
			tile_info.text = "道路モード中"
		elif demolition_mode:
			tile_info.text = "撤去モード中"
		else:
			tile_info.text = "マスを選択してください\n左クリック: 選択"

func _set_zoom(value: float) -> void:
	var new_zoom: float = clampf(value, 0.35, 2.0)
	camera.zoom = Vector2(new_zoom, new_zoom)
	_refresh_hover()
