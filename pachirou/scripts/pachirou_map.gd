extends Node2D

# Pachirou Step 9: one-cell display-scale test.
# Logical cells and real-world reference dimensions stay unchanged.
# Only the rendered equipment scale is reduced to fit the 64x32 grid cleanly.

@export var map_width: int = 10
@export var map_height: int = 10
@export var tile_width: float = 64.0
@export var tile_height: float = 32.0

const FLOOR_A := Color("c9c9c9")
const FLOOR_B := Color("a8a8a8")
const OCCUPIED_CELL := Color("d6b96b")
const STOOL_CELL := Color("7fa4b8")
const GUIDE := Color("f1f1f1")
const SHADOW := Color(0.04,0.04,0.05,0.25)
const FRAME_FRONT := Color("555b62")
const FRAME_SIDE := Color("3f454c")
const FRAME_TOP := Color("8d9399")
const FRAME_TRIM := Color("b1b6bc")
const BACKBOARD_FRONT := Color("666d75")
const BACKBOARD_SIDE := Color("444b53")
const SHELF_TOP := Color("a7adb4")
const SHELF_FRONT := Color("686f77")
const SHELF_SIDE := Color("4a5159")
const MACHINE_FRONT := Color("2949c7")
const MACHINE_SIDE := Color("19318e")
const MACHINE_TOP := Color("5873e6")
const MACHINE_DARK := Color("172139")
const REEL_BG := Color("e7ebf1")
const SAND_FRONT := Color("727982")
const SAND_SIDE := Color("4c535b")
const SAND_TOP := Color("a1a7ae")
const SAND_SCREEN := Color("202a31")
const COUNTER_FRONT := Color("242a31")
const COUNTER_SIDE := Color("151a1f")
const COUNTER_TOP := Color("4d555e")
const COUNTER_SCREEN := Color("79b6d8")
const SEAT_TOP := Color("4c535d")
const SEAT_INNER := Color("3e454e")
const SEAT_FRONT := Color("292f36")
const PIPING := Color("737b86")
const METAL_LIGHT := Color("d3d7dc")
const METAL_MID := Color("9da4ac")
const METAL_DARK := Color("646b74")
const BASE_TOP := Color("7c838c")
const BASE_FRONT := Color("4a5159")

const STOOL_SEAT_HEIGHT_MM := 480.0
const STOOL_SEAT_DIAMETER_MM := 400.0
const STOOL_BASE_DIAMETER_MM := 380.0
const MM_TO_PX := 0.08
const ISLAND_DISPLAY_SCALE := 0.85
const STOOL_DISPLAY_SCALE := 0.80

var world: Node2D

func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()
	var island_cell := Vector2i(6,4)
	var stool_cell := Vector2i(5,5)
	_highlight_cell(island_cell,OCCUPIED_CELL)
	_highlight_cell(stool_cell,STOOL_CELL)
	_create_island_frame_unit(island_cell)
	_create_stool_reference(stool_cell)
	_create_title()

func grid_to_world(cell: Vector2i) -> Vector2:
	var center_x: float = (map_width-1)*0.5
	var center_y: float = (map_height-1)*0.5
	var gx: float = float(cell.x)-center_x
	var gy: float = float(cell.y)-center_y
	return Vector2((gx-gy)*tile_width*0.5,(gx+gy)*tile_height*0.5)

func _tile_points(scale: float = 1.0) -> PackedVector2Array:
	return PackedVector2Array([Vector2(0,-tile_height*0.5*scale),Vector2(tile_width*0.5*scale,0),Vector2(0,tile_height*0.5*scale),Vector2(-tile_width*0.5*scale,0)])

func _create_floor() -> void:
	var root := Node2D.new()
	root.name = "Floor"
	world.add_child(root)
	for y in range(map_height):
		for x in range(map_width):
			var tile := Polygon2D.new()
			tile.polygon = _tile_points()
			tile.color = FLOOR_A if (x+y)%2==0 else FLOOR_B
			tile.position = grid_to_world(Vector2i(x,y))
			tile.z_index = -1000
			root.add_child(tile)

