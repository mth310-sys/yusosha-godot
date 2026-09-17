extends Node3D

const CHARACTER_HEIGHT: float = 1.20
const WALK_SPEED: float = 1.15
const EITA_MIN_X: float = -5.5
const EITA_MAX_X: float = 5.5
const BITA_MIN_X: float = -5.5
const BITA_MAX_X: float = 5.5
const BITA_AISLE_Z: float = 0.5
const BITA_SEAT_Z: float = -0.15
const BITA_SEAT_XS: Array[float] = [-5.0,-4.0,-3.0,-1.5,-0.5,0.5,2.0,3.0,4.0,5.0]

enum BitaState { WALKING, TO_SEAT, SITTING, FROM_SEAT }

var eita_direction: float = 1.0
var bita: Node3D
var bita_state: BitaState = BitaState.WALKING
var bita_target_x: float = 3.0
var bita_walk_direction: float = 1.0
var bita_state_time: float = 0.0
var bita_next_seat_time: float = 3.5
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	name = "Eita"
	position = Vector3(-3.5,0.0,-4.5)
	_build_customer(self)

	bita = Node3D.new()
	bita.name = "Bita"
	bita.position = Vector3(0.0,0.0,5.0)
	add_child(bita)
	_build_customer(bita)

func _process(delta: float) -> void:
	_update_eita(delta)
	_update_bita(delta)

func _update_eita(delta: float) -> void:
	position.x += eita_direction*WALK_SPEED*delta
	if position.x >= EITA_MAX_X:
		position.x = EITA_MAX_X
		eita_direction = -1.0
	elif position.x <= EITA_MIN_X:
		position.x = EITA_MIN_X
		eita_direction = 1.0
	rotation_degrees.y = 90.0 if eita_direction > 0.0 else -90.0
	_apply_walk_bob(self,Time.get_ticks_msec()*0.001)

func _update_bita(delta: float) -> void:
	bita_state_time += delta
	match bita_state:
		BitaState.WALKING:
			bita.position.x += bita_walk_direction*WALK_SPEED*0.85*delta
			if bita.position.x >= BITA_MAX_X:
				bita.position.x = BITA_MAX_X
				bita_walk_direction = -1.0
			elif bita.position.x <= BITA_MIN_X:
				bita.position.x = BITA_MIN_X
				bita_walk_direction = 1.0
			bita.rotation_degrees.y = 90.0 if bita_walk_direction > 0.0 else -90.0
			_apply_walk_bob(bita,Time.get_ticks_msec()*0.001+1.2)
			if bita_state_time >= bita_next_seat_time:
				bita_target_x = BITA_SEAT_XS[rng.randi_range(0,BITA_SEAT_XS.size()-1)]
				bita_state = BitaState.TO_SEAT
				bita_state_time = 0.0
		BitaState.TO_SEAT:
			var target := Vector3(bita_target_x,0.0,BITA_SEAT_Z)
			bita.position = bita.position.move_toward(target,WALK_SPEED*delta)
			bita.rotation_degrees.y = 180.0
			_apply_walk_bob(bita,Time.get_ticks_msec()*0.001+1.2)
			if bita.position.distance_to(target) < 0.03:
				bita.position = target
				bita_state = BitaState.SITTING
				bita_state_time = 0.0
				_set_sitting_pose(bita,true)
		BitaState.SITTING:
			if bita_state_time >= rng.randf_range(2.5,5.0):
				_set_sitting_pose(bita,false)
				bita_state = BitaState.FROM_SEAT
				bita_state_time = 0.0
		BitaState.FROM_SEAT:
			var aisle_target := Vector3(bita.position.x,0.0,BITA_AISLE_Z)
			bita.position = bita.position.move_toward(aisle_target,WALK_SPEED*delta)
			if bita.position.distance_to(aisle_target) < 0.03:
				bita.position = aisle_target
				bita_walk_direction = -1.0 if rng.randf() < 0.5 else 1.0
				bita_next_seat_time = rng.randf_range(3.0,7.0)
				bita_state = BitaState.WALKING
				bita_state_time = 0.0

func _apply_walk_bob(root: Node3D,t: float) -> void:
	var body := root.get_node_or_null("Body") as MeshInstance3D
	if body != null: body.position.y = 0.56+sin(t*9.0)*0.018

func _set_sitting_pose(root: Node3D,sitting: bool) -> void:
	var body := root.get_node_or_null("Body") as MeshInstance3D
	var head := root.get_node_or_null("Head") as MeshInstance3D
	var left_leg := root.get_node_or_null("LeftLeg") as MeshInstance3D
	var right_leg := root.get_node_or_null("RightLeg") as MeshInstance3D
	if body != null: body.position.y = 0.43 if sitting else 0.56
	if head != null: head.position.y = 0.83 if sitting else 0.96
	if left_leg != null: left_leg.rotation_degrees.x = -70.0 if sitting else 0.0
	if right_leg != null: right_leg.rotation_degrees.x = -70.0 if sitting else 0.0

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
