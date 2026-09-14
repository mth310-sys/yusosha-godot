extends Node2D

# Pachirou Step 3: pachislot stool quality prototype.
# Dimensions stay fixed while material/readability are refined for final game scale.

@export var map_width: int = 10
@export var map_height: int = 10
@export var tile_width: float = 64.0
@export var tile_height: float = 32.0

const FLOOR_A := Color("c9c9c9")
const FLOOR_B := Color("a8a8a8")

const SEAT_TOP := Color("4c535d")
const SEAT_INNER := Color("3e454e")
const SEAT_HIGHLIGHT := Color("606873")
const SEAT_FRONT := Color("292f36")
const SEAT_FRONT_LIGHT := Color("353c44")
const SEAT_SHELL := Color("1f252b")
const PIPING := Color("737b86")
const METAL_LIGHT := Color("d3d7dc")
const METAL_MID := Color("9da4ac")
const METAL_DARK := Color("646b74")
const METAL_DEEP := Color("454c54")
const BASE_TOP := Color("7c838c")
const BASE_INNER := Color("9299a2")
const BASE_FRONT := Color("4a5159")
const BASE_EDGE := Color("343a41")
const SHADOW := Color(0.04, 0.04, 0.05, 0.25)
const GUIDE := Color("e8e8e8")
const GUIDE_DIM := Color("bcc2ca")

# Real-hall reference dimensions used as the common Pachirou scale.
const STOOL_SEAT_HEIGHT_MM := 480.0
const STOOL_SEAT_DIAMETER_MM := 400.0
const STOOL_BASE_DIAMETER_MM := 380.0
const STOOL_SEAT_THICKNESS_MM := 70.0
const STOOL_COLUMN_DIAMETER_MM := 90.0
const MM_TO_PX := 0.08

var world: Node2D


func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)

	_create_floor()
	_create_stool_reference(Vector2i(5, 5))
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


