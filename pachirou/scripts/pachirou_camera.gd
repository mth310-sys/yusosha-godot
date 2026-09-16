extends Camera3D

@export var move_speed: float = 6.0
@export var drag_speed: float = 0.012

var _dragging: bool = false
var _last_mouse_position: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input.y += 1.0

	if input.length_squared() > 0.0:
		input = input.normalized()
		_move_on_map(input * move_speed * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_MIDDLE or mouse_button.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = mouse_button.pressed
			_last_mouse_position = mouse_button.position
	elif event is InputEventMouseMotion and _dragging:
		var mouse_motion := event as InputEventMouseMotion
		var delta_pixels: Vector2 = mouse_motion.position - _last_mouse_position
		_last_mouse_position = mouse_motion.position
		_move_on_map(Vector2(-delta_pixels.x, -delta_pixels.y) * drag_speed)

func _move_on_map(screen_delta: Vector2) -> void:
	# Move parallel to the floor while preserving the fixed isometric angle and zoom.
	var right := global_transform.basis.x
	right.y = 0.0
	right = right.normalized()
	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	global_position += right * screen_delta.x + forward * screen_delta.y
