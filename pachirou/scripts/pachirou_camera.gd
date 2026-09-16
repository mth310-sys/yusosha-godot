extends Camera3D

@export var move_speed: float = 6.0
@export var drag_speed: float = 0.012
@export var zoom_step: float = 0.85
@export var zoom_min: float = 2.2
@export var zoom_max: float = 16.0
@export var zoom_smoothing: float = 12.0

var _dragging: bool = false
var _target_size: float = 10.5

func _ready() -> void:
	_target_size = size

func _process(delta: float) -> void:
	var input := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): input.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): input.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): input.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): input.y += 1.0
	if input.length_squared() > 0.0:
		input = input.normalized()
		_move_screen_direction(input, move_speed * delta * max(0.35,size/10.5))
	size = lerpf(size,_target_size,1.0-exp(-zoom_smoothing*delta))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_WHEEL_UP and button.pressed:
			_target_size = clampf(_target_size-zoom_step,zoom_min,zoom_max)
			return
		if button.button_index == MOUSE_BUTTON_WHEEL_DOWN and button.pressed:
			_target_size = clampf(_target_size+zoom_step,zoom_min,zoom_max)
			return
		if button.button_index == MOUSE_BUTTON_LEFT or button.button_index == MOUSE_BUTTON_MIDDLE or button.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = button.pressed
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		_move_screen_direction(-motion.relative,drag_speed*max(0.35,size/10.5))

func _move_screen_direction(direction: Vector2,amount: float) -> void:
	var right: Vector3 = global_transform.basis.x
	right.y = 0.0
	right = right.normalized()
	var up_map := Vector3(-right.z,0.0,right.x)
	global_position += (right*direction.x+up_map*direction.y)*amount
