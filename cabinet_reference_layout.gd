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

	# Tuned against the supplied ZELVOLT reference image. Preserve the verified
	# reel/game logic while matching the cabinet's top panel, control deck, and
	# deep lower-panel proportions more closely.
	var cabinet := scene.get_node_or_null("CabinetBody") as Control
	var left_rail := scene.get_node_or_null("LeftRailOuter") as Control
	var right_rail := scene.get_node_or_null("RightRailOuter") as Control
	var left_led := scene.get_node_or_null("LeftLED") as Control
	var right_led := scene.get_node_or_null("RightLED") as Control
	var top_led := scene.get_node_or_null("TopLED") as Control
	var top_panel := scene.get_node_or_null("TopPanel") as Control
	var top_accent_left := scene.get_node_or_null("TopAccentLeft") as Control
	var top_accent_right := scene.get_node_or_null("TopAccentRight") as Control
	var reel_frame := scene.get_node_or_null("ReelFrame") as Control
	var info_back := scene.get_node_or_null("InfoBack") as Control
	var play_panel := scene.get_node_or_null("PlayPanel") as Control
	var lower_panel := scene.get_node_or_null("LowerPanel") as Control
	var lower_glow := scene.get_node_or_null("LowerGlow") as Control
	var lower_logo := scene.get_node_or_null("LowerLogo") as Control
	var lower_tagline := scene.get_node_or_null("LowerTagline") as Control

	if cabinet != null:
		_set_offsets(cabinet, -350.0, -520.0, 350.0, 520.0)
	if left_rail != null:
		_set_offsets(left_rail, -333.0, -495.0, -315.0, 495.0)
	if right_rail != null:
		_set_offsets(right_rail, 315.0, -495.0, 333.0, 495.0)
	if left_led != null:
		_set_offsets(left_led, -313.0, -450.0, -306.0, 450.0)
	if right_led != null:
		_set_offsets(right_led, 306.0, -450.0, 313.0, 450.0)
	if top_led != null:
		_set_offsets(top_led, -250.0, -500.0, 250.0, -489.0)
	if top_panel != null:
		_set_offsets(top_panel, -292.0, -460.0, 292.0, -315.0)
	if top_accent_left != null:
		_set_offsets(top_accent_left, -258.0, -472.0, -190.0, -452.0)
	if top_accent_right != null:
		_set_offsets(top_accent_right, 190.0, -472.0, 258.0, -452.0)
	if reel_frame != null:
		_set_offsets(reel_frame, -292.0, -298.0, 292.0, -38.0)
	if info_back != null:
		_set_offsets(info_back, -266.0, -28.0, 266.0, 48.0)
	if play_panel != null:
		_set_offsets(play_panel, -292.0, 58.0, 292.0, 260.0)
	if lower_panel != null:
		_set_offsets(lower_panel, -292.0, 275.0, 292.0, 505.0)
	if lower_glow != null:
		_set_offsets(lower_glow, -266.0, 295.0, 266.0, 480.0)
	if lower_logo != null:
		_set_offsets(lower_logo, -250.0, 335.0, 250.0, 398.0)
		lower_logo.add_theme_font_size_override("font_size", 40)
	if lower_tagline != null:
		_set_offsets(lower_tagline, -250.0, 402.0, 250.0, 432.0)
		lower_tagline.add_theme_font_size_override("font_size", 12)

	var vbox := scene.get_node_or_null("Center/VBox") as Control
	if vbox != null:
		vbox.custom_minimum_size = Vector2(584, 930)
		var reels := vbox.get_node_or_null("Reels") as Control
		var payline := vbox.get_node_or_null("Payline") as Control
		var info := vbox.get_node_or_null("Info") as Control
		var start := vbox.get_node_or_null("StartButton") as Control
		var bets := vbox.get_node_or_null("BetControls") as Control
		var stops := vbox.get_node_or_null("Stops") as Control
		if reels != null:
			_set_offsets(reels, 26.0, 185.0, 558.0, 377.0)
		if payline != null:
			_set_offsets(payline, 28.0, 381.0, 556.0, 402.0)
		if info != null:
			_set_offsets(info, 48.0, 408.0, 536.0, 470.0)
			_polish_info_typography(info)
		if start != null:
			_set_offsets(start, 6.0, 484.0, 187.0, 550.0)
			start.add_theme_font_size_override("font_size", 16)
		if bets != null:
			_set_offsets(bets, 197.0, 484.0, 578.0, 550.0)
			_polish_control_buttons(bets, false)
		if stops != null:
			_set_offsets(stops, 108.0, 566.0, 476.0, 666.0)
			_polish_control_buttons(stops, true)

	_install_lower_pattern(scene)
	_install_side_bevels(scene)
	_install_inner_chrome_rails(scene)
	_install_control_trim(scene)
	_install_lower_panel_facets(scene)
	_install_lower_side_grilles(scene)
	_install_lower_vent(scene)
	_install_top_speaker_accents(scene)

func _polish_info_typography(info: Control) -> void:
	for box in info.get_children():
		if box is Control:
			for child in box.get_children():
				if child is Label:
					var label := child as Label
					if label.text in ["CREDIT", "BET", "PAYOUT"]:
						label.add_theme_font_size_override("font_size", 13)
					else:
						label.add_theme_font_size_override("font_size", 24)

func _polish_control_buttons(container: Control, is_stop_row: bool) -> void:
	for child in container.get_children():
		if child is Button:
			var button := child as Button
			button.add_theme_font_size_override("font_size", 15 if not is_stop_row else 13)
			if is_stop_row:
				button.custom_minimum_size = Vector2(76.0, 76.0)

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
		down.points = PackedVector2Array([Vector2(x, 8.0), Vector2(x + 42.0, 178.0)])
		pattern.add_child(down)
		var up := Line2D.new()
		up.width = 2.0
		up.default_color = Color(1.0, 0.76, 0.04, 0.18)
		up.points = PackedVector2Array([Vector2(x + 42.0, 8.0), Vector2(x, 178.0)])
		pattern.add_child(up)

