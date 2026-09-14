extends Node2D

@export var map_width: int = 10
@export var map_height: int = 10
@export var tile_width: float = 64.0
@export var tile_height: float = 32.0

const FLOOR_A := Color("c9c9c9")
const FLOOR_B := Color("a8a8a8")
const BASE_FRONT := Color("555b62")
const BASE_SIDE := Color("3f454c")
const BASE_TOP := Color("8d9399")
const BACKBOARD := Color("666d75")
const BACKBOARD_SIDE := Color("444b53")
const SHELF_TOP := Color("a7adb4")
const SHELF_EDGE := Color("656c74")
const MACHINE_FRONT := Color("242932")
const MACHINE_SIDE := Color("171b22")
const MACHINE_TOP := Color("555b64")
const MACHINE_TRIM := Color("a7adb5")
const MACHINE_ACCENT := Color("c45139")
const MACHINE_DARK := Color("11151b")
const REEL_BG := Color("f2eee3")
const REEL_LINE := Color("c9c2b2")
const REEL_SYMBOL_RED := Color("d65a4a")
const REEL_SYMBOL_BLUE := Color("4d76b8")
const REEL_SYMBOL_GOLD := Color("d5a84b")
const BUTTON_RED := Color("d94a3f")
const BUTTON_DARK := Color("2b3037")
const SAND_FRONT := Color("727982")
const SAND_SIDE := Color("4c535b")
const SAND_TOP := Color("a1a7ae")
const SAND_SCREEN := Color("202a31")
const COUNTER_FRONT := Color("242a31")
const COUNTER_SIDE := Color("151a1f")
const COUNTER_SCREEN := Color("79b6d8")
const SEAT_TOP := Color("4c535d")
const SEAT_INNER := Color("343a42")
const SEAT_SIDE := Color("292f36")
const METAL := Color("aeb4bb")
const METAL_DARK := Color("666d75")

const BASE_HEIGHT := 36.0
const MACHINE_HEIGHT := 54.0
const SAND_HEIGHT := 48.0
const BACKBOARD_HEIGHT := 64.0
const STOOL_SCALE := 0.90

const WIDTH_AXIS := Vector2(32.0, 16.0)
const DEPTH_AXIS := Vector2(32.0, -16.0)
const MACHINE_FRONT_VECTOR := Vector2(21.0, 10.5)
const SAND_FRONT_VECTOR := Vector2(6.0, 3.0)
const MACHINE_DEPTH := Vector2(16.0, -8.0)
const SAND_DEPTH := Vector2(12.0, -6.0)
const BACKBOARD_THICKNESS_RATIO := 0.12
const BASE_DEPTH_RATIO := 0.70
const UNIT_REAR_SHIFT := Vector2(6.0, -3.0)
const STOOL_FRONT_OFFSET := Vector2(-40.0, 18.0)

var world: Node2D

func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()
	_create_island_bay(Vector2i(6, 4))
	_create_stool(Vector2i(6, 4))

func grid_to_world(cell: Vector2i) -> Vector2:
	var cx: float = (map_width - 1) * 0.5
	var cy: float = (map_height - 1) * 0.5
	var gx: float = float(cell.x) - cx
	var gy: float = float(cell.y) - cy
	return Vector2((gx - gy) * tile_width * 0.5, (gx + gy) * tile_height * 0.5)

func _tile_points() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, -16), Vector2(32, 0), Vector2(0, 16), Vector2(-32, 0)])

func _create_floor() -> void:
	var floor := Node2D.new()
	floor.name = "Floor"
	world.add_child(floor)
	for y in range(map_height):
		for x in range(map_width):
			var tile := Polygon2D.new()
			tile.polygon = _tile_points()
			tile.color = FLOOR_A if (x + y) % 2 == 0 else FLOOR_B
			tile.position = grid_to_world(Vector2i(x, y))
			tile.z_index = -1000
			floor.add_child(tile)

func _create_island_bay(cell: Vector2i) -> void:
	var bay := Node2D.new()
	bay.name = "IslandBay"
	bay.position = grid_to_world(cell) + UNIT_REAR_SHIFT
	bay.z_index = int(bay.position.y)
	world.add_child(bay)
	_create_island_frame(bay)
	_create_machine_and_sand(bay)
	_create_data_counter(bay)

func _base_top_left() -> Vector2:
	return Vector2(-32, -BASE_HEIGHT)

func _base_top_front() -> Vector2:
	return Vector2(0, 16 - BASE_HEIGHT)

func _base_back_left() -> Vector2:
	return _base_top_left() + DEPTH_AXIS * BASE_DEPTH_RATIO

func _base_back_right() -> Vector2:
	return _base_top_front() + DEPTH_AXIS * BASE_DEPTH_RATIO

