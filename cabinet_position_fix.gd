extends Node

func _ready() -> void:
	call_deferred("_apply_position_fixes")

func _set_offsets(node: Control, left: float, top: float, right: float, bottom: float) -> void:
	node.offset_left = left
	node.offset_top = top
	node.offset_right = right
	node.offset_bottom = bottom

func _apply_position_fixes() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	# Correct the parts that were visibly out of registration against the
	# supplied ZELVOLT cabinet reference. Keep gameplay/reel logic untouched.
	var info_back := scene.get_node_or_null("InfoBack") as Control
	var play_panel := scene.get_node_or_null("PlayPanel") as Control
	if info_back != null:
		_set_offsets(info_back, -266.0, -28.0, 266.0, 10.0)
	if play_panel != null:
		_set_offsets(play_panel, -292.0, 15.0, 292.0, 260.0)

	var vbox := scene.get_node_or_null("Center/VBox") as Control
	if vbox != null:
		var info := vbox.get_node_or_null("Info") as Control
		var start := vbox.get_node_or_null("StartButton") as Control
		var bets := vbox.get_node_or_null("BetControls") as Control
		var stops := vbox.get_node_or_null("Stops") as Control
		if info != null:
			_set_offsets(info, 48.0, 405.0, 536.0, 462.0)
		if start != null:
			_set_offsets(start, 6.0, 481.0, 187.0, 547.0)
		if bets != null:
			_set_offsets(bets, 197.0, 481.0, 578.0, 547.0)
		if stops != null:
			_set_offsets(stops, 82.0, 563.0, 502.0, 663.0)

	# The old trim line was crossing the START/BET/MAX BET row. Re-register it
	# around the full control deck instead of through the controls.
	var trim_shadow := scene.get_node_or_null("ReferenceControlTrimShadow") as Line2D
	var trim := scene.get_node_or_null("ReferenceControlTrim") as Line2D
	if trim_shadow != null:
		trim_shadow.points = PackedVector2Array([
			Vector2(350, 552), Vector2(930, 552), Vector2(930, 805),
			Vector2(350, 805), Vector2(350, 552)
		])
	if trim != null:
		trim.points = PackedVector2Array([
			Vector2(354, 557), Vector2(926, 557), Vector2(926, 800),
			Vector2(354, 800), Vector2(354, 557)
		])

	# Move the speaker shoulders outboard so they frame the upper panel rather
	# than intruding into the logo area.
	_move_speaker(scene, "ReferenceTopSpeakerLeft", -13.0, -7.0)
	_move_speaker(scene, "ReferenceTopSpeakerRight", 13.0, -7.0)
	_move_speaker_slits(scene, true, -13.0, -7.0)
	_move_speaker_slits(scene, false, 13.0, -7.0)

func _move_speaker(scene: Node, node_name: String, dx: float, dy: float) -> void:
	var speaker := scene.get_node_or_null(node_name) as Polygon2D
	if speaker == null:
		return
	var moved := PackedVector2Array()
	for point in speaker.polygon:
		moved.append(point + Vector2(dx, dy))
	speaker.polygon = moved

func _move_speaker_slits(scene: Node, left_side: bool, dx: float, dy: float) -> void:
	# Slits are unnamed, so constrain the search to the small upper-speaker area.
	for child in scene.get_children():
		if child is Line2D:
			var line := child as Line2D
			if line.points.size() != 2:
				continue
			var p := line.points[0]
			var is_upper := p.y >= 110.0 and p.y <= 140.0
			var is_side := p.x < 450.0 if left_side else p.x > 830.0
			if is_upper and is_side:
				var moved := PackedVector2Array()
				for point in line.points:
					moved.append(point + Vector2(dx, dy))
				line.points = moved
