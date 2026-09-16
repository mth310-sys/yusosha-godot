extends "res://scripts/pachirou_map.gd"

# Approved LEFT_DOWN stays untouched. LEFT_UP is generated from one physical
# X/Y/Z model and a 90-degree world rotation before isometric projection.
const ISO_X := Vector2(1.0, 0.5)
const ISO_Y := Vector2(-1.0, 0.5)

func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_create_floor()
	_create_locked_left_down(Vector2i(5, 6))
	_create_xyz_left_up(Vector2i(9, 7))

func _create_locked_left_down(cell: Vector2i) -> void:
	var unit := Node2D.new()
	unit.name = "LockedLeftDownBay"
	unit.position = grid_to_world(cell)
	unit.z_index = int(unit.position.y)
	world.add_child(unit)
	var bay := Node2D.new()
	bay.position = UNIT_REAR_SHIFT
	unit.add_child(bay)
	_create_island_frame(bay)
	_create_machine_and_sand(bay)
	_create_data_counter(bay)
	var stool := Node2D.new()
	stool.position = UNIT_REAR_SHIFT + STOOL_FRONT_OFFSET
	stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)
	unit.add_child(stool)
	_create_stool_geometry(stool)

func _rot_left(v: Vector3) -> Vector3:
	return Vector3(-v.y, v.x, v.z)

func _iso(v: Vector3) -> Vector2:
	var r: Vector3 = _rot_left(v)
	return ISO_X * r.x + ISO_Y * r.y + Vector2(0.0, -r.z)

func _quad3(parent: Node2D, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color, z: int) -> void:
	_add_poly(parent, PackedVector2Array([_iso(a), _iso(b), _iso(c), _iso(d)]), color, z)

func _box3(parent: Node2D, pos: Vector3, size: Vector3, front: Color, side: Color, top: Color, z: int) -> void:
	var x0: float = pos.x
	var y0: float = pos.y
	var z0: float = pos.z
	var x1: float = x0 + size.x
	var y1: float = y0 + size.y
	var z1: float = z0 + size.z
	# All physical faces exist. Draw order is chosen for the LEFT_UP view.
	_quad3(parent, Vector3(x0,y0,z0), Vector3(x1,y0,z0), Vector3(x1,y0,z1), Vector3(x0,y0,z1), front, z)
	_quad3(parent, Vector3(x1,y0,z0), Vector3(x1,y1,z0), Vector3(x1,y1,z1), Vector3(x1,y0,z1), side, z + 1)
	_quad3(parent, Vector3(x0,y1,z0), Vector3(x0,y0,z0), Vector3(x0,y0,z1), Vector3(x0,y1,z1), front.darkened(0.18), z + 1)
	_quad3(parent, Vector3(x0,y1,z1), Vector3(x0,y0,z1), Vector3(x1,y0,z1), Vector3(x1,y1,z1), top, z + 2)

func _panel3(parent: Node2D, pos: Vector3, size: Vector3, color: Color, z: int) -> void:
	_quad3(parent, pos, pos + Vector3(size.x,0,0), pos + Vector3(size.x,0,size.z), pos + Vector3(0,0,size.z), color, z)

