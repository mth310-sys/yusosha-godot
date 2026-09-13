extends Node

func _ready() -> void:
	call_deferred("_apply_reference_layout")

func _set_offsets(node: Control, left: float, top: float, right: float, bottom: float) -> void:
	node.offset_left = left
	node.offset_top = top
	node.offset_right = right
	node.offset_bottom = bottom

func _apply_reference_layout() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	# Reference proportions: illuminated upper panel -> reels -> info -> controls -> lower panel.
	var top_panel := scene.get_node_or_null("TopPanel") as Control
	var reel_frame := scene.get_node_or_null("ReelFrame") as Control
	var info_back := scene.get_node_or_null("InfoBack") as Control
	var play_panel := scene.get_node_or_null("PlayPanel") as Control
	var lower_panel := scene.get_node_or_null("LowerPanel") as Control
	var lower_glow := scene.get_node_or_null("LowerGlow") as Control
	var lower_logo := scene.get_node_or_null("LowerLogo") as Control
	var lower_tagline := scene.get_node_or_null("LowerTagline") as Control

	if top_panel != null:
		_set_offsets(top_panel, -292.0, -385.0, 292.0, -275.0)
	if reel_frame != null:
		_set_offsets(reel_frame, -292.0, -255.0, 292.0, 20.0)
	if info_back != null:
		_set_offsets(info_back, -265.0, 30.0, 265.0, 88.0)
	if play_panel != null:
		_set_offsets(play_panel, -292.0, 100.0, 292.0, 255.0)
	if lower_panel != null:
		_set_offsets(lower_panel, -292.0, 270.0, 292.0, 415.0)
	if lower_glow != null:
		_set_offsets(lower_glow, -266.0, 287.0, 266.0, 397.0)
	if lower_logo != null:
		_set_offsets(lower_logo, -250.0, 303.0, 250.0, 351.0)
	if lower_tagline != null:
		_set_offsets(lower_tagline, -250.0, 353.0, 250.0, 378.0)

	var vbox := scene.get_node_or_null("Center/VBox") as Control
	if vbox != null:
		var reels := vbox.get_node_or_null("Reels") as Control
		var payline := vbox.get_node_or_null("Payline") as Control
		var info := vbox.get_node_or_null("Info") as Control
		var start := vbox.get_node_or_null("StartButton") as Control
		var bets := vbox.get_node_or_null("BetControls") as Control
		var stops := vbox.get_node_or_null("Stops") as Control
		if reels != null:
			_set_offsets(reels, 26.0, 145.0, 558.0, 337.0)
		if payline != null:
			_set_offsets(payline, 28.0, 343.0, 556.0, 363.0)
		if info != null:
			_set_offsets(info, 48.0, 378.0, 536.0, 432.0)
		if start != null:
			_set_offsets(start, 4.0, 448.0, 184.0, 502.0)
		if bets != null:
			_set_offsets(bets, 194.0, 448.0, 580.0, 502.0)
		if stops != null:
			_set_offsets(stops, 108.0, 518.0, 476.0, 600.0)

	_install_lower_pattern(scene)
	_install_side_bevels(scene)

func _install_lower_pattern(scene: Node) -> void:
	var lower_glow := scene.get_node_or_null("LowerGlow") as Control
	if lower_glow == null or lower_glow.has_node("ReferencePattern"):
		return
	var pattern := Control.new()
	pattern.name = "ReferencePattern"
	pattern.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pattern.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pattern.z_index = 1
	lower_glow.add_child(pattern)

	for i in range(9):
		var x := 18.0 + float(i) * 62.0
		var down := Line2D.new()
		down.width = 2.0
		down.default_color = Color(1.0, 0.76, 0.04, 0.24)
		down.points = PackedVector2Array([Vector2(x, 8.0), Vector2(x + 42.0, 102.0)])
		pattern.add_child(down)
		var up := Line2D.new()
		up.width = 2.0
		up.default_color = Color(1.0, 0.76, 0.04, 0.18)
		up.points = PackedVector2Array([Vector2(x + 42.0, 8.0), Vector2(x, 102.0)])
		pattern.add_child(up)

func _install_side_bevels(scene: Node) -> void:
	if scene.has_node("ReferenceLeftBevel"):
		return
	var left := Polygon2D.new()
	left.name = "ReferenceLeftBevel"
	left.polygon = PackedVector2Array([Vector2(308, 240), Vector2(326, 222), Vector2(326, 695), Vector2(308, 672)])
	left.color = Color(0.76, 0.79, 0.84, 0.72)
	left.z_index = 1
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE if left is Control else 0
	scene.add_child(left)
	var right := Polygon2D.new()
	right.name = "ReferenceRightBevel"
	right.polygon = PackedVector2Array([Vector2(972, 222), Vector2(990, 240), Vector2(990, 672), Vector2(972, 695)])
	right.color = Color(0.76, 0.79, 0.84, 0.72)
	right.z_index = 1
	scene.add_child(right)
