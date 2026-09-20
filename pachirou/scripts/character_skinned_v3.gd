extends Node3D

# Pachirou Character Generator - Stage 1
# Skeleton and joint-weight validation only. Clothing/hair are intentionally absent.

@export var animate_walk: bool = true

var skeleton: Skeleton3D
var skin: Skin
var t: float = 0.0
var bones: Dictionary = {}

func _ready() -> void:
	_build_environment()
	_build_skeleton()
	_build_skin()
	_build_body()

func _process(delta: float) -> void:
	if not animate_walk:
		return
	t += delta
	var w: float = sin(t * 3.4)
	_pose("UpperArmL", Vector3.RIGHT, deg_to_rad(22.0) * w)
	_pose("UpperArmR", Vector3.RIGHT, -deg_to_rad(22.0) * w)
	_pose("UpperLegL", Vector3.RIGHT, -deg_to_rad(16.0) * w)
	_pose("UpperLegR", Vector3.RIGHT, deg_to_rad(16.0) * w)
	_pose("LowerLegL", Vector3.RIGHT, max(0.0, w) * deg_to_rad(18.0))
	_pose("LowerLegR", Vector3.RIGHT, max(0.0, -w) * deg_to_rad(18.0))

func _pose(name: String, axis: Vector3, angle: float) -> void:
	var idx: int = int(bones[name])
	skeleton.set_bone_pose_rotation(idx, Quaternion(axis, angle))

func _add_bone(name: String, parent: String, origin: Vector3) -> int:
	var idx: int = skeleton.add_bone(name)
	bones[name] = idx
	if parent != "":
		skeleton.set_bone_parent(idx, int(bones[parent]))
	skeleton.set_bone_rest(idx, Transform3D(Basis.IDENTITY, origin))
	return idx

func _build_skeleton() -> void:
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	add_child(skeleton)
	_add_bone("Root", "", Vector3.ZERO)
	_add_bone("Hips", "Root", Vector3(0, 0.48, 0))
	_add_bone("Spine", "Hips", Vector3(0, 0.14, 0))
	_add_bone("Chest", "Spine", Vector3(0, 0.15, 0))
	_add_bone("Head", "Chest", Vector3(0, 0.25, 0))
	_add_bone("ShoulderL", "Chest", Vector3(-0.13, 0.13, 0))
	_add_bone("UpperArmL", "ShoulderL", Vector3(-0.09, 0, 0))
	_add_bone("LowerArmL", "UpperArmL", Vector3(0, -0.16, 0))
	_add_bone("HandL", "LowerArmL", Vector3(0, -0.14, 0))
	_add_bone("ShoulderR", "Chest", Vector3(0.13, 0.13, 0))
	_add_bone("UpperArmR", "ShoulderR", Vector3(0.09, 0, 0))
	_add_bone("LowerArmR", "UpperArmR", Vector3(0, -0.16, 0))
	_add_bone("HandR", "LowerArmR", Vector3(0, -0.14, 0))
	_add_bone("UpperLegL", "Hips", Vector3(-0.08, -0.05, 0))
	_add_bone("LowerLegL", "UpperLegL", Vector3(0, -0.23, 0))
	_add_bone("FootL", "LowerLegL", Vector3(0, -0.21, 0))
	_add_bone("UpperLegR", "Hips", Vector3(0.08, -0.05, 0))
	_add_bone("LowerLegR", "UpperLegR", Vector3(0, -0.23, 0))
	_add_bone("FootR", "LowerLegR", Vector3(0, -0.21, 0))
	skeleton.reset_bone_poses()

func _build_skin() -> void:
	skin = Skin.new()
	for i in range(skeleton.get_bone_count()):
		skin.add_bind(i, skeleton.get_bone_global_rest(i).affine_inverse())

func _build_body() -> void:
	var body := MeshInstance3D.new()
	body.name = "BaseHumanTopology"
	body.mesh = _build_body_mesh()
	body.skin = skin
	body.skeleton = NodePath("../Skeleton3D")
	body.material_override = _material(Color(0.84, 0.64, 0.50))
	add_child(body)

