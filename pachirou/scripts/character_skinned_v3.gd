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

	# Torso: five rings provide enough deformation density for hips/spine/chest.
	var torso: Array = [
		[Vector3(0,0.43,0),0.13,0.085,"Hips","Spine",0.75],
		[Vector3(0,0.55,0),0.145,0.09,"Hips","Spine",0.35],
		[Vector3(0,0.66,0),0.16,0.095,"Spine","Chest",0.55],
		[Vector3(0,0.76,0),0.185,0.10,"Chest","Spine",0.85],
		[Vector3(0,0.83,0),0.15,0.09,"Chest","Spine",0.90]
	]
	_add_weighted_tube(st, torso, 12)

	# Limbs are generated with dense joint loops. This stage validates weighting;
	# clothing is added only after these joints deform cleanly.
	_add_limb(st, -1.0, "ShoulderL","UpperArmL","LowerArmL","HandL")
	_add_limb(st, 1.0, "ShoulderR","UpperArmR","LowerArmR","HandR")
	_add_leg(st, -1.0, "UpperLegL","LowerLegL","FootL")
	_add_leg(st, 1.0, "UpperLegR","LowerLegR","FootR")
	_add_head(st)
	st.generate_normals()
	return st.commit()

func _add_weighted_tube(st: SurfaceTool, rings: Array, segments: int) -> void:
	var points: Array[Array] = []
	for ring_data in rings:
		var ring: Array = []
		var center: Vector3 = ring_data[0]
		var rx: float = float(ring_data[1])
		var rz: float = float(ring_data[2])
		for s in range(segments):
			var a: float = TAU * float(s) / float(segments)
			ring.append([Vector3(center.x+cos(a)*rx,center.y,center.z+sin(a)*rz),ring_data[3],ring_data[4],float(ring_data[5])])
		points.append(ring)
	for r in range(points.size()-1):
		for s in range(segments):
			var n: int = (s+1)%segments
			_emit_quad(st,points[r][s],points[r+1][s],points[r][n],points[r+1][n])

func _add_limb(st: SurfaceTool, side: float, shoulder: String, upper: String, lower: String, hand: String) -> void:
	var x0: float = side*0.18
	var rings: Array = [
		[Vector3(x0,0.77,0),0.055,0.055,"Chest",shoulder,0.55],
		[Vector3(side*0.22,0.73,0),0.052,0.052,shoulder,upper,0.45],
		[Vector3(side*0.225,0.62,0),0.047,0.047,upper,lower,0.90],
		[Vector3(side*0.225,0.54,0),0.044,0.044,upper,lower,0.50],
		[Vector3(side*0.225,0.45,0),0.039,0.039,lower,hand,0.85]
	]
	_add_weighted_tube(st,rings,10)

func _add_leg(st: SurfaceTool, side: float, upper: String, lower: String, foot: String) -> void:
	var rings: Array = [
		[Vector3(side*0.08,0.44,0),0.073,0.07,"Hips",upper,0.55],
		[Vector3(side*0.08,0.34,0),0.068,0.065,upper,lower,0.90],
		[Vector3(side*0.08,0.23,0),0.060,0.058,upper,lower,0.50],
		[Vector3(side*0.08,0.12,0),0.052,0.052,lower,foot,0.85],
		[Vector3(side*0.08,0.04,0.025),0.055,0.09,foot,lower,0.95]
	]
	_add_weighted_tube(st,rings,10)

func _add_head(st: SurfaceTool) -> void:
	var rings: Array = [
		[Vector3(0,0.84,0),0.07,0.065,"Chest","Head",0.30],
		[Vector3(0,0.91,0),0.135,0.12,"Head","Chest",0.95],
		[Vector3(0,1.02,0),0.145,0.13,"Head","Chest",1.0],
		[Vector3(0,1.10,0),0.10,0.095,"Head","Chest",1.0]
	]
	_add_weighted_tube(st,rings,12)

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