func _board_thickness() -> Vector2:
	return -DEPTH_AXIS * BACKBOARD_THICKNESS_RATIO

func _board_front_left() -> Vector2:
	return _base_back_left() + _board_thickness()

func _board_front_right() -> Vector2:
	return _base_back_right() + _board_thickness()

func _create_island_frame(parent: Node2D) -> void:
	var floor_left := Vector2(-32, 0)
	var floor_front := Vector2(0, 16)
	var floor_back_right := floor_front + DEPTH_AXIS * BASE_DEPTH_RATIO
	var top_left := _base_top_left()
	var top_front := _base_top_front()
	var top_back_left := _base_back_left()
	var top_back_right := _base_back_right()
	_add_poly(parent, PackedVector2Array([floor_left, floor_front, top_front, top_left]), BASE_FRONT, 0)
	_add_poly(parent, PackedVector2Array([floor_front, floor_back_right, top_back_right, top_front]), BASE_SIDE, 0)
	_add_poly(parent, PackedVector2Array([top_back_left, top_back_right, top_front, top_left]), BASE_TOP, 0)
	var board_bottom_left := top_back_left
	var board_bottom_right := top_back_right
	var board_up := Vector2(0, -BACKBOARD_HEIGHT)
	var board_thickness := _board_thickness()
	_add_poly(parent, PackedVector2Array([board_bottom_left, board_bottom_right, board_bottom_right + board_up, board_bottom_left + board_up]), BACKBOARD, 1)
	_add_poly(parent, PackedVector2Array([board_bottom_right, board_bottom_right + board_thickness, board_bottom_right + board_thickness + board_up, board_bottom_right + board_up]), BACKBOARD_SIDE, 2)
	var shelf_back_left := _board_front_left() + Vector2(0, -MACHINE_HEIGHT)
	var shelf_back_right := _board_front_right() + Vector2(0, -MACHINE_HEIGHT)
	var shelf_forward := -DEPTH_AXIS * 0.18
	var shelf_front_left := shelf_back_left + shelf_forward
	var shelf_front_right := shelf_back_right + shelf_forward
	var shelf_drop := Vector2(0, 1.5)
	_add_poly(parent, PackedVector2Array([shelf_back_left, shelf_back_right, shelf_front_right, shelf_front_left]), SHELF_TOP, 20)
	_add_poly(parent, PackedVector2Array([shelf_front_left, shelf_front_right, shelf_front_right + shelf_drop, shelf_front_left + shelf_drop]), SHELF_EDGE, 20)

func _equipment_front_left() -> Vector2:
	return _base_top_left() + WIDTH_AXIS * 0.03 + DEPTH_AXIS * 0.08

func _create_machine_and_sand(parent: Node2D) -> void:
	var machine_lb := _equipment_front_left()
	var machine_fb := machine_lb + MACHINE_FRONT_VECTOR
	var sand_lb := machine_fb
	var sand_fb := sand_lb + SAND_FRONT_VECTOR
	_create_machine(parent, machine_lb, machine_fb, MACHINE_DEPTH)
	_create_sand(parent, sand_lb, sand_fb, SAND_DEPTH)

