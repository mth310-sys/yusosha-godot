extends "res://scripts/pachirou_map.gd"

enum BayDirection { LEFT_DOWN, RIGHT_DOWN, RIGHT_UP, LEFT_UP }

const ISO_X := Vector2(32.0, 16.0)
const ISO_Y := Vector2(-32.0, 16.0)
const ISO_Z := Vector2(0.0, -1.0)

func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()
	_create_bay_3d(Vector2i(4, 4), BayDirection.LEFT_DOWN)
	_create_bay_3d(Vector2i(9, 4), BayDirection.RIGHT_DOWN)
	_create_bay_3d(Vector2i(9, 9), BayDirection.RIGHT_UP)
	_create_bay_3d(Vector2i(4, 9), BayDirection.LEFT_UP)

func _axes(direction: BayDirection) -> Array[Vector2]:
	# right = seated player's right; back = from player toward island centre.
	match direction:
		BayDirection.LEFT_DOWN:
			return [ISO_X, -ISO_Y]
		BayDirection.RIGHT_DOWN:
			return [-ISO_Y, ISO_X]
		BayDirection.RIGHT_UP:
			return [-ISO_X, ISO_Y]
		BayDirection.LEFT_UP:
			return [ISO_Y, -ISO_X]
	return [ISO_X, -ISO_Y]

func _p(origin: Vector2, right: Vector2, back: Vector2, x: float, y: float, z: float) -> Vector2:
	return origin + right * x + back * y + ISO_Z * z

func _quad(parent: Node2D, a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color, z: int) -> void:
	_add_poly(parent, PackedVector2Array([a, b, c, d]), color, z)

func _create_bay_3d(cell: Vector2i, direction: BayDirection) -> void:
	var root := Node2D.new()
	root.name = "Bay_%s" % BayDirection.keys()[direction]
	root.position = grid_to_world(cell)
	root.z_index = int(root.position.y)
	world.add_child(root)
	var axes := _axes(direction)
	var right: Vector2 = axes[0]
	var back: Vector2 = axes[1]
	var origin := Vector2.ZERO
	_create_frame_3d(root, origin, right, back)
	_create_equipment_3d(root, origin, right, back, direction)
	_create_stool_3d(root, origin, back)

func _create_frame_3d(parent: Node2D, o: Vector2, r: Vector2, b: Vector2) -> void:
	# One physical carcass described in player-relative coordinates.
	var x0 := -0.50
	var x1 := 0.50
	var y0 := 0.02
	var y1 := 0.70
	var h := BASE_HEIGHT
	var fll := _p(o, r, b, x0, y0, 0.0)
	var flr := _p(o, r, b, x1, y0, 0.0)
	var br := _p(o, r, b, x1, y1, 0.0)
	var bl := _p(o, r, b, x0, y1, 0.0)
	var tll := _p(o, r, b, x0, y0, h)
	var tlr := _p(o, r, b, x1, y0, h)
	var tr := _p(o, r, b, x1, y1, h)
	var tl := _p(o, r, b, x0, y1, h)
	_quad(parent, fll, flr, tlr, tll, BASE_FRONT, 0)
	_quad(parent, flr, br, tr, tlr, BASE_SIDE, 0)
	_quad(parent, bl, br, tr, tl, BASE_SIDE, 0)
	_quad(parent, tll, tlr, tr, tl, BASE_TOP, 1)
	# Rear island board and its actual back face.
	var board_y0 := 0.58
	var board_y1 := 0.68
	var board_bottom := h
	var board_top := h + BACKBOARD_HEIGHT
	var a := _p(o, r, b, x0, board_y0, board_bottom)
	var d := _p(o, r, b, x1, board_y0, board_bottom)
	var au := _p(o, r, b, x0, board_y0, board_top)
	var du := _p(o, r, b, x1, board_y0, board_top)
	var rb := _p(o, r, b, x0, board_y1, board_bottom)
	var rr := _p(o, r, b, x1, board_y1, board_bottom)
	var rbu := _p(o, r, b, x0, board_y1, board_top)
	var rru := _p(o, r, b, x1, board_y1, board_top)
	_quad(parent, a, d, du, au, BACKBOARD, 3)
	_quad(parent, rb, rr, rru, rbu, Color("4d545c"), 2)
	_quad(parent, d, rr, rru, du, BACKBOARD_SIDE, 4)
	_quad(parent, au, du, rru, rbu, SHELF_TOP, 5)
	# Upper equipment box has front, back, side and top, so up-facing views expose its rear.
	var box_z0 := h + MACHINE_HEIGHT + 2.0
	var box_z1 := box_z0 + UPPER_BOX_HEIGHT
	var bx0 := -0.48
	var bx1 := 0.48
	var by0 := 0.38
	var by1 := 0.68
	var bf0 := _p(o, r, b, bx0, by0, box_z0)
	var bf1 := _p(o, r, b, bx1, by0, box_z0)
	var bfu0 := _p(o, r, b, bx0, by0, box_z1)
	var bfu1 := _p(o, r, b, bx1, by0, box_z1)
	var bb0 := _p(o, r, b, bx0, by1, box_z0)
	var bb1 := _p(o, r, b, bx1, by1, box_z0)
	var bbu0 := _p(o, r, b, bx0, by1, box_z1)
	var bbu1 := _p(o, r, b, bx1, by1, box_z1)
	_quad(parent, bf0, bf1, bfu1, bfu0, SHELF_EDGE, 20)
	_quad(parent, bb0, bb1, bbu1, bbu0, Color("50575f"), 19)
	_quad(parent, bfu0, bfu1, bbu1, bbu0, SHELF_TOP, 21)

