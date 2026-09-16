extends Node3D

var _time: float = 0.0
var _counters: Array[Node3D] = []

func _ready() -> void:
	call_deferred("_setup")

func _setup() -> void:
	await get_tree().process_frame
	var world := get_parent().get_node_or_null("World")
	if world == null:
		return
	_collect_islands(world)

func _collect_islands(node: Node) -> void:
	if node is Node3D and node.name == "IslandEquipment":
		_upgrade_counter(node as Node3D,_counters.size())
	for child in node.get_children():
		_collect_islands(child)

func _upgrade_counter(island: Node3D,index: int) -> void:
	var old := island.get_node_or_null("CounterQualityRig")
	if old != null:
		old.queue_free()
	var rig := Node3D.new()
	rig.name = "CounterQualityRig"
	island.add_child(rig)
	_counters.append(rig)
	var accent: Color = [Color("42d9ff"),Color("ff506d"),Color("ffd34a"),Color("9d68ff"),Color("4ee69a"),Color("ff76d2")][index%6]
	# Housing and layered bezel make the counter read as a separate electronic unit.
	_box(rig,"Housing",Vector3(0.80,0.145,0.125),Vector3(0,1.35,0.202),Color("202831"),0.28,0.28)
	_box(rig,"Bezel",Vector3(0.68,0.102,0.026),Vector3(0,1.35,0.276),Color("0b1016"),0.42,0.20)
	_box(rig,"Glass",Vector3(0.60,0.076,0.012),Vector3(0,1.35,0.296),Color("152f3b"),0.08,0.10)
	# Main display is split into information zones instead of one flat cyan rectangle.
	_emissive_box(rig,"DisplayMain",Vector3(0.365,0.050,0.009),Vector3(-0.065,1.35,0.304),accent.darkened(0.42),accent,0.55)
	_emissive_box(rig,"StatusLeft",Vector3(0.055,0.050,0.010),Vector3(-0.255,1.35,0.305),Color("18232b"),Color("66e6ff"),0.38)
	_emissive_box(rig,"StatusRight",Vector3(0.055,0.050,0.010),Vector3(0.255,1.35,0.305),Color("18232b"),Color("ffca55"),0.38)
	# Pixel-like numeric blocks: big game count plus smaller secondary counters.
	for d in range(3):
		_digit(rig,"MainDigit%d"%d,Vector3(-0.145+float(d)*0.085,1.35,0.312),Color("e8fbff"))
	for d in range(2):
		_digit(rig,"SubDigit%d"%d,Vector3(0.120+float(d)*0.055,1.35,0.312),accent.lightened(0.22),0.65)
	# Side indicators and top jackpot lamps.
	for i in range(5):
		_emissive_box(rig,"HistoryLamp%d"%i,Vector3(0.030,0.018,0.012),Vector3(-0.060+float(i)*0.034,1.382,0.313),Color("182027"),accent,0.18)
	_emissive_box(rig,"TopLampL",Vector3(0.105,0.018,0.018),Vector3(-0.205,1.426,0.244),Color("172029"),accent,0.25)
	_emissive_box(rig,"TopLampR",Vector3(0.105,0.018,0.018),Vector3(0.205,1.426,0.244),Color("172029"),accent.lightened(0.18),0.25)
	# Physical side caps and underside seam.
	_box(rig,"CapL",Vector3(0.050,0.125,0.145),Vector3(-0.395,1.35,0.200),Color("343e47"),0.36,0.25)
	_box(rig,"CapR",Vector3(0.050,0.125,0.145),Vector3(0.395,1.35,0.200),Color("343e47"),0.36,0.25)
	_box(rig,"LowerLip",Vector3(0.72,0.018,0.045),Vector3(0,1.279,0.245),Color("111820"),0.30,0.30)
	rig.set_meta("phase",float(index)*0.41)
	rig.set_meta("accent",accent)

func _digit(parent: Node3D,node_name: String,pos: Vector3,color: Color,scale: float = 1.0) -> void:
	var digit := Node3D.new()
	digit.name = node_name
	digit.position = pos
	digit.scale = Vector3(scale,scale,scale)
	parent.add_child(digit)
	var segs: Array[Vector3] = [Vector3(0,0.020,0),Vector3(0,-0.020,0),Vector3(-0.020,0,0),Vector3(0.020,0,0)]
	for i in range(segs.size()):
		var size := Vector3(0.030,0.006,0.006) if i < 2 else Vector3(0.006,0.034,0.006)
		_emissive_box(digit,"Seg%d"%i,size,segs[i],Color("162027"),color,0.85)

func _process(delta: float) -> void:
	_time += delta
	for rig in _counters:
		if not is_instance_valid(rig):
			continue
		var t: float = _time+float(rig.get_meta("phase",0.0))
		var pulse: float = 0.5+0.5*sin(t*2.6)
		var step: int = int(floor(t*2.2))%5
		_set_energy(rig.get_node_or_null("TopLampL") as MeshInstance3D,0.35+1.7*pulse)
		_set_energy(rig.get_node_or_null("TopLampR") as MeshInstance3D,0.35+1.7*(1.0-pulse))
		_set_energy(rig.get_node_or_null("DisplayMain") as MeshInstance3D,0.55+0.75*pulse)
		for i in range(5):
			_set_energy(rig.get_node_or_null("HistoryLamp%d"%i) as MeshInstance3D,1.8 if i == step else 0.16)

func _box(parent: Node3D,node_name: String,size: Vector3,pos: Vector3,color: Color,metallic: float,roughness: float) -> void:
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

func _emissive_box(parent: Node3D,node_name: String,size: Vector3,pos: Vector3,base: Color,emission: Color,energy: float) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base
	mat.roughness = 0.24
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = energy
	node.material_override = mat
	parent.add_child(node)

func _set_energy(node: MeshInstance3D,energy: float) -> void:
	if node == null:
		return
	var mat := node.material_override as StandardMaterial3D
	if mat != null:
		mat.emission_energy_multiplier = energy
