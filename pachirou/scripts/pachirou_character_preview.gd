extends Node3D

const CHARACTER_HEIGHT: float = 1.20
const TILE_SIZE: float = 1.0
const WALK_SPEED: float = 1.25

var bita: Node3D
var grid_rules: PachirouGridRules
var bita_path: Array[Vector2i] = []
var bita_path_index: int = 0
var bita_target_seat := Vector2i(-1,-1)
var bita_moving: bool = false

func _ready() -> void:
	name = "Eita"
	position = Vector3(-7.5,0.0,-9.5)
	_build_customer(self)
	bita = Node3D.new()
	bita.name = "Bita"
	bita.position = Vector3(TILE_SIZE,0.0,0.0)
	add_child(bita)
	_build_customer(bita)
	call_deferred("_start_bita_grid_test")

func _process(delta: float) -> void:
	if not bita_moving or grid_rules == null or bita_path_index >= bita_path.size(): return
	var target_global := grid_rules.cell_to_world(bita_path[bita_path_index])
	var current := bita.global_position
	var flat_target := Vector3(target_global.x,current.y,target_global.z)
	var distance := current.distance_to(flat_target)
	if distance <= 0.03:
		bita.global_position = flat_target
		bita_path_index += 1
		if bita_path_index >= bita_path.size():
			bita_moving = false
			_on_bita_reached_seat()
		return
	var direction := (flat_target-current).normalized()
	bita.global_position = current+direction*minf(WALK_SPEED*delta,distance)
	if direction.length_squared() > 0.001: bita.rotation.y = atan2(direction.x,direction.z)

func _start_bita_grid_test() -> void:
	grid_rules = get_tree().current_scene.get_node_or_null("GridRules") as PachirouGridRules
	if grid_rules == null: return
	while not grid_rules.layout_ready: await get_tree().process_frame
	var seats := grid_rules.available_seats()
	if seats.is_empty():
		push_warning("Bita: no registered seats")
		return
	var start := grid_rules.world_to_cell(bita.global_position)
	for seat in seats:
		var candidate := grid_rules.find_path(start,seat,bita)
		if not candidate.is_empty() and (bita_path.is_empty() or candidate.size() < bita_path.size()):
			bita_path = candidate
			bita_target_seat = seat
	if bita_path.is_empty():
		push_warning("Bita: no reachable seat from %s" % start)
		return
	if not grid_rules.reserve_seat(bita_target_seat,bita):
		bita_path.clear()
		return
	var start_world := grid_rules.cell_to_world(start)
	bita.global_position = Vector3(start_world.x,bita.global_position.y,start_world.z)
	bita_path_index = 1 if bita_path.size() > 1 else 0
	bita_moving = true

func _on_bita_reached_seat() -> void:
	if grid_rules == null or bita_target_seat.x < 0: return
	if grid_rules.occupy_seat(bita_target_seat,bita):
		bita.set_meta("interaction_state","AT_SEAT")
		var machine := grid_rules.machine_for_seat(bita_target_seat)
		if machine != null: bita.set_meta("target_machine",machine)

func _build_customer(root: Node3D) -> void:
	var skin := _material(Color(0.92,0.72,0.56))
	var hair := _material(Color(0.12,0.10,0.09))
	var shirt := _material(Color(0.20,0.52,0.72))
	var pants := _material(Color(0.16,0.19,0.24))
	var shoes := _material(Color(0.08,0.08,0.09))
	_box(root,"LeftShoe",Vector3(0.14,0.07,0.22),Vector3(-0.09,0.035,0.025),shoes)
	_box(root,"RightShoe",Vector3(0.14,0.07,0.22),Vector3(0.09,0.035,0.025),shoes)
	_box(root,"LeftLeg",Vector3(0.13,0.30,0.14),Vector3(-0.09,0.22,0.0),pants)
	_box(root,"RightLeg",Vector3(0.13,0.30,0.14),Vector3(0.09,0.22,0.0),pants)
	_box(root,"Body",Vector3(0.38,0.38,0.22),Vector3(0.0,0.56,0.0),shirt)
	_box(root,"LeftArm",Vector3(0.10,0.34,0.12),Vector3(-0.245,0.55,0.0),skin)
	_box(root,"RightArm",Vector3(0.10,0.34,0.12),Vector3(0.245,0.55,0.0),skin)
	_box(root,"Head",Vector3(0.42,0.40,0.38),Vector3(0.0,0.96,0.0),skin)
	_box(root,"HairTop",Vector3(0.44,0.10,0.40),Vector3(0.0,1.155,-0.01),hair)
	_box(root,"HairBack",Vector3(0.44,0.24,0.08),Vector3(0.0,1.04,-0.19),hair)
	_box(root,"LeftEye",Vector3(0.035,0.045,0.018),Vector3(-0.085,1.00,0.198),hair)
	_box(root,"RightEye",Vector3(0.035,0.045,0.018),Vector3(0.085,1.00,0.198),hair)

func _box(root: Node3D,node_name: String,size: Vector3,local_position: Vector3,material: StandardMaterial3D) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.material_override = material
	root.add_child(mesh_instance)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material
