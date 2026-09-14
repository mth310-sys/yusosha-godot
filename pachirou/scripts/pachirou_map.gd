extends Node2D

# Pachirou Step 6: grid-first island prototype.
# One machine + sand bay owns exactly one 64x32 floor cell.

@export var map_width: int = 10
@export var map_height: int = 10
@export var tile_width: float = 64.0
@export var tile_height: float = 32.0

const FLOOR_A := Color("c9c9c9")
const FLOOR_B := Color("a8a8a8")
const OCCUPIED_CELL := Color("d6b96b")
const STOOL_CELL := Color("7fa4b8")
const GUIDE := Color("f1f1f1")
const SHADOW := Color(0.04, 0.04, 0.05, 0.25)

const FRAME_FRONT := Color("555b62")
const FRAME_SIDE := Color("3f454c")
const FRAME_TOP := Color("8d9399")
const FRAME_TRIM := Color("b1b6bc")
const MACHINE_FRONT := Color("2949c7")
const MACHINE_SIDE := Color("19318e")
const MACHINE_TOP := Color("5873e6")
const MACHINE_DARK := Color("172139")
const REEL_BG := Color("e7ebf1")
const SAND_FRONT := Color("727982")
const SAND_SIDE := Color("4c535b")
const SAND_TOP := Color("a1a7ae")
const SAND_SCREEN := Color("202a31")

const SEAT_TOP := Color("4c535d")
const SEAT_INNER := Color("3e454e")
const SEAT_FRONT := Color("292f36")
const SEAT_SHELL := Color("1f252b")
const PIPING := Color("737b86")
const METAL_LIGHT := Color("d3d7dc")
const METAL_MID := Color("9da4ac")
const METAL_DARK := Color("646b74")
const BASE_TOP := Color("7c838c")
const BASE_FRONT := Color("4a5159")

# Real-world proportions remain reference data, but placement is grid-owned.
const STOOL_SEAT_HEIGHT_MM := 480.0
const STOOL_SEAT_DIAMETER_MM := 400.0
const STOOL_BASE_DIAMETER_MM := 380.0
const MM_TO_PX := 0.08

var world: Node2D


func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()

	var island_cell := Vector2i(6, 4)
	var stool_cell := Vector2i(5, 5)
	_highlight_cell(island_cell, OCCUPIED_CELL)
	_highlight_cell(stool_cell, STOOL_CELL)
	_create_island_frame_unit(island_cell)
	_create_stool_reference(stool_cell)
	_create_title()


func grid_to_world(cell: Vector2i) -> Vector2:
	var center_x: float = (map_width - 1) * 0.5
	var center_y: float = (map_height - 1) * 0.5
	var gx: float = float(cell.x) - center_x
	var gy: float = float(cell.y) - center_y
	return Vector2((gx - gy) * tile_width * 0.5, (gx + gy) * tile_height * 0.5)


func _tile_points(scale: float = 1.0) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -tile_height * 0.5 * scale),
		Vector2(tile_width * 0.5 * scale, 0),
		Vector2(0, tile_height * 0.5 * scale),
		Vector2(-tile_width * 0.5 * scale, 0)
	])


func _create_floor() -> void:
	var root := Node2D.new()
	root.name = "Floor"
	world.add_child(root)
	for y in range(map_height):
		for x in range(map_width):
			var tile := Polygon2D.new()
			tile.polygon = _tile_points()
			tile.color = FLOOR_A if (x + y) % 2 == 0 else FLOOR_B
			tile.position = grid_to_world(Vector2i(x, y))
			tile.z_index = -1000
			root.add_child(tile)


func _highlight_cell(cell: Vector2i, color: Color) -> void:
	var marker := Polygon2D.new()
	marker.name = "Cell_%d_%d" % [cell.x, cell.y]
	marker.polygon = _tile_points(0.92)
	marker.color = color
	marker.position = grid_to_world(cell)
	marker.z_index = -900
	world.add_child(marker)


