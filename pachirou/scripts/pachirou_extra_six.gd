extends Node3D

const GRID_SIZE := 18
const BASE_W := 1.00
const BASE_D := 0.70
const BASE_H := 0.36
const MACHINE_W := 0.64
const MACHINE_D := 0.34
const MACHINE_H := 0.82
const MACHINE_X := -0.10
const SAND_W := MACHINE_W * (7.0 / 20.5)
const SAND_H := MACHINE_H * (48.0 / 54.0)
const SAND_X := MACHINE_X + MACHINE_W * 0.5 + SAND_W * 0.5

func _ready() -> void:
	var cells: Array[Vector2i] = [Vector2i(3,6),Vector2i(5,6),Vector2i(7,6),Vector2i(9,6),Vector2i(11,6),Vector2i(13,6)]
	for i in range(6):
		_build_variant(cells[i],i)

func _cell_to_world(cell: Vector2i) -> Vector3:
	var half: float = float(GRID_SIZE-1)*0.5
	return Vector3(float(cell.x)-half,0.0,float(cell.y)-half)

func _palette(style: int) -> Array[Color]:
	match style:
		0: return [Color("78919a"),Color("c4d2cf"),Color("26333a"),Color("ed7147"),Color("63c9dc"),Color("fff0c9")]
		1: return [Color("343a40"),Color("8b949c"),Color("101317"),Color("c9272c"),Color("4da9d9"),Color("e8e4d8")]
		2: return [Color("272b35"),Color("596579"),Color("0c1018"),Color("ef3340"),Color("31d7ff"),Color("f7f7e8")]
		3: return [Color("31283e"),Color("75648e"),Color("110d18"),Color("ff3d91"),Color("b55cff"),Color("fff0fb")]
		4: return [Color("30343a"),Color("727a82"),Color("111417"),Color("ff8a22"),Color("ffd44a"),Color("fff5dc")]
		_: return [Color("243542"),Color("5f8397"),Color("0b1218"),Color("e94444"),Color("31e0c8"),Color("eefcff")]

func _build_variant(cell: Vector2i,style: int) -> void:
	var p: Array[Color] = _palette(style)
	var bay := Node3D.new()
	bay.name = "ExtraStyle_%d"%(style+1)
	bay.position = _cell_to_world(cell)
	add_child(bay)
	var island := Node3D.new()
	island.name = "IslandEquipment"
	bay.add_child(island)
	# Return to the original island-equipment proportions for all six.
	_box(island,"Base",Vector3(BASE_W,BASE_H,BASE_D),Vector3(0,BASE_H*0.5,0),p[0])
	_box(island,"BaseFrontTrim",Vector3(0.90,0.05,0.025),Vector3(0,0.10,BASE_D*0.5+0.013),p[2])
	_box(island,"BaseTopTrim",Vector3(0.90,0.035,0.025),Vector3(0,BASE_H-0.05,BASE_D*0.5+0.013),p[1])
	_box(island,"BackBoard",Vector3(BASE_W,1.00,0.08),Vector3(0,BASE_H+0.50,-0.28),p[0])
	_box(island,"BackRailL",Vector3(0.045,0.92,0.025),Vector3(-0.45,BASE_H+0.50,-0.228),p[2])
	_box(island,"BackRailR",Vector3(0.045,0.92,0.025),Vector3(0.45,BASE_H+0.50,-0.228),p[2])
	_box(island,"UpperBox",Vector3(BASE_W,0.14,0.41),Vector3(0,1.42,-0.035),p[1])
	_box(island,"DataCounter",Vector3(0.76,0.13,0.10),Vector3(0,1.35,0.195),p[2])
	_box(island,"CounterScreen",Vector3(0.60,0.075,0.028),Vector3(0,1.35,0.274),p[4])
	var machine := Node3D.new()
	machine.name = "MachineSlot"
	machine.position = Vector3(MACHINE_X,BASE_H,0.18)
	bay.add_child(machine)
	_build_machine(machine,p,style)
	var sand := Node3D.new()
	sand.name = "Sand"
	sand.position = Vector3(SAND_X,BASE_H,0.18)
	island.add_child(sand)
	_box(sand,"Cabinet",Vector3(SAND_W,SAND_H,MACHINE_D),Vector3(0,SAND_H*0.5,0),p[0])
	_box(sand,"Face",Vector3(SAND_W*0.70,SAND_H*0.72,0.025),Vector3(0,SAND_H*0.51,0.183),p[2])
	_box(sand,"Display",Vector3(SAND_W*0.54,SAND_H*0.18,0.028),Vector3(0,SAND_H*0.70,0.186),p[4])
	_box(sand,"Slot",Vector3(SAND_W*0.48,0.035,0.029),Vector3(0,SAND_H*0.32,0.187),p[1])
	_build_stool(island,Vector3(MACHINE_X,0,0.92),p,style)

