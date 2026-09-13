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

	# Tuned against the supplied ZELVOLT reference image from the data-counter down.
	var top_panel := scene.get_node_or_null("TopPanel") as Control
	var reel_frame := scene.get_node_or_null("ReelFrame") as Control
	var info_back := scene.get_node_or_null("InfoBack") as Control
	var play_panel := scene.get_node_or_null("PlayPanel") as Control
	var lower_panel := scene.get_node_or_null("LowerPanel") as Control
	var lower_glow := scene.get_node_or_null("LowerGlow") as Control
	var lower_logo := scene.get_node_or_null("LowerLogo") as Control
	var lower_tagline := scene.get_node_or_null("LowerTagline") as Control

	if top_panel != null:
		_set_offsets(top_panel, -292.0, -385.0, 292.0, -272.0)
	if reel_frame != null:
		_set_offsets(reel_frame, -292.0, -250.0, 292.0, 16.0)
	if info_back != null:
		_set_offsets(info_back, -266.0, 25.0, 266.0, 83.0)
	if play_panel != null:
		_set_offsets(play_panel, -292.0, 95.0, 292.0, 258.0)
	if lower_panel != null:
		_set_offsets(lower_panel, -292.0, 271.0, 292.0, 418.0)
	if lower_glow != null:
		_set_offsets(lower_glow, -266.0, 287.0, 266.0, 396.0)
	if lower_logo != null:
		_set_offsets(lower_logo, -250.0, 304.0, 250.0, 353.0)
		lower_logo.add_theme_font_size_override("font_size", 34)
	if lower_tagline != null:
		_set_offsets(lower_tagline, -250.0, 355.0, 250.0, 380.0)

	var vbox := scene.get_node_or_null("Center/VBox") as Control
	if vbox != null:
		var reels := vbox.get_node_or_null("Reels") as Control
		var payline := vbox.get_node_or_null("Payline") as Control
		var info := vbox.get_node_or_null("Info") as Control
		var start := vbox.get_node_or_null("StartButton") as Control
		var bets := vbox.get_node_or_null("BetControls") as Control
		var stops := vbox.get_node_or_null("Stops") as Control
		if reels != null:
			_set_offsets(reels, 26.0, 150.0, 558.0, 342.0)
		if payline != null:
			_set_offsets(payline, 28.0, 348.0, 556.0, 368.0)
		if info != null:
			_set_offsets(info, 48.0, 374.0, 536.0, 428.0)
		if start != null:
			_set_offsets(start, 6.0, 443.0, 187.0, 500.0)
		if bets != null:
			_set_offsets(bets, 197.0, 443.0, 578.0, 500.0)
		if stops != null:
			_set_offsets(stops, 108.0, 522.0, 476.0, 606.0)

	_install_lower_pattern(scene)
	_install_side_bevels(scene)
	_install_inner_chrome_rails(scene)
	_install_control_trim(scene)
	_install_lower_panel_facets(scene)
	_install_lower_vent(scene)
	_install_top_speaker_accents(scene)

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
	left.polygon = PackedVector2Array([Vector2(307, 224), Vector2(325, 207), Vector2(325, 704), Vector2(307, 681)])
	left.color = Color(0.82, 0.84, 0.88, 0.82)
	left.z_index = 1
	scene.add_child(left)
	var right := Polygon2D.new()
	right.name = "ReferenceRightBevel"
	right.polygon = PackedVector2Array([Vector2(955, 207), Vector2(973, 224), Vector2(973, 681), Vector2(955, 704)])
	right.color = Color(0.82, 0.84, 0.88, 0.82)
	right.z_index = 1
	scene.add_child(right)

func _install_inner_chrome_rails(scene: Node) -> void:
	if scene.has_node("ReferenceInnerRailLeft"):
		return
	for side in [-1, 1]:
		var x: float = 337.0 if side < 0 else 943.0
		var shadow := Line2D.new()
		shadow.name = "ReferenceInnerRailLeftShadow" if side < 0 else "ReferenceInnerRailRightShadow"
		shadow.width = 9.0
		shadow.default_color = Color(0.02, 0.025, 0.035, 0.95)
		shadow.points = PackedVector2Array([Vector2(x, 175.0), Vector2(x, 802.0)])
		shadow.z_index = 1
		scene.add_child(shadow)
		var highlight := Line2D.new()
		highlight.name = "ReferenceInnerRailLeft" if side < 0 else "ReferenceInnerRailRight"
		highlight.width = 3.0
		highlight.default_color = Color(0.86, 0.88, 0.92, 0.92)
		highlight.points = PackedVector2Array([Vector2(x + float(side) * 3.0, 178.0), Vector2(x + float(side) * 3.0, 800.0)])
		highlight.z_index = 2
		scene.add_child(highlight)

