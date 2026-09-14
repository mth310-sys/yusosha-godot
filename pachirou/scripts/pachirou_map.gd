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
const MACHINE_FRONT := Color("2949c7")
const MACHINE_SIDE := Color("19318e")
const MACHINE_TOP := Color("5873e6")
const MACHINE_DARK := Color("172139")
const REEL_BG := Color("f4f6fa")
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
const BACKBOARD_HEIGHT := 62.0
const STOOL_SCALE := 0.76

# One-cell equipment footprint.
# Front edge follows the same 2:1 isometric axis as the floor.
# Depth follows the opposite 2:-1 isometric axis.
const SET_FRONT_START := Vector2(-20.0, -40.0)
const MACHINE_FRONT_VECTOR := Vector2(22.0, 11.0)
const SAND_FRONT_VECTOR := Vector2(6.0, 3.0)
const EQUIPMENT_DEPTH := Vector2(8.0, -4.0)

var world: Node2D

func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()
	_create_island_bay(Vector2i(6, 4))
	_create_stool(Vector2i(5, 5))

func grid_to_world(cell: Vector2i) -> Vector2:
	var cx: float = (map_width - 1) * 0.5
	var cy: float = (map_height - 1) * 0.5
	var gx: float = float(cell.x) - cx
	var gy: float = float(cell.y) - cy
	return Vector2((gx - gy) * tile_width * 0.5, (gx + gy) * tile_height * 0.5)

func _tile_points() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -16),
		Vector2(32, 0),
		Vector2(0, 16),
		Vector2(-32, 0)
	])

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
	bay.position = grid_to_world(cell)
	bay.z_index = int(bay.position.y)
	world.add_child(bay)

	_create_full_cell_base(bay)
	_create_backboard(bay)
	_create_machine_and_sand(bay)
	_create_shelf_and_counter(bay)

func _create_full_cell_base(parent: Node2D) -> void:
	var back := Vector2(0, -16)
	var right := Vector2(32, 0)
	var front := Vector2(0, 16)
	var left := Vector2(-32, 0)
	var up := Vector2(0, -BASE_HEIGHT)

	_add_poly(parent, PackedVector2Array([left, front, front + up, left + up]), BASE_FRONT, 0)
	_add_poly(parent, PackedVector2Array([front, right, right + up, front + up]), BASE_SIDE, 0)
	_add_poly(parent, PackedVector2Array([back + up, right + up, front + up, left + up]), BASE_TOP, 0)

func _create_machine_and_sand(parent: Node2D) -> void:
	var machine_lb := SET_FRONT_START
	var machine_fb := machine_lb + MACHINE_FRONT_VECTOR
	var sand_lb := machine_fb
	var sand_fb := sand_lb + SAND_FRONT_VECTOR

	_create_machine(parent, machine_lb, machine_fb, EQUIPMENT_DEPTH)
	_create_sand(parent, sand_lb, sand_fb, EQUIPMENT_DEPTH)

func _create_backboard(parent: Node2D) -> void:
	# Rear edge is derived from the exact machine+sand footprint.
	var front_left := SET_FRONT_START
	var front_right := SET_FRONT_START + MACHINE_FRONT_VECTOR + SAND_FRONT_VECTOR
	var rear_left := front_left + EQUIPMENT_DEPTH
	var rear_right := front_right + EQUIPMENT_DEPTH
	var up := Vector2(0, -BACKBOARD_HEIGHT)
	var thickness := Vector2(3.0, -1.5)

	_add_poly(parent, PackedVector2Array([rear_left, rear_right, rear_right + up, rear_left + up]), BACKBOARD, 1)
	_add_poly(parent, PackedVector2Array([rear_right, rear_right + thickness, rear_right + thickness + up, rear_right + up]), BACKBOARD_SIDE, 1)

func _create_machine(parent: Node2D, lb: Vector2, fb: Vector2, depth: Vector2) -> void:
	var up := Vector2(0, -MACHINE_HEIGHT)
	_add_poly(parent, PackedVector2Array([lb, fb, fb + up, lb + up]), MACHINE_FRONT, 10)
	_add_poly(parent, PackedVector2Array([fb, fb + depth, fb + depth + up, fb + up]), MACHINE_SIDE, 10)
	_add_poly(parent, PackedVector2Array([lb + depth + up, fb + depth + up, fb + up, lb + up]), MACHINE_TOP, 10)

	_add_poly(parent, _face_quad(lb, fb, up, 0.10, 0.90, 0.73, 0.91), MACHINE_DARK, 11)
	_add_poly(parent, _face_quad(lb, fb, up, 0.10, 0.90, 0.43, 0.68), REEL_BG, 11)
	for i in range(3):
		var u0: float = 0.14 + float(i) * 0.25
		_add_poly(parent, _face_quad(lb, fb, up, u0, u0 + 0.19, 0.48, 0.64), Color("ffffff"), 12)
	_add_poly(parent, _face_quad(lb, fb, up, 0.12, 0.88, 0.12, 0.30), Color("20336f"), 11)

