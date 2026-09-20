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
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)

	# Stage 2: closed continuous body volume. Torso, neck/head and the limb roots
	# overlap inside the volume and every open end is capped, so no holes remain.
	var torso: Array = [
		[Vector3(0,0.40,0),0.145,0.095,"Hips","Spine",0.85],
		[Vector3(0,0.52,0),0.155,0.095,"Hips","Spine",0.45],
		[Vector3(0,0.65,0),0.170,0.100,"Spine","Chest",0.55],
		[Vector3(0,0.76,0),0.195,0.105,"Chest","Spine",0.90],
		[Vector3(0,0.83,0),0.165,0.095,"Chest","Spine",0.95]
	]
	_add_weighted_tube(st,torso,12,true,true)
	_add_limb(st,-1.0,"ShoulderL","UpperArmL","LowerArmL","HandL")
	_add_limb(st,1.0,"ShoulderR","UpperArmR","LowerArmR","HandR")
	_add_leg(st,-1.0,"UpperLegL","LowerLegL","FootL")
	_add_leg(st,1.0,"UpperLegR","LowerLegR","FootR")
	_add_head(st)
	st.generate_normals()
	return st.commit()

func _add_weighted_tube(st: SurfaceTool, rings: Array, segments: int, cap_top: bool = false, cap_bottom: bool = false) -> void:
	var points: Array[Array] = []
	for ring_data in rings:
		var ring: Array = []
		var center: Vector3 = ring_data[0]
		var rx: float = float(ring_data[1])
		var rz: float = float(ring_data[2])
		for s in range(segments):
			var angle: float = TAU*float(s)/float(segments)
			ring.append([Vector3(center.x+cos(angle)*rx,center.y,center.z+sin(angle)*rz),ring_data[3],ring_data[4],float(ring_data[5])])
		points.append(ring)
	for r in range(points.size()-1):
		for s in range(segments):
			var n: int = (s+1)%segments
			_emit_quad(st,points[r][s],points[r+1][s],points[r][n],points[r+1][n])
	if cap_bottom:
		_cap_ring(st,points[0],false)
	if cap_top:
		_cap_ring(st,points[points.size()-1],true)

func _cap_ring(st: SurfaceTool, ring: Array, top: bool) -> void:
	var center_pos := Vector3.ZERO
	for data in ring:
		center_pos += data[0]
	center_pos /= float(ring.size())
	var center: Array = [center_pos,ring[0][1],ring[0][2],ring[0][3]]
	for s in range(ring.size()):
		var n: int = (s+1)%ring.size()
		if top:
			_emit_vertex(st,center)
			_emit_vertex(st,ring[s])
			_emit_vertex(st,ring[n])
		else:
			_emit_vertex(st,center)
			_emit_vertex(st,ring[n])
			_emit_vertex(st,ring[s])

func _add_limb(st: SurfaceTool, side: float, shoulder: String, upper: String, lower: String, hand: String) -> void:
	# Root ring sits inside the chest volume; the exterior therefore reads as
	# one closed body instead of an arm tube ending at the shoulder.
	var rings: Array = [
		[Vector3(side*0.165,0.765,0),0.072,0.068,"Chest",shoulder,0.70],
		[Vector3(side*0.205,0.735,0),0.060,0.058,shoulder,upper,0.55],
		[Vector3(side*0.220,0.625,0),0.050,0.049,upper,lower,0.90],
		[Vector3(side*0.220,0.535,0),0.046,0.045,upper,lower,0.50],
		[Vector3(side*0.220,0.445,0),0.042,0.041,lower,hand,0.85],
		[Vector3(side*0.220,0.395,0),0.050,0.046,hand,lower,0.95]
	]
	_add_weighted_tube(st,rings,12,true,false)

func _add_leg(st: SurfaceTool, side: float, upper: String, lower: String, foot: String) -> void:
	var rings: Array = [
		[Vector3(side*0.080,0.430,0),0.082,0.075,"Hips",upper,0.65],
		[Vector3(side*0.080,0.350,0),0.072,0.068,upper,lower,0.90],
		[Vector3(side*0.080,0.240,0),0.062,0.060,upper,lower,0.55],
		[Vector3(side*0.080,0.130,0),0.054,0.053,lower,foot,0.85],
		[Vector3(side*0.080,0.055,0.020),0.058,0.085,foot,lower,0.95],
		[Vector3(side*0.080,0.025,0.050),0.060,0.105,foot,lower,1.0]
	]
	_add_weighted_tube(st,rings,12,true,false)

func _add_head(st: SurfaceTool) -> void:
	# Neck starts inside upper torso and head is capped at the crown.
	var rings: Array = [
		[Vector3(0,0.805,0),0.075,0.070,"Chest","Head",0.65],
		[Vector3(0,0.865,0),0.080,0.074,"Chest","Head",0.30],
		[Vector3(0,0.925,0),0.130,0.115,"Head","Chest",0.95],
		[Vector3(0,1.025,0),0.145,0.130,"Head","Chest",1.0],
		[Vector3(0,1.105,0),0.100,0.095,"Head","Chest",1.0]
	]
	_add_weighted_tube(st,rings,14,true,false)

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