func _create_xyz_left_up(cell: Vector2i) -> void:
	var unit := Node2D.new()
	unit.name = "SameBay_LeftUp90"
	unit.position = grid_to_world(cell)
	unit.z_index = int(unit.position.y)
	world.add_child(unit)

	# Physical dimensions correspond to the approved 64x32 tile model.
	_box3(unit, Vector3(-32.0,-11.2,0.0), Vector3(64.0,22.4,36.0), BASE_FRONT, BASE_SIDE, BASE_TOP, 0)
	_box3(unit, Vector3(-32.0,7.8,36.0), Vector3(64.0,3.8,64.0), BACKBOARD, BACKBOARD_SIDE, SHELF_TOP, 3)
	_box3(unit, Vector3(-32.0,0.8,88.0), Vector3(64.0,10.8,10.0), SHELF_EDGE, BACKBOARD_SIDE, SHELF_TOP, 20)

	# Machine and sand are the same physical pair, not separately redrawn orientations.
	_box3(unit, Vector3(-13.8,-8.0,36.0), Vector3(20.5,16.0,54.0), MACHINE_FRONT, MACHINE_SIDE, MACHINE_TOP, 10)
	_box3(unit, Vector3(6.7,-8.0,36.0), Vector3(7.0,16.0,48.0), SAND_FRONT, SAND_SIDE, SAND_TOP, 10)

	# Machine face details live on the same physical front plane.
	_panel3(unit, Vector3(-11.8,-8.15,73.0), Vector3(16.5,0.0,9.0), MACHINE_DARK, 15)
	_panel3(unit, Vector3(-11.8,-8.20,58.0), Vector3(16.5,0.0,14.0), MACHINE_TRIM, 15)
	for i in range(3):
		var rx: float = -10.9 + float(i) * 5.2
		_panel3(unit, Vector3(rx,-8.25,59.2), Vector3(4.1,0.0,11.2), REEL_BG, 16)
		_panel3(unit, Vector3(rx + 0.7,-8.30,61.0), Vector3(2.7,0.0,1.2), REEL_SYMBOL_RED, 17)
		_panel3(unit, Vector3(rx + 0.7,-8.30,64.4), Vector3(2.7,0.0,1.2), REEL_SYMBOL_GOLD, 17)
		_panel3(unit, Vector3(rx + 0.7,-8.30,67.8), Vector3(2.7,0.0,1.2), REEL_SYMBOL_BLUE, 17)
	_panel3(unit, Vector3(-11.8,-8.28,47.0), Vector3(16.5,0.0,8.0), MACHINE_DARK, 17)
	for i in range(3):
		var bx: float = -5.5 + float(i) * 4.0
		_panel3(unit, Vector3(bx,-8.34,49.0), Vector3(2.2,0.0,2.2), BUTTON_RED, 18)
	_panel3(unit, Vector3(-10.5,-8.18,39.5), Vector3(14.0,0.0,5.0), MACHINE_ACCENT, 13)

	# Sand face/status details.
	_panel3(unit, Vector3(7.5,-8.20,69.0), Vector3(5.4,0.0,8.0), SAND_SCREEN, 15)
	_panel3(unit, Vector3(8.0,-8.24,58.0), Vector3(4.4,0.0,2.0), Color("1b2026"), 16)
	_panel3(unit, Vector3(8.0,-8.24,52.0), Vector3(4.4,0.0,2.0), Color("1b2026"), 16)

	# Data counter and display above the same machine.
	_box3(unit, Vector3(-11.5,-10.0,92.0), Vector3(18.0,5.0,8.0), COUNTER_FRONT, COUNTER_SIDE, SHELF_EDGE, 30)
	_panel3(unit, Vector3(-9.8,-10.1,93.5), Vector3(14.5,0.0,4.5), COUNTER_SCREEN, 31)

	# Stool uses the same physical front-side offset, then receives the same rotation.
	var stool := Node2D.new()
	stool.name = "SameStool_LeftUp90"
	stool.position = _iso(Vector3(-40.0,-18.0,0.0))
	stool.scale = Vector2(STOOL_SCALE, STOOL_SCALE)
	unit.add_child(stool)
	_create_stool_geometry(stool)

func _create_stool_geometry(stool: Node2D) -> void:
	var seat_y: float = -38.4
	_add_poly(stool, _ellipse(Vector2(0, 0.5), 15.2, 6.4, 32), Color("4b525a"), 0)
	_add_poly(stool, _ellipse(Vector2(0, -0.8), 12.0, 4.8, 30), METAL_DARK, 1)
	_add_poly(stool, _ellipse(Vector2(0, -1.8), 9.5, 3.4, 28), METAL, 2)
	_add_poly(stool, _ellipse(Vector2(0, -2.2), 5.0, 1.9, 24), Color("d1d5d9"), 3)
	_add_poly(stool, PackedVector2Array([Vector2(-2.6, seat_y + 7.0), Vector2(2.6, seat_y + 7.0), Vector2(2.2, -4.0), Vector2(-2.2, -4.0)]), METAL_DARK, 1)
	_add_poly(stool, PackedVector2Array([Vector2(-1.5, seat_y + 6.0), Vector2(1.5, seat_y + 6.0), Vector2(1.5, -3.0), Vector2(-1.5, -3.0)]), METAL, 2)
	_add_poly(stool, _ellipse(Vector2(0, seat_y + 6.0), 5.0, 2.0, 24), METAL_DARK, 3)
	_add_poly(stool, _ellipse(Vector2(0, seat_y + 5.3), 3.7, 1.4, 22), METAL, 4)
	_add_poly(stool, _ellipse_band(Vector2(0, seat_y + 0.6), 16.0, 6.7, 5.2, 32), Color("20262d"), 4)
	_add_poly(stool, _ellipse(Vector2(0, seat_y), 16.0, 6.7, 34), SEAT_SIDE, 5)
	_add_poly(stool, _ellipse(Vector2(0, seat_y - 0.8), 14.6, 5.8, 34), SEAT_TOP, 6)
	_add_poly(stool, _ellipse(Vector2(0, seat_y - 1.2), 11.8, 4.3, 30), SEAT_INNER, 7)
