extends Node2D

# Pachirou Step 5: one-seat pachislot island prototype.
# Real-hall scale reference: stool + 480 mm base + machine + sand.

@export var map_width: int = 10
@export var map_height: int = 10
@export var tile_width: float = 64.0
@export var tile_height: float = 32.0

const FLOOR_A := Color("c9c9c9")
const FLOOR_B := Color("a8a8a8")
const SHADOW := Color(0.04, 0.04, 0.05, 0.25)
const GUIDE := Color("e8e8e8")

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

const ISLAND_TOP := Color("8a8f95")
const ISLAND_FRONT := Color("555b62")
const ISLAND_SIDE := Color("41474e")
const ISLAND_TRIM := Color("a7adb4")
const ISLAND_KICK := Color("30353a")

const MACHINE_FRONT := Color("2949c7")
const MACHINE_SIDE := Color("19318e")
const MACHINE_TOP := Color("5873e6")
const MACHINE_DARK := Color("172139")
const MACHINE_PANEL := Color("d9e2f4")
const MACHINE_BUTTON := Color("e9edf4")
const SAND_FRONT := Color("747b84")
const SAND_SIDE := Color("4d545c")
const SAND_TOP := Color("a2a8af")
const SAND_SCREEN := Color("202a31")

const STOOL_SEAT_HEIGHT_MM := 480.0
const STOOL_SEAT_DIAMETER_MM := 400.0
const STOOL_BASE_DIAMETER_MM := 380.0
const STOOL_SEAT_THICKNESS_MM := 70.0
const STOOL_COLUMN_DIAMETER_MM := 90.0

const ISLAND_BASE_HEIGHT_MM := 480.0
# One seat is widened to fit a 480 mm machine + 100 mm sand + installation clearances.
const ISLAND_BASE_WIDTH_MM := 660.0
const ISLAND_BASE_DEPTH_MM := 520.0
const MACHINE_WIDTH_MM := 480.0
const MACHINE_HEIGHT_MM := 810.0
const MACHINE_DEPTH_MM := 430.0
const SAND_WIDTH_MM := 100.0
const SAND_HEIGHT_MM := 720.0
const SAND_DEPTH_MM := 360.0
const MM_TO_PX := 0.08

var world: Node2D


func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()
	_create_one_seat_unit(Vector2i(6, 4))
	_create_stool_reference(Vector2i(4, 6))
	_create_title()


func grid_to_world(cell: Vector2i) -> Vector2:
	var center_x: float = (map_width - 1) * 0.5
	var center_y: float = (map_height - 1) * 0.5
	var gx: float = float(cell.x) - center_x
	var gy: float = float(cell.y) - center_y
	return Vector2((gx - gy) * tile_width * 0.5, (gx + gy) * tile_height * 0.5)


func _create_floor() -> void:
	var floor_root := Node2D.new()
	floor_root.name = "Floor"
	world.add_child(floor_root)
	var points := PackedVector2Array([Vector2(0, -16), Vector2(32, 0), Vector2(0, 16), Vector2(-32, 0)])
	for y in range(map_height):
		for x in range(map_width):
			var tile := Polygon2D.new()
			tile.polygon = points
			tile.color = FLOOR_A if (x + y) % 2 == 0 else FLOOR_B
			tile.position = grid_to_world(Vector2i(x, y))
			tile.z_index = -1000
			floor_root.add_child(tile)


func _iso_box(parent: Node2D, width_mm: float, depth_mm: float, height_mm: float, base_y: float, front_color: Color, side_color: Color, top_color: Color) -> Dictionary:
	var width_px: float = width_mm * MM_TO_PX
	var depth_px: float = depth_mm * MM_TO_PX
	var height_px: float = height_mm * MM_TO_PX
	var hx := Vector2(width_px * 0.25, width_px * 0.125)
	var hy := Vector2(-depth_px * 0.25, depth_px * 0.125)
	var origin := Vector2(0, base_y)
	var back: Vector2 = origin - hx - hy
	var right: Vector2 = origin + hx - hy
	var front: Vector2 = origin + hx + hy
	var left: Vector2 = origin - hx + hy
	var up := Vector2(0, -height_px)
	_add_polygon(parent, PackedVector2Array([left, front, front + up, left + up]), front_color)
	_add_polygon(parent, PackedVector2Array([front, right, right + up, front + up]), side_color)
	_add_polygon(parent, PackedVector2Array([back + up, right + up, front + up, left + up]), top_color)
	return {"back": back, "right": right, "front": front, "left": left, "up": up}


