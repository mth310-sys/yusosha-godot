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
const SHELF := Color("a7adb4")
const MACHINE_FRONT := Color("2949c7")
const MACHINE_SIDE := Color("19318e")
const MACHINE_TOP := Color("5873e6")
const MACHINE_DARK := Color("172139")
const REEL_BG := Color("f4f6fa")
const SAND_FRONT := Color("727982")
const SAND_SIDE := Color("4c535b")
const SAND_TOP := Color("a1a7ae")
const COUNTER := Color("242a31")
const COUNTER_SCREEN := Color("79b6d8")
const SEAT_TOP := Color("4c535d")
const SEAT_INNER := Color("343a42")
const SEAT_SIDE := Color("292f36")
const METAL := Color("aeb4bb")
const METAL_DARK := Color("666d75")

# Fixed design rules.
# One island bay always owns one complete 64x32 grid cell.
const EQUIPMENT_SCALE := 0.72
const STOOL_SCALE := 0.76

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

func _tile_points(scale: float = 1.0) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -tile_height * 0.5 * scale),
		Vector2(tile_width * 0.5 * scale, 0),
		Vector2(0, tile_height * 0.5 * scale),
		Vector2(-tile_width * 0.5 * scale, 0)
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

	# Full-cell base: this footprint is never scaled with the equipment.
	var back := Vector2(0, -16)
	var right := Vector2(32, 0)
	var front := Vector2(0, 16)
	var left := Vector2(-32, 0)
	var base_up := Vector2(0, -36)
	_add_poly(bay, PackedVector2Array([left, front, front + base_up, left + base_up]), BASE_FRONT, 0)
	_add_poly(bay, PackedVector2Array([front, right, right + base_up, front + base_up]), BASE_SIDE, 0)
	_add_poly(bay, PackedVector2Array([back + base_up, right + base_up, front + base_up, left + base_up]), BASE_TOP, 0)
	var mount_y := -36.0

	# Backboard is one clean frame behind the machine+sand pair.
	var board_l := Vector2(-25, mount_y - 5)
	var board_r := Vector2(26, mount_y + 19)
	var board_up := Vector2(0, -57)
	var board_depth := Vector2(3.5, -1.75)
	_add_poly(bay, PackedVector2Array([board_l, board_r, board_r + board_up, board_l + board_up]), BACKBOARD, 1)
	_add_poly(bay, PackedVector2Array([board_r, board_r + board_depth, board_r + board_depth + board_up, board_r + board_up]), BACKBOARD_SIDE, 1)

	# Machine and sand share one parent so their relative spacing cannot drift apart.
	var equipment := Node2D.new()
	equipment.name = "MachineAndSand"
	equipment.position = Vector2(-7, mount_y)
	equipment.scale = Vector2(EQUIPMENT_SCALE, EQUIPMENT_SCALE)
	equipment.z_index = 10
	bay.add_child(equipment)
	_create_machine(equipment, Vector2(-17, 0))
	_create_sand(equipment, Vector2(20, 3))

	# A single shallow shelf spans the equipment pair.
	var equipment_top := mount_y - 49.0
	var shelf_l := Vector2(-23, equipment_top - 3)
	var shelf_f := Vector2(0, equipment_top + 8)
	var shelf_r := Vector2(25, equipment_top + 6)
	var shelf_b := Vector2(3, equipment_top - 5)
	_add_poly(bay, PackedVector2Array([shelf_l, shelf_f, shelf_r, shelf_b]), SHELF, 20)

	# Compact counter centered over the pachislot machine, not over the sand.
	var counter := Node2D.new()
	counter.name = "DataCounter"
	counter.position = Vector2(-8, equipment_top - 1)
	counter.z_index = 30
	bay.add_child(counter)
	_create_counter(counter)

func _create_machine(parent: Node2D, origin: Vector2) -> void:
	var lb := origin + Vector2(-16, 8)
	var fb := origin + Vector2(12, 21)
	var depth := Vector2(14, -7)
	var up := Vector2(0, -68)
	_add_poly(parent, PackedVector2Array([lb, fb, fb + up, lb + up]), MACHINE_FRONT)
	_add_poly(parent, PackedVector2Array([fb, fb + depth, fb + depth + up, fb + up]), MACHINE_SIDE)
	_add_poly(parent, PackedVector2Array([lb + depth + up, fb + depth + up, fb + up, lb + up]), MACHINE_TOP)
	_add_poly(parent, _face_quad(lb, fb, up, 0.10, 0.90, 0.73, 0.91), MACHINE_DARK)
	_add_poly(parent, _face_quad(lb, fb, up, 0.10, 0.90, 0.44, 0.68), REEL_BG)
	for i in range(3):
		var u0: float = 0.14 + float(i) * 0.25
		_add_poly(parent, _face_quad(lb, fb, up, u0, u0 + 0.19, 0.48, 0.64), Color("ffffff"))
	_add_poly(parent, _face_quad(lb, fb, up, 0.12, 0.88, 0.12, 0.30), Color("20336f"))

func _create_sand(parent: Node2D, origin: Vector2) -> void:
	var lb := origin + Vector2(-4, 5)
	var fb := origin + Vector2(4, 9)
	var depth := Vector2(13, -6.5)
	var up := Vector2(0, -58)
	_add_poly(parent, PackedVector2Array([lb, fb, fb + up, lb + up]), SAND_FRONT)
	_add_poly(parent, PackedVector2Array([fb, fb + depth, fb + depth + up, fb + up]), SAND_SIDE)
	_add_poly(parent, PackedVector2Array([lb + depth + up, fb + depth + up, fb + up, lb + up]), SAND_TOP)
	_add_poly(parent, _face_quad(lb, fb, up, 0.15, 0.85, 0.70, 0.85), Color("202a31"))
	_add_poly(parent, _face_quad(lb, fb, up, 0.18, 0.82, 0.43, 0.54), Color("c3c8ce"))
	_add_poly(parent, _face_quad(lb, fb, up, 0.20, 0.80, 0.18, 0.28), Color("343b43"))

func _create_counter(parent: Node2D) -> void:
	var lb := Vector2(-8, 2)
	var fb := Vector2(8, 9)
	var depth := Vector2(4, -2)
	var up := Vector2(0, -8)
	_add_poly(parent, PackedVector2Array([lb, fb, fb + up, lb + up]), COUNTER)
	_add_poly(parent, PackedVector2Array([fb, fb + depth, fb + depth + up, fb + up]), Color("151a1f"))
	_add_poly(parent, _face_quad(lb, fb, up, 0.12, 0.88, 0.20, 0.78), COUNTER_SCREEN)

func _create_stool(cell: Vector2i) -> void:
	var stool := Node2D.new()
	stool.name = "Stool"
	stool.position = grid_to_world(cell) + Vector2(8, -3)
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