func _build_body_mesh() -> ArrayMesh:
	# Stage 3: one indexed skin. No overlapping tubes and no internal caps.
	# A single front/back silhouette supplies shared shoulder, crotch and neck vertices.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)

	var z: float = 0.085
	var front: Array = [
		[Vector3(-0.075,1.105,z),"Head","Chest",1.0], # 0 crown L
		[Vector3(0.075,1.105,z),"Head","Chest",1.0],  # 1 crown R
		[Vector3(-0.140,1.020,z),"Head","Chest",1.0], # 2 head L
		[Vector3(0.140,1.020,z),"Head","Chest",1.0],  # 3 head R
		[Vector3(-0.105,0.900,z),"Head","Chest",0.90],# 4 jaw L
		[Vector3(0.105,0.900,z),"Head","Chest",0.90], # 5 jaw R
		[Vector3(-0.070,0.840,z),"Chest","Head",0.65],# 6 neck L
		[Vector3(0.070,0.840,z),"Chest","Head",0.65], # 7 neck R
		[Vector3(-0.190,0.780,z),"Chest","ShoulderL",0.70], # 8 shoulder L
		[Vector3(0.190,0.780,z),"Chest","ShoulderR",0.70],  # 9 shoulder R
		[Vector3(-0.245,0.720,z),"ShoulderL","UpperArmL",0.45], # 10 upper arm L
		[Vector3(0.245,0.720,z),"ShoulderR","UpperArmR",0.45],  # 11 upper arm R
		[Vector3(-0.245,0.540,z),"UpperArmL","LowerArmL",0.55], # 12 elbow L
		[Vector3(0.245,0.540,z),"UpperArmR","LowerArmR",0.55],  # 13 elbow R
		[Vector3(-0.235,0.390,z),"LowerArmL","HandL",0.75], # 14 hand L
		[Vector3(0.235,0.390,z),"LowerArmR","HandR",0.75],  # 15 hand R
		[Vector3(-0.155,0.650,z),"Chest","Spine",0.65], # 16 armpit/chest L
		[Vector3(0.155,0.650,z),"Chest","Spine",0.65],  # 17 armpit/chest R
		[Vector3(-0.145,0.500,z),"Spine","Hips",0.55], # 18 waist L
		[Vector3(0.145,0.500,z),"Spine","Hips",0.55],  # 19 waist R
		[Vector3(-0.135,0.420,z),"Hips","UpperLegL",0.70], # 20 hip L
		[Vector3(0.135,0.420,z),"Hips","UpperLegR",0.70],  # 21 hip R
		[Vector3(-0.025,0.390,z),"Hips","UpperLegL",0.55], # 22 crotch L
		[Vector3(0.025,0.390,z),"Hips","UpperLegR",0.55],  # 23 crotch R
		[Vector3(-0.090,0.240,z),"UpperLegL","LowerLegL",0.55], # 24 knee L
		[Vector3(0.090,0.240,z),"UpperLegR","LowerLegR",0.55],  # 25 knee R
		[Vector3(-0.080,0.080,z),"LowerLegL","FootL",0.75], # 26 ankle L
		[Vector3(0.080,0.080,z),"LowerLegR","FootR",0.75],  # 27 ankle R
		[Vector3(-0.080,0.020,z+0.055),"FootL","LowerLegL",0.95], # 28 foot L
		[Vector3(0.080,0.020,z+0.055),"FootR","LowerLegR",0.95]   # 29 foot R
	]
	var back: Array = []
	for data in front:
		var p: Vector3 = data[0]
		back.append([Vector3(p.x,p.y,-z),data[1],data[2],data[3]])

	var tris := PackedInt32Array([
		0,2,1,1,2,3, 2,4,3,3,4,5, 4,6,5,5,6,7,
		6,8,7,7,8,9, 8,16,9,9,16,17,
		8,10,16, 10,12,16, 12,14,16,
		9,17,11, 11,17,13, 13,17,15,
		16,18,17,17,18,19, 18,20,19,19,20,21,
		20,22,21,21,22,23,
		20,24,22, 22,24,26, 22,26,28,
		21,23,25, 23,27,25, 23,29,27
	])
	for i in range(0,tris.size(),3):
		_emit_indexed_triangle(st,front,tris[i],tris[i+1],tris[i+2])
		_emit_indexed_triangle(st,back,tris[i+2],tris[i+1],tris[i])

	# Close only the true outside silhouette. These are exterior side faces,
	# not internal joint caps.
	var outline := PackedInt32Array([0,1,3,5,7,9,11,15,13,17,19,21,25,27,29,23,22,28,26,24,20,18,16,14,12,10,8,6,4,2])
	for i in range(outline.size()):
		var n: int = (i+1)%outline.size()
		var a_idx: int = outline[i]
		var b_idx: int = outline[n]
		_emit_side_quad(st,front[a_idx],front[b_idx],back[a_idx],back[b_idx])

	st.generate_normals()
	return st.commit()

func _emit_indexed_triangle(st: SurfaceTool, data: Array, ia: int, ib: int, ic: int) -> void:
	_emit_vertex(st,data[ia])
	_emit_vertex(st,data[ib])
	_emit_vertex(st,data[ic])

func _emit_side_quad(st: SurfaceTool, fa: Array, fb: Array, ba: Array, bb: Array) -> void:
	_emit_vertex(st,fa)
	_emit_vertex(st,ba)
	_emit_vertex(st,fb)
	_emit_vertex(st,fb)
	_emit_vertex(st,ba)
	_emit_vertex(st,bb)

func _emit_quad(st: SurfaceTool, a: Array, b: Array, c: Array, d: Array) -> void:
	_emit_vertex(st,a)
	_emit_vertex(st,b)
	_emit_vertex(st,c)
	_emit_vertex(st,c)
	_emit_vertex(st,b)
	_emit_vertex(st,d)

func _emit_vertex(st: SurfaceTool, data: Array) -> void:
	var bone_a: int = int(bones[String(data[1])])
	var bone_b: int = int(bones[String(data[2])])
	var wa: float = float(data[3])
	st.set_bones(PackedInt32Array([bone_a,bone_b,0,0]))
	st.set_weights(PackedFloat32Array([wa,1.0-wa,0.0,0.0]))
	st.add_vertex(data[0])

func _build_environment() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-35,0)
	light.light_energy = 1.05
	light.shadow_enabled = true
	add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-42,135,0)
	fill.light_energy = 0.32
	add_child(fill)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.45
	camera.position = Vector3(1.85,2.10,1.85)
	camera.rotation_degrees = Vector3(-35.264,45,0)
	camera.current = true
	add_child(camera)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(3,3)
	floor.mesh = plane
	floor.material_override = _material(Color(0.72,0.76,0.82))
	add_child(floor)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	return mat