func _create_machine(parent: Node2D, lb: Vector2, fb: Vector2, depth: Vector2) -> void:
	var up := Vector2(0, -MACHINE_HEIGHT)
	var front_push := -depth * 0.14
	_add_poly(parent, PackedVector2Array([lb, fb, fb + up, lb + up]), MACHINE_FRONT, 10)
	_add_poly(parent, PackedVector2Array([fb, fb + depth, fb + depth + up, fb + up]), MACHINE_SIDE, 10)
	_add_poly(parent, PackedVector2Array([lb + depth + up, fb + depth + up, fb + up, lb + up]), MACHINE_TOP, 10)
	_add_poly(parent, _face_quad(lb, fb, up, 0.03, 0.10, 0.06, 0.96), MACHINE_TRIM, 11)
	_add_poly(parent, _face_quad(lb, fb, up, 0.90, 0.97, 0.06, 0.96), MACHINE_TRIM, 11)

	var upper_lb := _face_point(lb, fb, up, 0.10, 0.78)
	var upper_rb := _face_point(lb, fb, up, 0.90, 0.78)
	var upper_up := Vector2(0, -MACHINE_HEIGHT * 0.17)
	_create_front_box(parent, upper_lb, upper_rb, upper_up, front_push * 0.45, MACHINE_DARK, MACHINE_SIDE, MACHINE_TOP, 14)
	_add_poly(parent, _face_quad(upper_lb + front_push * 0.45, upper_rb + front_push * 0.45, upper_up, 0.10, 0.90, 0.22, 0.72), MACHINE_ACCENT, 15)

	var reel_lb := _face_point(lb, fb, up, 0.08, 0.43)
	var reel_rb := _face_point(lb, fb, up, 0.92, 0.43)
	var reel_up := Vector2(0, -MACHINE_HEIGHT * 0.31)
	_create_front_box(parent, reel_lb, reel_rb, reel_up, front_push * 0.28, MACHINE_TRIM, MACHINE_SIDE, MACHINE_TOP, 14)
	var reel_face_lb := reel_lb + front_push * 0.28
	var reel_face_rb := reel_rb + front_push * 0.28
	for i in range(3):
		var u0: float = 0.07 + float(i) * 0.30
		var u1: float = u0 + 0.24
		_add_poly(parent, _face_quad(reel_face_lb, reel_face_rb, reel_up, u0, u1, 0.10, 0.88), REEL_BG, 15)
		_add_poly(parent, _face_quad(reel_face_lb, reel_face_rb, reel_up, u0 + 0.05, u1 - 0.05, 0.20, 0.31), REEL_SYMBOL_RED, 16)
		_add_poly(parent, _face_quad(reel_face_lb, reel_face_rb, reel_up, u0 + 0.05, u1 - 0.05, 0.44, 0.55), REEL_SYMBOL_GOLD, 16)
		_add_poly(parent, _face_quad(reel_face_lb, reel_face_rb, reel_up, u0 + 0.05, u1 - 0.05, 0.68, 0.79), REEL_SYMBOL_BLUE, 16)
		if i < 2:
			_add_poly(parent, _face_quad(reel_face_lb, reel_face_rb, reel_up, u1 + 0.015, u1 + 0.035, 0.08, 0.90), REEL_LINE, 16)

	var deck_lb := _face_point(lb, fb, up, 0.06, 0.28)
	var deck_rb := _face_point(lb, fb, up, 0.94, 0.28)
	var deck_up := Vector2(0, -MACHINE_HEIGHT * 0.13)
	_create_front_box(parent, deck_lb, deck_rb, deck_up, front_push, MACHINE_DARK, MACHINE_SIDE, MACHINE_TOP, 17)
	var deck_face_lb := deck_lb + front_push
	var deck_face_rb := deck_rb + front_push
	_add_poly(parent, _face_quad(deck_face_lb, deck_face_rb, deck_up, 0.09, 0.24, 0.22, 0.72), BUTTON_DARK, 18)
	for i in range(3):
		var center_u: float = 0.43 + float(i) * 0.18
		_add_poly(parent, _face_ellipse(deck_face_lb, deck_face_rb, deck_up, center_u, 0.47, 0.060, 0.23, 18), BUTTON_RED, 18)
		_add_poly(parent, _face_ellipse(deck_face_lb, deck_face_rb, deck_up, center_u, 0.47, 0.034, 0.13, 16), Color("f4d4cf"), 19)

	_add_poly(parent, _face_quad(lb, fb, up, 0.10, 0.90, 0.09, 0.27), Color("303741"), 11)
	_add_poly(parent, _face_quad(lb, fb, up, 0.19, 0.81, 0.14, 0.23), MACHINE_ACCENT, 12)
	var tray_lb := _face_point(lb, fb, up, 0.10, 0.035)
	var tray_rb := _face_point(lb, fb, up, 0.90, 0.035)
	var tray_up := Vector2(0, -MACHINE_HEIGHT * 0.075)
	_create_front_box(parent, tray_lb, tray_rb, tray_up, front_push * 1.05, MACHINE_DARK, MACHINE_SIDE, MACHINE_TOP, 17)
	var tray_face_lb := tray_lb + front_push * 1.05
	var tray_face_rb := tray_rb + front_push * 1.05
	_add_poly(parent, _face_quad(tray_face_lb, tray_face_rb, tray_up, 0.13, 0.87, 0.18, 0.60), Color("07090c"), 18)
	_add_poly(parent, _face_quad(tray_face_lb, tray_face_rb, tray_up, 0.20, 0.80, 0.12, 0.23), MACHINE_TRIM, 19)

func _create_front_box(parent: Node2D, lb: Vector2, rb: Vector2, up: Vector2, push: Vector2, front_color: Color, side_color: Color, top_color: Color, z: int) -> void:
	var fl := lb + push
	var fr := rb + push
	var bl := lb
	var br := rb
	_add_poly(parent, PackedVector2Array([fl, fr, fr + up, fl + up]), front_color, z)
	_add_poly(parent, PackedVector2Array([fr, br, br + up, fr + up]), side_color, z - 1)
	_add_poly(parent, PackedVector2Array([bl + up, br + up, fr + up, fl + up]), top_color, z)

