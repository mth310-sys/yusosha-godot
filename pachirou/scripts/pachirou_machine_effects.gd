extends Node3D

const REEL_PITCH: float = 0.072
const REEL_VISIBLE_ROWS: int = 3
const REEL_STRIP_SYMBOLS: int = 7
const REEL_BOTTOM: float = 0.417
const REEL_TOP: float = 0.633

var _time: float = 0.0
var _machines: Array[Node3D] = []

func _ready() -> void:
	call_deferred("_setup_effects")

func _setup_effects() -> void:
	await get_tree().process_frame
	var world := get_parent().get_node_or_null("World")
	if world == null:
		return
	_collect_machines(world)
	for i in range(_machines.size()):
		_add_effect_rig(_machines[i],i)

func _collect_machines(node: Node) -> void:
	if node is Node3D and node.name == "MachineSlot":
		_machines.append(node as Node3D)
	for child in node.get_children():
		_collect_machines(child)

func _add_effect_rig(machine: Node3D,index: int) -> void:
	var rig := Node3D.new()
	rig.name = "LiveEffectRig"
	machine.add_child(rig)
	var palette: Array[Color] = [Color("35e7ff"),Color("ff405f"),Color("ffd43b"),Color("a65cff"),Color("48ff91"),Color("ff6fd8")]
	var main: Color = palette[index%6]
	var sub: Color = palette[(index+2)%6]
	var accent: Color = palette[(index+4)%6]
	_add_lamp(rig,"TopGlow",Vector3(0,0.84,0.246),Vector3(0.46,0.038,0.022),main)
	_add_lamp(rig,"BezelTop",Vector3(0,0.745,0.251),Vector3(0.43,0.020,0.018),sub)
	_add_lamp(rig,"SideL",Vector3(-0.292,0.53,0.241),Vector3(0.022,0.47,0.020),sub)
	_add_lamp(rig,"SideR",Vector3(0.292,0.53,0.241),Vector3(0.022,0.47,0.020),accent)
	_add_lamp(rig,"Screen",Vector3(0,0.67,0.250),Vector3(0.395,0.075,0.014),main)
	_add_lamp(rig,"ScreenScan",Vector3(0,0.67,0.261),Vector3(0.37,0.010,0.010),Color("ffffff"))
	_add_lamp(rig,"ControlLine",Vector3(0,0.285,0.322),Vector3(0.44,0.018,0.018),accent)
	_add_lamp(rig,"UnderGlow",Vector3(0,0.075,0.215),Vector3(0.45,0.022,0.022),sub)
	for b in range(3):
		_add_lamp(rig,"Button%d"%b,Vector3((float(b)-1.0)*0.14,0.315,0.326),Vector3(0.062,0.027,0.027),main if b != 1 else accent)
	_build_reel_upgrade(rig,index,accent)
	var spill := OmniLight3D.new()
	spill.name = "CabinetSpill"
	spill.position = Vector3(0,0.58,0.38)
	spill.omni_range = 0.72
	spill.light_energy = 0.0
	spill.light_color = main
	spill.shadow_enabled = false
	rig.add_child(spill)
	rig.set_meta("phase",float(index)*0.53)
	rig.set_meta("pattern",index%6)
	rig.set_meta("style_group",index/6)

func _build_reel_upgrade(rig: Node3D,index: int,accent: Color) -> void:
	var reel_rig := Node3D.new()
	reel_rig.name = "ReelUpgrade"
	rig.add_child(reel_rig)
	_add_panel(reel_rig,"ReelWell",Vector3(0.515,0.255,0.022),Vector3(0,0.525,0.270),Color("080b0f"),0.55,0.18)
	_add_panel(reel_rig,"RailTop",Vector3(0.535,0.022,0.030),Vector3(0,0.656,0.294),Color("c3c9ce"),0.82,0.16)
	_add_panel(reel_rig,"RailBottom",Vector3(0.535,0.022,0.030),Vector3(0,0.394,0.294),Color("737c84"),0.78,0.18)
	_add_panel(reel_rig,"DividerL",Vector3(0.012,0.220,0.026),Vector3(-0.0775,0.525,0.298),Color("5b6269"),0.70,0.20)
	_add_panel(reel_rig,"DividerR",Vector3(0.012,0.220,0.026),Vector3(0.0775,0.525,0.298),Color("5b6269"),0.70,0.20)
	_add_lamp(reel_rig,"Payline",Vector3(0,0.525,0.318),Vector3(0.49,0.008,0.008),accent)
	for r in range(3):
		var reel := Node3D.new()
		reel.name = "Reel%d"%r
		reel.position = Vector3((float(r)-1.0)*0.155,0,0)
		reel_rig.add_child(reel)
		_add_panel(reel,"ReelPaper",Vector3(0.142,0.218,0.020),Vector3(0,0.525,0.288),Color("f8f5e9"),0.0,0.62)
		for s in range(REEL_STRIP_SYMBOLS):
			var symbol := Node3D.new()
			symbol.name = "StripSymbol%d"%s
			symbol.position = Vector3(0,0.453+float(s%3)*REEL_PITCH,0.307)
			reel.add_child(symbol)
			_build_symbol(symbol,(index*2+r*3+s)%6)
		reel.set_meta("reel_index",r)
		reel.set_meta("strip_offset",float((index+r*2)%REEL_STRIP_SYMBOLS)*REEL_PITCH)
	# Opaque lips hide symbols as they enter/leave the physical reel window.
	_add_panel(reel_rig,"TopMask",Vector3(0.49,0.050,0.032),Vector3(0,0.666,0.325),Color("11161c"),0.35,0.24)
	_add_panel(reel_rig,"BottomMask",Vector3(0.49,0.050,0.032),Vector3(0,0.384,0.325),Color("11161c"),0.35,0.24)