func _create_stool_reference(cell: Vector2i) -> void:
	var stool := Node2D.new()
	stool.name = "PachislotStoolProductionReference"
	stool.position = grid_to_world(cell) + Vector2(0, 8)
	stool.z_index = int(stool.position.y)
	world.add_child(stool)

	var seat_height_px := STOOL_SEAT_HEIGHT_MM * MM_TO_PX
	var seat_thickness_px := STOOL_SEAT_THICKNESS_MM * MM_TO_PX
	var seat_width_px := STOOL_SEAT_DIAMETER_MM * MM_TO_PX
	var base_width_px := STOOL_BASE_DIAMETER_MM * MM_TO_PX
	var column_width_px := STOOL_COLUMN_DIAMETER_MM * MM_TO_PX

	var seat_top_y := -seat_height_px
	var seat_rx := seat_width_px * 0.5
	var seat_ry := seat_rx * 0.42
	var base_rx := base_width_px * 0.5
	var base_ry := base_rx * 0.42
	var column_half := column_width_px * 0.5
	var seat_bottom_y := seat_top_y + seat_thickness_px

	# Contact shadow follows the floor projection and keeps the pedestal grounded.
	_add_polygon(stool, _ellipse_points(Vector2(2.0, 2.2), base_rx * 1.10, base_ry * 1.08, 40), SHADOW)

	# Low-profile floor disc: dark lower lip, metal top and a smaller brushed-metal centre.
	_add_polygon(stool, _ellipse_front_band(Vector2(0, -1), base_rx, base_ry, 3.2, 28), BASE_FRONT)
	_add_polygon(stool, _ellipse_points(Vector2(0, -1), base_rx, base_ry, 40), BASE_EDGE)
	_add_polygon(stool, _ellipse_points(Vector2(0, -1.5), base_rx - 1.2, base_ry - 0.7, 40), BASE_TOP)
	_add_polygon(stool, _ellipse_points(Vector2(-1.0, -2.0), base_rx * 0.68, base_ry * 0.58, 32), BASE_INNER)

	# Lower pedestal boss and trim ring hide the mechanical fixing point.
	var lower_rx := column_half + 3.3
	var lower_ry := lower_rx * 0.40
	_add_polygon(stool, _ellipse_front_band(Vector2(0, -5.2), lower_rx, lower_ry, 2.4, 20), METAL_DEEP)
	_add_polygon(stool, _ellipse_points(Vector2(0, -5.3), lower_rx, lower_ry, 28), METAL_DARK)
	_add_polygon(stool, _ellipse_points(Vector2(-0.6, -5.8), lower_rx * 0.68, lower_ry * 0.58, 24), METAL_MID)

	# Chrome pedestal. Four bands simulate cylindrical reflections at this small game scale.
	var column_top_y := seat_bottom_y + 2.0
	var column_bottom_y := -5.0
	_add_polygon(stool, PackedVector2Array([
		Vector2(-column_half, column_top_y), Vector2(-column_half * 0.48, column_top_y),
		Vector2(-column_half * 0.48, column_bottom_y), Vector2(-column_half, column_bottom_y)
	]), METAL_DEEP)
	_add_polygon(stool, PackedVector2Array([
		Vector2(-column_half * 0.48, column_top_y), Vector2(-column_half * 0.05, column_top_y),
		Vector2(-column_half * 0.05, column_bottom_y), Vector2(-column_half * 0.48, column_bottom_y)
	]), METAL_MID)
	_add_polygon(stool, PackedVector2Array([
		Vector2(-column_half * 0.05, column_top_y), Vector2(column_half * 0.45, column_top_y),
		Vector2(column_half * 0.45, column_bottom_y), Vector2(-column_half * 0.05, column_bottom_y)
	]), METAL_LIGHT)
	_add_polygon(stool, PackedVector2Array([
		Vector2(column_half * 0.45, column_top_y), Vector2(column_half, column_top_y),
		Vector2(column_half, column_bottom_y), Vector2(column_half * 0.45, column_bottom_y)
	]), METAL_DARK)

	# Under-seat mounting plate gives the cushion a believable mechanical connection.
	var mount_rx := seat_rx * 0.48
	var mount_ry := mount_rx * 0.30
	_add_polygon(stool, _ellipse_front_band(Vector2(0, seat_bottom_y + 1.4), mount_rx, mount_ry, 2.0, 22), METAL_DEEP)
	_add_polygon(stool, _ellipse_points(Vector2(0, seat_bottom_y + 1.0), mount_rx, mount_ry, 28), METAL_DARK)
	var upper_rx := column_half + 2.2
	var upper_ry := upper_rx * 0.40
	_add_polygon(stool, _ellipse_points(Vector2(0, seat_bottom_y + 1.7), upper_rx, upper_ry, 24), METAL_MID)

	# Upholstered cushion. A dark lower shell, curved side wall, piping and inset pad separate the materials.
	_add_polygon(stool, _ellipse_front_band(Vector2(0, seat_top_y + 1.2), seat_rx * 0.94, seat_ry * 0.92, seat_thickness_px + 1.0, 30), SEAT_SHELL)
	_add_polygon(stool, _ellipse_front_band(Vector2(0, seat_top_y), seat_rx, seat_ry, seat_thickness_px, 30), SEAT_FRONT)
	_add_polygon(stool, _ellipse_front_band(Vector2(0, seat_top_y + 0.5), seat_rx * 0.97, seat_ry * 0.96, seat_thickness_px * 0.48, 28), SEAT_FRONT_LIGHT)
	_add_polygon(stool, _ellipse_points(Vector2(0, seat_top_y), seat_rx, seat_ry, 44), PIPING)
	_add_polygon(stool, _ellipse_points(Vector2(0, seat_top_y - 0.6), seat_rx - 1.25, seat_ry - 0.75, 44), SEAT_TOP)
	_add_polygon(stool, _ellipse_points(Vector2(0.4, seat_top_y - 0.9), seat_rx * 0.76, seat_ry * 0.67, 36), SEAT_INNER)

	# Controlled highlights suggest a padded/vinyl surface without noisy pixel detail.
	_add_arc_line(stool, Vector2(-1.0, seat_top_y - 1.1), seat_rx * 0.67, seat_ry * 0.57, PI * 1.10, PI * 1.72, SEAT_HIGHLIGHT, 1.0, 10)
	_add_arc_line(stool, Vector2(0, -1.5), base_rx * 0.82, base_ry * 0.75, PI * 1.10, PI * 1.62, METAL_LIGHT, 0.8, 9)

	# Dimension guide remains for scale verification only.
	var guide_x := seat_rx + 18.0
	_add_line(stool, Vector2(guide_x, 0), Vector2(guide_x, seat_top_y), GUIDE_DIM, 1.0)
	_add_line(stool, Vector2(guide_x - 4, 0), Vector2(guide_x + 4, 0), GUIDE_DIM, 1.0)
	_add_line(stool, Vector2(guide_x - 4, seat_top_y), Vector2(guide_x + 4, seat_top_y), GUIDE_DIM, 1.0)

	var height_label := Label.new()
	height_label.text = "seat height 480 mm"
	height_label.position = Vector2(guide_x + 7, seat_top_y * 0.58)
	height_label.add_theme_font_size_override("font_size", 12)
	height_label.add_theme_color_override("font_color", GUIDE)
	stool.add_child(height_label)

	var size_label := Label.new()
	size_label.text = "seat 400 mm / base 380 mm"
	size_label.position = Vector2(-86, 20)
	size_label.add_theme_font_size_override("font_size", 12)
	size_label.add_theme_color_override("font_color", GUIDE)
	stool.add_child(size_label)


func _create_title() -> void:
	var layer := CanvasLayer.new()
	layer.name = "UI"
	add_child(layer)

	var label := Label.new()
	label.text = "PACHIROU  |  PACHISLOT STOOL PRODUCTION TEST  |  10 x 10"
	label.position = Vector2(24, 20)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("e8e8e8"))
	layer.add_child(label)

	var note := Label.new()
	note.text = "480 mm seat height / padded seat / chrome pedestal / low-profile floor disc"
	note.position = Vector2(24, 50)
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color("bfc4cc"))
	layer.add_child(note)


func _ellipse_points(center: Vector2, radius_x: float, radius_y: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points


func _ellipse_front_band(center: Vector2, radius_x: float, radius_y: float, thickness: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := PI * t
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	for i in range(segments, -1, -1):
		var t := float(i) / float(segments)
		var angle := PI * t
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y) + Vector2(0, thickness))
	return points


func _add_arc_line(parent: Node2D, center: Vector2, radius_x: float, radius_y: float, start_angle: float, end_angle: float, color: Color, width: float, segments: int) -> Line2D:
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := lerp(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.points = points
	parent.add_child(line)
	return line


func _add_line(parent: Node2D, from: Vector2, to: Vector2, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.points = PackedVector2Array([from, to])
	parent.add_child(line)
	return line


func _add_polygon(parent: Node2D, points: PackedVector2Array, color: Color) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	parent.add_child(polygon)
	return polygon
