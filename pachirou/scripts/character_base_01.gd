extends Node3D

# Character Base 01 — visual prototype only.
# Authored at equipment-relative scale. Existing stool seat top is ~0.605 and machine top is ~1.18.
# Standing top is ~1.14 so the character fits the hall and can later seat against the existing stool geometry.
const EQUIPMENT_SCALE := 0.58
const SKIN := Color("d7a47f")
const HAIR := Color("342b28")
const SHIRT := Color("f3f2ed")
const PANTS := Color("30343a")
const SHOES := Color("f5f5f1")
const EYES := Color("171717")

func _ready() -> void:
	_build_body()

func _build_body() -> void:
	var visual := Node3D.new()
	visual.name = "Visual"
	visual.scale = Vector3.ONE * EQUIPMENT_SCALE
	add_child(visual)
	# Approx. 3-head adult silhouette; no visible neck.
	# Feet / shoes

	# Straight trousers, separate modules.
	_limb_with_pivot("LegLPivot","LegL",0.13,0.58,Vector3(-0.17,0.69,0),Vector3(0,-0.27,0),PANTS)
	_limb_with_pivot("LegRPivot","LegR",0.13,0.58,Vector3(0.17,0.69,0),Vector3(0,-0.27,0),PANTS)
	# Barrel/oval torso and thin T-shirt shell.
	_sphere("Torso",Vector3(0.40,0.46,0.28),Vector3(0,0.91,0),SHIRT)
	# Short sleeves.
	_sphere("SleeveL",Vector3(0.15,0.18,0.16),Vector3(-0.40,1.03,0),SHIRT)
	_sphere("SleeveR",Vector3(0.15,0.18,0.16),Vector3(0.40,1.03,0),SHIRT)
	# Simple cylindrical arms.
	_limb_with_pivot("ArmLPivot","ArmL",0.105,0.43,Vector3(-0.42,1.00,0),Vector3(0,-0.21,0),SKIN)
	_limb_with_pivot("ArmRPivot","ArmR",0.105,0.43,Vector3(0.42,1.00,0),Vector3(0,-0.21,0),SKIN)
	# Mitten hands + separated thumbs.

	# Wide, slightly vertically compressed head.
	_sphere("Head",Vector3(0.46,0.39,0.39),Vector3(0,1.49,0),SKIN)
	# Small simplified ears.
	_sphere("EarL",Vector3(0.075,0.10,0.055),Vector3(-0.43,1.49,0),SKIN)
	_sphere("EarR",Vector3(0.075,0.10,0.055),Vector3(0.43,1.49,0),SKIN)
	# Normal face: tiny black dot eyes only.
	_sphere("EyeL",Vector3(0.030,0.040,0.018),Vector3(-0.135,1.50,0.382),EYES)
	_sphere("EyeR",Vector3(0.030,0.040,0.018),Vector3(0.135,1.50,0.382),EYES)
	# Modular short dark-brown hair: cap + simple front/back locks.
	_sphere("HairCap",Vector3(0.47,0.245,0.40),Vector3(0,1.70,-0.018),HAIR)
	for x in [-0.27,-0.135,0.0,0.135,0.27]:
		_sphere("FrontHair",Vector3(0.095,0.135,0.070),Vector3(x,1.62,0.345),HAIR)
	# T-shirt hem gives the clothing a separate shell instead of a body-colored blob.
	_cylinder("ShirtHem",0.37,0.055,Vector3(0,0.56,0),SHIRT)
	# Simple sneaker sole layer for a cleaner low-cut silhouette.
	_box_child("SoleL",Vector3(0.30,0.045,0.42),Vector3(0,-0.625,0.075),SHOES,get_node("Visual/LegLPivot"))
	_box_child("SoleR",Vector3(0.30,0.045,0.42),Vector3(0,-0.625,0.075),SHOES,get_node("Visual/LegRPivot"))

func _material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m

