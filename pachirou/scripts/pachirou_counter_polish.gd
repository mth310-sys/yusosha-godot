extends Node3D

var _time: float = 0.0
var _counters: Array[Node3D] = []

func _ready() -> void:
	call_deferred("_setup")

func _setup() -> void:
	await get_tree().process_frame
	var world := get_parent().get_node_or_null("World")
	if world == null: return
	_collect_islands(world)

func _collect_islands(node: Node) -> void:
	if node is Node3D and node.name == "IslandEquipment": _upgrade_counter(node as Node3D,_counters.size())
	for child in node.get_children(): _collect_islands(child)

func _upgrade_counter(island: Node3D,index: int) -> void:
	var rig := Node3D.new()
	rig.name = "CounterQualityRig"
	island.add_child(rig)
	_counters.append(rig)
	var accent: Color = [Color("28dfff"),Color("ff405e"),Color("ffd12e"),Color("a45cff"),Color("38e88a"),Color("ff65ce")][index%6]
	# Real hall counters are wide, shallow and mostly black, with large readable digits and illuminated side panels.
	_box(rig,"Body",Vector3(0.88,0.155,0.105),Vector3(0,1.35,0.215),Color("101419"),0.36,0.20)
	_box(rig,"FaceBezel",Vector3(0.78,0.125,0.020),Vector3(0,1.35,0.279),Color("05080b"),0.45,0.14)
	_box(rig,"DisplayGlass",Vector3(0.60,0.098,0.010),Vector3(0,1.35,0.293),Color("10181c"),0.10,0.08)
	# Large BB/RB/start-style seven-segment zones.
	_seven_digit(rig,"BigDigit",Vector3(-0.175,1.355,0.304),Color("fff4e6"),0.95)
	_seven_digit(rig,"RegDigit",Vector3(-0.035,1.355,0.304),Color("ff9a27"),0.72)
	_seven_digit(rig,"StartDigit",Vector3(0.175,1.355,0.304),Color("36ff75"),0.95)
	# Small lower information row and graph/history blocks.
	for i in range(7):
		_emissive_box(rig,"History%d"%i,Vector3(0.032,0.010,0.008),Vector3(-0.105+float(i)*0.036,1.308,0.305),Color("12181d"),accent,0.16)
	for i in range(4):
		_box(rig,"InfoTick%d"%i,Vector3(0.042,0.006,0.008),Vector3(-0.210+float(i)*0.060,1.318,0.305),Color("77838b"),0.0,0.55)
	# Distinct illuminated side wings, common on actual data/call lamps.
	_box(rig,"WingBaseL",Vector3(0.105,0.135,0.050),Vector3(-0.390,1.35,0.280),Color("151b21"),0.30,0.22)
	_box(rig,"WingBaseR",Vector3(0.105,0.135,0.050),Vector3(0.390,1.35,0.280),Color("151b21"),0.30,0.22)
	for row in range(4):
		for col in range(2):
			var y: float = 1.305+float(row)*0.030
			var xl: float = -0.414+float(col)*0.042
			var xr: float = 0.372+float(col)*0.042
			var c: Color = [Color("3ce6ff"),Color("ff3e6c"),Color("ffd23e"),Color("8b62ff")][(row+col+index)%4]
			_emissive_box(rig,"WingL_%d_%d"%[row,col],Vector3(0.032,0.022,0.010),Vector3(xl,y,0.309),Color("182128"),c,0.65)
			_emissive_box(rig,"WingR_%d_%d"%[row,col],Vector3(0.032,0.022,0.010),Vector3(xr,y,0.309),Color("182128"),c,0.65)
	# Bottom function buttons: call/data/history/display switching silhouette.
	for i in range(4):
		_box(rig,"FunctionButton%d"%i,Vector3(0.105,0.022,0.026),Vector3(-0.180+float(i)*0.120,1.274,0.294),Color("4a535a"),0.24,0.30)
	_box(rig,"NumberPlate",Vector3(0.105,0.025,0.010),Vector3(0,1.267,0.311),Color("d7bc35"),0.05,0.46)
	rig.set_meta("phase",float(index)*0.37)

func _seven_digit(parent: Node3D,node_name: String,pos: Vector3,color: Color,scale: float) -> void:
	var digit := Node3D.new(); digit.name = node_name; digit.position = pos; digit.scale = Vector3(scale,scale,scale); parent.add_child(digit)
	var h := Vector3(0.055,0.009,0.007)
	var v := Vector3(0.009,0.040,0.007)
	_emissive_box(digit,"A",h,Vector3(0,0.040,0),Color("261d1b"),color,1.15)
	_emissive_box(digit,"G",h,Vector3(0,0,0),Color("261d1b"),color,1.15)
	_emissive_box(digit,"D",h,Vector3(0,-0.040,0),Color("261d1b"),color,1.15)
	_emissive_box(digit,"F",v,Vector3(-0.030,0.021,0),Color("261d1b"),color,1.15)
	_emissive_box(digit,"B",v,Vector3(0.030,0.021,0),Color("261d1b"),color,1.15)
	_emissive_box(digit,"E",v,Vector3(-0.030,-0.021,0),Color("261d1b"),color,1.15)
	_emissive_box(digit,"C",v,Vector3(0.030,-0.021,0),Color("261d1b"),color,1.15)

func _process(delta: float) -> void:
	_time += delta
	for rig in _counters:
		if not is_instance_valid(rig): continue
		var t: float = _time+float(rig.get_meta("phase",0.0))
		var step: int = int(floor(t*3.0))%8
		for row in range(4):
			for col in range(2):
				var n: int = row*2+col
				var energy: float = 2.0 if n == step else 0.45+0.30*(0.5+0.5*sin(t*2.4+float(n)))
				_set_energy(rig.get_node_or_null("WingL_%d_%d"%[row,col]) as MeshInstance3D,energy)
				_set_energy(rig.get_node_or_null("WingR_%d_%d"%[row,col]) as MeshInstance3D,energy)
		for i in range(7):
			_set_energy(rig.get_node_or_null("History%d"%i) as MeshInstance3D,1.3 if i == int(floor(t*1.8))%7 else 0.12)

func _box(parent: Node3D,node_name: String,size: Vector3,pos: Vector3,color: Color,metallic: float,roughness: float) -> void:
	var node := MeshInstance3D.new(); node.name = node_name
	var mesh := BoxMesh.new(); mesh.size = size; node.mesh = mesh; node.position = pos
	var mat := StandardMaterial3D.new(); mat.albedo_color = color; mat.metallic = metallic; mat.roughness = roughness; node.material_override = mat
	parent.add_child(node)

func _emissive_box(parent: Node3D,node_name: String,size: Vector3,pos: Vector3,base: Color,emission: Color,energy: float) -> void:
	var node := MeshInstance3D.new(); node.name = node_name
	var mesh := BoxMesh.new(); mesh.size = size; node.mesh = mesh; node.position = pos
	var mat := StandardMaterial3D.new(); mat.albedo_color = base; mat.roughness = 0.20; mat.emission_enabled = true; mat.emission = emission; mat.emission_energy_multiplier = energy; node.material_override = mat
	parent.add_child(node)

func _set_energy(node: MeshInstance3D,energy: float) -> void:
	if node == null: return
	var mat := node.material_override as StandardMaterial3D
	if mat != null: mat.emission_energy_multiplier = energy