func _create_equipment_3d(parent: Node2D, o: Vector2, r: Vector2, b: Vector2, direction: BayDirection) -> void:
	# Player-relative layout: machine centred slightly left; sand ALWAYS on player-right.
	_create_box_equipment(parent, o, r, b, -0.40, 0.18, 0.12, 0.50, BASE_HEIGHT, MACHINE_HEIGHT, true, direction)
	_create_box_equipment(parent, o, r, b, 0.20, 0.40, 0.12, 0.48, BASE_HEIGHT, SAND_HEIGHT, false, direction)
	_create_counter_3d(parent, o, r, b, direction)

func _create_box_equipment(parent: Node2D, o: Vector2, r: Vector2, b: Vector2, x0: float, x1: float, y0: float, y1: float, z0: float, height: float, machine: bool, direction: BayDirection) -> void:
	var z1 := z0 + height
	var f0 := _p(o, r, b, x0, y0, z0)
	var f1 := _p(o, r, b, x1, y0, z0)
	var fu0 := _p(o, r, b, x0, y0, z1)
	var fu1 := _p(o, r, b, x1, y0, z1)
	var q0 := _p(o, r, b, x0, y1, z0)
	var q1 := _p(o, r, b, x1, y1, z0)
	var qu0 := _p(o, r, b, x0, y1, z1)
	var qu1 := _p(o, r, b, x1, y1, z1)
	var front_color := MACHINE_FRONT if machine else SAND_FRONT
	var side_color := MACHINE_SIDE if machine else SAND_SIDE
	var top_color := MACHINE_TOP if machine else SAND_TOP
	_quad(parent, f0, f1, fu1, fu0, front_color, 10)
	_quad(parent, f1, q1, qu1, fu1, side_color, 11)
	_quad(parent, q0, q1, qu1, qu0, Color("343b43") if machine else Color("59616a"), 9)
	_quad(parent, fu0, fu1, qu1, qu0, top_color, 12)
	var front_visible := direction == BayDirection.LEFT_DOWN or direction == BayDirection.RIGHT_DOWN
	if front_visible:
		if machine:
			_draw_machine_front(parent, o, r, b, x0, x1, y0, z0, height)
		else:
			_draw_sand_front(parent, o, r, b, x0, x1, y0, z0, height)
	else:
		_draw_service_back(parent, o, r, b, x0, x1, y1, z0, height, machine)

func _face3(o: Vector2, r: Vector2, b: Vector2, x0: float, x1: float, y: float, z0: float, z1: float) -> PackedVector2Array:
	return PackedVector2Array([_p(o,r,b,x0,y,z0), _p(o,r,b,x1,y,z0), _p(o,r,b,x1,y,z1), _p(o,r,b,x0,y,z1)])

func _draw_machine_front(parent: Node2D, o: Vector2, r: Vector2, b: Vector2, x0: float, x1: float, y: float, z0: float, h: float) -> void:
	var w := x1 - x0
	_add_poly(parent, _face3(o,r,b,x0+w*0.08,x1-w*0.08,y-0.015,z0+h*0.44,z0+h*0.73), MACHINE_TRIM, 14)
	for i in range(3):
		var a := x0 + w * (0.13 + float(i)*0.27)
		var c := a + w*0.20
		_add_poly(parent, _face3(o,r,b,a,c,y-0.025,z0+h*0.49,z0+h*0.68), REEL_BG, 15)
		_add_poly(parent, _face3(o,r,b,a+w*0.03,c-w*0.03,y-0.03,z0+h*0.55,z0+h*0.58), REEL_SYMBOL_RED, 16)
		_add_poly(parent, _face3(o,r,b,a+w*0.03,c-w*0.03,y-0.03,z0+h*0.61,z0+h*0.64), REEL_SYMBOL_BLUE, 16)
	_add_poly(parent, _face3(o,r,b,x0+w*0.08,x1-w*0.08,y-0.03,z0+h*0.27,z0+h*0.40), MACHINE_DARK, 15)
	_add_poly(parent, _face3(o,r,b,x0+w*0.16,x1-w*0.16,y-0.025,z0+h*0.76,z0+h*0.90), MACHINE_ACCENT, 15)

