extends Node

var _installed := false

func _ready() -> void:
	call_deferred("_install_fx")

func _install_fx() -> void:
	if _installed:
		return
	var scene := get_tree().current_scene
	if scene == null:
		await get_tree().process_frame
		scene = get_tree().current_scene
	if scene == null:
		return
	_installed = true

	_apply_led_shader(scene.get_node_or_null("LeftLED") as CanvasItem, 0.0)
	_apply_led_shader(scene.get_node_or_null("RightLED") as CanvasItem, 0.65)
	_apply_led_shader(scene.get_node_or_null("TopLED") as CanvasItem, 0.25)
	_apply_lower_glow_shader(scene.get_node_or_null("LowerGlow") as CanvasItem)
	_install_metal_sheen(scene)
	_install_top_panel_light(scene)

func _apply_led_shader(item: CanvasItem, phase: float) -> void:
	if item == null:
		return
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;
uniform float phase = 0.0;
void fragment() {
	vec4 base = COLOR;
	float slow = 0.82 + 0.18 * sin(TIME * 2.6 + phase);
	float spark = pow(max(0.0, sin(TIME * 9.0 + phase * 4.0)), 18.0) * 0.85;
	float edge = 1.0 - abs(UV.x * 2.0 - 1.0);
	float hot = 0.75 + 0.35 * edge;
	vec3 rgb = base.rgb * (slow * hot + spark);
	COLOR = vec4(rgb, base.a * (0.82 + spark * 0.16));
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("phase", phase)
	item.material = mat

func _apply_lower_glow_shader(item: CanvasItem) -> void:
	if item == null:
		return
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec4 base = COLOR;
	float wave = 0.88 + 0.12 * sin(TIME * 1.7);
	float center = 1.0 - distance(UV, vec2(0.5, 0.5)) * 0.65;
	COLOR = vec4(base.rgb * wave * center, base.a);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	item.material = mat

func _install_metal_sheen(scene: Node) -> void:
	if scene.has_node("GodotMetalSheenLeft"):
		return
	# Keep sheen entirely inside the slim chrome faces so it cannot overlap the cabinet body.
	for side in [-1, 1]:
		var strip := ColorRect.new()
		strip.name = "GodotMetalSheenLeft" if side < 0 else "GodotMetalSheenRight"
		strip.position = Vector2(354.0 if side < 0 else 910.0, 66.0)
		strip.size = Vector2(12.0, 928.0)
		strip.color = Color(1, 1, 1, 1)
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.z_index = 31
		var shader := Shader.new()
		shader.code = """
shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float phase = 0.0;
void fragment() {
	float sweep = fract(TIME * 0.075 + phase);
	float d = abs(UV.y - sweep);
	d = min(d, 1.0 - d);
	float beam = smoothstep(0.075, 0.0, d);
	float ridge = smoothstep(0.50, 0.10, abs(UV.x - 0.50));
	float alpha = beam * ridge * 0.12;
	COLOR = vec4(vec3(0.82, 0.89, 1.0) * alpha, alpha);
}
"""
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("phase", 0.0 if side < 0 else 0.48)
		strip.material = mat
		scene.add_child(strip)

func _install_top_panel_light(scene: Node) -> void:
	if scene.has_node("GodotTopPanelLight"):
		return
	var glow := ColorRect.new()
	glow.name = "GodotTopPanelLight"
	glow.position = Vector2(354.0, 78.0)
	glow.size = Vector2(572.0, 154.0)
	glow.color = Color(1, 1, 1, 1)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index = 28
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded, blend_add;
void fragment() {
	vec2 p = UV;
	float edge_x = smoothstep(0.18, 0.0, min(p.x, 1.0 - p.x));
	float edge_y = smoothstep(0.22, 0.0, min(p.y, 1.0 - p.y));
	float border = max(edge_x, edge_y);
	float sweep_pos = fract(TIME * 0.11);
	float sweep = smoothstep(0.09, 0.0, abs(p.x - sweep_pos));
	float pulse = 0.72 + 0.28 * sin(TIME * 2.0);
	float alpha = border * 0.10 * pulse + sweep * 0.045;
	COLOR = vec4(vec3(1.0, 0.70, 0.08) * alpha, alpha);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	glow.material = mat
	scene.add_child(glow)