func _build_symbol(parent: Node3D,kind: int) -> void:
	match kind:
		0:
			# Red 7 silhouette.
			_add_panel(parent,"SevenTop",Vector3(0.078,0.018,0.012),Vector3(0,0.020,0),Color("e83d45"),0.0,0.42)
			_add_panel(parent,"SevenStem",Vector3(0.022,0.052,0.012),Vector3(0.020,-0.008,0),Color("e83d45"),0.0,0.42)
		1:
			# BAR-style dark plaque with a bright center stripe.
			_add_panel(parent,"BarPlate",Vector3(0.092,0.046,0.012),Vector3.ZERO,Color("20242a"),0.15,0.34)
			_add_panel(parent,"BarStripe",Vector3(0.072,0.012,0.014),Vector3(0,0,0.003),Color("f2f2e8"),0.0,0.42)
		2:
			# Bell: gold cap/body/clapper.
			_add_panel(parent,"BellCap",Vector3(0.052,0.014,0.012),Vector3(0,0.021,0),Color("ffd447"),0.12,0.38)
			_add_panel(parent,"BellBody",Vector3(0.074,0.034,0.012),Vector3(0,0.000,0),Color("eeb72d"),0.12,0.38)
			_add_panel(parent,"BellClapper",Vector3(0.018,0.012,0.014),Vector3(0,-0.025,0.002),Color("b87916"),0.18,0.34)
		3:
			# Cherries: paired red fruit and green stem.
			_add_panel(parent,"CherryL",Vector3(0.034,0.034,0.013),Vector3(-0.020,-0.008,0),Color("e73545"),0.0,0.42)
			_add_panel(parent,"CherryR",Vector3(0.034,0.034,0.013),Vector3(0.020,-0.003,0),Color("f04a55"),0.0,0.42)
			_add_panel(parent,"Stem",Vector3(0.012,0.038,0.014),Vector3(0.008,0.024,0.002),Color("45a85c"),0.0,0.48)
		4:
			# Blue replay-like double chevron.
			_add_panel(parent,"ReplayA",Vector3(0.070,0.018,0.012),Vector3(0,0.014,0),Color("3b8ff0"),0.0,0.40)
			_add_panel(parent,"ReplayB",Vector3(0.070,0.018,0.012),Vector3(0,-0.014,0),Color("65b8ff"),0.0,0.40)
		_:
			# Watermelon/fruit symbol.
			_add_panel(parent,"Fruit",Vector3(0.076,0.046,0.012),Vector3.ZERO,Color("54b85e"),0.0,0.46)
			_add_panel(parent,"FruitCore",Vector3(0.054,0.026,0.014),Vector3(0,0,0.003),Color("ef5b65"),0.0,0.46)

func _add_panel(parent: Node3D,node_name: String,size: Vector3,pos: Vector3,color: Color,metallic: float,roughness: float) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	node.material_override = mat
	parent.add_child(node)

func _add_lamp(parent: Node3D,node_name: String,pos: Vector3,size: Vector3,color: Color) -> void:
	var lamp := MeshInstance3D.new()
	lamp.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	lamp.mesh = mesh
	lamp.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.28)
	material.metallic = 0.08
	material.roughness = 0.30
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.2
	lamp.material_override = material
	parent.add_child(lamp)

func _process(delta: float) -> void:
	_time += delta
	for machine in _machines:
		var rig := machine.get_node_or_null("LiveEffectRig") as Node3D
		if rig == null:
			continue
		var phase: float = float(rig.get_meta("phase",0.0))
		var pattern: int = int(rig.get_meta("pattern",0))
		var group: int = int(rig.get_meta("style_group",0))
		_animate_rig(rig,_time+phase,pattern,group)

