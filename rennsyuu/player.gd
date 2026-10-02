extends CharacterBody2D


var speed := 200.0
var walk_time := 0.0


# =========================
# Visual
# =========================

@onready var visual = $Visual


# =========================
# 頭・顔
# =========================

@onready var head = $Visual/Head
@onready var face = $Visual/Head/Face

@onready var left_eye = $Visual/Head/Face/LeftEye
@onready var right_eye = $Visual/Head/Face/RightEye

@onready var left_pupil = $Visual/Head/Face/LeftEye/LeftPupil
@onready var right_pupil = $Visual/Head/Face/RightEye/RightPupil

@onready var left_brow = $Visual/Head/Face/LeftBrow
@onready var right_brow = $Visual/Head/Face/RightBrow

@onready var nose = $Visual/Head/Face/Nose
@onready var mouth = $Visual/Head/Face/Mouth

@onready var left_ear = $Visual/Head/LeftEar
@onready var right_ear = $Visual/Head/RightEar

@onready var hair_front = $Visual/Head/HairFront


# =========================
# 胴体
# =========================

@onready var neck = $Visual/Neck
@onready var clavicle = $Visual/Clavicle
@onready var chest = $Visual/Chest
@onready var pelvis = $Visual/Pelvis


# =========================
# 腕
# =========================

@onready var left_shoulder = $Visual/LeftShoulder
@onready var right_shoulder = $Visual/RightShoulder

@onready var left_elbow = $Visual/LeftShoulder/LeftUpperArm/LeftElbow
@onready var right_elbow = $Visual/RightShoulder/RightUpperArm/RightElbow


# =========================
# 脚
# =========================

@onready var left_hip = $Visual/LeftHip
@onready var right_hip = $Visual/RightHip

@onready var left_knee = $Visual/LeftHip/LeftThigh/LeftKnee
@onready var right_knee = $Visual/RightHip/RightThigh/RightKnee


# =========================
# 基準位置
# =========================

var head_base_y := -47.0
var neck_base_y := -29.0
var clavicle_base_y := -18.0
var chest_base_y := 0.0
var pelvis_base_y := 27.0


# =========================
# 初期化
# =========================

func _ready():
	reset_pose()
	normal_face()


# =========================
# 毎フレーム
# =========================

func _physics_process(delta):
	var direction = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	velocity = direction * speed
	move_and_slide()

	if direction != Vector2.ZERO:
		walk_time += delta * 8.0
		animate_walk(walk_time)
	else:
		reset_pose()


# =========================
# 歩行
# =========================

func animate_walk(t):
	var swing = sin(t)
	var bounce = abs(sin(t * 2.0))

	# 腕
	left_shoulder.rotation = swing * 0.45
	right_shoulder.rotation = -swing * 0.45

	# 肘
	left_elbow.rotation = -0.18
	right_elbow.rotation = 0.18

	# 脚
	left_hip.rotation = -swing * 0.35
	right_hip.rotation = swing * 0.35

	# 膝
	left_knee.rotation = 0.10
	right_knee.rotation = -0.10

	# 胴体
	chest.rotation = swing * 0.08
	pelvis.rotation = -swing * 0.06

	# 上下バウンド
	head.position.y = head_base_y + bounce * 1.5
	neck.position.y = neck_base_y + bounce * 1.2
	clavicle.position.y = clavicle_base_y + bounce * 1.1
	chest.position.y = chest_base_y + bounce * 1.0
	pelvis.position.y = pelvis_base_y + bounce * 1.0


# =========================
# 停止時
# =========================

func reset_pose():
	left_shoulder.rotation = 0.0
	right_shoulder.rotation = 0.0

	left_elbow.rotation = -0.18
	right_elbow.rotation = 0.18

	left_hip.rotation = 0.0
	right_hip.rotation = 0.0

	left_knee.rotation = 0.0
	right_knee.rotation = 0.0

	chest.rotation = 0.0
	pelvis.rotation = 0.0

	head.position.y = head_base_y
	neck.position.y = neck_base_y
	clavicle.position.y = clavicle_base_y
	chest.position.y = chest_base_y
	pelvis.position.y = pelvis_base_y


# =========================
# 通常の顔
# =========================

func normal_face():
	left_eye.scale = Vector2.ONE
	right_eye.scale = Vector2.ONE

	left_pupil.position = Vector2.ZERO
	right_pupil.position = Vector2.ZERO

	left_brow.rotation = 0.0
	right_brow.rotation = 0.0

	mouth.scale = Vector2.ONE


# =========================
# 目を閉じる
# =========================

func close_eyes():
	left_eye.scale.y = 0.15
	right_eye.scale.y = 0.15


# =========================
# 目を開く
# =========================

func open_eyes():
	left_eye.scale.y = 1.0
	right_eye.scale.y = 1.0


# =========================
# まばたき
# =========================

func blink():
	close_eyes()

	await get_tree().create_timer(0.12).timeout

	open_eyes()


# =========================
# 瞳を中央へ
# =========================

func pupils_center():
	left_pupil.position = Vector2.ZERO
	right_pupil.position = Vector2.ZERO


# =========================
# 左を見る
# =========================

func pupils_left():
	left_pupil.position.x = -1.0
	right_pupil.position.x = -1.0


# =========================
# 右を見る
# =========================

func pupils_right():
	left_pupil.position.x = 1.0
	right_pupil.position.x = 1.0


# =========================
# 上を見る
# =========================

func pupils_up():
	left_pupil.position.y = -1.0
	right_pupil.position.y = -1.0


# =========================
# 下を見る
# =========================

func pupils_down():
	left_pupil.position.y = 1.0
	right_pupil.position.y = 1.0


# =========================
# 口を開く
# =========================

func open_mouth():
	mouth.scale.y = 2.0


# =========================
# 口を閉じる
# =========================

func close_mouth():
	mouth.scale.y = 1.0


# =========================
# 怒り顔
# =========================

func angry_face():
	left_brow.rotation = 0.20
	right_brow.rotation = -0.20

	open_eyes()
	close_mouth()


# =========================
# 驚き顔
# =========================

func surprised_face():
	left_brow.rotation = -0.15
	right_brow.rotation = 0.15

	left_eye.scale.y = 1.4
	right_eye.scale.y = 1.4

	mouth.scale.y = 2.5
