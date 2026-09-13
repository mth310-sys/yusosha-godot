extends Node2D

func _ready() -> void:
	z_index = 30
	queue_redraw()

func _draw() -> void:
	# Rebuilt from the supplied cabinet reference: broad segmented chrome side
	# rails, dark inner channels, bevel breaks, and a restrained top/bottom crown.
	# Avoid a simple rounded-rectangle outline; the real cabinet reads as stacked
	# metal sections around the playfield.
	_draw_side_rail(true)
	_draw_side_rail(false)
	_draw_top_crown()
	_draw_section_shoulders()
	_draw_lower_kick()

func _mirror_x(points: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(Vector2(1280.0 - p.x, p.y))
	return out

func _draw_side_rail(left: bool) -> void:
	# Outer silver shell. It widens around the top and bottom just like the
	# reference cabinet and narrows through the central vertical section.
	var shell := PackedVector2Array([
		Vector2(330, 55), Vector2(342, 30), Vector2(365, 18), Vector2(390, 18),
		Vector2(400, 42), Vector2(397, 108), Vector2(388, 148), Vector2(388, 210),
		Vector2(378, 232), Vector2(378, 690), Vector2(388, 716), Vector2(388, 850),
		Vector2(397, 882), Vector2(400, 1012), Vector2(390, 1040), Vector2(363, 1040),
		Vector2(342, 1028), Vector2(330, 1004)
	])
	if not left:
		shell = _mirror_x(shell)
	draw_colored_polygon(shell, Color(0.70, 0.73, 0.78, 1.0))

	# Bright outside face.
	var bright := PackedVector2Array([
		Vector2(338, 64), Vector2(348, 39), Vector2(365, 30), Vector2(377, 30),
		Vector2(381, 48), Vector2(378, 210), Vector2(366, 238), Vector2(366, 684),
		Vector2(378, 714), Vector2(378, 1008), Vector2(369, 1027), Vector2(354, 1023),
		Vector2(345, 1000), Vector2(345, 70)
	])
	if not left:
		bright = _mirror_x(bright)
	draw_colored_polygon(bright, Color(0.90, 0.92, 0.95, 0.98))

	# Mid-tone bevel / inner face.
	var bevel := PackedVector2Array([
		Vector2(366, 72), Vector2(378, 55), Vector2(388, 55), Vector2(386, 205),
		Vector2(376, 236), Vector2(376, 682), Vector2(386, 715), Vector2(386, 1000),
		Vector2(377, 1019), Vector2(366, 1009)
	])
	if not left:
		bevel = _mirror_x(bevel)
	draw_colored_polygon(bevel, Color(0.48, 0.51, 0.57, 0.98))

	# Black inner channel adjacent to the game face.
	var channel := PackedVector2Array([
		Vector2(383, 76), Vector2(391, 67), Vector2(397, 72), Vector2(394, 198),
		Vector2(384, 239), Vector2(384, 676), Vector2(394, 718), Vector2(394, 993),
		Vector2(390, 1009), Vector2(383, 1001)
	])
	if not left:
		channel = _mirror_x(channel)
	draw_colored_polygon(channel, Color(0.025, 0.03, 0.045, 1.0))

	# Thin chrome glint on the inner edge.
	var x := 397.0 if left else 883.0
	draw_line(Vector2(x, 82), Vector2(x, 996), Color(0.88, 0.90, 0.94, 0.78), 2.0)

func _draw_top_crown() -> void:
	# Top bridge is deliberately not a full rectangular border.
	var top_shadow := PackedVector2Array([
		Vector2(382, 22), Vector2(898, 22), Vector2(918, 38), Vector2(906, 55),
		Vector2(374, 55), Vector2(362, 38)
	])
	draw_colored_polygon(top_shadow, Color(0.09, 0.11, 0.15, 1.0))
	var top_face := PackedVector2Array([
		Vector2(390, 16), Vector2(890, 16), Vector2(910, 31), Vector2(900, 42),
		Vector2(380, 42), Vector2(370, 31)
	])
	draw_colored_polygon(top_face, Color(0.82, 0.84, 0.88, 1.0))
	draw_line(Vector2(397, 30), Vector2(883, 30), Color(0.97, 0.98, 1.0, 0.86), 3.0)

func _draw_section_shoulders() -> void:
	# The reference has obvious diagonal breaks around the upper display/reel
	# section and again above the lower panel.
	var left_upper := PackedVector2Array([
		Vector2(365, 150), Vector2(387, 123), Vector2(387, 202), Vector2(366, 229)
	])
	var left_mid := PackedVector2Array([
		Vector2(365, 590), Vector2(386, 614), Vector2(386, 682), Vector2(365, 656)
	])
	var left_lower := PackedVector2Array([
		Vector2(365, 805), Vector2(386, 830), Vector2(386, 900), Vector2(365, 875)
	])
	for poly in [left_upper, left_mid, left_lower]:
		draw_colored_polygon(poly, Color(0.78, 0.81, 0.86, 0.98))
		var mirrored := _mirror_x(poly)
		draw_colored_polygon(mirrored, Color(0.78, 0.81, 0.86, 0.98))

	# Dark seams make each metal section read separately.
	for y in [232.0, 692.0, 904.0]:
		draw_line(Vector2(366, y), Vector2(397, y), Color(0.05, 0.055, 0.07, 0.95), 3.0)
		draw_line(Vector2(883, y), Vector2(914, y), Color(0.05, 0.055, 0.07, 0.95), 3.0)

func _draw_lower_kick() -> void:
	# Upper lip above the lower illumination panel.
	var upper_lip := PackedVector2Array([
		Vector2(382, 805), Vector2(898, 805), Vector2(916, 821), Vector2(904, 836),
		Vector2(376, 836), Vector2(364, 821)
	])
	draw_colored_polygon(upper_lip, Color(0.58, 0.61, 0.67, 1.0))
	draw_line(Vector2(378, 838), Vector2(902, 838), Color(0.035, 0.04, 0.052, 1.0), 4.0)

	# Bottom kick plate and dark recessed vent channel.
	var kick := PackedVector2Array([
		Vector2(372, 1016), Vector2(908, 1016), Vector2(924, 1028), Vector2(912, 1042),
		Vector2(368, 1042), Vector2(356, 1028)
	])
	draw_colored_polygon(kick, Color(0.50, 0.53, 0.59, 0.98))
	draw_line(Vector2(378, 1022), Vector2(902, 1022), Color(0.92, 0.94, 0.97, 0.75), 2.0)
	draw_line(Vector2(388, 1033), Vector2(892, 1033), Color(0.03, 0.035, 0.045, 1.0), 7.0)