func _install_side_bevels(scene: Node) -> void:
	if scene.has_node("ReferenceLeftBevel"):
		return
	var left := Polygon2D.new()
	left.name = "ReferenceLeftBevel"
	left.polygon = PackedVector2Array([Vector2(307, 260), Vector2(325, 238), Vector2(325, 880), Vector2(307, 856)])
	left.color = Color(0.82, 0.84, 0.88, 0.82)
	left.z_index = 1
	scene.add_child(left)
	var right := Polygon2D.new()
	right.name = "ReferenceRightBevel"
	right.polygon = PackedVector2Array([Vector2(955, 238), Vector2(973, 260), Vector2(973, 856), Vector2(955, 880)])
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
		shadow.points = PackedVector2Array([Vector2(x, 215.0), Vector2(x, 990.0)])
		shadow.z_index = 1
		scene.add_child(shadow)
		var highlight := Line2D.new()
		highlight.name = "ReferenceInnerRailLeft" if side < 0 else "ReferenceInnerRailRight"
		highlight.width = 3.0
		highlight.default_color = Color(0.86, 0.88, 0.92, 0.92)
		highlight.points = PackedVector2Array([Vector2(x + float(side) * 3.0, 218.0), Vector2(x + float(side) * 3.0, 988.0)])
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
		Vector2(350, 582), Vector2(930, 582), Vector2(930, 805),
		Vector2(350, 805), Vector2(350, 582)
	])
	shadow.z_index = 1
	scene.add_child(shadow)
	var trim := Line2D.new()
	trim.name = "ReferenceControlTrim"
	trim.width = 4.0
	trim.default_color = Color(0.78, 0.81, 0.86, 0.95)
	trim.points = PackedVector2Array([
		Vector2(354, 587), Vector2(926, 587), Vector2(926, 800),
		Vector2(354, 800), Vector2(354, 587)
	])
	trim.z_index = 2
	scene.add_child(trim)

func _install_lower_panel_facets(scene: Node) -> void:
	if scene.has_node("ReferenceLowerFacetTop"):
		return
	var top_facet := Polygon2D.new()
	top_facet.name = "ReferenceLowerFacetTop"
	top_facet.polygon = PackedVector2Array([
		Vector2(357, 810), Vector2(923, 810), Vector2(902, 830), Vector2(378, 830)
	])
	top_facet.color = Color(0.58, 0.61, 0.66, 0.92)
	top_facet.z_index = 2
	scene.add_child(top_facet)
	var top_shadow := Line2D.new()
	top_shadow.name = "ReferenceLowerFacetTopShadow"
	top_shadow.width = 3.0
	top_shadow.default_color = Color(0.04, 0.045, 0.055, 1.0)
	top_shadow.points = PackedVector2Array([Vector2(378, 831), Vector2(902, 831)])
	top_shadow.z_index = 3
	scene.add_child(top_shadow)
	var bottom_facet := Polygon2D.new()
	bottom_facet.name = "ReferenceLowerFacetBottom"
	bottom_facet.polygon = PackedVector2Array([
		Vector2(378, 1037), Vector2(902, 1037), Vector2(922, 1052), Vector2(358, 1052)
	])
	bottom_facet.color = Color(0.48, 0.51, 0.56, 0.90)
	bottom_facet.z_index = 2
	scene.add_child(bottom_facet)

func _install_lower_side_grilles(scene: Node) -> void:
	if scene.has_node("ReferenceLowerSideGrilleLeft"):
		return
	for side in [-1, 1]:
		var grille := Control.new()
		grille.name = "ReferenceLowerSideGrilleLeft" if side < 0 else "ReferenceLowerSideGrilleRight"
		grille.position = Vector2(386.0 if side < 0 else 824.0, 950.0)
		grille.size = Vector2(70.0, 52.0)
		grille.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grille.z_index = 4
		scene.add_child(grille)
		for i in range(7):
			var slit := Line2D.new()
			slit.width = 4.0
			slit.default_color = Color(0.08, 0.085, 0.095, 0.98)
			var x := 8.0 + float(i) * 9.0
			slit.points = PackedVector2Array([
				Vector2(x + (8.0 if side < 0 else 0.0), 5.0),
				Vector2(x + (0.0 if side < 0 else 8.0), 47.0)
			])
			grille.add_child(slit)

func _install_lower_vent(scene: Node) -> void:
	if scene.has_node("ReferenceLowerVent"):
		return
	var vent := Control.new()
	vent.name = "ReferenceLowerVent"
	vent.position = Vector2(374, 1010)
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
		var cx := 378.0 if side < 0 else 902.0
		speaker.polygon = PackedVector2Array([
			Vector2(cx - 35.0, 105.0), Vector2(cx + 35.0, 105.0),
			Vector2(cx + 26.0, 164.0), Vector2(cx - 26.0, 164.0)
		])
		speaker.color = Color(0.16, 0.17, 0.20, 0.96)
		speaker.z_index = 3
		scene.add_child(speaker)
		for j in range(5):
			var slit := Line2D.new()
			slit.width = 3.0
			slit.default_color = Color(0.025, 0.025, 0.035, 1.0)
			slit.points = PackedVector2Array([
				Vector2(cx - 24.0 + float(j) * 11.0, 118.0),
				Vector2(cx - 33.0 + float(j) * 11.0, 151.0)
			])
			slit.z_index = 4
			scene.add_child(slit)
