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

	# Do not create replacement overlays. Rework the existing cabinet parts in place.
	_apply_led_shader(scene.get_node_or_null("LeftLED") as CanvasItem, 0.0)
	_apply_led_shader(scene.get_node_or_null("RightLED") as CanvasItem, 0.65)
	_apply_led_shader(scene.get_node_or_null("TopLED") as CanvasItem, 0.25)
	_apply_lower_glow_shader(scene.get_node_or_null("LowerGlow") as CanvasItem)
	_apply_metal_sheen(scene.get_node_or_null("LeftRailOuter") as CanvasItem, 0.0)
	_apply_metal_sheen(scene.get_node_or_null("RightRailOuter") as CanvasItem, 0.48)
	_apply_top_panel_light(scene.get_node_or_null("TopPanel") as CanvasItem)

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

func _apply_metal_sheen(item: CanvasItem, phase: float) -> void:
	if item == null:
		return
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;
uniform float phase = 0.0;
void fragment() {
	vec4 base = COLOR;
	float sweep = fract(TIME * 0.075 + phase);
	float d = abs(UV.y - sweep);
	d = min(d, 1.0 - d);
	float beam = smoothstep(0.08, 0.0, d);
	float ridge = smoothstep(0.50, 0.08, abs(UV.x - 0.50));
	float lift = beam * ridge * 0.20;
	vec3 metal = base.rgb * (0.88 + 0.12 * ridge) + vec3(0.16, 0.19, 0.24) * lift;
	COLOR = vec4(metal, base.a);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("phase", phase)
	item.material = mat

func _apply_top_panel_light(item: CanvasItem) -> void:
	if item == null:
		return
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec4 base = COLOR;
	vec2 p = UV;
	float edge_x = smoothstep(0.16, 0.0, min(p.x, 1.0 - p.x));
	float edge_y = smoothstep(0.20, 0.0, min(p.y, 1.0 - p.y));
	float border = max(edge_x, edge_y);
	float sweep_pos = fract(TIME * 0.11);
	float sweep = smoothstep(0.08, 0.0, abs(p.x - sweep_pos));
	float pulse = 0.80 + 0.20 * sin(TIME * 2.0);
	vec3 glow = vec3(0.20, 0.10, 0.01) * border * pulse + vec3(0.10, 0.065, 0.005) * sweep;
	COLOR = vec4(base.rgb + glow, base.a);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	item.material = mat
