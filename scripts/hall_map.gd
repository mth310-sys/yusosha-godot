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
const MACHINE_SLOT_EMPTY := Color("f4d35e")
const MACHINE_SLOT_EDGE := Color("fff2b2")
const MACHINE_BODY := Color("4056a1")
const MACHINE_SCREEN := Color("9ee7ff")
const ISLAND_WIDTH := 6
const ISLAND_HEIGHT := 2

@onready var camera: Camera2D = $Camera2D
@onready var info_text: Label = $UI/InfoPanel/Margin/Text
@onready var machine_panel: PanelContainer = $UI/MachinePanel
@onready var machine_text: Label = $UI/MachinePanel/Margin/Text
@onready var daily_panel: PanelContainer = $UI/DailyPanel
@onready var daily_text: Label = $UI/DailyPanel/Margin/Text

var dragging := false
var last_mouse_position := Vector2.ZERO
var entrance_tiles: Array[Vector2i] = []
var island_mode := false
var hovered_tile := Vector2i(-1, -1)
var next_island_id := 1
var island_rotated := false
var islands: Dictionary = {}
var machine_mode := false
var machines: Dictionary = {}
var next_machine_id := 1
var selected_machine_id := ""
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	map_width = 32
	map_height = 24
	var saved_hall: Dictionary = GameState.get_hall(GameState.selected_building_id)
	if saved_hall.is_empty():
		build_map("floor")
		_build_shell()
	else:
		map_data = saved_hall["map_data"].duplicate(true)
		islands = saved_hall["islands"].duplicate(true)
		next_island_id = int(saved_hall["next_island_id"])
		machines = saved_hall.get("machines", {}).duplicate(true)
		next_machine_id = int(saved_hall.get("next_machine_id", 1))
	camera.position = Vector2(0.0, map_height * tile_height * 0.5)
	camera.zoom = Vector2(0.9, 0.9)
	rng.randomize()
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

	for island_id in islands:
		_draw_machine_slots(islands[island_id])
	for machine_id in machines:
		_draw_machine(machines[machine_id])

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

func _build_machine_slots(origin: Vector2i, rotated: bool, island_id: String) -> Array:
	var slots: Array = []
	for index in range(ISLAND_WIDTH):
		if rotated:
			slots.append({
				"slot_id": "%s_A_%02d" % [island_id, index + 1],
				"island_id": island_id,
				"position": origin + Vector2i(0, index),
				"facing": "west",
				"machine_id": ""
			})
			slots.append({
				"slot_id": "%s_B_%02d" % [island_id, index + 1],
				"island_id": island_id,
				"position": origin + Vector2i(1, index),
				"facing": "east",
				"machine_id": ""
			})
		else:
			slots.append({
				"slot_id": "%s_A_%02d" % [island_id, index + 1],
				"island_id": island_id,
				"position": origin + Vector2i(index, 0),
				"facing": "north",
				"machine_id": ""
			})
			slots.append({
				"slot_id": "%s_B_%02d" % [island_id, index + 1],
				"island_id": island_id,
				"position": origin + Vector2i(index, 1),
				"facing": "south",
				"machine_id": ""
			})
	return slots

func _draw_machine_slots(island: Dictionary) -> void:
	var slots: Array = island.get("machine_slots", [])
	for slot in slots:
		if str(slot.get("machine_id", "")) != "":
			continue
		var tile: Vector2i = slot["position"]
		var center: Vector2 = grid_to_world(tile.x, tile.y)
		draw_circle(center, 4.5, MACHINE_SLOT_EMPTY)
		draw_circle(center, 4.5, MACHINE_SLOT_EDGE, false, 1.2, true)

func _draw_machine(machine: Dictionary) -> void:
	var tile: Vector2i = machine["position"]
	var center: Vector2 = grid_to_world(tile.x, tile.y)
	var body := Rect2(center - Vector2(7.0, 12.0), Vector2(14.0, 20.0))
	draw_rect(body, MACHINE_BODY)
	draw_rect(Rect2(center - Vector2(4.5, 8.5), Vector2(9.0, 6.0)), MACHINE_SCREEN)
	draw_string(ThemeDB.fallback_font, center + Vector2(-5.0, 5.0), str(machine["number"]), HORIZONTAL_ALIGNMENT_CENTER, 10.0, 8, Color.WHITE)

