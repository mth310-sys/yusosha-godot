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
	if node is Node3D and node.name == "IslandEquipment":
		var island := node as Node3D
		var row_type: int = _row_type_from_world_z(island.global_position.z)
		_upgrade_counter(island,_counters.size(),row_type)
	for child in node.get_children(): _collect_islands(child)

func _row_type_from_world_z(z: float) -> int:
	# Showcase rows are centered around grid z=2/4/6 -> world z=-6.5/-4.5/-2.5.
	if z < -5.5: return 0
	if z < -3.5: return 1
	return 2

func _upgrade_counter(island: Node3D,index: int,row_type: int) -> void:
	var rig := Node3D.new(); rig.name = "CounterQualityRig"; island.add_child(rig); _counters.append(rig)
	var accent: Color = [Color("28dfff"),Color("ff405e"),Color("ffd12e"),Color("a45cff"),Color("38e88a"),Color("ff65ce")][index%6]
	match row_type:
		0: _build_classic_counter(rig,accent,index)
		1: _build_lcd_counter(rig,accent,index)
		_: _build_premium_counter(rig,accent,index)
	rig.set_meta("phase",float(index)*0.37)
	rig.set_meta("counter_type",row_type)

func _build_classic_counter(rig: Node3D,accent: Color,index: int) -> void:
	# Row 1: traditional hall counter - black body, large segmented counts, side call lamps.
	_box(rig,"Body",Vector3(0.88,0.155,0.105),Vector3(0,1.35,0.215),Color("101419"),0.36,0.20)
	_box(rig,"FaceBezel",Vector3(0.78,0.125,0.020),Vector3(0,1.35,0.279),Color("05080b"),0.45,0.14)
	_box(rig,"DisplayGlass",Vector3(0.60,0.098,0.010),Vector3(0,1.35,0.293),Color("10181c"),0.10,0.08)
	_seven_digit(rig,"BigDigit",Vector3(-0.175,1.355,0.304),Color("fff4e6"),0.95)
	_seven_digit(rig,"RegDigit",Vector3(-0.035,1.355,0.304),Color("ff9a27"),0.72)
	_seven_digit(rig,"StartDigit",Vector3(0.175,1.355,0.304),Color("36ff75"),0.95)
	for i in range(7): _emissive_box(rig,"History%d"%i,Vector3(0.032,0.010,0.008),Vector3(-0.105+float(i)*0.036,1.308,0.305),Color("12181d"),accent,0.16)
	_build_side_wings(rig,accent,index,0.390,1.35)
	for i in range(4): _box(rig,"FunctionButton%d"%i,Vector3(0.105,0.022,0.026),Vector3(-0.180+float(i)*0.120,1.274,0.294),Color("4a535a"),0.24,0.30)

func _build_lcd_counter(rig: Node3D,accent: Color,index: int) -> void:
	# Row 2: modern wide LCD data display with graph area and slim illuminated end caps.
	_box(rig,"Body",Vector3(0.91,0.175,0.115),Vector3(0,1.35,0.212),Color("171b20"),0.32,0.18)
	_box(rig,"SilverTop",Vector3(0.83,0.020,0.105),Vector3(0,1.438,0.216),Color("78838c"),0.70,0.18)
	_box(rig,"ScreenBezel",Vector3(0.79,0.135,0.020),Vector3(0,1.35,0.283),Color("06090c"),0.40,0.12)
	_box(rig,"LCDGlass",Vector3(0.70,0.108,0.010),Vector3(0,1.35,0.297),Color("10252d"),0.08,0.08)
	_emissive_box(rig,"LCDHeader",Vector3(0.66,0.018,0.007),Vector3(0,1.390,0.305),Color("102129"),accent,0.40)
	# Left big count, center status, right history graph.
	_seven_digit(rig,"LCDMain",Vector3(-0.235,1.348,0.307),Color("dffaff"),0.88)
	_seven_digit(rig,"LCDSub",Vector3(-0.115,1.348,0.307),Color("ffcc54"),0.58)
	for i in range(8):
		var h: float = 0.010+float((i*3+index)%5)*0.010
		_emissive_box(rig,"Graph%d"%i,Vector3(0.025,h,0.007),Vector3(0.055+float(i)*0.038,1.315+h*0.5,0.307),Color("102027"),accent,0.34)
	for i in range(3): _emissive_box(rig,"Status%d"%i,Vector3(0.050,0.014,0.007),Vector3(-0.020+float(i)*0.062,1.382,0.307),Color("102027"),[Color("4ee89b"),Color("ffcf4a"),Color("ff5b73")][i],0.42)
	_emissive_box(rig,"EdgeL",Vector3(0.026,0.135,0.022),Vector3(-0.425,1.35,0.291),Color("192129"),accent,0.55)
	_emissive_box(rig,"EdgeR",Vector3(0.026,0.135,0.022),Vector3(0.425,1.35,0.291),Color("192129"),accent,0.55)
	for i in range(3): _box(rig,"TouchKey%d"%i,Vector3(0.095,0.018,0.024),Vector3(-0.105+float(i)*0.105,1.272,0.297),Color("5b646c"),0.25,0.24)