func _create_sand(parent: Node2D, lb: Vector2, fb: Vector2, depth: Vector2) -> void:
	var up := Vector2(0, -SAND_HEIGHT)
	_add_poly(parent, PackedVector2Array([lb, fb, fb + up, lb + up]), SAND_FRONT, 10)
	_add_poly(parent, PackedVector2Array([fb, fb + depth, fb + depth + up, fb + up]), SAND_SIDE, 10)
	_add_poly(parent, PackedVector2Array([lb + depth + up, fb + depth + up, fb + up, lb + up]), SAND_TOP, 10)

	_add_poly(parent, _face_quad(lb, fb, up, 0.18, 0.82, 0.70, 0.85), SAND_SCREEN, 11)
	_add_poly(parent, _face_quad(lb, fb, up, 0.20, 0.80, 0.43, 0.54), Color("c3c8ce"), 11)
	_add_poly(parent, _face_quad(lb, fb, up, 0.22, 0.78, 0.18, 0.28), Color("343b43"), 11)

func _create_shelf_and_counter(parent: Node2D) -> void:
	var machine_lb := SET_FRONT_START
	var machine_fb := machine_lb + MACHINE_FRONT_VECTOR
	var set_fb := machine_fb + SAND_FRONT_VECTOR
	var shelf_y_offset := Vector2(0, -MACHINE_HEIGHT - 3.0)

	# Shelf uses the same left/right span as the machine+sand set and a shallower depth.
	var shelf_left := machine_lb + shelf_y_offset
	var shelf_right := set_fb + shelf_y_offset
	var shelf_depth := EQUIPMENT_DEPTH * 0.75
	var shelf_back_left := shelf_left + shelf_depth
	var shelf_back_right := shelf_right + shelf_depth
	var drop := Vector2(0, 1.5)

	_add_poly(parent, PackedVector2Array([shelf_back_left, shelf_back_right, shelf_right, shelf_left]), SHELF_TOP, 20)
	_add_poly(parent, PackedVector2Array([shelf_left, shelf_right, shelf_right + drop, shelf_left + drop]), SHELF_EDGE, 20)

	# Counter is centered over the machine only.
	var machine_center := (machine_lb + machine_fb) * 0.5 + Vector2(0, -MACHINE_HEIGHT - 4.0)
	var counter_half := MACHINE_FRONT_VECTOR * 0.28
	var counter_lb := machine_center - counter_half
	var counter_fb := machine_center + counter_half
	var counter_up := Vector2(0, -7)
	var counter_depth := Vector2(3.5, -1.75)

	_add_poly(parent, PackedVector2Array([counter_lb, counter_fb, counter_fb + counter_up, counter_lb + counter_up]), COUNTER_FRONT, 30)
	_add_poly(parent, PackedVector2Array([counter_fb, counter_fb + counter_depth, counter_fb + counter_depth + counter_up, counter_fb + counter_up]), COUNTER_SIDE, 30)
	_add_poly(parent, _face_quad(counter_lb, counter_fb, counter_up, 0.12, 0.88, 0.20, 0.78), COUNTER_SCREEN, 31)

func _create_stool(cell: Vector2i) -> void:
	var stool := Node2D.new()
	stool.name = "Stool"

	# Align the stool with the machine face center, projected into the adjacent aisle cell.
	var machine_center_x := (SET_FRONT_START.x + (SET_FRONT_START + MACHINE_FRONT_VECTOR).x) * 0.5
	stool.position = grid_to_world(cell) + Vector2(machine_center_x * 0.32, -4)
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
	return PackedVector2Array([
		_face_point(lb, fb, up, u0, v0),
		_face_point(lb, fb, up, u1, v0),
		_face_point(lb, fb, up, u1, v1),
		_face_point(lb, fb, up, u0, v1)
	])

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