func _install_control_trim(scene: Node) -> void:
	if scene.has_node("ReferenceControlTrim"):
		return
	var shadow := Line2D.new()
	shadow.name = "ReferenceControlTrimShadow"
	shadow.width = 10.0
	shadow.default_color = Color(0.02, 0.025, 0.035, 0.95)
	shadow.points = PackedVector2Array([
		Vector2(350, 518), Vector2(930, 518), Vector2(930, 712),
		Vector2(350, 712), Vector2(350, 518)
	])
	shadow.z_index = 1
	scene.add_child(shadow)
	var trim := Line2D.new()
	trim.name = "ReferenceControlTrim"
	trim.width = 4.0
	trim.default_color = Color(0.78, 0.81, 0.86, 0.95)
	trim.points = PackedVector2Array([
		Vector2(354, 523), Vector2(926, 523), Vector2(926, 706),
		Vector2(354, 706), Vector2(354, 523)
	])
	trim.z_index = 2
	scene.add_child(trim)

func _install_lower_panel_facets(scene: Node) -> void:
	if scene.has_node("ReferenceLowerFacetTop"):
		return
	var top_facet := Polygon2D.new()
	top_facet.name = "ReferenceLowerFacetTop"
	top_facet.polygon = PackedVector2Array([
		Vector2(357, 716), Vector2(923, 716), Vector2(902, 735), Vector2(378, 735)
	])
	top_facet.color = Color(0.58, 0.61, 0.66, 0.92)
	top_facet.z_index = 2
	scene.add_child(top_facet)
	var top_shadow := Line2D.new()
	top_shadow.name = "ReferenceLowerFacetTopShadow"
	top_shadow.width = 3.0
	top_shadow.default_color = Color(0.04, 0.045, 0.055, 1.0)
	top_shadow.points = PackedVector2Array([Vector2(378, 736), Vector2(902, 736)])
	top_shadow.z_index = 3
	scene.add_child(top_shadow)
	var bottom_facet := Polygon2D.new()
	bottom_facet.name = "ReferenceLowerFacetBottom"
	bottom_facet.polygon = PackedVector2Array([
		Vector2(378, 846), Vector2(902, 846), Vector2(922, 861), Vector2(358, 861)
	])
	bottom_facet.color = Color(0.48, 0.51, 0.56, 0.90)
	bottom_facet.z_index = 2
	scene.add_child(bottom_facet)

func _install_lower_vent(scene: Node) -> void:
	if scene.has_node("ReferenceLowerVent"):
		return
	var vent := Control.new()
	vent.name = "ReferenceLowerVent"
	vent.position = Vector2(374, 826)
	vent.size = Vector2(532, 25)
	vent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vent.z_index = 4
	scene.add_child(vent)

	var backing := ColorRect.new()
	backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backing.color = Color(0.015, 0.018, 0.023, 0.98)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vent.add_child(backing)

	for i in range(33):
		var groove := ColorRect.new()
		groove.position = Vector2(5.0 + float(i) * 16.0, 4.0)
		groove.size = Vector2(5.0, 17.0)
		groove.color = Color(0.18, 0.19, 0.21, 0.98)
		groove.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vent.add_child(groove)
		var shine := ColorRect.new()
		shine.position = Vector2(7.0 + float(i) * 16.0, 4.0)
		shine.size = Vector2(1.0, 17.0)
		shine.color = Color(0.45, 0.47, 0.50, 0.42)
		shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vent.add_child(shine)

func _install_top_speaker_accents(scene: Node) -> void:
	if scene.has_node("ReferenceTopSpeakerLeft"):
		return
	for side in [-1, 1]:
		var speaker := Polygon2D.new()
		speaker.name = "ReferenceTopSpeakerLeft" if side < 0 else "ReferenceTopSpeakerRight"
		var cx := 382.0 if side < 0 else 898.0
		speaker.polygon = PackedVector2Array([
			Vector2(cx - 37.0, 90.0), Vector2(cx + 37.0, 90.0),
			Vector2(cx + 27.0, 143.0), Vector2(cx - 27.0, 143.0)
		])
		speaker.color = Color(0.16, 0.17, 0.20, 0.96)
		speaker.z_index = 3
		scene.add_child(speaker)
		for j in range(5):
			var slit := Line2D.new()
			slit.width = 3.0
			slit.default_color = Color(0.025, 0.025, 0.035, 1.0)
			slit.points = PackedVector2Array([
				Vector2(cx - 25.0 + float(j) * 11.0, 103.0),
				Vector2(cx - 34.0 + float(j) * 11.0, 132.0)
			])
			slit.z_index = 4
			scene.add_child(slit)
