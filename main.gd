extends Control

const SPIN_INTERVAL := 0.065
const MAX_BET := 3
const SETTING := 1
const BIG_GAMES := 55
const REG_GAMES := 14
const BIG_GROSS_PAYOUT := 765
const REG_GROSS_PAYOUT := 162
const SYMBOL_ASSET_BASE := "https://mth310-sys.github.io/Chappy5/src/game/slot-pachiro/machines/zelvolt/symbols/"

const BIG_ODDS := {1: 330.0, 2: 310.0, 3: 290.0, 4: 270.0, 5: 250.0, 6: 210.0}
const REG_ODDS := {1: 470.0, 2: 430.0, 3: 390.0, 4: 350.0, 5: 310.0, 6: 270.0}
const ROLE_ODDS := {
	"REPLAY": 7.3,
	"BELL": 60.0,
	"GRAPE": 50.0,
	"CHERRY": 80.0,
}
const ROLE_PAYOUT := {
	"REPLAY": 0,
	"BELL": 10,
	"GRAPE": 8,
	"CHERRY": 2,
	"MISS": 0,
	"BIG": 0,
	"REG": 0,
}
const SYMBOL_FILES := {
	"7R": "7R.webp",
	"7W": "7W.webp",
	"BAR": "BAR.webp",
	"BELL": "BELL.webp",
	"CHERRY": "CHERRY.webp",
	"GRAPE": "GRAPE.webp",
	"REPLAY": "REPLAY.webp",
}

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
var result_type: String = "MISS"
var target_symbol: String = ""
var total_games: int = 0
var bonus_type: String = ""
var bonus_games_total: int = 0
var bonus_games_played: int = 0
var bonus_gross_paid: int = 0
var symbol_textures: Dictionary = {}
var reel_images: Array = []

func _ready() -> void:
	randomize()
	_build_reel_image_layers()
	_load_symbol_art()
	start_button.pressed.connect(_on_start_pressed)
	bet_button.pressed.connect(_on_bet_pressed)
	max_bet_button.pressed.connect(_on_max_bet_pressed)
	for i in stop_buttons.size():
		stop_buttons[i].pressed.connect(_on_stop_pressed.bind(i))
		stop_buttons[i].disabled = true
	_update_all_reels()
	_refresh_ui()

func _build_reel_image_layers() -> void:
	reel_images.clear()
	for reel in reel_rows:
		var image_row: Array[TextureRect] = []
		for label in reel:
			var image_rect := TextureRect.new()
			image_rect.name = "SymbolArt"
			image_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.add_child(image_rect)
			image_row.append(image_rect)
		reel_images.append(image_row)

func _load_symbol_art() -> void:
	for symbol in SYMBOL_FILES.keys():
		var request := HTTPRequest.new()
		request.name = "SymbolRequest_%s" % symbol
		add_child(request)
		request.request_completed.connect(_on_symbol_request_completed.bind(str(symbol), request))
		var error := request.request(SYMBOL_ASSET_BASE + str(SYMBOL_FILES[symbol]))
		if error != OK:
			request.queue_free()

func _on_symbol_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, symbol: String, request: HTTPRequest) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
		var image := Image.new()
		var image_error := image.load_webp_from_buffer(body)
		if image_error == OK:
			symbol_textures[symbol] = ImageTexture.create_from_image(image)
			_update_all_reels()
	request.queue_free()

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
	if spinning.has(true) or _in_bonus():
		return
	if bet >= MAX_BET or credit <= 0:
		return
	credit -= 1
	bet += 1
	payout = 0
	_refresh_ui()

func _on_max_bet_pressed() -> void:
	if spinning.has(true) or _in_bonus():
		return
	while bet < MAX_BET and credit > 0:
		credit -= 1
		bet += 1
	payout = 0
	_refresh_ui()

func _on_start_pressed() -> void:
	if spinning.has(true):
		return

	if _in_bonus():
		_start_bonus_spin()
		return

	if bet != MAX_BET:
		status_label.text = "BET 3 TO START"
		return

	_choose_result()
	_start_reels()
	payout = 0
	status_label.text = "SPINNING - STOP 1 / 2 / 3"
	_refresh_controls()
	_refresh_counters()

func _start_bonus_spin() -> void:
	if bonus_games_played >= bonus_games_total:
		_finish_bonus()
		return
	result_type = "BONUS"
	target_symbol = "BELL"
	_start_reels()
	payout = 0
	status_label.text = "%s %d/%d - STOP 1 / 2 / 3" % [bonus_type, bonus_games_played + 1, bonus_games_total]
	_refresh_controls()
	_refresh_counters()

func _start_reels() -> void:
	for i in spinning.size():
		spinning[i] = true
		reel_accum[i] = 0.0
		stop_buttons[i].disabled = false

func _on_stop_pressed(index: int) -> void:
	if index < 0 or index >= spinning.size():
		return
	if not spinning[index]:
		return

	spinning[index] = false
	stop_buttons[index].disabled = true

	if _in_bonus():
		_set_reel_middle_to_symbol(index, "BELL")
	else:
		_apply_result_stop(index)
	_update_reel(index)

	if spinning.has(true):
		status_label.text = "SPINNING - STOP REMAINING REELS"
	else:
		if _in_bonus():
			_resolve_bonus_spin()
		else:
			_resolve_result()

