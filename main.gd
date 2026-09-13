extends Control

const SYMBOLS := ["7", "BAR", "CHERRY", "BELL", "REPLAY"]
const SPIN_INTERVAL := 0.07

@onready var reel_labels: Array[Label] = [
	$Center/VBox/Reels/Reel1,
	$Center/VBox/Reels/Reel2,
	$Center/VBox/Reels/Reel3,
]
@onready var start_button: Button = $Center/VBox/StartButton
@onready var stop_buttons: Array[Button] = [
	$Center/VBox/Stops/Stop1,
	$Center/VBox/Stops/Stop2,
	$Center/VBox/Stops/Stop3,
]
@onready var status_label: Label = $Center/VBox/Status

var spinning := [false, false, false]
var symbol_index := [0, 2, 4]
var accum := 0.0

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	for i in stop_buttons.size():
		stop_buttons[i].pressed.connect(_on_stop_pressed.bind(i))
		stop_buttons[i].disabled = true
	_update_reels()
	status_label.text = "READY"

func _process(delta: float) -> void:
	if not spinning.has(true):
		return
	accum += delta
	if accum < SPIN_INTERVAL:
		return
	accum = 0.0
	for i in reel_labels.size():
		if spinning[i]:
			symbol_index[i] = (symbol_index[i] + 1) % SYMBOLS.size()
	_update_reels()

func _on_start_pressed() -> void:
	if spinning.has(true):
		return
	for i in spinning.size():
		spinning[i] = true
		stop_buttons[i].disabled = false
	start_button.disabled = true
	status_label.text = "SPINNING"

func _on_stop_pressed(index: int) -> void:
	if not spinning[index]:
		return
	spinning[index] = false
	stop_buttons[index].disabled = true
	if not spinning.has(true):
		start_button.disabled = false
		status_label.text = "READY"

func _update_reels() -> void:
	for i in reel_labels.size():
		reel_labels[i].text = SYMBOLS[symbol_index[i]]
