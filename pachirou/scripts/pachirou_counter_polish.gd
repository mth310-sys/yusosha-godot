extends Node3D

var _time: float = 0.0
var _counters: Array[Node3D] = []
var _states: Array[PachirouDataCounterState] = []

func _ready() -> void:
	call_deferred("_setup")

func _setup() -> void:
	await get_tree().process_frame
	var world := get_parent().get_node_or_null("World")
	if world == null: return
	_collect_islands(world)

func _collect_islands(node: Node) -> void:
	if node is Node3D and node.name == "IslandEquipment":
		var island := node as Node3D
		var row_type: int = _row_type_from_world_z(island.global_position.z)
		_upgrade_counter(island,_counters.size(),row_type)
	for child in node.get_children(): _collect_islands(child)

func _row_type_from_world_z(z: float) -> int:
	if z < -5.5: return 0
	if z < -3.5: return 1
	return 2

func _upgrade_counter(island: Node3D,index: int,row_type: int) -> void:
	var rig := Node3D.new(); rig.name = "CounterQualityRig"; island.add_child(rig); _counters.append(rig)
	var state := PachirouDataCounterState.new(); state.setup(101+index); _states.append(state)
	rig.set_meta("counter_state",state); rig.set_meta("phase",float(index)*0.37); rig.set_meta("counter_type",row_type)
	var accent: Color = [Color("28dfff"),Color("ff405e"),Color("ffd12e"),Color("a45cff"),Color("38e88a"),Color("ff65ce")][index%6]
	_build_mount(rig,row_type)
	match row_type:
		0: _build_classic_counter(rig,accent,index)
		1: _build_lcd_counter(rig,accent,index)
		_: _build_premium_counter(rig,accent,index)
	_build_live_status(rig,accent,row_type)

func _build_mount(rig: Node3D,row_type: int) -> void:
	# Real equipment needs a visible mounting bracket and cable/connector zone to the island backboard.
	_box(rig,"MountRail",Vector3(0.78,0.040,0.090),Vector3(0,1.445,0.145),Color("343b41"),0.62,0.22)
	_box(rig,"MountNeckL",Vector3(0.055,0.120,0.075),Vector3(-0.300,1.385,0.155),Color("252b30"),0.58,0.24)
	_box(rig,"MountNeckR",Vector3(0.055,0.120,0.075),Vector3(0.300,1.385,0.155),Color("252b30"),0.58,0.24)
	if row_type == 2: _box(rig,"PremiumBridge",Vector3(0.58,0.035,0.060),Vector3(0,1.465,0.190),Color("505b63"),0.72,0.18)

func _build_classic_counter(rig: Node3D,accent: Color,index: int) -> void:
	_box(rig,"Body",Vector3(0.88,0.175,0.125),Vector3(0,1.35,0.220),Color("101419"),0.36,0.20)
	_box(rig,"FaceBezel",Vector3(0.78,0.140,0.025),Vector3(0,1.35,0.295),Color("05080b"),0.45,0.14)
	_box(rig,"DisplayGlass",Vector3(0.59,0.105,0.012),Vector3(0,1.35,0.314),Color("10181c"),0.10,0.08)
	_three_digit_group(rig,"BIG",Vector3(-0.190,1.355,0.326),Color("fff4e6"),0.52)
	_two_digit_group(rig,"REG",Vector3(0.005,1.355,0.326),Color("ff9a27"),0.48)
	_three_digit_group(rig,"GAME",Vector3(0.205,1.355,0.326),Color("36ff75"),0.52)
	for i in range(8): _emissive_box(rig,"History%d"%i,Vector3(0.026,0.010,0.008),Vector3(-0.105+float(i)*0.030,1.302,0.327),Color("12181d"),accent,0.14)
	_build_side_wings(rig,accent,index)
	for i in range(4): _box(rig,"FunctionButton%d"%i,Vector3(0.092,0.022,0.030),Vector3(-0.150+float(i)*0.100,1.254,0.312),Color("59636b"),0.26,0.26)

func _build_lcd_counter(rig: Node3D,accent: Color,index: int) -> void:
	_box(rig,"Body",Vector3(0.92,0.195,0.135),Vector3(0,1.35,0.218),Color("171b20"),0.32,0.18)
	_box(rig,"SilverTop",Vector3(0.84,0.020,0.115),Vector3(0,1.452,0.220),Color("78838c"),0.70,0.18)
	_box(rig,"ScreenBezel",Vector3(0.80,0.155,0.026),Vector3(0,1.35,0.302),Color("06090c"),0.40,0.12)
	_box(rig,"LCDGlass",Vector3(0.72,0.125,0.012),Vector3(0,1.35,0.322),Color("10252d"),0.08,0.08)
	_emissive_box(rig,"LCDHeader",Vector3(0.67,0.018,0.008),Vector3(0,1.397,0.330),Color("102129"),accent,0.40)
	_three_digit_group(rig,"LCD_GAME",Vector3(-0.225,1.350,0.332),Color("dffaff"),0.56)
	for i in range(9):
		var h: float = 0.010+float((i*3+index)%5)*0.010
		_emissive_box(rig,"Graph%d"%i,Vector3(0.023,h,0.008),Vector3(0.035+float(i)*0.034,1.305+h*0.5,0.332),Color("102027"),accent,0.34)
	for i in range(3): _emissive_box(rig,"Status%d"%i,Vector3(0.050,0.014,0.008),Vector3(-0.005+float(i)*0.062,1.388,0.332),Color("102027"),[Color("4ee89b"),Color("ffcf4a"),Color("ff5b73")][i],0.42)
	_emissive_box(rig,"EdgeL",Vector3(0.026,0.155,0.025),Vector3(-0.435,1.35,0.315),Color("192129"),accent,0.55)
	_emissive_box(rig,"EdgeR",Vector3(0.026,0.155,0.025),Vector3(0.435,1.35,0.315),Color("192129"),accent,0.55)
	for i in range(3): _box(rig,"TouchKey%d"%i,Vector3(0.095,0.020,0.028),Vector3(-0.105+float(i)*0.105,1.245,0.315),Color("5b646c"),0.25,0.24)

