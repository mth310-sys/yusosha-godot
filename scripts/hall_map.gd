extends GridMapBase

const FLOOR_A := Color("c8c2b6")
const FLOOR_B := Color("beb8ad")
const GRID_COLOR := Color(0.32, 0.30, 0.28, 0.38)
const BORDER_COLOR := Color("f0e6d2")
const WALL_TOP := Color("5c6670")
const WALL_SIDE := Color("3d454d")
const ENTRANCE_COLOR := Color("77b8d8")
const WALL_HEIGHT := 18.0

@onready var camera: Camera2D = $Camera2D

var dragging := false
var last_mouse_position := Vector2.ZERO
var entrance_tiles: Array[Vector2i] = []

func _ready() -> void:
	map_width = 32
	map_height = 24
	build_map("floor")
	_build_shell()
	camera.position = Vector2(0.0, map_height * tile_height * 0.5)
	camera.zoom = Vector2(0.9, 0.9)
	queue_redraw()

func _build_shell() -> void:
	var entrance_left := map_width / 2 - 1
	var entrance_right := map_width / 2
	entrance_tiles = [
		Vector2i(entrance_left, map_height - 1),
		Vector2i(entrance_right, map_height - 1)
	]

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

	for y in range(map_height):
		for x in range(map_width):
			var tile := Vector2i(x, y)
			if get_cell(tile)["type"] == "wall":
				_draw_wall_tile(tile)

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

func _process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		camera.position += direction * 700.0 * delta / camera.zoom.x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://main.tscn")
		return

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
	var new_zoom: float = clampf(value, 0.45, 2.0)
	camera.zoom = Vector2(new_zoom, new_zoom)
