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
	_tapered_cylinder("Waist", 0.235, 0.265, 0.12, Vector3(0,0.535,0), PANTS, visual, 22)
	_make_leg("LegLPivot", -0.155)
	_make_leg("LegRPivot", 0.155)

	# T-shirt: tapered shell + separate hem and sleeves.
	_tapered_cylinder("Torso", 0.305, 0.365, 0.565, Vector3(0,0.865,0), SHIRT, visual, 32)
	_tapered_cylinder("ShirtHem", 0.305, 0.320, 0.075, Vector3(0,0.575,0), SHIRT, visual, 24)
	_sphere_child("SleeveL", Vector3(0.135,0.155,0.135), Vector3(-0.335,1.035,0), SHIRT, visual, 20, 10)
	_sphere_child("SleeveR", Vector3(0.135,0.155,0.135), Vector3(0.335,1.035,0), SHIRT, visual, 20, 10)
	_torus_child("Collar", 0.115, 0.018, Vector3(0,1.225,0.015), SHIRT, visual)

	# Arms / mitten hands. Pivots are retained for animation.
	_make_arm("ArmLPivot", -0.415, true)
	_make_arm("ArmRPivot", 0.415, false)

	# Head: wide and slightly compressed, no visible neck.
	_sphere_child("Head", Vector3(0.445,0.375,0.365), Vector3(0,1.475,0), SKIN, visual, 28, 14)
	_sphere_child("EarL", Vector3(0.068,0.090,0.052), Vector3(-0.425,1.475,0), SKIN, visual, 16, 8)
	_sphere_child("EarR", Vector3(0.068,0.090,0.052), Vector3(0.425,1.475,0), SKIN, visual, 16, 8)
	_sphere_child("EyeL", Vector3(0.026,0.033,0.016), Vector3(-0.125,1.490,0.360), EYES, visual, 12, 6)
	_sphere_child("EyeR", Vector3(0.026,0.033,0.016), Vector3(0.125,1.490,0.360), EYES, visual, 12, 6)

	# Short hair: one clean cap with a restrained modular fringe.
	_sphere_child("HairCap", Vector3(0.442,0.215,0.365), Vector3(0,1.680,-0.025), HAIR, visual, 32, 16)
	_sphere_child("HairBack", Vector3(0.390,0.135,0.080), Vector3(0,1.585,-0.325), HAIR, visual, 24, 12)
	_prism_child("FringeL", Vector3(0.22,0.13,0.08), Vector3(-0.19,1.605,0.345), Vector3(-8,0,-12), HAIR, visual)
	_prism_child("FringeC", Vector3(0.24,0.14,0.08), Vector3(0,1.595,0.352), Vector3(-10,0,0), HAIR, visual)
	_prism_child("FringeR", Vector3(0.22,0.13,0.08), Vector3(0.19,1.605,0.345), Vector3(-8,0,12), HAIR, visual)

func _make_leg(pivot_name:String, x:float) -> void:
	var visual := get_node_or_null("Visual") as Node3D
	if visual == null:
		return
	var pivot := Node3D.new()
	pivot.name = pivot_name
	pivot.position = Vector3(x,0.69,0)
	visual.add_child(pivot)
	_tapered_cylinder("LegL" if x < 0.0 else "LegR", 0.105, 0.125, 0.52, Vector3(0,-0.27,0), PANTS, pivot, 18)
	# Low-cut sneaker: rounded upper, toe and thin sole.
	_box_child("Sole", Vector3(0.245,0.045,0.350), Vector3(0,-0.555,0.070), SOLE, pivot)
	_sphere_child("ShoeUpper", Vector3(0.118,0.080,0.175), Vector3(0,-0.500,0.075), SHOES, pivot, 20, 10)
	_sphere_child("Toe", Vector3(0.115,0.070,0.120), Vector3(0,-0.505,0.185), SHOES, pivot, 20, 10)

func _make_arm(pivot_name:String, x:float, left:bool) -> void:
	var visual := get_node_or_null("Visual") as Node3D
	if visual == null:
		return
	var pivot := Node3D.new()
	pivot.name = pivot_name
	pivot.position = Vector3(x,1.01,0)
	visual.add_child(pivot)
	_tapered_cylinder("ArmL" if left else "ArmR", 0.078, 0.094, 0.37, Vector3(0,-0.205,0), SKIN, pivot, 16)
	_sphere_child("HandL" if left else "HandR", Vector3(0.102,0.125,0.090), Vector3(0,-0.445,0), SKIN, pivot, 18, 9)
	_sphere_child("ThumbL" if left else "ThumbR", Vector3(0.047,0.066,0.047), Vector3(0.075 if left else -0.075,-0.425,0.055), SKIN, pivot, 14, 7)

func _material(c:Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.88
	return m

func _prism_child(n:String,s:Vector3,p:Vector3,rot:Vector3,c:Color,parent:Node3D) -> void:
	var node := MeshInstance3D.new()
	node.name = n
	var mesh := PrismMesh.new()
	mesh.size = s
	node.mesh = mesh
	node.position = p
	node.rotation_degrees = rot
	node.material_override = _material(c)
	parent.add_child(node)

func _torus_child(n:String,ring_r:float,pipe_r:float,p:Vector3,c:Color,parent:Node3D) -> void:
	var node := MeshInstance3D.new()
	node.name = n
	var mesh := TorusMesh.new()
	mesh.inner_radius = ring_r - pipe_r
	mesh.outer_radius = ring_r + pipe_r
	mesh.rings = 24
	mesh.ring_segments = 12
	node.mesh = mesh
	node.position = p
	node.rotation_degrees = Vector3(90,0,0)
	node.material_override = _material(c)
	parent.add_child(node)

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