func _create_sand(parent: Node2D, lb: Vector2, fb: Vector2, depth: Vector2) -> void:
	var up := Vector2(0, -SAND_HEIGHT)
	_add_poly(parent, PackedVector2Array([lb, fb, fb + up, lb + up]), SAND_FRONT, 10)
	_add_poly(parent, PackedVector2Array([fb, fb + depth, fb + depth + up, fb + up]), SAND_SIDE, 10)
	_add_poly(parent, PackedVector2Array([lb + depth + up, fb + depth + up, fb + up, lb + up]), SAND_TOP, 10)
	_add_poly(parent, _face_quad(lb, fb, up, 0.18, 0.82, 0.70, 0.85), SAND_SCREEN, 11)
	_add_poly(parent, _face_quad(lb, fb, up, 0.20, 0.80, 0.43, 0.54), Color("c3c8ce"), 11)
	_add_poly(parent, _face_quad(lb, fb, up, 0.22, 0.78, 0.18, 0.28), Color("343b43"), 11)

func _create_data_counter(parent: Node2D) -> void:
	var shelf_back_left: Vector2 = _board_front_left() + Vector2(0, -MACHINE_HEIGHT)
	var shelf_forward: Vector2 = -DEPTH_AXIS * 0.18
	var shelf_front_left: Vector2 = shelf_back_left + shelf_forward
	var machine_ratio: float = MACHINE_FRONT_VECTOR.x / WIDTH_AXIS.x
	var counter_right_ratio: float = minf(machine_ratio - 0.06, 0.62)
	var counter_left: Vector2 = shelf_front_left + WIDTH_AXIS * 0.08
	var counter_right: Vector2 = shelf_front_left + WIDTH_AXIS * counter_right_ratio
	var counter_up: Vector2 = Vector2(0, -7)
	var counter_depth: Vector2 = DEPTH_AXIS * 0.10
	_add_poly(parent, PackedVector2Array([counter_left, counter_right, counter_right + counter_up, counter_left + counter_up]), COUNTER_FRONT, 30)
	_add_poly(parent, PackedVector2Array([counter_right, counter_right + counter_depth, counter_right + counter_depth + counter_up, counter_right + counter_up]), COUNTER_SIDE, 30)
	_add_poly(parent, _face_quad(counter_left, counter_right, counter_up, 0.12, 0.88, 0.20, 0.78), COUNTER_SCREEN, 31)

func _create_stool(cell: Vector2i) -> void:
	var stool := Node2D.new()
	stool.name = "Stool"
	stool.position = grid_to_world(cell) + UNIT_REAR_SHIFT + STOOL_FRONT_OFFSET
	stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)
	stool.z_index = int(stool.position.y)
	world.add_child(stool)
	var seat_y := -38.4
	_add_poly(stool, _ellipse(Vector2(0, -1), 15.2, 6.4, 28), METAL_DARK)
	_add_poly(stool, _ellipse(Vector2(0, -2), 11.0, 4.2, 24), METAL)
	_add_poly(stool, PackedVector2Array([Vector2(-2, seat_y + 5), Vector2(2, seat_y + 5), Vector2(2, -5), Vector2(-2, -5)]), METAL)
	_add_poly(stool, _ellipse_band(Vector2(0, seat_y), 16.0, 6.7, 5.0, 28), SEAT_SIDE)
	_add_poly(stool, _ellipse(Vector2(0, seat_y), 16.0, 6.7, 32), SEAT_TOP)
	_add_poly(stool, _ellipse(Vector2(0, seat_y - 0.7), 12.0, 4.4, 28), SEAT_INNER)

func _face_point(lb: Vector2, fb: Vector2, up: Vector2, u: float, v: float) -> Vector2:
	return lb.lerp(fb, u) + up * v

func _face_quad(lb: Vector2, fb: Vector2, up: Vector2, u0: float, u1: float, v0: float, v1: float) -> PackedVector2Array:
	return PackedVector2Array([_face_point(lb, fb, up, u0, v0), _face_point(lb, fb, up, u1, v0), _face_point(lb, fb, up, u1, v1), _face_point(lb, fb, up, u0, v1)])

func _face_ellipse(lb: Vector2, fb: Vector2, up: Vector2, center_u: float, center_v: float, radius_u: float, radius_v: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		var u: float = center_u + cos(angle) * radius_u
		var v: float = center_v + sin(angle) * radius_v
		points.append(_face_point(lb, fb, up, u, v))
	return points

func _ellipse(center: Vector2, rx: float, ry: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	return points

func _ellipse_band(center: Vector2, rx: float, ry: float, thickness: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var angle: float = PI * t
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	for i in range(segments, -1, -1):
		var t: float = float(i) / float(segments)
		var angle: float = PI * t
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry) + Vector2(0, thickness))
	return points

func _add_poly(parent: Node2D, points: PackedVector2Array, color: Color, z: int = 0) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	polygon.z_index = z
	parent.add_child(polygon)
	return polygon