func _highlight_cell(cell: Vector2i,color: Color) -> void:
	var marker := Polygon2D.new()
	marker.polygon = _tile_points(0.92)
	marker.color = color
	marker.position = grid_to_world(cell)
	marker.z_index = -900
	world.add_child(marker)

func _create_island_frame_unit(cell: Vector2i) -> void:
	var unit := Node2D.new()
	unit.name = "OneCellHallIslandBay"
	unit.position = grid_to_world(cell)
	unit.scale = Vector2(ISLAND_DISPLAY_SCALE,ISLAND_DISPLAY_SCALE)
	unit.z_index = int(unit.position.y)
	world.add_child(unit)
	var back := Vector2(0,-14)
	var right := Vector2(28,0)
	var front := Vector2(0,14)
	var left := Vector2(-28,0)
	var base_up := Vector2(0,-38.4)
	_add_polygon(unit,PackedVector2Array([left+Vector2(2,3),front+Vector2(2,3),right+Vector2(2,3),back+Vector2(2,3)]),SHADOW)
	_add_polygon(unit,PackedVector2Array([left,front,front+base_up,left+base_up]),FRAME_FRONT)
	_add_polygon(unit,PackedVector2Array([front,right,right+base_up,front+base_up]),FRAME_SIDE)
	_add_polygon(unit,PackedVector2Array([back+base_up,right+base_up,front+base_up,left+base_up]),FRAME_TOP)
	var mount_y: float = -38.4
	var cabinet_top_y: float = mount_y-64.8
	var board_left_bottom := Vector2(-23,mount_y-8)
	var board_right_bottom := Vector2(27,mount_y+16)
	var board_depth := Vector2(5,-2.5)
	var board_up := Vector2(0,-84)
	_add_polygon(unit,PackedVector2Array([board_left_bottom,board_right_bottom,board_right_bottom+board_up,board_left_bottom+board_up]),BACKBOARD_FRONT)
	_add_polygon(unit,PackedVector2Array([board_right_bottom,board_right_bottom+board_depth,board_right_bottom+board_depth+board_up,board_right_bottom+board_up]),BACKBOARD_SIDE)
	var machine := Node2D.new()
	machine.name = "PachislotMachine"
	machine.position = Vector2(-8,-2)
	unit.add_child(machine)
	_create_machine_insert(machine,mount_y)
	var sand := Node2D.new()
	sand.name = "SandUnit"
	sand.position = Vector2(18,11)
	unit.add_child(sand)
	_create_sand_insert(sand,mount_y)
	var shelf_y: float = cabinet_top_y-2.0
	var shelf_left := Vector2(-24,shelf_y-5)
	var shelf_front := Vector2(0,shelf_y+7)
	var shelf_right := Vector2(27,shelf_y+5)
	var shelf_back := Vector2(4,shelf_y-7)
	var shelf_thickness := Vector2(0,2)
	_add_polygon(unit,PackedVector2Array([shelf_left,shelf_front,shelf_right,shelf_back]),SHELF_TOP)
	_add_polygon(unit,PackedVector2Array([shelf_left,shelf_front,shelf_front+shelf_thickness,shelf_left+shelf_thickness]),SHELF_FRONT)
	_add_polygon(unit,PackedVector2Array([shelf_front,shelf_right,shelf_right+shelf_thickness,shelf_front+shelf_thickness]),SHELF_SIDE)
	var counter := Node2D.new()
	counter.name = "DataCounter"
	counter.position = Vector2(-7,shelf_y+1)
	unit.add_child(counter)
	_create_data_counter(counter)
	_add_polygon(unit,PackedVector2Array([Vector2(-28,mount_y),Vector2(28,mount_y),Vector2(28,mount_y+2),Vector2(-28,mount_y+2)]),FRAME_TRIM)
	var tag := Label.new()
	tag.text = "ISLAND: 1 CELL / 85%"
	tag.position = Vector2(-48,20)
	tag.add_theme_font_size_override("font_size",10)
	tag.add_theme_color_override("font_color",GUIDE)
	unit.add_child(tag)

