extends Node3D

# Character Base 01 — equipment-relative, modular visual.
const EQUIPMENT_SCALE := 0.58
const SKIN := Color("d7a47f")
const HAIR := Color("342b28")
const SHIRT := Color("f3f2ed")
const PANTS := Color("30343a")
const SHOES := Color("f5f5f1")
const SOLE := Color("deded9")
const EYES := Color("171717")

func _ready() -> void:
	_build_body()

func _build_body() -> void:
	var visual := Node3D.new()
	visual.name = "Visual"
	visual.scale = Vector3.ONE * EQUIPMENT_SCALE
	add_child(visual)

	# Legs / straight trousers. Pivots are retained for animation.
	_make_leg("LegLPivot", -0.165)
	_make_leg("LegRPivot", 0.165)

	# T-shirt: tapered shell + separate hem and sleeves.
	_tapered_cylinder("Torso", 0.335, 0.405, 0.62, Vector3(0,0.88,0), SHIRT, visual, 24)
	_tapered_cylinder("ShirtHem", 0.355, 0.365, 0.075, Vector3(0,0.585,0), SHIRT, visual, 24)
	_sphere_child("SleeveL", Vector3(0.155,0.175,0.155), Vector3(-0.385,1.055,0), SHIRT, visual, 20, 10)
	_sphere_child("SleeveR", Vector3(0.155,0.175,0.155), Vector3(0.385,1.055,0), SHIRT, visual, 20, 10)

	# Arms / mitten hands. Pivots are retained for animation.
	_make_arm("ArmLPivot", -0.415, true)
	_make_arm("ArmRPivot", 0.415, false)

	# Head: wide and slightly compressed, no visible neck.
	_sphere_child("Head", Vector3(0.455,0.385,0.385), Vector3(0,1.485,0), SKIN, visual, 28, 14)
	_sphere_child("EarL", Vector3(0.068,0.090,0.052), Vector3(-0.438,1.485,0), SKIN, visual, 16, 8)
	_sphere_child("EarR", Vector3(0.068,0.090,0.052), Vector3(0.438,1.485,0), SKIN, visual, 16, 8)
	_sphere_child("EyeL", Vector3(0.026,0.033,0.016), Vector3(-0.132,1.500,0.381), EYES, visual, 12, 6)
	_sphere_child("EyeR", Vector3(0.026,0.033,0.016), Vector3(0.132,1.500,0.381), EYES, visual, 12, 6)

	# Short hair: one clean cap with a restrained modular fringe.
	_sphere_child("HairCap", Vector3(0.463,0.245,0.395), Vector3(0,1.705,-0.020), HAIR, visual, 28, 14)
	_sphere_child("HairBack", Vector3(0.405,0.185,0.090), Vector3(0,1.575,-0.330), HAIR, visual, 20, 10)
	_sphere_child("FringeL", Vector3(0.205,0.105,0.050), Vector3(-0.205,1.610,0.350), HAIR, visual, 18, 8)
	_sphere_child("FringeC", Vector3(0.205,0.095,0.052), Vector3(0.000,1.600,0.360), HAIR, visual, 18, 8)
	_sphere_child("FringeR", Vector3(0.205,0.105,0.050), Vector3(0.205,1.610,0.350), HAIR, visual, 18, 8)

func _make_leg(pivot_name:String, x:float) -> void:
	var visual := get_node_or_null("Visual") as Node3D
	if visual == null:
		return
	var pivot := Node3D.new()
	pivot.name = pivot_name
	pivot.position = Vector3(x,0.69,0)
	visual.add_child(pivot)
	_tapered_cylinder("LegL" if x < 0.0 else "LegR", 0.115, 0.135, 0.54, Vector3(0,-0.27,0), PANTS, pivot, 18)
	# Low-cut sneaker: rounded upper, toe and thin sole.
	_box_child("Sole", Vector3(0.275,0.055,0.405), Vector3(0,-0.575,0.065), SOLE, pivot)
	_box_child("ShoeUpper", Vector3(0.245,0.115,0.345), Vector3(0,-0.515,0.045), SHOES, pivot)
	_sphere_child("Toe", Vector3(0.123,0.070,0.105), Vector3(0,-0.515,0.205), SHOES, pivot, 16, 8)

func _make_arm(pivot_name:String, x:float, left:bool) -> void:
	var visual := get_node_or_null("Visual") as Node3D
	if visual == null:
		return
	var pivot := Node3D.new()
	pivot.name = pivot_name
	pivot.position = Vector3(x,1.01,0)
	visual.add_child(pivot)
	_tapered_cylinder("ArmL" if left else "ArmR", 0.085, 0.102, 0.39, Vector3(0,-0.205,0), SKIN, pivot, 16)
	_sphere_child("HandL" if left else "HandR", Vector3(0.112,0.135,0.095), Vector3(0,-0.445,0), SKIN, pivot, 18, 9)
	_sphere_child("ThumbL" if left else "ThumbR", Vector3(0.047,0.066,0.047), Vector3(0.075 if left else -0.075,-0.425,0.055), SKIN, pivot, 14, 7)

func _material(c:Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.88
	return m

func _sphere_child(n:String,s:Vector3,p:Vector3,c:Color,parent:Node3D,segments:int=20,rings:int=10) -> void:
	var node := MeshInstance3D.new()
	node.name = n
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = segments
	mesh.rings = rings
	node.mesh = mesh
	node.scale = s
	node.position = p
	node.material_override = _material(c)
	parent.add_child(node)

func _tapered_cylinder(n:String,top_r:float,bottom_r:float,h:float,p:Vector3,c:Color,parent:Node3D,segments:int=20) -> void:
	var node := MeshInstance3D.new()
	node.name = n
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = h
	mesh.radial_segments = segments
	node.mesh = mesh
	node.position = p
	node.material_override = _material(c)
	parent.add_child(node)

func _box_child(n:String,s:Vector3,p:Vector3,c:Color,parent:Node3D) -> void:
	var node := MeshInstance3D.new()
	node.name = n
	var mesh := BoxMesh.new()
	mesh.size = s
	node.mesh = mesh
	node.position = p
	node.material_override = _material(c)
	parent.add_child(node)