func _create_one_seat_unit(cell: Vector2i) -> void:
	var unit := Node2D.new()
	unit.name = "OneSeatIslandUnit"
	unit.position = grid_to_world(cell) + Vector2(0, 8)
	unit.z_index = int(unit.position.y)
	world.add_child(unit)

	# Island base, 480 mm mounting surface.
	var base := _iso_box(unit, ISLAND_BASE_WIDTH_MM, ISLAND_BASE_DEPTH_MM, ISLAND_BASE_HEIGHT_MM, 0.0, ISLAND_FRONT, ISLAND_SIDE, ISLAND_TOP)
	var left: Vector2 = base["left"]
	var front: Vector2 = base["front"]
	var right: Vector2 = base["right"]
	var up: Vector2 = base["up"]
	var trim_drop := Vector2(0, 2.0)
	_add_polygon(unit, PackedVector2Array([left + up, front + up, front + up + trim_drop, left + up + trim_drop]), ISLAND_TRIM)
	_add_polygon(unit, PackedVector2Array([front + up, right + up, right + up + trim_drop, front + up + trim_drop]), Color("858c94"))
	_add_polygon(unit, PackedVector2Array([left + Vector2(3,-1), front + Vector2(-3,-1), front + Vector2(-3,-6), left + Vector2(3,-6)]), ISLAND_KICK)

	var mount_y: float = -ISLAND_BASE_HEIGHT_MM * MM_TO_PX

	# Machine and sand share the mounting surface. Their centres are offset along the island width axis.
	var width_axis := Vector2(0.5, 0.25)
	var machine_center_mm: float = -(SAND_WIDTH_MM + 20.0) * 0.5
	var sand_center_mm: float = MACHINE_WIDTH_MM * 0.5 + 20.0

	var machine := Node2D.new()
	machine.name = "TestPachislotMachine"
	machine.position = width_axis * machine_center_mm * MM_TO_PX
	unit.add_child(machine)
	var m := _iso_box(machine, MACHINE_WIDTH_MM, MACHINE_DEPTH_MM, MACHINE_HEIGHT_MM, mount_y, MACHINE_FRONT, MACHINE_SIDE, MACHINE_TOP)
	_add_machine_face_details(machine, m)

	var sand := Node2D.new()
	sand.name = "SandUnit"
	sand.position = width_axis * sand_center_mm * MM_TO_PX
	unit.add_child(sand)
	var s := _iso_box(sand, SAND_WIDTH_MM, SAND_DEPTH_MM, SAND_HEIGHT_MM, mount_y, SAND_FRONT, SAND_SIDE, SAND_TOP)
	_add_sand_face_details(sand, s)

	var label := Label.new()
	label.text = "480 machine + 100 sand / seat width 660 mm"
	label.position = Vector2(-92, 26)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", GUIDE)
	unit.add_child(label)


func _face_point(left_bottom: Vector2, front_bottom: Vector2, up: Vector2, u: float, v: float) -> Vector2:
	return left_bottom.lerp(front_bottom, u) + up * v


func _face_quad(left_bottom: Vector2, front_bottom: Vector2, up: Vector2, u0: float, u1: float, v0: float, v1: float) -> PackedVector2Array:
	return PackedVector2Array([
		_face_point(left_bottom, front_bottom, up, u0, v0),
		_face_point(left_bottom, front_bottom, up, u1, v0),
		_face_point(left_bottom, front_bottom, up, u1, v1),
		_face_point(left_bottom, front_bottom, up, u0, v1)
	])


func _add_machine_face_details(parent: Node2D, box: Dictionary) -> void:
	var left: Vector2 = box["left"]
	var front: Vector2 = box["front"]
	var up: Vector2 = box["up"]
	# Upper display, reel window, control strip and lower panel all follow the projected cabinet face.
	_add_polygon(parent, _face_quad(left, front, up, 0.10, 0.90, 0.72, 0.91), MACHINE_DARK)
	_add_polygon(parent, _face_quad(left, front, up, 0.12, 0.88, 0.43, 0.68), MACHINE_PANEL)
	for i in range(3):
		var u0: float = 0.15 + float(i) * 0.24
		_add_polygon(parent, _face_quad(left, front, up, u0, u0 + 0.18, 0.47, 0.64), Color("f5f6f8"))
	_add_polygon(parent, _face_quad(left, front, up, 0.10, 0.90, 0.32, 0.40), Color("213164"))
	for i in range(3):
		var u: float = 0.32 + float(i) * 0.18
		var p: Vector2 = _face_point(left, front, up, u, 0.36)
		_add_polygon(parent, _ellipse_points(p, 1.4, 0.65, 16), MACHINE_BUTTON)
	_add_polygon(parent, _face_quad(left, front, up, 0.14, 0.86, 0.08, 0.27), Color("20336f"))