func _machine_at(tile: Vector2i) -> String:
	for machine_id in machines:
		if machines[machine_id]["position"] == tile:
			return machine_id
	return ""

func _select_machine(tile: Vector2i) -> void:
	selected_machine_id = _machine_at(tile)
	_update_machine_panel()
	queue_redraw()

func _update_machine_panel() -> void:
	if selected_machine_id == "" or not machines.has(selected_machine_id):
		machine_panel.visible = false
		return
	var machine: Dictionary = machines[selected_machine_id]
	var model: Dictionary = MachineCatalog.get_model(str(machine.get("model_id", "")))
	var power_text := "ON" if bool(machine.get("power_on", true)) else "OFF"
	var operating_text := "稼働中" if bool(machine.get("operating", false)) else "停止"
	machine_text.text = "台詳細\n台番号: %d\n機種: %s\n設定: %d\n電源: %s / %s\nゲーム数: %d\nIN: %d枚\nOUT: %d枚\n差枚: %+d枚\n売上: %d円\n\n1〜6: 設定変更 / T: 営業テスト" % [
		int(machine.get("number", 0)),
		str(model.get("name", "不明")),
		int(machine.get("setting", 1)),
		power_text,
		operating_text,
		int(machine.get("games", 0)),
		int(machine.get("coin_in", 0)),
		int(machine.get("coin_out", 0)),
		int(machine.get("net_coins", 0)),
		int(machine.get("sales_yen", 0))
	]
	machine_panel.visible = true

func _simulate_machine(machine: Dictionary, min_games: int, max_games: int) -> Dictionary:
	if not bool(machine.get("power_on", true)):
		return {"games": 0, "coin_in": 0, "coin_out": 0, "net": 0, "sales": 0}
	var setting: int = clampi(int(machine.get("setting", 1)), 1, 6)
	var games: int = rng.randi_range(min_games, max_games)
	var coin_in: int = games * 3
	var payout_rates := [0.965, 0.980, 0.995, 1.015, 1.040, 1.070]
	var expected_out: float = float(coin_in) * payout_rates[setting - 1]
	var variance: float = rng.randf_range(-0.12, 0.12)
	var coin_out: int = maxi(0, int(round(expected_out * (1.0 + variance))))
	var net: int = coin_out - coin_in
	var sales: int = maxi(0, -net * 20)
	machine["games"] = int(machine.get("games", 0)) + games
	machine["coin_in"] = int(machine.get("coin_in", 0)) + coin_in
	machine["coin_out"] = int(machine.get("coin_out", 0)) + coin_out
	machine["net_coins"] = int(machine.get("coin_out", 0)) - int(machine.get("coin_in", 0))
	machine["sales_yen"] = int(machine.get("sales_yen", 0)) + sales
	return {"games": games, "coin_in": coin_in, "coin_out": coin_out, "net": net, "sales": sales}

func _run_full_day() -> void:
	if machines.is_empty():
		return
	var total_games := 0
	var total_in := 0
	var total_out := 0
	var total_sales := 0
	for machine_id in machines:
		var result: Dictionary = _simulate_machine(machines[machine_id], 1800, 7000)
		total_games += int(result["games"])
		total_in += int(result["coin_in"])
		total_out += int(result["coin_out"])
		total_sales += int(result["sales"])
	var total_net: int = total_out - total_in
	var gross_profit: int = (total_in - total_out) * 20
	daily_text.text = "1営業日 結果\n設置台数: %d台\n総ゲーム数: %dG\nIN: %d枚 / OUT: %d枚\n差枚: %+d枚\n売上: %d円\n粗利: %+d円" % [
		machines.size(), total_games, total_in, total_out, total_net, total_sales, gross_profit
	]
	daily_panel.visible = true
	_update_machine_panel()
	queue_redraw()

func _run_selected_machine_test() -> void:
	if selected_machine_id == "" or not machines.has(selected_machine_id):
		return
	var machine: Dictionary = machines[selected_machine_id]
	if not bool(machine.get("power_on", true)):
		return
	machine["operating"] = true
	_simulate_machine(machine, 180, 320)
	machine["operating"] = false
	_update_machine_panel()
	queue_redraw()

func _set_selected_machine_setting(value: int) -> void:
	if selected_machine_id == "" or not machines.has(selected_machine_id):
		return
	machines[selected_machine_id]["setting"] = clampi(value, 1, 6)
	_update_machine_panel()