func _choose_result() -> void:
	var roll: float = randf()
	var edge: float = 0.0

	edge += 1.0 / BIG_ODDS[SETTING]
	if roll < edge:
		result_type = "BIG"
		target_symbol = "7R" if randf() < 0.8 else "7W"
		return

	edge += 1.0 / REG_ODDS[SETTING]
	if roll < edge:
		result_type = "REG"
		target_symbol = "BAR"
		return

	for role in ["REPLAY", "BELL", "GRAPE", "CHERRY"]:
		edge += 1.0 / float(ROLE_ODDS[role])
		if roll < edge:
			result_type = role
			target_symbol = role
			return

	result_type = "MISS"
	target_symbol = ""

func _apply_result_stop(reel: int) -> void:
	if result_type in ["BIG", "REG", "REPLAY", "BELL", "GRAPE"]:
		_set_reel_middle_to_symbol(reel, target_symbol)
	elif result_type == "CHERRY" and reel == 0:
		_set_reel_middle_to_symbol(reel, "CHERRY")

func _set_reel_middle_to_symbol(reel: int, symbol: String) -> void:
	var strip: Array = REEL_STRIPS[reel]
	for i in strip.size():
		if str(strip[i]) == symbol:
			reel_index[reel] = i
			return

func _resolve_result() -> void:
	total_games += 1
	payout = int(ROLE_PAYOUT[result_type])
	credit += payout

	if result_type == "REPLAY":
		bet = MAX_BET
		status_label.text = "REPLAY - PRESS START"
	elif result_type == "BIG":
		bet = 0
		_begin_bonus("BIG")
		return
	elif result_type == "REG":
		bet = 0
		_begin_bonus("REG")
		return
	else:
		bet = 0
		if result_type == "MISS":
			status_label.text = "MISS - BET 3 TO START"
		else:
			status_label.text = "%s +%d - BET 3 TO START" % [result_type, payout]

	_refresh_counters()
	_refresh_controls()

func _begin_bonus(kind: String) -> void:
	bonus_type = kind
	bonus_games_played = 0
	bonus_gross_paid = 0
	bonus_games_total = BIG_GAMES if kind == "BIG" else REG_GAMES
	payout = 0
	status_label.text = "%s BONUS START - PRESS START" % bonus_type
	_refresh_counters()
	_refresh_controls()

func _resolve_bonus_spin() -> void:
	var total_gross: int = BIG_GROSS_PAYOUT if bonus_type == "BIG" else REG_GROSS_PAYOUT
	var remaining_games: int = bonus_games_total - bonus_games_played
	var remaining_gross: int = total_gross - bonus_gross_paid
	var gross_this_game: int = int(ceil(float(remaining_gross) / float(remaining_games)))
	var net_this_game: int = gross_this_game - MAX_BET

	payout = gross_this_game
	credit += net_this_game
	bonus_gross_paid += gross_this_game
	bonus_games_played += 1
	total_games += 1

	if bonus_games_played >= bonus_games_total:
		_finish_bonus()
	else:
		status_label.text = "%s %d/%d  PAY %d  NET +%d - PRESS START" % [bonus_type, bonus_games_played, bonus_games_total, gross_this_game, net_this_game]
		_refresh_counters()
		_refresh_controls()

func _finish_bonus() -> void:
	var finished_type: String = bonus_type
	var net_total: int = 600 if finished_type == "BIG" else 120
	bonus_type = ""
	bonus_games_total = 0
	bonus_games_played = 0
	bonus_gross_paid = 0
	bet = 0
	status_label.text = "%s END  NET +%d - BET 3 TO START" % [finished_type, net_total]
	_refresh_counters()
	_refresh_controls()

func _in_bonus() -> bool:
	return bonus_type != ""

func _refresh_ui() -> void:
	_refresh_counters()
	_refresh_controls()
	if not spinning.has(true):
		if _in_bonus():
			status_label.text = "%s BONUS - PRESS START" % bonus_type
		elif bet == MAX_BET:
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
	var active_spin: bool = spinning.has(true)
	start_button.disabled = active_spin or (not _in_bonus() and bet != MAX_BET)
	bet_button.disabled = active_spin or _in_bonus() or bet >= MAX_BET or credit <= 0
	max_bet_button.disabled = active_spin or _in_bonus() or bet >= MAX_BET or credit <= 0
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
	_set_reel_cell(reel, 0, str(strip[top]))
	_set_reel_cell(reel, 1, str(strip[middle]))
	_set_reel_cell(reel, 2, str(strip[bottom]))

func _set_reel_cell(reel: int, row: int, symbol: String) -> void:
	var label: Label = reel_rows[reel][row]
	var image_rect: TextureRect = reel_images[reel][row]
	if symbol_textures.has(symbol):
		label.text = ""
		image_rect.texture = symbol_textures[symbol]
		image_rect.visible = true
	else:
		image_rect.texture = null
		image_rect.visible = false
		label.text = symbol
