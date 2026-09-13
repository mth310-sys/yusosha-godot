extends Node2D

func _ready() -> void:
	z_index = 30
	queue_redraw()

func _draw() -> void:
	# Restrained cabinet frame based on the supplied reference.
	# Keep the black cabinet face dominant and use chrome only as structural accents.
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
	# Slim outer shell. The previous version was too wide and too bright.
	var shell := PackedVector2Array([
		Vector2(342, 58), Vector2(350, 36), Vector2(368, 25), Vector2(386, 25),
		Vector2(392, 46), Vector2(390, 205), Vector2(382, 232), Vector2(382, 690),
		Vector2(390, 716), Vector2(390, 1008), Vector2(384, 1028), Vector2(366, 1028),
		Vector2(350, 1018), Vector2(342, 998)
	])
	if not left:
		shell = _mirror_x(shell)
	draw_colored_polygon(shell, Color(0.60, 0.63, 0.69, 1.0))

	# One restrained highlight face instead of several broad chrome layers.
	var face := PackedVector2Array([
		Vector2(349, 66), Vector2(357, 44), Vector2(370, 36), Vector2(379, 36),
		Vector2(382, 51), Vector2(380, 204), Vector2(371, 236), Vector2(371, 684),
		Vector2(380, 714), Vector2(380, 1004), Vector2(373, 1017), Vector2(360, 1013),
		Vector2(353, 994), Vector2(353, 72)
	])
	if not left:
		face = _mirror_x(face)
	draw_colored_polygon(face, Color(0.79, 0.82, 0.87, 0.96))

	# Narrow dark inner channel lets the black cabinet body remain dominant.
	var channel := PackedVector2Array([
		Vector2(377, 76), Vector2(384, 66), Vector2(390, 72), Vector2(388, 198),
		Vector2(378, 239), Vector2(378, 676), Vector2(388, 718), Vector2(388, 993),
		Vector2(384, 1007), Vector2(377, 1000)
	])
	if not left:
		channel = _mirror_x(channel)
	draw_colored_polygon(channel, Color(0.025, 0.03, 0.043, 1.0))

	# Thin inner-edge glint only.
	var x := 389.0 if left else 891.0
	draw_line(Vector2(x, 84), Vector2(x, 995), Color(0.84, 0.87, 0.92, 0.62), 1.5)

func _draw_top_crown() -> void:
	# Keep the top bridge slim so it does not compete with the ZELVOLT panel.
	var shadow := PackedVector2Array([
		Vector2(380, 27), Vector2(900, 27), Vector2(913, 39), Vector2(904, 50),
		Vector2(376, 50), Vector2(367, 39)
	])
	draw_colored_polygon(shadow, Color(0.08, 0.095, 0.13, 1.0))
	var face := PackedVector2Array([
		Vector2(389, 22), Vector2(891, 22), Vector2(904, 32), Vector2(897, 39),
		Vector2(383, 39), Vector2(376, 32)
	])
	draw_colored_polygon(face, Color(0.66, 0.69, 0.74, 0.95))
	draw_line(Vector2(397, 29), Vector2(883, 29), Color(0.91, 0.93, 0.96, 0.65), 2.0)

func _draw_section_shoulders() -> void:
	# Preserve the characteristic diagonal breaks, but keep them narrow.
	var left_upper := PackedVector2Array([
		Vector2(353, 158), Vector2(379, 132), Vector2(379, 199), Vector2(354, 226)
	])
	var left_mid := PackedVector2Array([
		Vector2(353, 596), Vector2(378, 617), Vector2(378, 678), Vector2(353, 654)
	])
	var left_lower := PackedVector2Array([
		Vector2(353, 810), Vector2(378, 832), Vector2(378, 894), Vector2(353, 872)
	])
	for poly in [left_upper, left_mid, left_lower]:
		draw_colored_polygon(poly, Color(0.69, 0.72, 0.77, 0.94))
		draw_colored_polygon(_mirror_x(poly), Color(0.69, 0.72, 0.77, 0.94))

	for y in [232.0, 692.0, 904.0]:
		draw_line(Vector2(354, y), Vector2(389, y), Color(0.045, 0.05, 0.065, 0.94), 2.0)
		draw_line(Vector2(891, y), Vector2(926, y), Color(0.045, 0.05, 0.065, 0.94), 2.0)

func _draw_lower_kick() -> void:
	# Lower trim stays visible, but no longer forms a heavy chrome bar.
	var upper_lip := PackedVector2Array([
		Vector2(378, 808), Vector2(902, 808), Vector2(912, 820), Vector2(903, 831),
		Vector2(377, 831), Vector2(368, 820)
	])
	draw_colored_polygon(upper_lip, Color(0.49, 0.52, 0.58, 0.94))
	draw_line(Vector2(379, 833), Vector2(901, 833), Color(0.035, 0.04, 0.052, 1.0), 3.0)

	var kick := PackedVector2Array([
		Vector2(374, 1018), Vector2(906, 1018), Vector2(916, 1027), Vector2(908, 1037),
		Vector2(372, 1037), Vector2(364, 1027)
	])
	draw_colored_polygon(kick, Color(0.43, 0.46, 0.51, 0.96))
	draw_line(Vector2(382, 1024), Vector2(898, 1024), Color(0.78, 0.81, 0.85, 0.62), 1.5)
	draw_line(Vector2(390, 1031), Vector2(890, 1031), Color(0.025, 0.03, 0.04, 1.0), 6.0)