func _create_island_frame_unit(cell: Vector2i) -> void:
	var unit := Node2D.new()
	unit.name = "OneCellIslandBay"
	unit.position = grid_to_world(cell)
	unit.z_index = int(unit.position.y)
	world.add_child(unit)

	# The footprint is derived directly from the highlighted 64x32 cell.
	# A small margin keeps the cell boundary readable.
	var back := Vector2(0, -14.0)
	var right := Vector2(28.0, 0)
	var front := Vector2(0, 14.0)
	var left := Vector2(-28.0, 0)
	var base_up := Vector2(0, -38.4) # 480 mm reference height.

	_add_polygon(unit, PackedVector2Array([left + Vector2(2,3), front + Vector2(2,3), right + Vector2(2,3), back + Vector2(2,3)]), SHADOW)
	_add_polygon(unit, PackedVector2Array([left, front, front + base_up, left + base_up]), FRAME_FRONT)
	_add_polygon(unit, PackedVector2Array([front, right, right + base_up, front + base_up]), FRAME_SIDE)
	_add_polygon(unit, PackedVector2Array([back + base_up, right + base_up, front + base_up, left + base_up]), FRAME_TOP)

	# Machine/sand are fitted into the upper frame rather than standing on a separate box.
	var mount_y: float = -38.4
	var machine := Node2D.new()
	machine.name = "MachineOpening"
	machine.position = Vector2(-4.0, 0)
	unit.add_child(machine)
	_create_machine_insert(machine, mount_y)

	var sand := Node2D.new()
	sand.name = "SandOpening"
	sand.position = Vector2(20.0, 10.0)
	unit.add_child(sand)
	_create_sand_insert(sand, mount_y)

	# Narrow framing lips visually bind the inserts into the island equipment.
	_add_polygon(unit, PackedVector2Array([Vector2(-28,mount_y), Vector2(28,mount_y), Vector2(28,mount_y+2), Vector2(-28,mount_y+2)]), FRAME_TRIM)

	var tag := Label.new()
	tag.text = "ISLAND: 1 CELL"
	tag.position = Vector2(-42, 20)
	tag.add_theme_font_size_override("font_size", 10)
	tag.add_theme_color_override("font_color", GUIDE)
	unit.add_child(tag)


func _create_machine_insert(parent: Node2D, mount_y: float) -> void:
	# 480 mm cabinet is scaled to occupy most of the bay width while leaving room for the sand.
	var lb := Vector2(-20, mount_y + 5)
	var fb := Vector2(7, mount_y + 18)
	var rb := Vector2(17, mount_y + 13)
	var bb := Vector2(-10, mount_y)
	var up := Vector2(0, -64.8) # 810 mm.
	_add_polygon(parent, PackedVector2Array([lb, fb, fb+up, lb+up]), MACHINE_FRONT)
	_add_polygon(parent, PackedVector2Array([fb, rb, rb+up, fb+up]), MACHINE_SIDE)
	_add_polygon(parent, PackedVector2Array([bb+up, rb+up, fb+up, lb+up]), MACHINE_TOP)
	_add_polygon(parent, _face_quad(lb, fb, up, 0.10, 0.90, 0.72, 0.90), MACHINE_DARK)
	_add_polygon(parent, _face_quad(lb, fb, up, 0.10, 0.90, 0.43, 0.67), REEL_BG)
	for i in range(3):
		var u0: float = 0.14 + float(i) * 0.25
		_add_polygon(parent, _face_quad(lb, fb, up, u0, u0+0.19, 0.47, 0.63), Color("ffffff"))
	_add_polygon(parent, _face_quad(lb, fb, up, 0.10, 0.90, 0.31, 0.39), Color("213164"))
	_add_polygon(parent, _face_quad(lb, fb, up, 0.14, 0.86, 0.08, 0.26), Color("20336f"))


func _create_sand_insert(parent: Node2D, mount_y: float) -> void:
	var lb := Vector2(-5, mount_y + 2)
	var fb := Vector2(1, mount_y + 5)
	var rb := Vector2(6, mount_y + 2.5)
	var bb := Vector2(0, mount_y)
	var up := Vector2(0, -57.6)
	_add_polygon(parent, PackedVector2Array([lb, fb, fb+up, lb+up]), SAND_FRONT)
	_add_polygon(parent, PackedVector2Array([fb, rb, rb+up, fb+up]), SAND_SIDE)
	_add_polygon(parent, PackedVector2Array([bb+up, rb+up, fb+up, lb+up]), SAND_TOP)
	_add_polygon(parent, _face_quad(lb, fb, up, 0.15, 0.85, 0.70, 0.86), SAND_SCREEN)
	_add_polygon(parent, _face_quad(lb, fb, up, 0.18, 0.82, 0.45, 0.55), Color("c3c8ce"))


func _face_point(left_bottom: Vector2, front_bottom: Vector2, up: Vector2, u: float, v: float) -> Vector2:
	return left_bottom.lerp(front_bottom, u) + up * v


