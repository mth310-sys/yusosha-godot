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
	# Stage 4: generate the body from the skeleton itself.
	# Each bone chain supplies its centre line; cross-sections are connected along it.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)

	# Torso is the hub. Shoulder and hip roots are intentionally broad so the
	# skin follows the skeleton instead of a flat front/back silhouette.
	_add_bone_chain(st,[
		_ring(Vector3(0,0.40,0),0.145,0.095,"Hips","Spine",0.82),
		_ring(Vector3(0,0.50,0),0.155,0.098,"Hips","Spine",0.55),
		_ring(Vector3(0,0.62,0),0.165,0.102,"Spine","Chest",0.55),
		_ring(Vector3(0,0.73,0),0.185,0.108,"Chest","Spine",0.82),
		_ring(Vector3(0,0.79,0),0.175,0.100,"Chest","Spine",0.92)
	],14,true,true)

	_add_arm_from_skeleton(st,-1.0,"ShoulderL","UpperArmL","LowerArmL","HandL")
	_add_arm_from_skeleton(st,1.0,"ShoulderR","UpperArmR","LowerArmR","HandR")
	_add_leg_from_skeleton(st,-1.0,"UpperLegL","LowerLegL","FootL")
	_add_leg_from_skeleton(st,1.0,"UpperLegR","LowerLegR","FootR")
	_add_head_from_skeleton(st)

	st.generate_normals()
	return st.commit()

func _ring(center: Vector3, rx: float, rz: float, bone_a: String, bone_b: String, weight_a: float) -> Array:
	return [center,rx,rz,bone_a,bone_b,weight_a]

func _bone_rest_position(name: String) -> Vector3:
	return skeleton.get_bone_global_rest(int(bones[name])).origin

func _add_arm_from_skeleton(st: SurfaceTool, side: float, shoulder: String, upper: String, lower: String, hand: String) -> void:
	var shoulder_p: Vector3 = _bone_rest_position(shoulder)
	var upper_p: Vector3 = _bone_rest_position(upper)
	var lower_p: Vector3 = _bone_rest_position(lower)
	var hand_p: Vector3 = _bone_rest_position(hand)
	var root_x: float = side*0.145
	var rings: Array = [
		_ring(Vector3(root_x,shoulder_p.y-0.015,0),0.070,0.070,"Chest",shoulder,0.72),
		_ring(Vector3((root_x+upper_p.x)*0.5,upper_p.y,0),0.061,0.061,shoulder,upper,0.55),
		_ring(Vector3(upper_p.x,upper_p.y-0.055,0),0.054,0.054,upper,shoulder,0.82),
		_ring(Vector3(lower_p.x,lower_p.y+0.045,0),0.048,0.048,upper,lower,0.55),
		_ring(Vector3(lower_p.x,lower_p.y-0.035,0),0.044,0.044,lower,upper,0.82),
		_ring(Vector3(hand_p.x,hand_p.y+0.025,0),0.042,0.042,lower,hand,0.55),
		_ring(Vector3(hand_p.x,hand_p.y-0.035,0),0.050,0.045,hand,lower,0.95)
	]
	_add_bone_chain(st,rings,10,true,true)

func _add_leg_from_skeleton(st: SurfaceTool, side: float, upper: String, lower: String, foot: String) -> void:
	var upper_p: Vector3 = _bone_rest_position(upper)
	var lower_p: Vector3 = _bone_rest_position(lower)
	var foot_p: Vector3 = _bone_rest_position(foot)
	var rings: Array = [
		_ring(Vector3(side*0.075,0.43,0),0.078,0.073,"Hips",upper,0.62),
		_ring(Vector3(upper_p.x,upper_p.y-0.055,0),0.072,0.068,upper,"Hips",0.82),
		_ring(Vector3(lower_p.x,lower_p.y+0.050,0),0.064,0.060,upper,lower,0.55),
		_ring(Vector3(lower_p.x,lower_p.y-0.040,0),0.058,0.055,lower,upper,0.82),
		_ring(Vector3(foot_p.x,foot_p.y+0.045,0),0.052,0.050,lower,foot,0.55),
		_ring(Vector3(foot_p.x,0.035,0.035),0.058,0.095,foot,lower,0.96)
	]
	_add_bone_chain(st,rings,10,true,true)

func _add_head_from_skeleton(st: SurfaceTool) -> void:
	var head_p: Vector3 = _bone_rest_position("Head")
	var rings: Array = [
		_ring(Vector3(0,0.795,0),0.070,0.067,"Chest","Head",0.68),
		_ring(Vector3(0,head_p.y-0.035,0),0.080,0.074,"Head","Chest",0.58),
		_ring(Vector3(0,head_p.y+0.035,0),0.125,0.112,"Head","Chest",0.92),
		_ring(Vector3(0,head_p.y+0.115,0),0.145,0.128,"Head","Chest",0.98),
		_ring(Vector3(0,head_p.y+0.195,0),0.105,0.095,"Head","Chest",1.0)
	]
	_add_bone_chain(st,rings,14,true,true)

func _add_bone_chain(st: SurfaceTool, rings: Array, segments: int, cap_first: bool, cap_last: bool) -> void:
	var loops: Array = []
	for data in rings:
		var loop: Array = []
		var center: Vector3 = data[0]
		var rx: float = float(data[1])
		var rz: float = float(data[2])
		for s in range(segments):
			var angle: float = TAU*float(s)/float(segments)
			loop.append([Vector3(center.x+cos(angle)*rx,center.y,center.z+sin(angle)*rz),data[3],data[4],data[5]])
		loops.append(loop)
	for r in range(loops.size()-1):
		for s in range(segments):
			var n: int = (s+1)%segments
			_emit_quad(st,loops[r][s],loops[r+1][s],loops[r][n],loops[r+1][n])
	if cap_first:
		_emit_cap(st,loops[0],false)
	if cap_last:
		_emit_cap(st,loops[loops.size()-1],true)

func _emit_cap(st: SurfaceTool, loop: Array, top: bool) -> void:
	var center_pos := Vector3.ZERO
	for data in loop:
		center_pos += data[0]
	center_pos /= float(loop.size())
	var center: Array = [center_pos,loop[0][1],loop[0][2],loop[0][3]]
	for s in range(loop.size()):
		var n: int = (s+1)%loop.size()
		if top:
			_emit_vertex(st,center)
			_emit_vertex(st,loop[s])
			_emit_vertex(st,loop[n])
		else:
			_emit_vertex(st,center)
			_emit_vertex(st,loop[n])
			_emit_vertex(st,loop[s])

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
