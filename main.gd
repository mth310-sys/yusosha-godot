extends Control

const SPIN_INTERVAL := 0.065
const MAX_BET := 3

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
@onready var bet_button: Button = $Center/VBox/BetControls/BetButton
@onready var max_bet_button: Button = $Center/VBox/BetControls/MaxBetButton
@onready var stop_buttons: Array[Button] = [
	$Center/VBox/Stops/Stop1,
	$Center/VBox/Stops/Stop2,
	$Center/VBox/Stops/Stop3,
]
@onready var status_label: Label = $Center/VBox/Status
@onready var credit_label: Label = $Center/VBox/Info/CreditBox/Value
@onready var bet_label: Label = $Center/VBox/Info/BetBox/Value
@onready var payout_label: Label = $Center/VBox/Info/PayoutBox/Value

var spinning: Array[bool] = [false, false, false]
var reel_index: Array[int] = [0, 1, 3]
var reel_accum: Array[float] = [0.0, 0.0, 0.0]
var credit: int = 50
var bet: int = 0
var payout: int = 0

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	bet_button.pressed.connect(_on_bet_pressed)
	max_bet_button.pressed.connect(_on_max_bet_pressed)
	for i in stop_buttons.size():
		stop_buttons[i].pressed.connect(_on_stop_pressed.bind(i))
		stop_buttons[i].disabled = true
	_update_all_reels()
	_refresh_ui()

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
		KEY_B:
			_on_bet_pressed()
		KEY_M:
			_on_max_bet_pressed()
		KEY_ENTER, KEY_SPACE:
			_on_start_pressed()
		KEY_1:
			_on_stop_pressed(0)
		KEY_2:
			_on_stop_pressed(1)
		KEY_3:
			_on_stop_pressed(2)

func _on_bet_pressed() -> void:
	if spinning.has(true):
		return
	if bet >= MAX_BET or credit <= 0:
		return
	credit -= 1
	bet += 1
	payout = 0
	_refresh_ui()

func _on_max_bet_pressed() -> void:
	if spinning.has(true):
		return
	while bet < MAX_BET and credit > 0:
		credit -= 1
		bet += 1
	payout = 0
	_refresh_ui()

func _on_start_pressed() -> void:
	if spinning.has(true):
		return
	if bet != MAX_BET:
		status_label.text = "BET 3 TO START"
		return

	for i in spinning.size():
		spinning[i] = true
		reel_accum[i] = 0.0
		stop_buttons[i].disabled = false

	payout = 0
	status_label.text = "SPINNING - STOP 1 / 2 / 3"
	_refresh_controls()
	_refresh_counters()

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
		bet = 0
		status_label.text = "BET 3 TO START"
		_refresh_ui()

func _refresh_ui() -> void:
	_refresh_counters()
	_refresh_controls()
	if not spinning.has(true):
		if bet == MAX_BET:
			status_label.text = "READY - PRESS START"
		elif credit <= 0 and bet < MAX_BET:
			status_label.text = "NO CREDIT"
		else:
			status_label.text = "BET 3 TO START"

func _refresh_counters() -> void:
	credit_label.text = str(credit)
	bet_label.text = str(bet)
	payout_label.text = str(payout)

func _refresh_controls() -> void:
	var active_spin := spinning.has(true)
	start_button.disabled = active_spin or bet != MAX_BET
	bet_button.disabled = active_spin or bet >= MAX_BET or credit <= 0
	max_bet_button.disabled = active_spin or bet >= MAX_BET or credit <= 0
	if not active_spin:
		for button in stop_buttons:
			button.disabled = true

func _update_all_reels() -> void:
	for i in reel_rows.size():
		_update_reel(i)

func _update_reel(reel: int) -> void:
	var strip: Array = REEL_STRIPS[reel]
	var middle: int = reel_index[reel]
	var top: int = posmod(middle - 1, strip.size())
	var bottom: int = posmod(middle + 1, strip.size())

	reel_rows[reel][0].text = str(strip[top])
	reel_rows[reel][1].text = str(strip[middle])
	reel_rows[reel][2].text = str(strip[bottom])
