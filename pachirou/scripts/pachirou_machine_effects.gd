extends Node3D

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
		_add_effect_rig(_machines[i], i)

func _collect_machines(node: Node) -> void:
	if node is Node3D and node.name == "MachineSlot":
		_machines.append(node as Node3D)
	for child in node.get_children():
		_collect_machines(child)

func _add_effect_rig(machine: Node3D, index: int) -> void:
	var old := machine.get_node_or_null("LiveEffectRig")
	if old != null:
		old.queue_free()
	var rig := Node3D.new()
	rig.name = "LiveEffectRig"
	machine.add_child(rig)
	var palette: Array[Color] = [Color("35e7ff"),Color("ff405f"),Color("ffd43b"),Color("a65cff"),Color("48ff91"),Color("ff6fd8")]
	var main: Color = palette[index % 6]
	var sub: Color = palette[(index + 2) % 6]
	var accent: Color = palette[(index + 4) % 6]

	# Layered luminous hardware: header, bezel, side rails, control lamps and underglow.
	_add_lamp(rig,"TopGlow",Vector3(0.0,0.84,0.246),Vector3(0.46,0.038,0.022),main)
	_add_lamp(rig,"BezelTop",Vector3(0.0,0.745,0.251),Vector3(0.43,0.020,0.018),sub)
	_add_lamp(rig,"SideL",Vector3(-0.292,0.53,0.241),Vector3(0.022,0.47,0.020),sub)
	_add_lamp(rig,"SideR",Vector3(0.292,0.53,0.241),Vector3(0.022,0.47,0.020),accent)
	_add_lamp(rig,"Screen",Vector3(0.0,0.62,0.250),Vector3(0.395,0.115,0.014),main)
	_add_lamp(rig,"ScreenScan",Vector3(0.0,0.62,0.261),Vector3(0.37,0.012,0.010),Color("ffffff"))
	_add_lamp(rig,"ControlLine",Vector3(0.0,0.285,0.322),Vector3(0.44,0.018,0.018),accent)
	_add_lamp(rig,"UnderGlow",Vector3(0.0,0.075,0.215),Vector3(0.45,0.022,0.022),sub)
	for b in range(3):
		_add_lamp(rig,"Button%d"%b,Vector3((float(b)-1.0)*0.14,0.315,0.326),Vector3(0.062,0.027,0.027),main if b != 1 else accent)
	for r in range(3):
		_add_lamp(rig,"ReelTick%d"%r,Vector3((float(r)-1.0)*0.15,0.505,0.269),Vector3(0.10,0.014,0.012),sub)

	# Tiny local light gives emissive parts a subtle spill onto nearby cabinet surfaces.
	var spill := OmniLight3D.new()
	spill.name = "CabinetSpill"
	spill.position = Vector3(0.0,0.58,0.38)
	spill.omni_range = 0.72
	spill.light_energy = 0.0
	spill.light_color = main
	spill.shadow_enabled = false
	rig.add_child(spill)

	rig.set_meta("phase",float(index)*0.53)
	rig.set_meta("pattern",index % 6)
	rig.set_meta("style_group",index / 6)

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

	# Scan bar physically moves over the display, making the cabinet read as an active screen.
	if scan != null:
		var scan_y: float = 0.57+0.10*(0.5+0.5*sin(t*2.7))
		scan.position.y = scan_y
		_set_energy(scan,0.45+2.2*pulse)

	# Stop buttons and reel ticks chase independently instead of blinking as one block.
	var chase_step: int = int(floor(t*5.5))%3
	for b in range(3):
		var button := rig.get_node_or_null("Button%d"%b) as MeshInstance3D
		_set_energy(button,3.6 if chase_step == b else 0.25)
		var tick := rig.get_node_or_null("ReelTick%d"%b) as MeshInstance3D
		var tick_wave: float = 0.5+0.5*sin(t*6.0-float(b)*1.6)
		_set_energy(tick,0.25+2.0*tick_wave)

	# Later style groups are progressively more luminous; AT row gets the strongest spill.
	if spill != null:
		var group_gain: float = 0.10+float(group)*0.07
		spill.light_energy = group_gain*(0.35+0.65*pulse+0.55*flash)

func _set_energy(node: MeshInstance3D,energy: float) -> void:
	if node == null:
		return
	var material := node.material_override as StandardMaterial3D
	if material != null:
		material.emission_energy_multiplier = energy