func _face_quad(left_bottom: Vector2, front_bottom: Vector2, up: Vector2, u0: float, u1: float, v0: float, v1: float) -> PackedVector2Array:
	return PackedVector2Array([
		_face_point(left_bottom, front_bottom, up, u0, v0),
		_face_point(left_bottom, front_bottom, up, u1, v0),
		_face_point(left_bottom, front_bottom, up, u1, v1),
		_face_point(left_bottom, front_bottom, up, u0, v1)
	])


func _create_stool_reference(cell: Vector2i) -> void:
	var stool := Node2D.new()
	stool.name = "StandardStool"
	stool.position = grid_to_world(cell)
	stool.z_index = int(stool.position.y)
	world.add_child(stool)

	var seat_h: float = STOOL_SEAT_HEIGHT_MM * MM_TO_PX
	var seat_rx: float = STOOL_SEAT_DIAMETER_MM * MM_TO_PX * 0.5
	var seat_ry: float = seat_rx * 0.42
	var base_rx: float = STOOL_BASE_DIAMETER_MM * MM_TO_PX * 0.5
	var base_ry: float = base_rx * 0.42
	var top_y: float = -seat_h
	var seat_t: float = 5.6

	_add_polygon(stool, _ellipse_points(Vector2(2,2), base_rx*1.06, base_ry*1.06, 32), SHADOW)
	_add_polygon(stool, _ellipse_front_band(Vector2(0,-1), base_rx, base_ry, 3.0, 24), BASE_FRONT)
	_add_polygon(stool, _ellipse_points(Vector2(0,-1.5), base_rx, base_ry, 32), BASE_TOP)
	_add_polygon(stool, _ellipse_points(Vector2(0,-2), base_rx*0.65, base_ry*0.55, 24), METAL_MID)
	_add_polygon(stool, PackedVector2Array([Vector2(-3.6,top_y+seat_t+2),Vector2(3.6,top_y+seat_t+2),Vector2(3.6,-5),Vector2(-3.6,-5)]), METAL_DARK)
	_add_polygon(stool, PackedVector2Array([Vector2(-0.8,top_y+seat_t+2),Vector2(1.2,top_y+seat_t+2),Vector2(1.2,-5),Vector2(-0.8,-5)]), METAL_LIGHT)
	_add_polygon(stool, _ellipse_points(Vector2(0,top_y+seat_t+1), seat_rx*0.46, seat_ry*0.42, 20), METAL_DARK)
	_add_polygon(stool, _ellipse_front_band(Vector2(0,top_y), seat_rx, seat_ry, seat_t, 28), SEAT_FRONT)
	_add_polygon(stool, _ellipse_points(Vector2(0,top_y), seat_rx, seat_ry, 36), PIPING)
	_add_polygon(stool, _ellipse_points(Vector2(0,top_y-0.7), seat_rx-1.2, seat_ry-0.7, 36), SEAT_TOP)
	_add_polygon(stool, _ellipse_points(Vector2(0.4,top_y-1), seat_rx*0.76, seat_ry*0.67, 28), SEAT_INNER)

	var tag := Label.new()
	tag.text = "STOOL CELL"
	tag.position = Vector2(-30, 16)
	tag.add_theme_font_size_override("font_size", 10)
	tag.add_theme_color_override("font_color", GUIDE)
	stool.add_child(tag)


func _create_title() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "PACHIROU  |  GRID-FIRST ISLAND TEST  |  10 x 10"
	label.position = Vector2(24, 20)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", GUIDE)
	layer.add_child(label)
	var note := Label.new()
	note.text = "YELLOW = one machine+sand bay / BLUE = stool position / each marker = exactly one 64x32 cell"
	note.position = Vector2(24, 50)
	note.add_theme_font_size_override("font_size", 13)
	note.add_theme_color_override("font_color", Color("d4d7db"))
	layer.add_child(note)


func _ellipse_points(center: Vector2, radius_x: float, radius_y: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle)*radius_x, sin(angle)*radius_y))
	return points


func _ellipse_front_band(center: Vector2, radius_x: float, radius_y: float, thickness: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var angle: float = PI * t
		points.append(center + Vector2(cos(angle)*radius_x, sin(angle)*radius_y))
	for i in range(segments, -1, -1):
		var t: float = float(i) / float(segments)
		var angle: float = PI * t
		points.append(center + Vector2(cos(angle)*radius_x, sin(angle)*radius_y) + Vector2(0,thickness))
	return points


func _add_polygon(parent: Node2D, points: PackedVector2Array, color: Color) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	parent.add_child(polygon)
	return polygon