func _create_machine_insert(parent: Node2D,mount_y: float) -> void:
	var lb := Vector2(-20,mount_y+5)
	var fb := Vector2(7,mount_y+18)
	var depth_vec := Vector2(16,-8)
	var rb := fb+depth_vec
	var bb := lb+depth_vec
	var up := Vector2(0,-64.8)
	_add_polygon(parent,PackedVector2Array([lb,fb,fb+up,lb+up]),MACHINE_FRONT)
	_add_polygon(parent,PackedVector2Array([fb,rb,rb+up,fb+up]),MACHINE_SIDE)
	_add_polygon(parent,PackedVector2Array([bb+up,rb+up,fb+up,lb+up]),MACHINE_TOP)
	_add_polygon(parent,_face_quad(lb,fb,up,0.10,0.90,0.72,0.90),MACHINE_DARK)
	_add_polygon(parent,_face_quad(lb,fb,up,0.10,0.90,0.43,0.67),REEL_BG)
	for i in range(3):
		var u0: float = 0.14+float(i)*0.25
		_add_polygon(parent,_face_quad(lb,fb,up,u0,u0+0.19,0.47,0.63),Color("ffffff"))
	_add_polygon(parent,_face_quad(lb,fb,up,0.10,0.90,0.31,0.39),Color("213164"))
	_add_polygon(parent,_face_quad(lb,fb,up,0.14,0.86,0.08,0.26),Color("20336f"))

func _create_sand_insert(parent: Node2D,mount_y: float) -> void:
	var lb := Vector2(-5,mount_y+2)
	var fb := Vector2(2,mount_y+5.5)
	var depth_vec := Vector2(14,-7)
	var rb := fb+depth_vec
	var bb := lb+depth_vec
	var up := Vector2(0,-57.6)
	_add_polygon(parent,PackedVector2Array([lb,fb,fb+up,lb+up]),SAND_FRONT)
	_add_polygon(parent,PackedVector2Array([fb,rb,rb+up,fb+up]),SAND_SIDE)
	_add_polygon(parent,PackedVector2Array([bb+up,rb+up,fb+up,lb+up]),SAND_TOP)
	_add_polygon(parent,_face_quad(lb,fb,up,0.15,0.85,0.70,0.86),SAND_SCREEN)
	_add_polygon(parent,_face_quad(lb,fb,up,0.18,0.82,0.45,0.55),Color("c3c8ce"))
	_add_polygon(parent,_face_quad(lb,fb,up,0.20,0.80,0.20,0.29),Color("343b43"))

func _create_data_counter(parent: Node2D) -> void:
	var lb := Vector2(-10,1)
	var fb := Vector2(8,9)
	var depth_vec := Vector2(5,-2.5)
	var rb := fb+depth_vec
	var bb := lb+depth_vec
	var up := Vector2(0,-10)
	_add_polygon(parent,PackedVector2Array([lb,fb,fb+up,lb+up]),COUNTER_FRONT)
	_add_polygon(parent,PackedVector2Array([fb,rb,rb+up,fb+up]),COUNTER_SIDE)
	_add_polygon(parent,PackedVector2Array([bb+up,rb+up,fb+up,lb+up]),COUNTER_TOP)
	_add_polygon(parent,_face_quad(lb,fb,up,0.12,0.88,0.20,0.78),COUNTER_SCREEN)

func _face_point(left_bottom: Vector2,front_bottom: Vector2,up: Vector2,u: float,v: float) -> Vector2:
	return left_bottom.lerp(front_bottom,u)+up*v

func _face_quad(left_bottom: Vector2,front_bottom: Vector2,up: Vector2,u0: float,u1: float,v0: float,v1: float) -> PackedVector2Array:
	return PackedVector2Array([_face_point(left_bottom,front_bottom,up,u0,v0),_face_point(left_bottom,front_bottom,up,u1,v0),_face_point(left_bottom,front_bottom,up,u1,v1),_face_point(left_bottom,front_bottom,up,u0,v1)])

