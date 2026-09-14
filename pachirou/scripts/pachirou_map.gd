extends Node2D

# Pachirou Step 2: single-seat island scale prototype.
# Logical coordinates stay square; rendering is converted to diamonds.

@export var map_width: int = 10
@export var map_height: int = 10
@export var tile_width: float = 64.0
@export var tile_height: float = 32.0

const FLOOR_A := Color("c9c9c9")
const FLOOR_B := Color("a8a8a8")
const SLOT_FRONT := Color("344fd0")
const SLOT_SIDE := Color("24378f")
const SLOT_TOP := Color("5872f0")
const SLOT_DARK := Color("151b48")
const SLOT_REEL := Color("ecece6")
const BASE_FRONT := Color("535963")
const BASE_SIDE := Color("3d424a")
const BASE_TOP := Color("747b86")
const SAND_FRONT := Color("c9ccd2")
const COUNTER_BODY := Color("20252c")
const COUNTER_SCREEN := Color("55b9e8")
const CHAIR_MAIN := Color("3d4148")
const CHARACTER_BODY := Color("f4f4f4")
const CHARACTER_HEAD := Color("e5b58f")

var world: Node2D


func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)

	_create_floor()
	_create_island_seat(Vector2i(5, 4))
	_create_seated_reference(Vector2i(4, 6))
	_create_title()


func grid_to_world(cell: Vector2i) -> Vector2:
	var center_x := (map_width - 1) * 0.5
	var center_y := (map_height - 1) * 0.5
	var gx := float(cell.x) - center_x
	var gy := float(cell.y) - center_y
	return Vector2(
		(gx - gy) * tile_width * 0.5,
		(gx + gy) * tile_height * 0.5
	)


func _create_floor() -> void:
	var floor_root := Node2D.new()
	floor_root.name = "Floor"
	floor_root.y_sort_enabled = false
	world.add_child(floor_root)

	var points := PackedVector2Array([
		Vector2(0.0, -tile_height * 0.5),
		Vector2(tile_width * 0.5, 0.0),
		Vector2(0.0, tile_height * 0.5),
		Vector2(-tile_width * 0.5, 0.0)
	])

	for y in range(map_height):
		for x in range(map_width):
			var tile := Polygon2D.new()
			tile.name = "Tile_%02d_%02d" % [x, y]
			tile.polygon = points
			tile.color = FLOOR_A if (x + y) % 2 == 0 else FLOOR_B
			tile.position = grid_to_world(Vector2i(x, y))
			tile.z_index = -1000
			floor_root.add_child(tile)


func _create_island_seat(cell: Vector2i) -> void:
	var seat := Node2D.new()
	seat.name = "IslandSeatPrototype"
	seat.position = grid_to_world(cell)
	seat.z_index = int(seat.position.y)
	world.add_child(seat)

	# Standard height reference for Pachirou: base top ~= round-chair seat height.
	var base_height := 18.0
	var cabinet_height := 44.0

	# One-seat island base. It is wider than the cabinet because the right side holds the sand.
	var b_back := Vector2(0, -11)
	var b_right := Vector2(31, 4)
	var b_front := Vector2(0, 19)
	var b_left := Vector2(-31, 4)
	var up_base := Vector2(0, -base_height)

	_add_polygon(seat, PackedVector2Array([b_left, b_front, b_front + up_base, b_left + up_base]), BASE_FRONT)
	_add_polygon(seat, PackedVector2Array([b_front, b_right, b_right + up_base, b_front + up_base]), BASE_SIDE)
	_add_polygon(seat, PackedVector2Array([b_back + up_base, b_right + up_base, b_front + up_base, b_left + up_base]), BASE_TOP)

	# Cabinet starts on the base top, never directly on the floor.
	var cab_floor := Vector2(0, -base_height - 1)
	var cab_left := cab_floor + Vector2(-22, -1)
	var cab_front := cab_floor + Vector2(-2, 9)
	var cab_right := cab_floor + Vector2(15, 0)
	var cab_back := cab_floor + Vector2(-5, -10)
	var up_cab := Vector2(0, -cabinet_height)

	_add_polygon(seat, PackedVector2Array([cab_left, cab_front, cab_front + up_cab, cab_left + up_cab]), SLOT_FRONT)
	_add_polygon(seat, PackedVector2Array([cab_front, cab_right, cab_right + up_cab, cab_front + up_cab]), SLOT_SIDE)
	_add_polygon(seat, PackedVector2Array([cab_back + up_cab, cab_right + up_cab, cab_front + up_cab, cab_left + up_cab]), SLOT_TOP)

	# Reel/display surfaces follow the cabinet front plane.
	_add_polygon(seat, PackedVector2Array([
		Vector2(-18, -54), Vector2(-6, -48), Vector2(-6, -39), Vector2(-18, -45)
	]), SLOT_DARK)
	_add_polygon(seat, PackedVector2Array([
		Vector2(-18, -37), Vector2(-6, -31), Vector2(-6, -23), Vector2(-18, -29)
	]), SLOT_REEL)
	_add_polygon(seat, PackedVector2Array([
		Vector2(-17, -22), Vector2(-4, -15.5), Vector2(-8, -12), Vector2(-21, -18.5)
	]), Color("2b3fb0"))

	# Sand occupies the narrow space beside the machine as part of each seat unit.
	var sand_bottom_left := Vector2(16, -base_height + 1)
	var sand_bottom_right := Vector2(27, -base_height + 6)
	var sand_top_right := sand_bottom_right + Vector2(0, -35)
	var sand_top_left := sand_bottom_left + Vector2(0, -35)
	_add_polygon(seat, PackedVector2Array([sand_bottom_left, sand_bottom_right, sand_top_right, sand_top_left]), SAND_FRONT)
	_add_polygon(seat, PackedVector2Array([
		Vector2(18, -45), Vector2(25, -41.5), Vector2(25, -36), Vector2(18, -39.5)
	]), Color("353a42"))

	# Data counter sits above the reel line and is reachable from the seated position.
	_add_polygon(seat, PackedVector2Array([
		Vector2(-19, -72), Vector2(-3, -64), Vector2(-3, -56), Vector2(-19, -64)
	]), COUNTER_BODY)
	_add_polygon(seat, PackedVector2Array([
		Vector2(-16, -68), Vector2(-6, -63), Vector2(-6, -59), Vector2(-16, -64)
	]), COUNTER_SCREEN)