func _build_premium_counter(rig: Node3D,accent: Color,index: int) -> void:
	# Row 3: premium call/data unit - taller center screen, sculpted side light towers and status crown.
	_box(rig,"RearBody",Vector3(0.90,0.190,0.120),Vector3(0,1.35,0.205),Color("11151a"),0.42,0.16)
	_box(rig,"CenterFrame",Vector3(0.66,0.165,0.032),Vector3(0,1.35,0.283),Color("252d35"),0.55,0.14)
	_box(rig,"CenterGlass",Vector3(0.58,0.130,0.012),Vector3(0,1.35,0.305),Color("0c1c25"),0.10,0.06)
	_emissive_box(rig,"Crown",Vector3(0.50,0.022,0.020),Vector3(0,1.445,0.282),Color("182129"),accent,0.65)
	_seven_digit(rig,"PremiumMain",Vector3(-0.155,1.362,0.315),Color("f0fbff"),1.00)
	_seven_digit(rig,"PremiumSub",Vector3(0.010,1.362,0.315),accent.lightened(0.25),0.78)
	for i in range(6):
		var c: Color = [Color("3de8ff"),Color("ff496d"),Color("ffd347")][i%3]
		_emissive_box(rig,"PremiumHistory%d"%i,Vector3(0.034,0.012+float(i%3)*0.009,0.008),Vector3(0.115+float(i%3)*0.045,1.318+float(i/3)*0.034,0.315),Color("101a20"),c,0.45)
	_box(rig,"TowerBaseL",Vector3(0.115,0.180,0.060),Vector3(-0.390,1.35,0.275),Color("202830"),0.45,0.16)
	_box(rig,"TowerBaseR",Vector3(0.115,0.180,0.060),Vector3(0.390,1.35,0.275),Color("202830"),0.45,0.16)
	for i in range(5):
		_emissive_box(rig,"TowerL%d"%i,Vector3(0.060,0.024,0.012),Vector3(-0.390,1.292+float(i)*0.030,0.314),Color("162028"),accent.lightened(float(i)*0.06),0.55)
		_emissive_box(rig,"TowerR%d"%i,Vector3(0.060,0.024,0.012),Vector3(0.390,1.292+float(i)*0.030,0.314),Color("162028"),accent.lightened(float(4-i)*0.06),0.55)
	for i in range(3): _box(rig,"PremiumKey%d"%i,Vector3(0.090,0.022,0.030),Vector3(-0.100+float(i)*0.100,1.267,0.300),Color("68737c"),0.35,0.20)

func _build_side_wings(rig: Node3D,accent: Color,index: int,x: float,y: float) -> void:
	_box(rig,"WingBaseL",Vector3(0.105,0.135,0.050),Vector3(-x,y,0.280),Color("151b21"),0.30,0.22)
	_box(rig,"WingBaseR",Vector3(0.105,0.135,0.050),Vector3(x,y,0.280),Color("151b21"),0.30,0.22)
	for row in range(4):
		for col in range(2):
			var c: Color = [Color("3ce6ff"),Color("ff3e6c"),Color("ffd23e"),Color("8b62ff")][(row+col+index)%4]
			_emissive_box(rig,"WingL_%d_%d"%[row,col],Vector3(0.032,0.022,0.010),Vector3(-0.414+float(col)*0.042,1.305+float(row)*0.030,0.309),Color("182128"),c,0.65)
			_emissive_box(rig,"WingR_%d_%d"%[row,col],Vector3(0.032,0.022,0.010),Vector3(0.372+float(col)*0.042,1.305+float(row)*0.030,0.309),Color("182128"),c,0.65)

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
		if kind == 0:
			for row in range(4):
				for col in range(2):
					var n: int = row*2+col; var energy: float = 2.0 if n == step else 0.35
					_set_energy(rig.get_node_or_null("WingL_%d_%d"%[row,col]) as MeshInstance3D,energy); _set_energy(rig.get_node_or_null("WingR_%d_%d"%[row,col]) as MeshInstance3D,energy)
		elif kind == 1:
			var pulse: float = 0.5+0.5*sin(t*2.1); _set_energy(rig.get_node_or_null("EdgeL") as MeshInstance3D,0.35+1.4*pulse); _set_energy(rig.get_node_or_null("EdgeR") as MeshInstance3D,0.35+1.4*(1.0-pulse)); _set_energy(rig.get_node_or_null("LCDHeader") as MeshInstance3D,0.35+0.7*pulse)
		else:
			var chase: int = int(floor(t*4.0))%5
			for i in range(5):
				_set_energy(rig.get_node_or_null("TowerL%d"%i) as MeshInstance3D,1.8 if i == chase else 0.35); _set_energy(rig.get_node_or_null("TowerR%d"%i) as MeshInstance3D,1.8 if i == 4-chase else 0.35)

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