func _cylinder(n:String,r:float,h:float,p:Vector3,c:Color) -> void:
	var node:=MeshInstance3D.new()
	node.name=n
	var mesh:=CylinderMesh.new()
	mesh.top_radius=r
	mesh.bottom_radius=r
	mesh.height=h
	mesh.radial_segments=20
	node.mesh=mesh
	node.position=p
	node.material_override=_material(c)
	var visual := get_node_or_null("Visual") as Node3D
	if visual != null:
		visual.add_child(node)

func _sphere_child(n:String,s:Vector3,p:Vector3,c:Color,parent:Node3D) -> void:
	var node:=MeshInstance3D.new()
	node.name=n
	var mesh:=SphereMesh.new()
	mesh.radius=1.0
	mesh.height=2.0
	mesh.radial_segments=16
	mesh.rings=8
	node.mesh=mesh
	node.scale=s
	node.position=p
	node.material_override=_material(c)
	parent.add_child(node)

func _box_child(n:String,s:Vector3,p:Vector3,c:Color,parent:Node3D) -> void:
	var node:=MeshInstance3D.new()
	node.name=n
	var mesh:=BoxMesh.new()
	mesh.size=s
	node.mesh=mesh
	node.position=p
	node.material_override=_material(c)
	parent.add_child(node)

func _sphere(n:String,s:Vector3,p:Vector3,c:Color) -> void:
	var node:=MeshInstance3D.new()
	node.name=n
	var mesh:=SphereMesh.new()
	mesh.radius=1.0
	mesh.height=2.0
	mesh.radial_segments=16
	mesh.rings=8
	node.mesh=mesh
	node.scale=s
	node.position=p
	node.material_override=_material(c)
	var visual := get_node_or_null("Visual") as Node3D
	if visual != null:
		visual.add_child(node)

func _limb_with_pivot(pivot_name:String,n:String,r:float,h:float,pivot_pos:Vector3,local_pos:Vector3,c:Color) -> void:
	var visual := get_node_or_null("Visual") as Node3D
	if visual == null:
		return
	var pivot := Node3D.new()
	pivot.name = pivot_name
	pivot.position = pivot_pos
	visual.add_child(pivot)
	var node := MeshInstance3D.new()
	node.name = n
	var mesh := CapsuleMesh.new()
	mesh.radius = r
	mesh.height = h
	mesh.radial_segments = 12
	mesh.rings = 4
	node.mesh = mesh
	node.position = local_pos
	node.material_override = _material(c)
	pivot.add_child(node)
	if n == "LegL" or n == "LegR":
		_box_child("ShoeL" if n == "LegL" else "ShoeR", Vector3(0.28,0.14,0.40), Vector3(0,-0.56,0.07), SHOES, pivot)
	elif n == "ArmL" or n == "ArmR":
		_sphere_child("HandL" if n == "ArmL" else "HandR", Vector3(0.13,0.15,0.11), Vector3(0,-0.47,0), SKIN, pivot)
		_sphere_child("ThumbL" if n == "ArmL" else "ThumbR", Vector3(0.055,0.075,0.055), Vector3(0.09 if n == "ArmL" else -0.09,-0.45,0.07), SKIN, pivot)

func _capsule(n:String,r:float,h:float,p:Vector3,c:Color) -> void:
	var node:=MeshInstance3D.new()
	node.name=n
	var mesh:=CapsuleMesh.new()
	mesh.radius=r
	mesh.height=h
	mesh.radial_segments=12
	mesh.rings=4
	node.mesh=mesh
	node.position=p
	node.material_override=_material(c)
	var visual := get_node_or_null("Visual") as Node3D
	if visual != null:
		visual.add_child(node)

func _box(n:String,s:Vector3,p:Vector3,c:Color,rot:Vector3) -> void:
	var node:=MeshInstance3D.new()
	node.name=n
	var mesh:=BoxMesh.new()
	mesh.size=s
	node.mesh=mesh
	node.position=p
	node.rotation_degrees=rot
	node.material_override=_material(c)
	var visual := get_node_or_null("Visual") as Node3D
	if visual != null:
		visual.add_child(node)
