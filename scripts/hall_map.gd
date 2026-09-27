extends GridMapBase

const FLOOR_A := Color("c8c2b6")
const FLOOR_B := Color("beb8ad")
const GRID_COLOR := Color(0.32, 0.30, 0.28, 0.38)
const BORDER_COLOR := Color("f0e6d2")
const WALL_TOP := Color("5c6670")
const WALL_SIDE := Color("3d454d")
const ENTRANCE_COLOR := Color("77b8d8")
const WALL_HEIGHT := 18.0
const ISLAND_COLOR := Color("8a5b3d")
const ISLAND_EDGE := Color("d7aa78")
const ISLAND_PREVIEW_OK := Color(0.25, 0.90, 0.45, 0.38)
const ISLAND_PREVIEW_BAD := Color(0.95, 0.25, 0.25, 0.38)
const ISLAND_WIDTH := 6
const ISLAND_HEIGHT := 2

@onready var camera: Camera2D = $Camera2D
@onready var info_text: Label = $UI/InfoPanel/Margin/Text

var dragging := false
var last_mouse_position := Vector2.ZERO
var entrance_tiles: Array[Vector2i] = []
var island_mode := false
var hovered_tile := Vector2i(-1, -1)
var next_island_id := 1

func _ready() -> void:
	map_width = 32
	map_height = 24
	build_map("floor")
	_build_shell()
	camera.position = Vector2(0.0, map_height * tile_height * 0.5)
	camera.zoom = Vector2(0.9, 0.9)
	_update_info()
	queue_redraw()

func _build_shell() -> void:
	var entrance_left := map_width / 2 - 1
	var entrance_right := map_width / 2
	entrance_tiles = [Vector2i(entrance_left, map_height - 1), Vector2i(entrance_right, map_height - 1)]
	for y in range(map_height):
		for x in range(map_width):
			var tile := Vector2i(x, y)
			var is_edge := x == 0 or x == map_width - 1 or y == 0 or y == map_height - 1
			if not is_edge:
				continue
			var cell: Dictionary = get_cell(tile)
			if entrance_tiles.has(tile):
				cell["type"] = "entrance"
				cell["occupied"] = false
				cell["object_id"] = "main_entrance"
			else:
				cell["type"] = "wall"
				cell["occupied"] = true
				cell["object_id"] = "outer_wall"

func _draw() -> void:
	for y in range(map_height):
		for x in range(map_width):
			var tile := Vector2i(x, y)
			var points: PackedVector2Array = tile_points(x, y)
			var cell: Dictionary = get_cell(tile)
			var floor_color: Color = FLOOR_A if (x + y) % 2 == 0 else FLOOR_B
			if cell["type"] == "entrance":
				floor_color = ENTRANCE_COLOR
			draw_colored_polygon(points, floor_color)
			draw_polyline(points + PackedVector2Array([points[0]]), GRID_COLOR, 1.0, true)
			if cell["type"] == "island":
				draw_colored_polygon(points, ISLAND_COLOR)
				draw_polyline(points + PackedVector2Array([points[0]]), ISLAND_EDGE, 1.5, true)

	for y in range(map_height):
		for x in range(map_width):
			var tile := Vector2i(x, y)
			if get_cell(tile)["type"] == "wall":
				_draw_wall_tile(tile)

	if island_mode and is_valid_tile(hovered_tile):
		_draw_island_preview(hovered_tile)

	var top: Vector2 = grid_to_world(0, 0) + Vector2(0.0, -tile_height * 0.5)
	var right: Vector2 = grid_to_world(map_width - 1, 0) + Vector2(tile_width * 0.5, 0.0)
	var bottom: Vector2 = grid_to_world(map_width - 1, map_height - 1) + Vector2(0.0, tile_height * 0.5)
	var left: Vector2 = grid_to_world(0, map_height - 1) + Vector2(-tile_width * 0.5, 0.0)
	draw_polyline(PackedVector2Array([top, right, bottom, left, top]), BORDER_COLOR, 3.0, true)

func _draw_wall_tile(tile: Vector2i) -> void:
	var base: PackedVector2Array = tile_points(tile.x, tile.y)
	var top := PackedVector2Array()
	for point in base:
		top.append(point + Vector2(0.0, -WALL_HEIGHT))
	var side_right := PackedVector2Array([base[1], base[2], top[2], top[1]])
	var side_left := PackedVector2Array([base[2], base[3], top[3], top[2]])
	draw_colored_polygon(side_right, WALL_SIDE)
	draw_colored_polygon(side_left, WALL_SIDE)
	draw_colored_polygon(top, WALL_TOP)
	draw_polyline(top + PackedVector2Array([top[0]]), BORDER_COLOR, 1.0, true)

func _island_tiles(origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(ISLAND_HEIGHT):
		for x in range(ISLAND_WIDTH):
			result.append(origin + Vector2i(x, y))
	return result

func _can_place_island(origin: Vector2i) -> bool:
	for tile in _island_tiles(origin):
		if not is_valid_tile(tile):
			return false
		var cell: Dictionary = get_cell(tile)
		if cell["type"] != "floor" or bool(cell.get("occupied", false)):
			return false
	return true

func _draw_island_preview(origin: Vector2i) -> void:
	var preview_color: Color = ISLAND_PREVIEW_OK if _can_place_island(origin) else ISLAND_PREVIEW_BAD
	for tile in _island_tiles(origin):
		if is_valid_tile(tile):
			draw_colored_polygon(tile_points(tile.x, tile.y), preview_color)

func _place_island(origin: Vector2i) -> void:
	if not _can_place_island(origin):
		return
	var island_id := "island_%d" % next_island_id
	for tile in _island_tiles(origin):
		var cell: Dictionary = get_cell(tile)
		cell["type"] = "island"
		cell["occupied"] = true
		cell["object_id"] = island_id
	next_island_id += 1
	queue_redraw()

func _process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		camera.position += direction * 700.0 * delta / camera.zoom.x
	_refresh_hover()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			island_mode = true
			_update_info()
			queue_redraw()
			return
		if event.keycode == KEY_ESCAPE:
			if island_mode:
				island_mode = false
				_update_info()
				queue_redraw()
			else:
				get_tree().change_scene_to_file("res://main.tscn")
			return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
			last_mouse_position = event.position
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed and island_mode:
			_place_island(_tile_under_mouse())
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
	var new_hover: Vector2i = _tile_under_mouse()
	if not is_valid_tile(new_hover):
		new_hover = Vector2i(-1, -1)
	if new_hover != hovered_tile:
		hovered_tile = new_hover
		queue_redraw()

func _update_info() -> void:
	if island_mode:
		info_text.text = "遊創舎 HALL MAP 02\n島配置モード: I\n6×2マス / 左クリック: 配置 / Esc: 終了"
	else:
		info_text.text = "遊創舎 HALL MAP 02\n店内: 32 × 24 マス\nI: 島配置 / Esc: 屋外へ戻る"

func _set_zoom(value: float) -> void:
	var new_zoom: float = clampf(value, 0.45, 2.0)
	camera.zoom = Vector2(new_zoom, new_zoom)
	_refresh_hover()
