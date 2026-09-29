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
const LOT_COLOR := Color(0.20, 0.62, 0.92, 0.14)
const LOT_BORDER_COLOR := Color(0.38, 0.78, 1.0, 0.58)
const LOT_PREVIEW_COLOR := Color(0.30, 0.78, 1.0, 0.18)
const BUILDING_COLOR := Color(0.72, 0.36, 0.20, 0.88)
const BUILDING_PREVIEW_OK := Color(0.25, 0.90, 0.45, 0.38)
const BUILDING_PREVIEW_BAD := Color(0.95, 0.25, 0.25, 0.38)
const BUILDING_WIDTH := 6
const BUILDING_HEIGHT := 5

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
var lot_mode := false
var lot_start := Vector2i(-1, -1)
var next_lot_id := 1
var building_mode := false
var next_building_id := 1
var buildings: Dictionary = {}

func _ready() -> void:
	if GameState.world_initialized:
		map_data = GameState.world_map_data.duplicate(true)
		buildings = GameState.world_buildings.duplicate(true)
		next_lot_id = GameState.next_lot_id
		next_building_id = GameState.next_building_id
	else:
		build_map("land")
		_generate_initial_city()
	camera.position = Vector2(0.0, map_height * tile_height * 0.5)
	camera.zoom = Vector2(0.72, 0.72)
	_update_tile_info()
	_update_mode_info()
	queue_redraw()


func _generate_initial_city() -> void:
	# Fixed town layout. Roads divide the map into blocks and lots vary in size.
	# Two-tile central avenues.
	for x in range(24, 26):
		for y in range(map_height):
			_set_generated_road(Vector2i(x, y))
	for y in range(24, 26):
		for x in range(map_width):
			_set_generated_road(Vector2i(x, y))

	# One-tile local streets, connected to the central avenues and map edges.
	for y in [8, 16, 34, 42]:
		for x in range(map_width):
			_set_generated_road(Vector2i(x, y))
	for x in [8, 16, 34, 42]:
		for y in range(map_height):
			_set_generated_road(Vector2i(x, y))

	# Lots deliberately vary from compact to large hall sites.
	# North-west.
	_generate_lot_rect(Vector2i(1, 1), Vector2i(7, 7))
	_generate_lot_rect(Vector2i(9, 1), Vector2i(15, 7))
	_generate_lot_rect(Vector2i(17, 1), Vector2i(23, 7))
	_generate_lot_rect(Vector2i(1, 9), Vector2i(7, 15))
	_generate_lot_rect(Vector2i(9, 9), Vector2i(15, 15))
	_generate_lot_rect(Vector2i(17, 9), Vector2i(23, 15))
	_generate_lot_rect(Vector2i(1, 17), Vector2i(15, 23))
	_generate_lot_rect(Vector2i(17, 17), Vector2i(23, 23))

	# North-east.
	_generate_lot_rect(Vector2i(26, 1), Vector2i(33, 7))
	_generate_lot_rect(Vector2i(35, 1), Vector2i(41, 7))
	_generate_lot_rect(Vector2i(43, 1), Vector2i(48, 15))
	_generate_lot_rect(Vector2i(26, 9), Vector2i(33, 15))
	_generate_lot_rect(Vector2i(35, 9), Vector2i(41, 15))
	_generate_lot_rect(Vector2i(26, 17), Vector2i(41, 23))
	_generate_lot_rect(Vector2i(43, 17), Vector2i(48, 23))

	# South-west.
	_generate_lot_rect(Vector2i(1, 26), Vector2i(15, 33))
	_generate_lot_rect(Vector2i(17, 26), Vector2i(23, 33))
	_generate_lot_rect(Vector2i(1, 35), Vector2i(7, 41))
	_generate_lot_rect(Vector2i(9, 35), Vector2i(23, 41))
	_generate_lot_rect(Vector2i(1, 43), Vector2i(7, 48))
	_generate_lot_rect(Vector2i(9, 43), Vector2i(15, 48))
	_generate_lot_rect(Vector2i(17, 43), Vector2i(23, 48))

	# South-east: keep several large commercial plots.
	_generate_lot_rect(Vector2i(26, 26), Vector2i(41, 33))
	_generate_lot_rect(Vector2i(43, 26), Vector2i(48, 33))
	_generate_lot_rect(Vector2i(26, 35), Vector2i(33, 48))
	_generate_lot_rect(Vector2i(35, 35), Vector2i(48, 41))
	_generate_lot_rect(Vector2i(35, 43), Vector2i(41, 48))
	_generate_lot_rect(Vector2i(43, 43), Vector2i(48, 48))

	_recalculate_all_road_shapes()

func _set_generated_road(tile: Vector2i) -> void:
	if not is_valid_tile(tile):
		return
	var cell: Dictionary = get_cell(tile)
	cell["type"] = "road"
	cell["occupied"] = true
	cell["object_id"] = "road"
	cell["lot_id"] = 0

