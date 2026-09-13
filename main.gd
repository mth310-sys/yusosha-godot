extends Control

const SPIN_INTERVAL := 0.065

const REEL_STRIPS := [
	["7R", "BELL", "GRAPE", "CHERRY", "BELL", "BAR", "GRAPE", "BELL", "REPLAY", "GRAPE", "CHERRY", "BELL", "7W", "GRAPE", "BELL", "CHERRY", "BAR", "GRAPE", "BELL", "REPLAY", "GRAPE"],
	["GRAPE", "BELL", "BAR", "CHERRY", "GRAPE", "BELL", "REPLAY", "GRAPE", "BELL", "7R", "CHERRY", "GRAPE", "BELL", "BAR", "GRAPE", "7W", "BELL", "CHERRY", "GRAPE", "BELL", "REPLAY"],
	["BELL", "GRAPE", "CHERRY", "BAR", "BELL", "GRAPE", "REPLAY", "CHERRY", "BELL", "GRAPE", "7R", "BELL", "GRAPE", "BAR", "CHERRY", "BELL", "7W", "GRAPE", "REPLAY", "BELL", "GRAPE"],
]

@onready var reel_rows := [
	[
		$Center/VBox/Reels/Reel1/Top,
		$Center/VBox/Reels/Reel1/Middle,
		$Center/VBox/Reels/Reel1/Bottom,
	],
	[
		$Center/VBox/Reels/Reel2/Top,
		$Center/VBox/Reels/Reel2/Middle,
		$Center/VBox/Reels/Reel2/Bottom,
	],
	[
		$Center/VBox/Reels/Reel3/Top,
		$Center/VBox/Reels/Reel3/Middle,
		$Center/VBox/Reels/Reel3/Bottom,
	],
]

@onready var start_button: Button = $Center/VBox/StartButton
@onready var stop_buttons: Array[Button] = [
	$Center/VBox/Stops/Stop1,
	$Center/VBox/Stops/Stop2,
	$Center/VBox/Stops/Stop3,
]
@onready var status_label: Label = $Center/VBox/Status

var spinning := [false, false, false]
var reel_index := [0, 1, 3]
var reel_accum := [0.0, 0.0, 0.0]

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	for i in stop_buttons.size():
		stop_buttons[i].pressed.connect(_on_stop_pressed.bind(i))
		stop_buttons[i].disabled = true
	_update_all_reels()
	status_label.text = "PRESS START"

func _process(delta: float) -> void:
	for i in spinning.size():
		if not spinning[i]:
			continue
		reel_accum[i] += delta
		while reel_accum[i] >= SPIN_INTERVAL:
			reel_accum[i] -= SPIN_INTERVAL
			reel_index[i] = (reel_index[i] + 1) % REEL_STRIPS[i].size()
			_update_reel(i)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_ENTER, KEY_SPACE:
			_on_start_pressed()
		KEY_1:
			_on_stop_pressed(0)
		KEY_2:
			_on_stop_pressed(1)
		KEY_3:
			_on_stop_pressed(2)

func _on_start_pressed() -> void:
	if spinning.has(true):
		return

	for i in spinning.size():
		spinning[i] = true
		reel_accum[i] = 0.0
		stop_buttons[i].disabled = false

	start_button.disabled = true
	status_label.text = "SPINNING - STOP 1 / 2 / 3"

func _on_stop_pressed(index: int) -> void:
	if index < 0 or index >= spinning.size():
		return
	if not spinning[index]:
		return

	spinning[index] = false
	stop_buttons[index].disabled = true
	_update_reel(index)

	if spinning.has(true):
		status_label.text = "SPINNING - STOP REMAINING REELS"
	else:
		start_button.disabled = false
		status_label.text = "ALL REELS STOPPED - PRESS START"

func _update_all_reels() -> void:
	for i in reel_rows.size():
		_update_reel(i)

func _update_reel(reel: int) -> void:
	var strip = REEL_STRIPS[reel]
	var middle := reel_index[reel]
	var top := posmod(middle - 1, strip.size())
	var bottom := posmod(middle + 1, strip.size())

	reel_rows[reel][0].text = strip[top]
	reel_rows[reel][1].text = strip[middle]
	reel_rows[reel][2].text = strip[bottom]
