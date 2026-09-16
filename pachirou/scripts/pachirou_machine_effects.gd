extends Node3D

var _time: float = 0.0
var _machines: Array[Node3D] = []

func _ready() -> void:
	call_deferred("_setup_effects")

func _setup_effects() -> void:
	await get_tree().process_frame
	var world := get_parent().get_node_or_null("World")
	if world == null: return
	_collect_machines(world)
	for i in range(_machines.size()): _add_effect_rig(_machines[i],i)

func _collect_machines(node: Node) -> void:
	if node is Node3D and node.name == "MachineSlot": _machines.append(node as Node3D)
	for child in node.get_children(): _collect_machines(child)

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
	for b in range(3): _add_lamp(rig,"Button%d"%b,Vector3((float(b)-1.0)*0.14,0.315,0.326),Vector3(0.062,0.027,0.027),main if b != 1 else accent)
	_build_reel_upgrade(rig,index,main,sub,accent)
	var spill := OmniLight3D.new()
	spill.name = "CabinetSpill"; spill.position = Vector3(0,0.58,0.38); spill.omni_range = 0.72; spill.light_energy = 0.0; spill.light_color = main; spill.shadow_enabled = false
	rig.add_child(spill)
	rig.set_meta("phase",float(index)*0.53); rig.set_meta("pattern",index%6); rig.set_meta("style_group",index/6)

func _build_reel_upgrade(rig: Node3D,index: int,main: Color,sub: Color,accent: Color) -> void:
	var reel_rig := Node3D.new(); reel_rig.name = "ReelUpgrade"; rig.add_child(reel_rig)
	# Dark recessed window, chrome-like rails and a visible payline.
	_add_panel(reel_rig,"ReelWell",Vector3(0.49,0.225,0.018),Vector3(0,0.525,0.270),Color("10141a"),0.62,0.15)
	_add_panel(reel_rig,"ReelRailTop",Vector3(0.51,0.018,0.024),Vector3(0,0.645,0.282),Color("b8c0c7"),0.72,0.20)
	_add_panel(reel_rig,"ReelRailBottom",Vector3(0.51,0.018,0.024),Vector3(0,0.405,0.282),Color("7c858d"),0.70,0.22)
	_add_lamp(reel_rig,"Payline",Vector3(0,0.525,0.294),Vector3(0.48,0.009,0.008),accent)
	for r in range(3):
		var reel := Node3D.new(); reel.name = "Reel%d"%r; reel.position = Vector3((float(r)-1.0)*0.155,0,0); reel_rig.add_child(reel)
		_add_panel(reel,"ReelPaper",Vector3(0.137,0.205,0.018),Vector3(0,0.525,0.286),Color("f4f0df"),0.0,0.72)
		# Three symbol rows remain visible; their Y positions animate to create vertical reel travel.
		for s in range(3):
			var symbol_color: Color = [Color("e84545"),Color("f3c846"),Color("4acb8c"),main,sub][(index+r+s)%5]
			_add_symbol(reel,"Symbol%d"%s,Vector3(0,0.455+float(s)*0.070,0.299),symbol_color,(index+r+s)%4)
		reel.set_meta("reel_index",r)
		reel.set_meta("offset",float((index+r)%5)*0.013)

func _add_symbol(parent: Node3D,node_name: String,pos: Vector3,color: Color,kind: int) -> void:
	var symbol := Node3D.new(); symbol.name = node_name; symbol.position = pos; parent.add_child(symbol)
	match kind:
		0:
			_add_panel(symbol,"Mark",Vector3(0.070,0.040,0.012),Vector3.ZERO,color,0.0,0.55)
		1:
			_add_panel(symbol,"MarkA",Vector3(0.055,0.055,0.012),Vector3.ZERO,color,0.0,0.55)
			_add_panel(symbol,"MarkB",Vector3(0.020,0.020,0.014),Vector3(0.025,0.018,0.002),Color("ffffff"),0.0,0.55)
		2:
			_add_panel(symbol,"MarkA",Vector3(0.075,0.024,0.012),Vector3(0,0.013,0),color,0.0,0.55)
			_add_panel(symbol,"MarkB",Vector3(0.045,0.024,0.012),Vector3(0,-0.018,0),color.darkened(0.18),0.0,0.55)
		_:
			_add_panel(symbol,"MarkA",Vector3(0.024,0.058,0.012),Vector3(-0.020,0,0),color,0.0,0.55)
			_add_panel(symbol,"MarkB",Vector3(0.024,0.058,0.012),Vector3(0.020,0,0),color.lightened(0.18),0.0,0.55)

func _add_panel(parent: Node3D,node_name: String,size: Vector3,pos: Vector3,color: Color,metallic: float,roughness: float) -> void:
	var node := MeshInstance3D.new(); node.name = node_name
	var mesh := BoxMesh.new(); mesh.size = size; node.mesh = mesh; node.position = pos
	var mat := StandardMaterial3D.new(); mat.albedo_color = color; mat.metallic = metallic; mat.roughness = roughness; node.material_override = mat
	parent.add_child(node)