func _generate_lot_rect(a: Vector2i, b: Vector2i) -> void:
	var lot_id := next_lot_id
	var placed := false
	for y in range(a.y, b.y + 1):
		for x in range(a.x, b.x + 1):
			var tile := Vector2i(x, y)
			if not is_valid_tile(tile) or _is_road(tile):
				continue
			var cell: Dictionary = get_cell(tile)
			cell["lot_id"] = lot_id
			placed = true
	if placed:
		next_lot_id += 1

func _recalculate_all_road_shapes() -> void:
	for y in range(map_height):
		for x in range(map_width):
			var tile := Vector2i(x, y)
			if _is_road(tile):
				get_cell(tile)["road_shape"] = _road_shape(tile)

func _draw() -> void:
	for y in range(map_height):
		for x in range(map_width):
			var points: PackedVector2Array = tile_points(x, y)
			var cell: Dictionary = map_data[y][x]
			var tile_color: Color = ROAD_COLOR if cell["type"] == "road" else (LAND_A if (x + y) % 2 == 0 else LAND_B)
			var line_color: Color = ROAD_GRID_COLOR if cell["type"] == "road" else GRID_COLOR
			draw_colored_polygon(points, tile_color)
			draw_polyline(points + PackedVector2Array([points[0]]), line_color, 1.0, true)
			if int(cell.get("lot_id", 0)) > 0:
				draw_colored_polygon(points, LOT_COLOR)
				draw_polyline(points + PackedVector2Array([points[0]]), LOT_BORDER_COLOR, 1.4, true)
			if str(cell.get("object_id", "")).begins_with("hall_"):
				draw_colored_polygon(points, BUILDING_COLOR)
			if cell["type"] == "road":
				_draw_road_connections(Vector2i(x, y))

	if lot_mode and is_valid_tile(lot_start) and is_valid_tile(hovered_tile):
		_draw_lot_preview(lot_start, hovered_tile)
	if building_mode and is_valid_tile(hovered_tile):
		_draw_building_preview(hovered_tile)

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
		if event.keycode == KEY_ENTER:
			_enter_selected_building()
			return
		if event.keycode == KEY_B:
			building_mode = true
			lot_mode = false
			road_mode = false
			demolition_mode = false
			painting_road = false
			demolishing = false
			lot_start = Vector2i(-1, -1)
			_update_mode_info()
			_update_tile_info()
			queue_redraw()
			return
		if event.keycode == KEY_L:
			lot_mode = true
			building_mode = false
			road_mode = false
			demolition_mode = false
			painting_road = false
			demolishing = false
			lot_start = Vector2i(-1, -1)
			_update_mode_info()
			_update_tile_info()
			queue_redraw()
			return
		if event.keycode == KEY_R:
			road_mode = true
			lot_mode = false
			building_mode = false
			lot_start = Vector2i(-1, -1)
			demolition_mode = false
			painting_road = false
			demolishing = false
			_update_mode_info()
			_update_tile_info()
			queue_redraw()
			return
		if event.keycode == KEY_X:
			demolition_mode = true
			lot_mode = false
			building_mode = false
			lot_start = Vector2i(-1, -1)
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
			lot_mode = false
			building_mode = false
			lot_start = Vector2i(-1, -1)
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
			if building_mode and event.pressed:
				_place_building(_tile_under_mouse())
			elif lot_mode and event.pressed:
				_handle_lot_click(_tile_under_mouse())
			elif road_mode:
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
	if cell["type"] == "road" or not is_cell_free(tile):
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

func _draw_lot_preview(a: Vector2i, b: Vector2i) -> void:
	var min_x: int = mini(a.x, b.x)
	var max_x: int = maxi(a.x, b.x)
	var min_y: int = mini(a.y, b.y)
	var max_y: int = maxi(a.y, b.y)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var tile := Vector2i(x, y)
			if is_valid_tile(tile) and not _is_road(tile):
				draw_colored_polygon(tile_points(x, y), LOT_PREVIEW_COLOR)

func _handle_lot_click(tile: Vector2i) -> void:
	if not is_valid_tile(tile) or _is_road(tile):
		return
	if not is_valid_tile(lot_start):
		lot_start = tile
		selected_tile = tile
		_update_tile_info()
		queue_redraw()
		return
	_create_lot(lot_start, tile)
	lot_start = Vector2i(-1, -1)
	selected_tile = tile
	_update_tile_info()
	queue_redraw()

func _create_lot(a: Vector2i, b: Vector2i) -> void:
	var min_x: int = mini(a.x, b.x)
	var max_x: int = maxi(a.x, b.x)
	var min_y: int = mini(a.y, b.y)
	var max_y: int = maxi(a.y, b.y)
	var placed := false
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var tile := Vector2i(x, y)
			if not _is_road(tile):
				map_data[y][x]["lot_id"] = next_lot_id
				placed = true
	if placed:
		next_lot_id += 1