func _animate_rig(rig: Node3D,t: float,pattern: int,group: int) -> void:
	var top := rig.get_node_or_null("TopGlow") as MeshInstance3D
	var bezel := rig.get_node_or_null("BezelTop") as MeshInstance3D
	var left := rig.get_node_or_null("SideL") as MeshInstance3D
	var right := rig.get_node_or_null("SideR") as MeshInstance3D
	var screen := rig.get_node_or_null("Screen") as MeshInstance3D
	var scan := rig.get_node_or_null("ScreenScan") as MeshInstance3D
	var control := rig.get_node_or_null("ControlLine") as MeshInstance3D
	var under := rig.get_node_or_null("UnderGlow") as MeshInstance3D
	var spill := rig.get_node_or_null("CabinetSpill") as OmniLight3D
	var pulse: float = 0.5+0.5*sin(t*3.4)
	var slow: float = 0.5+0.5*sin(t*1.55)
	var flash: float = 1.0 if fmod(t,2.65)<0.11 else 0.0
	match pattern:
		0:
			_set_energy(top,0.8+2.7*pulse); _set_energy(left,0.4+2.0*(1.0-pulse)); _set_energy(right,0.4+2.0*pulse)
		1:
			_set_energy(top,0.6+4.2*flash); _set_energy(left,0.5+3.0*flash); _set_energy(right,0.5+3.0*flash)
		2:
			_set_energy(left,0.4+3.0*(0.5+0.5*sin(t*5.2))); _set_energy(right,0.4+3.0*(0.5+0.5*sin(t*5.2+3.14159))); _set_energy(top,0.7+2.2*pulse)
		3:
			_set_energy(top,0.5+3.2*slow); _set_energy(left,0.4+2.5*(0.5+0.5*sin(t*2.1+2.1))); _set_energy(right,0.4+2.5*(0.5+0.5*sin(t*2.1+4.2)))
		4:
			var beat: float = pow(max(0.0,sin(t*4.8)),10.0)
			_set_energy(top,0.7+4.5*beat); _set_energy(left,0.5+2.8*beat); _set_energy(right,0.5+2.8*beat)
		_:
			_set_energy(top,0.8+2.6*pulse); _set_energy(left,0.6+2.0*pulse); _set_energy(right,0.6+2.0*(1.0-pulse))
	_set_energy(bezel,0.35+1.6*(1.0-pulse))
	_set_energy(screen,0.55+1.7*slow+1.3*flash)
	_set_energy(control,0.35+1.8*pulse)
	_set_energy(under,0.20+1.2*slow)
	if scan != null:
		scan.position.y = 0.64+0.06*(0.5+0.5*sin(t*2.7))
		_set_energy(scan,0.45+2.2*pulse)
	var chase_step: int = int(floor(t*5.5))%3
	for b in range(3):
		_set_energy(rig.get_node_or_null("Button%d"%b) as MeshInstance3D,3.6 if chase_step == b else 0.25)
	_animate_reels(rig,t)
	if spill != null:
		spill.light_energy = (0.10+float(group)*0.07)*(0.35+0.65*pulse+0.55*flash)

func _animate_reels(rig: Node3D,t: float) -> void:
	var reel_rig := rig.get_node_or_null("ReelUpgrade") as Node3D
	if reel_rig == null:
		return
	# One cycle: full-speed spin, then genuine left/middle/right sequential stop and result hold.
	var cycle: float = fmod(t,5.4)
	for r in range(3):
		var reel := reel_rig.get_node_or_null("Reel%d"%r) as Node3D
		if reel == null:
			continue
		var stop_time: float = 2.45+float(r)*0.48
		var spinning: bool = cycle < stop_time
		var speed: float = 0.92+float(r)*0.08
		var raw_offset: float = fmod(t*speed+float(reel.get_meta("strip_offset",0.0)),REEL_PITCH*float(REEL_STRIP_SYMBOLS))
		var stopped_index: int = (r*2+int(floor(t/5.4)))%REEL_STRIP_SYMBOLS
		var stopped_offset: float = float(stopped_index)*REEL_PITCH
		var strip_offset: float = raw_offset if spinning else stopped_offset
		for s in range(REEL_STRIP_SYMBOLS):
			var symbol := reel.get_node_or_null("StripSymbol%d"%s) as Node3D
			if symbol == null:
				continue
			var relative: float = fmod(float(s)*REEL_PITCH-strip_offset,REEL_PITCH*float(REEL_STRIP_SYMBOLS))
			if relative < 0.0:
				relative += REEL_PITCH*float(REEL_STRIP_SYMBOLS)
			# Wrap the continuous strip through the three-row physical window.
			var window_span: float = REEL_PITCH*float(REEL_VISIBLE_ROWS)
			var visible_relative: float = fmod(relative,window_span)
			var y: float = REEL_BOTTOM+REEL_PITCH*0.5+visible_relative
			symbol.position.y = y
			symbol.visible = y > REEL_BOTTOM and y < REEL_TOP

func _set_energy(node: MeshInstance3D,energy: float) -> void:
	if node == null:
		return
	var material := node.material_override as StandardMaterial3D
	if material != null:
		material.emission_energy_multiplier = energy