func _draw_sand_front(parent: Node2D, o: Vector2, r: Vector2, b: Vector2, x0: float, x1: float, y: float, z0: float, h: float) -> void:
	var w := x1-x0
	_add_poly(parent, _face3(o,r,b,x0+w*0.16,x1-w*0.16,y-0.02,z0+h*0.66,z0+h*0.84), SAND_SCREEN, 15)
	_add_poly(parent, _face3(o,r,b,x0+w*0.20,x1-w*0.20,y-0.02,z0+h*0.38,z0+h*0.46), Color("20252b"), 15)

func _draw_service_back(parent: Node2D, o: Vector2, r: Vector2, b: Vector2, x0: float, x1: float, y: float, z0: float, h: float, machine: bool) -> void:
	var w := x1-x0
	var panel := Color("272d34") if machine else Color("3a4149")
	_add_poly(parent, _face3(o,r,b,x0+w*0.12,x1-w*0.12,y+0.015,z0+h*0.14,z0+h*0.42), panel, 13)
	_add_poly(parent, _face3(o,r,b,x0+w*0.20,x1-w*0.20,y+0.02,z0+h*0.68,z0+h*0.73), Color("11161b"), 14)
	_add_poly(parent, _face3(o,r,b,x0+w*0.20,x1-w*0.20,y+0.02,z0+h*0.78,z0+h*0.83), Color("11161b"), 14)

func _create_counter_3d(parent: Node2D, o: Vector2, r: Vector2, b: Vector2, direction: BayDirection) -> void:
	var z0 := BASE_HEIGHT + MACHINE_HEIGHT + 5.0
	var z1 := z0 + 8.0
	var y0 := 0.27
	var y1 := 0.40
	var x0 := -0.30
	var x1 := 0.30
	_quad(parent, _p(o,r,b,x0,y0,z0), _p(o,r,b,x1,y0,z0), _p(o,r,b,x1,y0,z1), _p(o,r,b,x0,y0,z1), COUNTER_FRONT, 30)
	_quad(parent, _p(o,r,b,x0,y1,z0), _p(o,r,b,x1,y1,z0), _p(o,r,b,x1,y1,z1), _p(o,r,b,x0,y1,z1), Color("353c44"), 29)
	var front_visible := direction == BayDirection.LEFT_DOWN or direction == BayDirection.RIGHT_DOWN
	var yy := y0-0.01 if front_visible else y1+0.01
	_add_poly(parent, _face3(o,r,b,-0.22,0.22,yy,z0+1.8,z1-1.6), COUNTER_SCREEN if front_visible else Color("20262d"), 31)

func _create_stool_3d(parent: Node2D, o: Vector2, back: Vector2) -> void:
	var stool := Node2D.new()
	stool.name = "Stool"
	stool.position = o - back * 0.78
	stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)
	parent.add_child(stool)
	var seat_y: float = -38.4
	_add_poly(stool, _ellipse(Vector2(0,0.5),15.2,6.4,32), Color("4b525a"), 0)
	_add_poly(stool, _ellipse(Vector2(0,-0.8),12.0,4.8,30), METAL_DARK, 1)
	_add_poly(stool, _ellipse(Vector2(0,-1.8),9.5,3.4,28), METAL, 2)
	_add_poly(stool, PackedVector2Array([Vector2(-2.6,seat_y+7.0),Vector2(2.6,seat_y+7.0),Vector2(2.2,-4.0),Vector2(-2.2,-4.0)]), METAL_DARK, 1)
	_add_poly(stool, PackedVector2Array([Vector2(-1.5,seat_y+6.0),Vector2(1.5,seat_y+6.0),Vector2(1.5,-3.0),Vector2(-1.5,-3.0)]), METAL, 2)
	_add_poly(stool, _ellipse(Vector2(0,seat_y),16.0,6.7,34), SEAT_SIDE, 5)
	_add_poly(stool, _ellipse(Vector2(0,seat_y-0.8),14.6,5.8,34), SEAT_TOP, 6)
	_add_poly(stool, _ellipse(Vector2(0,seat_y-1.2),11.8,4.3,30), SEAT_INNER, 7)