func _building_tiles(origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(BUILDING_HEIGHT):
		for x in range(BUILDING_WIDTH):
			result.append(origin + Vector2i(x, y))
	return result

func _can_place_building(origin: Vector2i) -> bool:
	var origin_cell: Dictionary = get_cell(origin)
	if origin_cell.is_empty():
		return false
	var required_lot_id: int = int(origin_cell.get("lot_id", 0))
	if required_lot_id <= 0:
		return false
	for tile in _building_tiles(origin):
		if not is_valid_tile(tile):
			return false
		var cell: Dictionary = get_cell(tile)
		if int(cell.get("lot_id", 0)) != required_lot_id:
			return false
		if cell["type"] == "road" or bool(cell.get("occupied", false)):
			return false
	return true

func _draw_building_preview(origin: Vector2i) -> void:
	var preview_color: Color = BUILDING_PREVIEW_OK if _can_place_building(origin) else BUILDING_PREVIEW_BAD
	for tile in _building_tiles(origin):
		if is_valid_tile(tile):
			draw_colored_polygon(tile_points(tile.x, tile.y), preview_color)

func _place_building(origin: Vector2i) -> void:
	if not _can_place_building(origin):
		return
	var building_id := "hall_%d" % next_building_id
	var lot_id: int = int(get_cell(origin).get("lot_id", 0))
	var entrance := origin + Vector2i(BUILDING_WIDTH / 2, BUILDING_HEIGHT - 1)
	buildings[building_id] = {
		"id": building_id,
		"type": "pachinko_hall",
		"name": "仮ホール %d" % next_building_id,
		"lot_id": lot_id,
		"origin": origin,
		"size": Vector2i(BUILDING_WIDTH, BUILDING_HEIGHT),
		"entrance": entrance
	}
	for tile in _building_tiles(origin):
		var cell: Dictionary = get_cell(tile)
		cell["occupied"] = true
		cell["object_id"] = building_id
	next_building_id += 1
	selected_tile = origin
	_update_tile_info()
	queue_redraw()

func _enter_selected_building() -> void:
	if not is_valid_tile(selected_tile):
		return
	var object_id: String = str(get_cell(selected_tile).get("object_id", ""))
	if not buildings.has(object_id):
		return
	GameState.selected_building_id = object_id
	GameState.store_world(map_data, buildings, next_lot_id, next_building_id)
	get_tree().change_scene_to_file("res://hall.tscn")

func _update_mode_info() -> void:
	if building_mode:
		mode_info.text = "建物モード: ON\n仮ホール 6×5 / 左クリック: 配置 / Esc: 終了"
	elif lot_mode:
		mode_info.text = "敷地モード: ON\n始点 → 終点をクリック / Esc: 終了"
	elif road_mode:
		mode_info.text = "道路モード: ON\n左クリック/ドラッグ: 敷設 / X: 撤去 / Esc: 終了"
	elif demolition_mode:
		mode_info.text = "撤去モード: ON\n左クリック/ドラッグ: 道路撤去 / R: 敷設 / Esc: 終了"
	else:
		mode_info.text = "通常モード\n初期街マップ生成済み / B: 建物\nR: 道路 / X: 撤去 / L: 敷地編集"

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
			var object_id: String = str(cell.get("object_id", ""))
			if buildings.has(object_id):
				var building: Dictionary = buildings[object_id]
				tile_info.text = "%s\n建物ID: %s / Enter: 店内へ" % [building["name"], building["id"]]
			else:
				tile_info.text = "選択マス: (%d, %d)\n種別: %s / 使用中: %s" % [selected_tile.x, selected_tile.y, cell["type"], "はい" if cell["occupied"] else "いいえ"]
	elif is_valid_tile(hovered_tile):
		if building_mode:
			tile_info.text = "カーソル: (%d, %d)\n仮ホール 6×5: %s" % [hovered_tile.x, hovered_tile.y, "配置可能" if _can_place_building(hovered_tile) else "配置不可"]
		elif lot_mode:
			tile_info.text = "カーソル: (%d, %d)\n%s" % [hovered_tile.x, hovered_tile.y, "終点を選択" if is_valid_tile(lot_start) else "敷地の始点を選択"]
		elif road_mode:
			tile_info.text = "カーソル: (%d, %d)\n道路を敷設できます" % [hovered_tile.x, hovered_tile.y]
		elif demolition_mode:
			tile_info.text = "カーソル: (%d, %d)\n道路を撤去できます" % [hovered_tile.x, hovered_tile.y]
		else:
			tile_info.text = "カーソル: (%d, %d)\n左クリックで選択" % [hovered_tile.x, hovered_tile.y]
	else:
		if building_mode:
			tile_info.text = "建物モード中"
		elif lot_mode:
			tile_info.text = "敷地モード中"
		elif road_mode:
			tile_info.text = "道路モード中"
		elif demolition_mode:
			tile_info.text = "撤去モード中"
		else:
			tile_info.text = "マスを選択してください\n左クリック: 選択"

func _set_zoom(value: float) -> void:
	var new_zoom: float = clampf(value, 0.35, 2.0)
	camera.zoom = Vector2(new_zoom, new_zoom)
	_refresh_hover()