func _add_lamp(parent: Node3D,node_name: String,pos: Vector3,size: Vector3,color: Color) -> void:
	var lamp := MeshInstance3D.new(); lamp.name = node_name
	var mesh := BoxMesh.new(); mesh.size = size; lamp.mesh = mesh; lamp.position = pos
	var material := StandardMaterial3D.new(); material.albedo_color = color.darkened(0.28); material.metallic = 0.08; material.roughness = 0.30; material.emission_enabled = true; material.emission = color; material.emission_energy_multiplier = 0.2
	lamp.material_override = material; parent.add_child(lamp)

func _process(delta: float) -> void:
	_time += delta
	for machine in _machines:
		var rig := machine.get_node_or_null("LiveEffectRig") as Node3D
		if rig == null: continue
		var phase: float = float(rig.get_meta("phase",0.0)); var pattern: int = int(rig.get_meta("pattern",0)); var group: int = int(rig.get_meta("style_group",0))
		_animate_rig(rig,_time+phase,pattern,group)

func _animate_rig(rig: Node3D,t: float,pattern: int,group: int) -> void:
	var top := rig.get_node_or_null("TopGlow") as MeshInstance3D; var bezel := rig.get_node_or_null("BezelTop") as MeshInstance3D
	var left := rig.get_node_or_null("SideL") as MeshInstance3D; var right := rig.get_node_or_null("SideR") as MeshInstance3D
	var screen := rig.get_node_or_null("Screen") as MeshInstance3D; var scan := rig.get_node_or_null("ScreenScan") as MeshInstance3D
	var control := rig.get_node_or_null("ControlLine") as MeshInstance3D; var under := rig.get_node_or_null("UnderGlow") as MeshInstance3D
	var spill := rig.get_node_or_null("CabinetSpill") as OmniLight3D
	var pulse: float = 0.5+0.5*sin(t*3.4); var slow: float = 0.5+0.5*sin(t*1.55); var flash: float = 1.0 if fmod(t,2.65)<0.11 else 0.0
	match pattern:
		0: _set_energy(top,0.8+2.7*pulse); _set_energy(left,0.4+2.0*(1.0-pulse)); _set_energy(right,0.4+2.0*pulse)
		1: _set_energy(top,0.6+4.2*flash); _set_energy(left,0.5+3.0*flash); _set_energy(right,0.5+3.0*flash)
		2: _set_energy(left,0.4+3.0*(0.5+0.5*sin(t*5.2))); _set_energy(right,0.4+3.0*(0.5+0.5*sin(t*5.2+3.14159))); _set_energy(top,0.7+2.2*pulse)
		3: _set_energy(top,0.5+3.2*slow); _set_energy(left,0.4+2.5*(0.5+0.5*sin(t*2.1+2.1))); _set_energy(right,0.4+2.5*(0.5+0.5*sin(t*2.1+4.2)))
		4:
			var beat: float = pow(max(0.0,sin(t*4.8)),10.0); _set_energy(top,0.7+4.5*beat); _set_energy(left,0.5+2.8*beat); _set_energy(right,0.5+2.8*beat)
		_: _set_energy(top,0.8+2.6*pulse); _set_energy(left,0.6+2.0*pulse); _set_energy(right,0.6+2.0*(1.0-pulse))
	_set_energy(bezel,0.35+1.6*(1.0-pulse)); _set_energy(screen,0.55+1.7*slow+1.3*flash); _set_energy(control,0.35+1.8*pulse); _set_energy(under,0.20+1.2*slow)
	if scan != null: scan.position.y = 0.64+0.06*(0.5+0.5*sin(t*2.7)); _set_energy(scan,0.45+2.2*pulse)
	var chase_step: int = int(floor(t*5.5))%3
	for b in range(3): _set_energy(rig.get_node_or_null("Button%d"%b) as MeshInstance3D,3.6 if chase_step == b else 0.25)
	_animate_reels(rig,t)
	if spill != null: spill.light_energy = (0.10+float(group)*0.07)*(0.35+0.65*pulse+0.55*flash)

func _animate_reels(rig: Node3D,t: float) -> void:
	var reel_rig := rig.get_node_or_null("ReelUpgrade") as Node3D
	if reel_rig == null: return
	# 4.8 second cycle: spin together, then left/middle/right stop in sequence, short result hold.
	var cycle: float = fmod(t,4.8)
	for r in range(3):
		var reel := reel_rig.get_node_or_null("Reel%d"%r) as Node3D
		if reel == null: continue
		var stop_time: float = 2.25+float(r)*0.42
		var spinning: bool = cycle < stop_time
		var travel: float = fmod(t*(1.75+float(r)*0.13)+float(reel.get_meta("offset",0.0)),0.070) if spinning else float(r)*0.011
		for s in range(3):
			var symbol := reel.get_node_or_null("Symbol%d"%s) as Node3D
			if symbol != null:
				var base_y: float = 0.455+float(s)*0.070
				symbol.position.y = base_y-travel

func _set_energy(node: MeshInstance3D,energy: float) -> void:
	if node == null: return
	var material := node.material_override as StandardMaterial3D
	if material != null: material.emission_energy_multiplier = energy