func _create_seated_reference(cell: Vector2i) -> void:
	var reference := Node2D.new()
	reference.name = "SeatedScaleReference"
	reference.position = grid_to_world(cell) + Vector2(0, 7)
	reference.z_index = int(reference.position.y)
	world.add_child(reference)

	# Round stool: seat top is intentionally the same 18 px height as the island base.
	var stool_top := Vector2(0, -18)
	_add_polygon(reference, PackedVector2Array([
		Vector2(-11, -20), Vector2(0, -25), Vector2(11, -20), Vector2(0, -15)
	]), CHAIR_MAIN)
	_add_polygon(reference, PackedVector2Array([
		Vector2(-5, -17), Vector2(-1, -17), Vector2(-2, 1), Vector2(-6, 1),
		Vector2(1, -17), Vector2(5, -17), Vector2(6, 1), Vector2(2, 1)
	]), Color("292d33"))

	# Seated person: hips sit on the stool; head/eye line is used to judge reel height.
	_add_polygon(reference, PackedVector2Array([
		stool_top + Vector2(-8, -23), stool_top + Vector2(7, -23),
		stool_top + Vector2(8, -3), stool_top + Vector2(-6, -3)
	]), CHARACTER_BODY)

	var head_points := PackedVector2Array()
	for i in range(10):
		var angle := TAU * float(i) / 10.0
		head_points.append(Vector2(cos(angle), sin(angle)) * 7.0 + stool_top + Vector2(0, -31))
	_add_polygon(reference, head_points, CHARACTER_HEAD)

	# Bent legs make it read as a seated scale reference instead of a standing character.
	_add_polygon(reference, PackedVector2Array([
		Vector2(-6, -21), Vector2(0, -21), Vector2(-4, -10), Vector2(-10, -5), Vector2(-13, -8), Vector2(-8, -14),
		Vector2(1, -21), Vector2(7, -21), Vector2(12, -10), Vector2(10, -4), Vector2(6, -5), Vector2(7, -12)
	]), Color("374151"))


func _create_title() -> void:
	var layer := CanvasLayer.new()
	layer.name = "UI"
	add_child(layer)

	var label := Label.new()
	label.text = "PACHIROU  |  ISLAND SEAT SCALE TEST  |  10 x 10"
	label.position = Vector2(24, 20)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("e8e8e8"))
	layer.add_child(label)

	var note := Label.new()
	note.text = "base + machine + sand + data counter / stool seat height = base top"
	note.position = Vector2(24, 50)
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color("bfc4cc"))
	layer.add_child(note)


func _add_polygon(parent: Node2D, points: PackedVector2Array, color: Color) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	parent.add_child(polygon)
	return polygon