func _add_sand_face_details(parent: Node2D, box: Dictionary) -> void:
	var left: Vector2 = box["left"]
	var front: Vector2 = box["front"]
	var up: Vector2 = box["up"]
	_add_polygon(parent, _face_quad(left, front, up, 0.16, 0.84, 0.72, 0.88), SAND_SCREEN)
	_add_polygon(parent, _face_quad(left, front, up, 0.20, 0.80, 0.48, 0.58), Color("c3c8ce"))
	_add_polygon(parent, _face_quad(left, front, up, 0.22, 0.78, 0.18, 0.27), Color("31383f"))


func _create_stool_reference(cell: Vector2i) -> void:
	var stool := Node2D.new()
	stool.name = "StandardPachislotStool"
	stool.position = grid_to_world(cell) + Vector2(0, 8)
	stool.z_index = int(stool.position.y)
	world.add_child(stool)

	var seat_h: float = STOOL_SEAT_HEIGHT_MM * MM_TO_PX
	var seat_t: float = STOOL_SEAT_THICKNESS_MM * MM_TO_PX
	var seat_rx: float = STOOL_SEAT_DIAMETER_MM * MM_TO_PX * 0.5
	var seat_ry: float = seat_rx * 0.42
	var base_rx: float = STOOL_BASE_DIAMETER_MM * MM_TO_PX * 0.5
	var base_ry: float = base_rx * 0.42
	var col: float = STOOL_COLUMN_DIAMETER_MM * MM_TO_PX * 0.5
	var top_y: float = -seat_h
	var bottom_y: float = top_y + seat_t

	_add_polygon(stool, _ellipse_points(Vector2(2,2), base_rx*1.08, base_ry*1.08, 36), SHADOW)
	_add_polygon(stool, _ellipse_front_band(Vector2(0,-1), base_rx, base_ry, 3.0, 28), BASE_FRONT)
	_add_polygon(stool, _ellipse_points(Vector2(0,-1.5), base_rx, base_ry, 36), BASE_TOP)
	_add_polygon(stool, _ellipse_points(Vector2(0,-2), base_rx*0.68, base_ry*0.58, 28), METAL_MID)
	_add_polygon(stool, PackedVector2Array([Vector2(-col,bottom_y+2), Vector2(col,bottom_y+2), Vector2(col,-5), Vector2(-col,-5)]), METAL_DARK)
	_add_polygon(stool, PackedVector2Array([Vector2(-col*0.25,bottom_y+2), Vector2(col*0.35,bottom_y+2), Vector2(col*0.35,-5), Vector2(-col*0.25,-5)]), METAL_LIGHT)
	_add_polygon(stool, _ellipse_points(Vector2(0,bottom_y+1), seat_rx*0.46, seat_ry*0.42, 24), METAL_DARK)
	_add_polygon(stool, _ellipse_front_band(Vector2(0,top_y+1), seat_rx*0.94, seat_ry*0.92, seat_t+1, 30), SEAT_SHELL)
	_add_polygon(stool, _ellipse_front_band(Vector2(0,top_y), seat_rx, seat_ry, seat_t, 30), SEAT_FRONT)
	_add_polygon(stool, _ellipse_points(Vector2(0,top_y), seat_rx, seat_ry, 40), PIPING)
	_add_polygon(stool, _ellipse_points(Vector2(0,top_y-0.7), seat_rx-1.2, seat_ry-0.7, 40), SEAT_TOP)
	_add_polygon(stool, _ellipse_points(Vector2(0.4,top_y-1), seat_rx*0.76, seat_ry*0.67, 32), SEAT_INNER)

	var label := Label.new()
	label.text = "standard stool 480 mm"
	label.position = Vector2(-48, 18)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", GUIDE)
	stool.add_child(label)


func _create_title() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "PACHIROU  |  ONE-SEAT ISLAND FIT TEST  |  10 x 10"
	label.position = Vector2(24, 20)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", GUIDE)
	layer.add_child(label)
	var note := Label.new()
	note.text = "base top 480 mm / machine 480 x 810 / sand 100 mm / stool 480 mm"
	note.position = Vector2(24, 50)
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color("bfc4cc"))
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