func _build_machine(parent: Node3D,p: Array[Color],style: int) -> void:
	var face := MACHINE_D*0.5+0.013
	_box(parent,"Cabinet",Vector3(MACHINE_W,MACHINE_H,MACHINE_D),Vector3(0,MACHINE_H*0.5,0),p[2])
	_box(parent,"TrimL",Vector3(0.04,0.74,0.028),Vector3(-0.285,0.43,face),p[1])
	_box(parent,"TrimR",Vector3(0.04,0.74,0.028),Vector3(0.285,0.43,face),p[1])
	if style == 0:
		# Stronger box-garden / management-SLG readability: chunky, cheerful and icon-like.
		_box(parent,"KairoTop",Vector3(0.58,0.14,0.07),Vector3(0,0.80,face+0.02),p[4])
		_box(parent,"KairoReelFrame",Vector3(0.55,0.28,0.04),Vector3(0,0.54,face+0.025),p[1])
		for i in range(3): _box(parent,"KairoReel%d"%i,Vector3(0.15,0.19,0.045),Vector3((float(i)-1.0)*0.17,0.54,face+0.05),p[5])
		_box(parent,"KairoControl",Vector3(0.58,0.13,0.13),Vector3(0,0.29,face+0.04),p[2])
		for i in range(3): _box(parent,"KairoButton%d"%i,Vector3(0.09,0.05,0.05),Vector3((float(i)-1.0)*0.15,0.31,face+0.12),p[3])
		_box(parent,"KairoLower",Vector3(0.48,0.12,0.035),Vector3(0,0.12,face+0.02),p[3])
	elif style == 1:
		# Realistic pursuit: layered bezel, recessed reels, control deck and small hardware.
		_box(parent,"MetalTop",Vector3(0.56,0.13,0.055),Vector3(0,0.80,face+0.01),p[0])
		_box(parent,"GlassOuter",Vector3(0.56,0.31,0.035),Vector3(0,0.55,face+0.015),Color("171b20"))
		_box(parent,"GlassInner",Vector3(0.50,0.25,0.038),Vector3(0,0.55,face+0.035),p[1])
		for i in range(3):
			_box(parent,"RealReel%d"%i,Vector3(0.145,0.205,0.042),Vector3((float(i)-1.0)*0.16,0.55,face+0.06),p[5])
		_box(parent,"ControlDeck",Vector3(0.59,0.12,0.16),Vector3(0,0.30,face+0.055),p[0])
		for i in range(3): _cylinder(parent,"Stop%d"%i,0.035,0.025,Vector3((float(i)-1.0)*0.14,0.35,0.31),Color("d63c3c"))
		_cylinder(parent,"Lever",0.025,0.055,Vector3(-0.25,0.27,0.30),Color("b7bcc0"))
		_box(parent,"CoinTray",Vector3(0.42,0.055,0.07),Vector3(0,0.10,face+0.045),Color("60666b"))
	else:
		_build_at_machine(parent,p,style,face)