func _build_premium_counter(rig: Node3D,accent: Color,index: int) -> void:
	_box(rig,"RearBody",Vector3(0.92,0.215,0.145),Vector3(0,1.35,0.215),Color("11151a"),0.42,0.16)
	_box(rig,"CenterFrame",Vector3(0.66,0.185,0.038),Vector3(0,1.35,0.305),Color("252d35"),0.55,0.14)
	_box(rig,"CenterGlass",Vector3(0.58,0.150,0.014),Vector3(0,1.35,0.332),Color("0c1c25"),0.10,0.06)
	_emissive_box(rig,"Crown",Vector3(0.50,0.024,0.022),Vector3(0,1.466,0.302),Color("182129"),accent,0.65)
	_three_digit_group(rig,"PREMIUM_GAME",Vector3(-0.155,1.365,0.342),Color("f0fbff"),0.60)
	_two_digit_group(rig,"PREMIUM_BONUS",Vector3(0.095,1.365,0.342),accent.lightened(0.25),0.54)
	for i in range(7):
		var c: Color = [Color("3de8ff"),Color("ff496d"),Color("ffd347")][i%3]
		_emissive_box(rig,"PremiumHistory%d"%i,Vector3(0.026,0.012+float(i%3)*0.009,0.008),Vector3(0.075+float(i%4)*0.035,1.305+float(i/4)*0.036,0.342),Color("101a20"),c,0.45)
	_box(rig,"TowerBaseL",Vector3(0.115,0.205,0.070),Vector3(-0.400,1.35,0.300),Color("202830"),0.45,0.16)
	_box(rig,"TowerBaseR",Vector3(0.115,0.205,0.070),Vector3(0.400,1.35,0.300),Color("202830"),0.45,0.16)
	for i in range(6):
		_emissive_box(rig,"TowerL%d"%i,Vector3(0.060,0.024,0.014),Vector3(-0.400,1.278+float(i)*0.031,0.342),Color("162028"),accent.lightened(float(i)*0.05),0.55)
		_emissive_box(rig,"TowerR%d"%i,Vector3(0.060,0.024,0.014),Vector3(0.400,1.278+float(i)*0.031,0.342),Color("162028"),accent.lightened(float(5-i)*0.05),0.55)
	for i in range(3): _box(rig,"PremiumKey%d"%i,Vector3(0.090,0.022,0.032),Vector3(-0.100+float(i)*0.100,1.235,0.328),Color("68737c"),0.35,0.20)

func _build_live_status(rig: Node3D,accent: Color,row_type: int) -> void:
	# Shared gameplay status layer: occupied/available, call lamp and machine-number plate.
	var z: float = 0.344 if row_type == 2 else 0.334
	_emissive_box(rig,"OccupiedLamp",Vector3(0.052,0.014,0.008),Vector3(-0.285,1.410,z),Color("10191d"),Color("4dff8a"),0.18)
	_emissive_box(rig,"CallLamp",Vector3(0.052,0.014,0.008),Vector3(0.285,1.410,z),Color("211315"),Color("ff3f59"),0.12)
	_box(rig,"MachineNumberPlate",Vector3(0.105,0.024,0.010),Vector3(0,1.250,z),Color("d6c66a"),0.08,0.40)

func _build_side_wings(rig: Node3D,accent: Color,index: int) -> void:
	_box(rig,"WingBaseL",Vector3(0.105,0.150,0.055),Vector3(-0.400,1.35,0.300),Color("151b21"),0.30,0.22); _box(rig,"WingBaseR",Vector3(0.105,0.150,0.055),Vector3(0.400,1.35,0.300),Color("151b21"),0.30,0.22)
	for row in range(4):
		for col in range(2):
			var c: Color = [Color("3ce6ff"),Color("ff3e6c"),Color("ffd23e"),Color("8b62ff")][(row+col+index)%4]
			_emissive_box(rig,"WingL_%d_%d"%[row,col],Vector3(0.032,0.024,0.010),Vector3(-0.424+float(col)*0.042,1.300+float(row)*0.032,0.336),Color("182128"),c,0.65); _emissive_box(rig,"WingR_%d_%d"%[row,col],Vector3(0.032,0.024,0.010),Vector3(0.382+float(col)*0.042,1.300+float(row)*0.032,0.336),Color("182128"),c,0.65)

