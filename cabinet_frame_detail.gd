extends Node2D

func _ready() -> void:
	z_index = 30
	queue_redraw()

func _draw() -> void:
	# Outer chrome silhouette: closer to the supplied ZELVOLT cabinet reference.
	var outer := PackedVector2Array([
		Vector2(366, 20), Vector2(914, 20), Vector2(930, 24), Vector2(941, 36),
		Vector2(946, 52), Vector2(946, 1010), Vector2(941, 1025), Vector2(930, 1037),
		Vector2(914, 1042), Vector2(366, 1042), Vector2(350, 1037), Vector2(339, 1025),
		Vector2(334, 1010), Vector2(334, 52), Vector2(339, 36), Vector2(350, 24),
		Vector2(366, 20)
	])
	draw_polyline(outer, Color(0.82, 0.85, 0.90, 1.0), 10.0, true)

	var inner := PackedVector2Array([
		Vector2(374, 34), Vector2(906, 34), Vector2(918, 38), Vector2(925, 48),
		Vector2(928, 62), Vector2(928, 998), Vector2(924, 1012), Vector2(915, 1022),
		Vector2(902, 1026), Vector2(378, 1026), Vector2(365, 1022), Vector2(356, 1012),
		Vector2(352, 998), Vector2(352, 62), Vector2(355, 48), Vector2(362, 38),
		Vector2(374, 34)
	])
	draw_polyline(inner, Color(0.10, 0.12, 0.16, 1.0), 7.0, true)

	# Bright chrome lips inside the dark rail.
	draw_line(Vector2(365, 70), Vector2(365, 1000), Color(0.92, 0.94, 0.98, 0.92), 4.0)
	draw_line(Vector2(915, 70), Vector2(915, 1000), Color(0.92, 0.94, 0.98, 0.92), 4.0)
	draw_line(Vector2(374, 53), Vector2(906, 53), Color(0.90, 0.92, 0.96, 0.82), 3.0)

	# Slanted shoulder pieces around the reel / control sections.
	var left_upper := PackedVector2Array([Vector2(351, 188), Vector2(370, 164), Vector2(370, 238), Vector2(351, 258)])
	var right_upper := PackedVector2Array([Vector2(929, 164), Vector2(929, 238), Vector2(948, 258), Vector2(948, 188)])
	var left_lower := PackedVector2Array([Vector2(351, 704), Vector2(370, 725), Vector2(370, 792), Vector2(351, 770)])
	var right_lower := PackedVector2Array([Vector2(929, 725), Vector2(948, 704), Vector2(948, 770), Vector2(929, 792)])
	for poly in [left_upper, right_upper, left_lower, right_lower]:
		draw_colored_polygon(poly, Color(0.70, 0.73, 0.78, 0.96))

	# Dark inset lines give the rails the layered, extruded look of the reference.
	draw_line(Vector2(378, 92), Vector2(378, 980), Color(0.03, 0.035, 0.05, 0.98), 8.0)
	draw_line(Vector2(902, 92), Vector2(902, 980), Color(0.03, 0.035, 0.05, 0.98), 8.0)
	draw_line(Vector2(382, 92), Vector2(382, 980), Color(0.55, 0.58, 0.64, 0.70), 2.0)
	draw_line(Vector2(898, 92), Vector2(898, 980), Color(0.55, 0.58, 0.64, 0.70), 2.0)

	# Lower chrome kick / base frame.
	var base_top := PackedVector2Array([Vector2(376, 888), Vector2(904, 888), Vector2(916, 902), Vector2(364, 902)])
	draw_colored_polygon(base_top, Color(0.58, 0.61, 0.67, 0.96))
	draw_line(Vector2(364, 904), Vector2(916, 904), Color(0.05, 0.055, 0.07, 1.0), 4.0)
	draw_line(Vector2(374, 1028), Vector2(906, 1028), Color(0.65, 0.68, 0.73, 0.95), 5.0)

	# Small top-corner facets to avoid the old boxy silhouette.
	var left_crown := PackedVector2Array([Vector2(349, 62), Vector2(370, 41), Vector2(395, 41), Vector2(384, 63)])
	var right_crown := PackedVector2Array([Vector2(910, 41), Vector2(931, 62), Vector2(896, 63), Vector2(885, 41)])
	draw_colored_polygon(left_crown, Color(0.76, 0.79, 0.84, 0.95))
	draw_colored_polygon(right_crown, Color(0.76, 0.79, 0.84, 0.95))