func _build_at_machine(parent: Node3D,p: Array[Color],style: int,face: float) -> void:
	# Four AT-machine concepts keep the original footprint but emphasize large displays and lighting.
	match style:
		2:
			_emissive_box(parent,"ATWideDisplay",Vector3(0.58,0.29,0.045),Vector3(0,0.68,face+0.04),p[4])
			_box(parent,"ATReels",Vector3(0.50,0.22,0.04),Vector3(0,0.45,face+0.045),p[1])
			for i in range(3): _box(parent,"ATR%d"%i,Vector3(0.14,0.16,0.045),Vector3((float(i)-1.0)*0.16,0.45,face+0.07),p[5])
			_emissive_box(parent,"ATSideL",Vector3(0.035,0.68,0.04),Vector3(-0.29,0.50,face+0.03),p[3])
			_emissive_box(parent,"ATSideR",Vector3(0.035,0.68,0.04),Vector3(0.29,0.50,face+0.03),p[3])
		3:
			_box(parent,"ATCrown",Vector3(0.62,0.16,0.09),Vector3(0,0.86,0.01),p[1])
			_emissive_box(parent,"ATPurpleDisplay",Vector3(0.54,0.30,0.045),Vector3(0,0.64,face+0.04),p[4])
			_box(parent,"ATSmallReels",Vector3(0.46,0.19,0.04),Vector3(0,0.40,face+0.04),p[5])
			_emissive_box(parent,"WingL",Vector3(0.08,0.45,0.06),Vector3(-0.33,0.57,0.03),p[3])
			_emissive_box(parent,"WingR",Vector3(0.08,0.45,0.06),Vector3(0.33,0.57,0.03),p[3])
		4:
			_emissive_box(parent,"ATGoldHeader",Vector3(0.60,0.13,0.06),Vector3(0,0.82,face+0.02),p[4])
			_box(parent,"ATDualUpper",Vector3(0.52,0.20,0.04),Vector3(0,0.66,face+0.035),p[3])
			_box(parent,"ATReelWindow",Vector3(0.52,0.23,0.04),Vector3(0,0.45,face+0.04),p[1])
			for i in range(3): _box(parent,"GoldR%d"%i,Vector3(0.145,0.17,0.045),Vector3((float(i)-1.0)*0.16,0.45,face+0.065),p[5])
			for i in range(5): _emissive_box(parent,"GoldLamp%d"%i,Vector3(0.045,0.045,0.04),Vector3(-0.20+float(i)*0.10,0.28,face+0.10),p[4])
		5:
			_box(parent,"ATTechCrown",Vector3(0.58,0.12,0.08),Vector3(0,0.84,0.01),p[0])
			_emissive_box(parent,"ATTechScreen",Vector3(0.56,0.27,0.045),Vector3(0,0.67,face+0.04),p[4])
			_box(parent,"ATTechReels",Vector3(0.48,0.21,0.04),Vector3(0,0.44,face+0.04),p[1])
			for i in range(3): _box(parent,"TechR%d"%i,Vector3(0.135,0.16,0.045),Vector3((float(i)-1.0)*0.15,0.44,face+0.065),p[5])
			_emissive_box(parent,"TechBarL",Vector3(0.04,0.70,0.04),Vector3(-0.29,0.48,face+0.025),p[4])
			_emissive_box(parent,"TechBarR",Vector3(0.04,0.70,0.04),Vector3(0.29,0.48,face+0.025),p[3])
	_box(parent,"ATControl",Vector3(0.58,0.11,0.14),Vector3(0,0.27,face+0.05),p[2])
	for i in range(3): _cylinder(parent,"ATStop%d"%i,0.038,0.026,Vector3((float(i)-1.0)*0.14,0.33,0.31),p[3])
	_box(parent,"ATLower",Vector3(0.50,0.11,0.035),Vector3(0,0.11,face+0.02),p[3])

func _build_stool(parent: Node3D,pos: Vector3,p: Array[Color],style: int) -> void:
	var stool := Node3D.new()
	stool.name = "RoundStool"
	stool.position = pos
	parent.add_child(stool)
	var radius: float = 0.24 if style == 0 else 0.22
	_cylinder(stool,"Base",0.22,0.055,Vector3(0,0.0275,0),p[0])
	_cylinder(stool,"Post",0.035,0.42,Vector3(0,0.27,0),p[1])
	_cylinder(stool,"Seat",radius,0.11,Vector3(0,0.55,0),p[2])

func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.78
	return m

func _emissive_material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 2.2
	return m

func _box(parent: Node3D,node_name: String,size: Vector3,pos: Vector3,color: Color) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.material_override = _material(color)
	parent.add_child(node)

func _emissive_box(parent: Node3D,node_name: String,size: Vector3,pos: Vector3,color: Color) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.material_override = _emissive_material(color)
	parent.add_child(node)

func _cylinder(parent: Node3D,node_name: String,radius: float,height: float,pos: Vector3,color: Color) -> void:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	node.mesh = mesh
	node.position = pos
	node.material_override = _material(color)
	parent.add_child(node)
