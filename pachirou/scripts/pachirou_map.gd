extends Node2D

# Pachirou Step 1: isometric hall scale prototype.
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
	_create_slot_machine(Vector2i(6, 4))
	_create_chair(Vector2i(5, 5))
	_create_character(Vector2i(3, 5))
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


func _create_slot_machine(cell: Vector2i) -> void:
	var machine := Node2D.new()
	machine.name = "TestSlotMachineIso"
	machine.position = grid_to_world(cell)
	machine.z_index = int(machine.position.y)
	world.add_child(machine)

	# Cabinet footprint uses the SAME isometric axes as the 64x32 floor tile.
	# It occupies about 60% of one floor cell so its contact with the floor is readable.
	var base_back := Vector2(0, -9)
	var base_right := Vector2(20, 0)
	var base_front := Vector2(0, 10)
	var base_left := Vector2(-20, 0)
	var cabinet_height := 44.0

	var top_back := base_back + Vector2(0, -cabinet_height)
	var top_right := base_right + Vector2(0, -cabinet_height)
	var top_front := base_front + Vector2(0, -cabinet_height)
	var top_left := base_left + Vector2(0, -cabinet_height)

	# Contact shadow: same diamond orientation as the floor.
	_add_polygon(machine, PackedVector2Array([
		base_back + Vector2(0, 2),
		base_right + Vector2(0, 2),
		base_front + Vector2(0, 2),
		base_left + Vector2(0, 2)
	]), Color(0.05, 0.05, 0.07, 0.35))

	# Two visible vertical faces. The southwest face is treated as the cabinet front.
	_add_polygon(machine, PackedVector2Array([
		base_left, base_front, top_front, top_left
	]), SLOT_FRONT)
	_add_polygon(machine, PackedVector2Array([
		base_front, base_right, top_right, top_front
	]), SLOT_SIDE)

	# Top face is a smaller diamond parallel to the floor plane.
	_add_polygon(machine, PackedVector2Array([
		top_back, top_right, top_front, top_left
	]), SLOT_TOP)

	# Display and reel windows are parallelograms that sit ON the slanted front face.
	# They follow the same left->front edge direction, rather than screen-aligned rectangles.
	_add_polygon(machine, PackedVector2Array([
		Vector2(-15, -37), Vector2(-2, -30.5), Vector2(-2, -21.5), Vector2(-15, -28)
	]), SLOT_DARK)
	_add_polygon(machine, PackedVector2Array([
		Vector2(-14, -18), Vector2(-2, -12), Vector2(-2, -4), Vector2(-14, -10)
	]), SLOT_REEL)

	# Small control shelf protruding from the front edge.
	_add_polygon(machine, PackedVector2Array([
		Vector2(-13, -3), Vector2(1, 4), Vector2(-3, 7), Vector2(-17, 0)
	]), Color("2b3fb0"))


func _create_chair(cell: Vector2i) -> void:
	var chair := Node2D.new()
	chair.name = "TestChair"
	chair.position = grid_to_world(cell) + Vector2(0, 6)
	chair.z_index = int(chair.position.y)
	world.add_child(chair)

	_add_polygon(chair, PackedVector2Array([
		Vector2(-11, -16), Vector2(11, -16), Vector2(16, -10), Vector2(-6, -10)
	]), CHAIR_MAIN)
	_add_polygon(chair, PackedVector2Array([
		Vector2(-8, -30), Vector2(10, -30), Vector2(10, -16), Vector2(-8, -16)
	]), Color("555b64"))
	_add_polygon(chair, PackedVector2Array([
		Vector2(-6, -10), Vector2(-2, -10), Vector2(-2, 4), Vector2(-6, 4),
		Vector2(8, -10), Vector2(12, -10), Vector2(12, 4), Vector2(8, 4)
	]), Color("2a2d32"))


func _create_character(cell: Vector2i) -> void:
	var character := Node2D.new()
	character.name = "TestCharacter"
	character.position = grid_to_world(cell)
	character.z_index = int(character.position.y)
	world.add_child(character)

	_add_polygon(character, PackedVector2Array([
		Vector2(-10, -25), Vector2(10, -25), Vector2(9, -2), Vector2(-9, -2)
	]), CHARACTER_BODY)

	var head_points := PackedVector2Array()
	for i in range(10):
		var angle := TAU * float(i) / 10.0
		head_points.append(Vector2(cos(angle), sin(angle)) * 8.0 + Vector2(0, -33))
	_add_polygon(character, head_points, CHARACTER_HEAD)

	_add_polygon(character, PackedVector2Array([
		Vector2(-8, -2), Vector2(-2, -2), Vector2(-3, 6), Vector2(-8, 6),
		Vector2(2, -2), Vector2(8, -2), Vector2(8, 6), Vector2(3, 6)
	]), Color("374151"))


func _create_title() -> void:
	var layer := CanvasLayer.new()
	layer.name = "UI"
	add_child(layer)

	var label := Label.new()
	label.text = "PACHIROU  |  ISOMETRIC GEOMETRY TEST  |  10 x 10"
	label.position = Vector2(24, 20)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("e8e8e8"))
	layer.add_child(label)

	var note := Label.new()
	note.text = "Floor 64x32 / cabinet footprint aligned to floor isometric axes"
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
