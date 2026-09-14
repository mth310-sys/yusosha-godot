extends Node2D

# Pachirou Step 3: pachislot stool scale prototype.
# The stool is isolated first so its proportions can become the reference for island height.

@export var map_width: int = 10
@export var map_height: int = 10
@export var tile_width: float = 64.0
@export var tile_height: float = 32.0

const FLOOR_A := Color("c9c9c9")
const FLOOR_B := Color("a8a8a8")

const STOOL_SEAT := Color("454b54")
const STOOL_SEAT_SIDE := Color("30353c")
const STOOL_COLUMN := Color("aeb4bc")
const STOOL_COLUMN_DARK := Color("747b84")
const STOOL_BASE := Color("697079")
const STOOL_BASE_SIDE := Color("4d535b")
const GUIDE := Color("e8e8e8")
const GUIDE_DIM := Color("bcc2ca")

# Real-hall reference dimensions used only as a proportion guide.
# Seat height is intentionally close to the future island-base top height.
const STOOL_SEAT_HEIGHT_MM := 480.0
const STOOL_SEAT_DIAMETER_MM := 400.0
const STOOL_BASE_DIAMETER_MM := 380.0
const STOOL_SEAT_THICKNESS_MM := 70.0
const STOOL_COLUMN_DIAMETER_MM := 90.0

# Screen scale for vertical dimensions. Horizontal round surfaces are projected as isometric ellipses.
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
	stool.name = "PachislotStoolReference"
	stool.position = grid_to_world(cell) + Vector2(0, 8)
	stool.z_index = int(stool.position.y)
	world.add_child(stool)

	var seat_height_px := STOOL_SEAT_HEIGHT_MM * MM_TO_PX
	var seat_thickness_px := STOOL_SEAT_THICKNESS_MM * MM_TO_PX
	var seat_width_px := STOOL_SEAT_DIAMETER_MM * MM_TO_PX
	var base_width_px := STOOL_BASE_DIAMETER_MM * MM_TO_PX
	var column_width_px := STOOL_COLUMN_DIAMETER_MM * MM_TO_PX

	# Round objects are drawn as flattened ellipses to match the 2:1 isometric floor projection.
	var seat_top_y := -seat_height_px
	var seat_rx := seat_width_px * 0.5
	var seat_ry := seat_rx * 0.42
	var base_rx := base_width_px * 0.5
	var base_ry := base_rx * 0.42

	# Floor-mounted circular base.
	_add_polygon(stool, _ellipse_points(Vector2(0, -1), base_rx, base_ry, 24), STOOL_BASE)
	_add_polygon(stool, PackedVector2Array([
		Vector2(-base_rx, -1),
		Vector2(0, base_ry - 1),
		Vector2(0, base_ry + 3),
		Vector2(-base_rx, 3)
	]), STOOL_BASE_SIDE)

	# Central pedestal column.
	var column_half := column_width_px * 0.5
	var column_top_y := seat_top_y + seat_thickness_px
	_add_polygon(stool, PackedVector2Array([
		Vector2(-column_half, column_top_y),
		Vector2(column_half, column_top_y),
		Vector2(column_half, -2),
		Vector2(-column_half, -2)
	]), STOOL_COLUMN)
	_add_polygon(stool, PackedVector2Array([
		Vector2(column_half, column_top_y),
		Vector2(column_half + 2, column_top_y + 1),
		Vector2(column_half + 2, -1),
		Vector2(column_half, -2)
	]), STOOL_COLUMN_DARK)

	# Seat cushion side thickness first, then the top surface.
	_add_polygon(stool, PackedVector2Array([
		Vector2(-seat_rx, seat_top_y),
		Vector2(0, seat_top_y + seat_ry),
		Vector2(0, seat_top_y + seat_ry + seat_thickness_px),
		Vector2(-seat_rx, seat_top_y + seat_thickness_px)
	]), STOOL_SEAT_SIDE)
	_add_polygon(stool, PackedVector2Array([
		Vector2(0, seat_top_y + seat_ry),
		Vector2(seat_rx, seat_top_y),
		Vector2(seat_rx, seat_top_y + seat_thickness_px),
		Vector2(0, seat_top_y + seat_ry + seat_thickness_px)
	]), Color("383e46"))
	_add_polygon(stool, _ellipse_points(Vector2(0, seat_top_y), seat_rx, seat_ry, 24), STOOL_SEAT)

	# Dimension guide: floor to seat top. This will later be aligned to the island base top.
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
	label.text = "PACHIROU  |  PACHISLOT STOOL SCALE TEST  |  10 x 10"
	label.position = Vector2(24, 20)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("e8e8e8"))
	layer.add_child(label)

	var note := Label.new()
	note.text = "chair first: 480 mm seat height / 400 mm seat / 380 mm floor base"
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
