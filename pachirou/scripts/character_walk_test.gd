extends Node

@export var move_speed: float = 1.35
@export var step_bob: float = 0.018
@export var step_frequency: float = 9.0

var _grid: PachirouGridRules
var _path: Array[Vector2i] = []
var _path_index: int = 0
var _step_time: float = 0.0
var _visual: Node3D
var _character_ready: bool = false
var _character: Node3D

func _ready() -> void:
	call_deferred("_begin_walk_test")

func _begin_walk_test() -> void:
	_character = get_parent() as Node3D
	if _character == null:
		return
	# CharacterBase01 builds Visual in its own _ready(). Wait until that has completed.
	for wait_index in range(2):
		await get_tree().process_frame
	_visual = _character.get_node_or_null("Visual") as Node3D
	_character_ready = _visual != null
	_grid = get_tree().current_scene.get_node_or_null("GridRules") as PachirouGridRules
	if _grid == null:
		return
	while not _grid.layout_ready:
		await get_tree().process_frame
	var start := _grid.world_to_cell(_character.global_position)
	if not _grid.is_walkable(start):
		start = _nearest_walkable(start)
		_character.global_position = _grid.cell_to_world(start)
	var goal := _choose_goal(start)
	_path = _grid.find_path(start, goal, self)
	_path_index = 1 if _path.size() > 1 else 0

func _process(delta: float) -> void:
	if not _character_ready or _grid == null or _path_index >= _path.size():
		_reset_bob()
		return
	var target := _grid.cell_to_world(_path[_path_index])
	var offset := target - _character.global_position
	offset.y = 0.0
	if offset.length() < 0.035:
		_character.global_position.x = target.x
		_character.global_position.z = target.z
		_path_index += 1
		if _path_index >= _path.size():
			_reset_bob()
		return
		target = _grid.cell_to_world(_path[_path_index])
		offset = target - _character.global_position
		offset.y = 0.0
	if offset.length_squared() <= 0.0001:
		return
	var direction := offset.normalized()
	_character.global_position += direction * minf(move_speed * delta, offset.length())
	_character.rotation.y = atan2(direction.x, direction.z)
	_step_time += delta * step_frequency
	if _visual != null:
		_visual.position.y = absf(sin(_step_time)) * step_bob

func _choose_goal(start: Vector2i) -> Vector2i:
	var candidates: Array[Vector2i] = [
		Vector2i(3,18), Vector2i(6,18), Vector2i(9,18), Vector2i(12,18),
		Vector2i(15,18), Vector2i(18,18), Vector2i(18,16), Vector2i(18,15),
		Vector2i(3,16), Vector2i(3,15)
	]
	var best := start
	var best_distance: int = -1
	for cell in candidates:
		if not _grid.is_walkable(cell):
			continue
		var test_path := _grid.find_path(start, cell, self)
		if test_path.is_empty():
			continue
		var distance := test_path.size()
		if distance > best_distance:
			best_distance = distance
			best = cell
	return best

func _nearest_walkable(origin: Vector2i) -> Vector2i:
	for radius in range(1, 22):
		for z in range(origin.y - radius, origin.y + radius + 1):
			for x in range(origin.x - radius, origin.x + radius + 1):
				var cell := Vector2i(x,z)
				if _grid.is_inside(cell) and _grid.is_walkable(cell):
					return cell
	return origin

func _reset_bob() -> void:
	if _visual != null:
		_visual.position.y = move_toward(_visual.position.y, 0.0, 0.003)
