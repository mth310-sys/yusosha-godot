extends Node

var elapsed: float = 0.0
var last_mode: String = ""
var flash_time: float = 0.0

func _process(delta: float) -> void:
	elapsed += delta
	flash_time = maxf(0.0, flash_time - delta)

	var scene := get_tree().current_scene
	if scene == null:
		return

	var title := scene.get_node_or_null("Center/VBox/Title") as Label
	var subtitle := scene.get_node_or_null("Center/VBox/Subtitle") as Label
	var status := scene.get_node_or_null("Center/VBox/Status") as Label
	if title == null or subtitle == null or status == null:
		return

	var mode := _resolve_mode(status.text)
	if mode != last_mode:
		last_mode = mode
		flash_time = 0.45 if mode in ["BIG", "REG"] else 0.18

	_apply_display(title, subtitle, status, mode)

func _resolve_mode(status_text: String) -> String:
	if "BIG" in status_text:
		return "BIG"
	if "REG" in status_text:
		return "REG"
	if "SPINNING" in status_text or "STOP REMAINING" in status_text:
		return "SPIN"
	if "REPLAY" in status_text:
		return "REPLAY"
	if "+" in status_text and not "NET" in status_text:
		return "HIT"
	return "NORMAL"

func _apply_display(title: Label, subtitle: Label, status: Label, mode: String) -> void:
	var pulse := 0.5 + 0.5 * sin(elapsed * 7.0)
	var flash := clampf(flash_time * 2.2, 0.0, 1.0)

	title.text = "ZELVOLT"

	match mode:
		"BIG":
			title.add_theme_color_override("font_color", Color(1.0, 0.93, 0.28, 1.0))
			title.add_theme_color_override("font_outline_color", Color(0.95, 0.24 + pulse * 0.16, 0.02, 1.0))
			subtitle.text = "BIG BONUS  /  55G  /  NET +600"
			subtitle.add_theme_color_override("font_color", Color(1.0, 0.78 + pulse * 0.18, 0.12, 1.0))
		"REG":
			title.add_theme_color_override("font_color", Color(1.0, 0.42 + pulse * 0.18, 0.18, 1.0))
			title.add_theme_color_override("font_outline_color", Color(0.75, 0.02, 0.02, 1.0))
			subtitle.text = "REG BONUS  /  14G  /  NET +120"
			subtitle.add_theme_color_override("font_color", Color(1.0, 0.34 + pulse * 0.16, 0.18, 1.0))
		"SPIN":
			title.add_theme_color_override("font_color", Color(1.0, 0.80 + pulse * 0.12, 0.12, 1.0))
			title.add_theme_color_override("font_outline_color", Color(0.22, 0.12, 0.01, 1.0))
			subtitle.text = "LIGHTNING REEL CONTROL"
			subtitle.add_theme_color_override("font_color", Color(0.92, 0.92, 0.84, 1.0))
		"REPLAY":
			title.add_theme_color_override("font_color", Color(0.52, 0.82, 1.0, 1.0))
			title.add_theme_color_override("font_outline_color", Color(0.03, 0.16, 0.36, 1.0))
			subtitle.text = "REPLAY  /  NEXT GAME READY"
			subtitle.add_theme_color_override("font_color", Color(0.62, 0.86, 1.0, 1.0))
		"HIT":
			title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.18, 1.0))
			title.add_theme_color_override("font_outline_color", Color(0.40, 0.20, 0.01, 1.0))
			subtitle.text = "PAYOUT DETECTED"
			subtitle.add_theme_color_override("font_color", Color(1.0, 0.82, 0.24, 1.0))
		_:
			title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.12, 1.0))
			title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
			subtitle.text = "LIGHTNING NORMAL TYPE  /  SETTING 1"
			subtitle.add_theme_color_override("font_color", Color(0.72, 0.75, 0.82, 1.0))

	if flash > 0.0:
		status.modulate = Color(1.0, 1.0, 1.0, 0.72 + 0.28 * flash)
	else:
		status.modulate = Color.WHITE