func _find_empty_slot_at(tile: Vector2i) -> Dictionary:
	for island_id in islands:
		var slots: Array = islands[island_id].get("machine_slots", [])
		for slot in slots:
			if slot["position"] == tile and str(slot.get("machine_id", "")) == "":
				return {"island_id": island_id, "slot_id": slot["slot_id"]}
	return {}

func _place_machine(tile: Vector2i) -> void:
	var found: Dictionary = _find_empty_slot_at(tile)
	if found.is_empty():
		return
	var island_id: String = found["island_id"]
	var slot_id: String = found["slot_id"]
	var slots: Array = islands[island_id]["machine_slots"]
	for slot in slots:
		if slot["slot_id"] == slot_id:
			var machine_id := "machine_%d" % next_machine_id
			slot["machine_id"] = machine_id
			var model: Dictionary = MachineCatalog.get_default_model()
			machines[machine_id] = {
				"id": machine_id,
				"number": next_machine_id,
				"model_id": str(model.get("id", MachineCatalog.DEFAULT_MODEL_ID)),
				"island_id": island_id,
				"slot_id": slot_id,
				"position": slot["position"],
				"facing": slot["facing"],
				"setting": 1,
				"power_on": true,
				"operating": false,
				"occupied_by": "",
				"games": 0,
				"coin_in": 0,
				"coin_out": 0,
				"net_coins": 0,
				"sales_yen": 0
			}
			next_machine_id += 1
			queue_redraw()
			return

func _island_size() -> Vector2i:
	return Vector2i(ISLAND_HEIGHT, ISLAND_WIDTH) if island_rotated else Vector2i(ISLAND_WIDTH, ISLAND_HEIGHT)

func _island_tiles(origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var size: Vector2i = _island_size()
	for y in range(size.y):
		for x in range(size.x):
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
	var size: Vector2i = _island_size()
	islands[island_id] = {
		"id": island_id,
		"origin": origin,
		"size": size,
		"direction": "vertical" if island_rotated else "horizontal",
		"machine_slots": _build_machine_slots(origin, island_rotated, island_id)
	}
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
		if event.keycode == KEY_D:
			_run_full_day()
			return
		if selected_machine_id != "" and event.keycode == KEY_T:
			_run_selected_machine_test()
			return
		if selected_machine_id != "" and event.keycode >= KEY_1 and event.keycode <= KEY_6:
			_set_selected_machine_setting(int(event.keycode - KEY_1 + 1))
			return
		if island_mode and (event.keycode == KEY_Q or event.keycode == KEY_E):
			island_rotated = not island_rotated
			_update_info()
			queue_redraw()
			return
		if event.keycode == KEY_S:
			machine_mode = true
			island_mode = false
			_update_info()
			queue_redraw()
			return
		if event.keycode == KEY_I:
			island_mode = true
			machine_mode = false
			_update_info()
			queue_redraw()
			return
		if event.keycode == KEY_ESCAPE:
			if island_mode or machine_mode:
				island_mode = false
				machine_mode = false
				_update_info()
				queue_redraw()
			else:
				GameState.store_hall(GameState.selected_building_id, map_data, islands, next_island_id, machines, next_machine_id)
				get_tree().change_scene_to_file("res://main.tscn")
			return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
			last_mouse_position = event.position
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed and island_mode:
			_place_island(_tile_under_mouse())
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed and machine_mode:
			_place_machine(_tile_under_mouse())
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not island_mode and not machine_mode:
			_select_machine(_tile_under_mouse())
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
	if machine_mode:
		info_text.text = "遊創舎 HALL MAP 09\\n実機配置モード: S\\n黄色の空き位置を左クリック / Esc: 終了"
	elif island_mode:
		var size: Vector2i = _island_size()
		info_text.text = "遊創舎 HALL MAP 09\n島配置モード\n%d×%d / Q・E: 回転 / 左クリック: 配置 / Esc: 終了" % [size.x, size.y]
	else:
		info_text.text = "遊創舎 HALL MAP 09\n店内: 32 × 24 マス\nI: 島配置 / S: 実機配置 / D: 1日営業 / Esc: 屋外へ戻る"

func _set_zoom(value: float) -> void:
	var new_zoom: float = clampf(value, 0.45, 2.0)
	camera.zoom = Vector2(new_zoom, new_zoom)
	_refresh_hover()