func _create_stool_reference(cell: Vector2i) -> void:
	var stool := Node2D.new()
	stool.name = "StandardStool"
	stool.position = grid_to_world(cell)+Vector2(9,-4)
	stool.scale = Vector2(STOOL_DISPLAY_SCALE,STOOL_DISPLAY_SCALE)
	stool.z_index = int(stool.position.y)
	world.add_child(stool)
	var seat_h: float = STOOL_SEAT_HEIGHT_MM*MM_TO_PX
	var seat_rx: float = STOOL_SEAT_DIAMETER_MM*MM_TO_PX*0.5
	var seat_ry: float = seat_rx*0.42
	var base_rx: float = STOOL_BASE_DIAMETER_MM*MM_TO_PX*0.5
	var base_ry: float = base_rx*0.42
	var top_y: float = -seat_h
	var seat_t: float = 5.6
	_add_polygon(stool,_ellipse_points(Vector2(2,2),base_rx*1.06,base_ry*1.06,32),SHADOW)
	_add_polygon(stool,_ellipse_front_band(Vector2(0,-1),base_rx,base_ry,3.0,24),BASE_FRONT)
	_add_polygon(stool,_ellipse_points(Vector2(0,-1.5),base_rx,base_ry,32),BASE_TOP)
	_add_polygon(stool,_ellipse_points(Vector2(0,-2),base_rx*0.65,base_ry*0.55,24),METAL_MID)
	_add_polygon(stool,PackedVector2Array([Vector2(-3.6,top_y+seat_t+2),Vector2(3.6,top_y+seat_t+2),Vector2(3.6,-5),Vector2(-3.6,-5)]),METAL_DARK)
	_add_polygon(stool,PackedVector2Array([Vector2(-0.8,top_y+seat_t+2),Vector2(1.2,top_y+seat_t+2),Vector2(1.2,-5),Vector2(-0.8,-5)]),METAL_LIGHT)
	_add_polygon(stool,_ellipse_points(Vector2(0,top_y+seat_t+1),seat_rx*0.46,seat_ry*0.42,20),METAL_DARK)
	_add_polygon(stool,_ellipse_front_band(Vector2(0,top_y),seat_rx,seat_ry,seat_t,28),SEAT_FRONT)
	_add_polygon(stool,_ellipse_points(Vector2(0,top_y),seat_rx,seat_ry,36),PIPING)
	_add_polygon(stool,_ellipse_points(Vector2(0,top_y-0.7),seat_rx-1.2,seat_ry-0.7,36),SEAT_TOP)
	_add_polygon(stool,_ellipse_points(Vector2(0.4,top_y-1),seat_rx*0.76,seat_ry*0.67,28),SEAT_INNER)
	var tag := Label.new()
	tag.text = "STOOL CELL / 80%"
	tag.position = Vector2(-38,16)
	tag.add_theme_font_size_override("font_size",10)
	tag.add_theme_color_override("font_color",GUIDE)
	stool.add_child(tag)

func _create_title() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "PACHIROU  |  ONE-CELL SCALE TEST  |  10 x 10"
	label.position = Vector2(24,20)
	label.add_theme_font_size_override("font_size",20)
	label.add_theme_color_override("font_color",GUIDE)
	layer.add_child(label)
	var note := Label.new()
	note.text = "logical cell unchanged / island display 85% / stool display 80% / real dimensions retained"
	note.position = Vector2(24,50)
	note.add_theme_font_size_override("font_size",13)
	note.add_theme_color_override("font_color",Color("d4d7db"))
	layer.add_child(note)

func _ellipse_points(center: Vector2,radius_x: float,radius_y: float,segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle: float = TAU*float(i)/float(segments)
		points.append(center+Vector2(cos(angle)*radius_x,sin(angle)*radius_y))
	return points

func _ellipse_front_band(center: Vector2,radius_x: float,radius_y: float,thickness: float,segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments+1):
		var t: float = float(i)/float(segments)
		var angle: float = PI*t
		points.append(center+Vector2(cos(angle)*radius_x,sin(angle)*radius_y))
	for i in range(segments,-1,-1):
		var t: float = float(i)/float(segments)
		var angle: float = PI*t
		points.append(center+Vector2(cos(angle)*radius_x,sin(angle)*radius_y)+Vector2(0,thickness))
	return points

func _add_polygon(parent: Node2D,points: PackedVector2Array,color: Color) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	parent.add_child(polygon)
	return polygon