func _three_digit_group(parent: Node3D,prefix: String,pos: Vector3,color: Color,scale: float) -> void:
	for i in range(3): _seven_digit(parent,prefix+str(i),pos+Vector3((float(i)-1.0)*0.070*scale,0,0),color,scale)

func _two_digit_group(parent: Node3D,prefix: String,pos: Vector3,color: Color,scale: float) -> void:
	for i in range(2): _seven_digit(parent,prefix+str(i),pos+Vector3((float(i)-0.5)*0.070*scale,0,0),color,scale)

func _seven_digit(parent: Node3D,node_name: String,pos: Vector3,color: Color,scale: float) -> void:
	var digit := Node3D.new(); digit.name = node_name; digit.position = pos; digit.scale = Vector3(scale,scale,scale); parent.add_child(digit)
	var h := Vector3(0.055,0.009,0.007); var v := Vector3(0.009,0.040,0.007)
	_emissive_box(digit,"A",h,Vector3(0,0.040,0),Color("261d1b"),color,1.15); _emissive_box(digit,"G",h,Vector3.ZERO,Color("261d1b"),color,1.15); _emissive_box(digit,"D",h,Vector3(0,-0.040,0),Color("261d1b"),color,1.15)
	_emissive_box(digit,"F",v,Vector3(-0.030,0.021,0),Color("261d1b"),color,1.15); _emissive_box(digit,"B",v,Vector3(0.030,0.021,0),Color("261d1b"),color,1.15); _emissive_box(digit,"E",v,Vector3(-0.030,-0.021,0),Color("261d1b"),color,1.15); _emissive_box(digit,"C",v,Vector3(0.030,-0.021,0),Color("261d1b"),color,1.15)

func _process(delta: float) -> void:
	_time += delta
	for rig in _counters:
		if not is_instance_valid(rig): continue
		var t: float = _time+float(rig.get_meta("phase",0.0)); var kind: int = int(rig.get_meta("counter_type",0)); var step: int = int(floor(t*3.0))%8
		var state: PachirouDataCounterState = rig.get_meta("counter_state") as PachirouDataCounterState
		_set_energy(rig.get_node_or_null("OccupiedLamp") as MeshInstance3D,1.6 if state != null and state.is_occupied else 0.12)
		_set_energy(rig.get_node_or_null("CallLamp") as MeshInstance3D,2.4 if state != null and state.call_active else 0.10)
		if kind == 0:
			for row in range(4):
				for col in range(2):
					var n: int = row*2+col; var energy: float = 2.0 if n == step else 0.35
					_set_energy(rig.get_node_or_null("WingL_%d_%d"%[row,col]) as MeshInstance3D,energy); _set_energy(rig.get_node_or_null("WingR_%d_%d"%[row,col]) as MeshInstance3D,energy)
		elif kind == 1:
			var pulse: float = 0.5+0.5*sin(t*2.1); _set_energy(rig.get_node_or_null("EdgeL") as MeshInstance3D,0.35+1.4*pulse); _set_energy(rig.get_node_or_null("EdgeR") as MeshInstance3D,0.35+1.4*(1.0-pulse)); _set_energy(rig.get_node_or_null("LCDHeader") as MeshInstance3D,0.35+0.7*pulse)
		else:
			var chase: int = int(floor(t*4.0))%6
			for i in range(6): _set_energy(rig.get_node_or_null("TowerL%d"%i) as MeshInstance3D,1.8 if i == chase else 0.35); _set_energy(rig.get_node_or_null("TowerR%d"%i) as MeshInstance3D,1.8 if i == 5-chase else 0.35)

func _box(parent: Node3D,node_name: String,size: Vector3,pos: Vector3,color: Color,metallic: float,roughness: float) -> void:
	var node := MeshInstance3D.new(); node.name = node_name; var mesh := BoxMesh.new(); mesh.size = size; node.mesh = mesh; node.position = pos
	var mat := StandardMaterial3D.new(); mat.albedo_color = color; mat.metallic = metallic; mat.roughness = roughness; node.material_override = mat; parent.add_child(node)

func _emissive_box(parent: Node3D,node_name: String,size: Vector3,pos: Vector3,base: Color,emission: Color,energy: float) -> void:
	var node := MeshInstance3D.new(); node.name = node_name; var mesh := BoxMesh.new(); mesh.size = size; node.mesh = mesh; node.position = pos
	var mat := StandardMaterial3D.new(); mat.albedo_color = base; mat.roughness = 0.20; mat.emission_enabled = true; mat.emission = emission; mat.emission_energy_multiplier = energy; node.material_override = mat; parent.add_child(node)

func _set_energy(node: MeshInstance3D,energy: float) -> void:
	if node == null: return
	var mat := node.material_override as StandardMaterial3D
	if mat != null: mat.emission_energy_multiplier = energy
