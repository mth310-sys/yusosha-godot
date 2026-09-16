extends Node3D

var _time: float = 0.0
var _machines: Array[Node3D] = []
var _lights: Array[MeshInstance3D] = []

func _ready() -> void:
	# Builders create their machines in _ready(), so collect them one frame later.
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
	if node is Node3D and (node.name == "MachineSlot"):
		_machines.append(node as Node3D)
	for child in node.get_children():
		_collect_machines(child)

func _add_effect_rig(machine: Node3D, index: int) -> void:
	var rig := Node3D.new()
	rig.name = "LiveEffectRig"
	machine.add_child(rig)
	var palette: Array[Color] = [Color("35e7ff"),Color("ff405f"),Color("ffd43b"),Color("a65cff"),Color("48ff91"),Color("ff6fd8")]
	var main: Color = palette[index % palette.size()]
	var sub: Color = palette[(index + 2) % palette.size()]
	_add_lamp(rig,"LiveTop",Vector3(0.0,0.83,0.245),Vector3(0.44,0.045,0.025),main)
	_add_lamp(rig,"LiveLeft",Vector3(-0.285,0.52,0.235),Vector3(0.025,0.42,0.025),sub)
	_add_lamp(rig,"LiveRight",Vector3(0.285,0.52,0.235),Vector3(0.025,0.42,0.025),sub)
	for b in range(3):
		_add_lamp(rig,"LiveButton%d"%b,Vector3((float(b)-1.0)*0.14,0.31,0.315),Vector3(0.065,0.025,0.025),main if b%2==0 else sub)
	# A thin animated screen layer makes every cabinet look powered and active.
	_add_lamp(rig,"LiveScreen",Vector3(0.0,0.62,0.247),Vector3(0.40,0.12,0.018),main)
	rig.set_meta("phase",float(index)*0.47)
	rig.set_meta("pattern",index % 6)

func _add_lamp(parent: Node3D,node_name: String,pos: Vector3,size: Vector3,color: Color) -> void:
	var lamp := MeshInstance3D.new()
	lamp.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	lamp.mesh = mesh
	lamp.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.25
	lamp.material_override = material
	lamp.set_meta("base_color",color)
	parent.add_child(lamp)
	_lights.append(lamp)

func _process(delta: float) -> void:
	_time += delta
	for i in range(_machines.size()):
		var machine := _machines[i]
		var rig := machine.get_node_or_null("LiveEffectRig") as Node3D
		if rig == null:
			continue
		var phase: float = float(rig.get_meta("phase",0.0))
		var pattern: int = int(rig.get_meta("pattern",0))
		_animate_rig(rig,_time+phase,pattern)

func _animate_rig(rig: Node3D,t: float,pattern: int) -> void:
	var top := rig.get_node_or_null("LiveTop") as MeshInstance3D
	var left := rig.get_node_or_null("LiveLeft") as MeshInstance3D
	var right := rig.get_node_or_null("LiveRight") as MeshInstance3D
	var screen := rig.get_node_or_null("LiveScreen") as MeshInstance3D
	var pulse: float = 0.5 + 0.5*sin(t*4.0)
	match pattern:
		0:
			_set_energy(top,0.5+3.5*pulse)
			_set_energy(left,0.4+2.4*(1.0-pulse))
			_set_energy(right,0.4+2.4*pulse)
		1:
			var flash: float = 4.5 if fmod(t,1.15)<0.16 else 0.35
			_set_energy(top,flash); _set_energy(left,flash); _set_energy(right,flash)
		2:
			_set_energy(left,0.3+3.5*(0.5+0.5*sin(t*6.0)))
			_set_energy(right,0.3+3.5*(0.5+0.5*sin(t*6.0+3.14)))
			_set_energy(top,1.0+2.0*pulse)
		3:
			_set_energy(top,0.4+4.0*(0.5+0.5*sin(t*2.4)))
			_set_energy(left,0.4+3.0*(0.5+0.5*sin(t*2.4+2.1)))
			_set_energy(right,0.4+3.0*(0.5+0.5*sin(t*2.4+4.2)))
		4:
			var beat: float = pow(max(0.0,sin(t*5.0)),8.0)
			_set_energy(top,0.6+5.0*beat); _set_energy(left,0.5+3.0*beat); _set_energy(right,0.5+3.0*beat)
		_:
			_set_energy(top,1.0+3.0*pulse); _set_energy(left,1.0+2.0*pulse); _set_energy(right,1.0+2.0*(1.0-pulse))
	_set_energy(screen,0.45+1.7*(0.5+0.5*sin(t*2.8)))
	for b in range(3):
		var button := rig.get_node_or_null("LiveButton%d"%b) as MeshInstance3D
		var chase: float = 3.8 if int(floor(t*5.0))%3 == b else 0.3
		_set_energy(button,chase)

func _set_energy(node: MeshInstance3D,energy: float) -> void:
	if node == null:
		return
	var material := node.material_override as StandardMaterial3D
	if material != null:
		material.emission_energy_multiplier = energy
