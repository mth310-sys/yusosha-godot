class_name PachirouDataCounterState
extends RefCounted

signal changed
signal bonus_registered(kind: String)
signal call_state_changed(active: bool)

var machine_number: int = 0
var total_games: int = 0
var current_games: int = 0
var big_count: int = 0
var reg_count: int = 0
var at_count: int = 0
var total_in: int = 0
var total_out: int = 0
var current_medals: int = 0
var max_medals: int = 0
var is_occupied: bool = false
var call_active: bool = false
var bonus_history: Array[Dictionary] = []
var medal_history: Array[int] = [0]

func setup(number: int) -> void:
	machine_number = number
	changed.emit()

func register_game(bet: int = 3,payout: int = 0) -> void:
	total_games += 1
	current_games += 1
	total_in += maxi(0,bet)
	total_out += maxi(0,payout)
	current_medals += payout-bet
	max_medals = maxi(max_medals,current_medals)
	medal_history.append(current_medals)
	if medal_history.size() > 48: medal_history.pop_front()
	changed.emit()

func register_bonus(kind: String,payout: int = 0) -> void:
	var normalized := kind.to_upper()
	match normalized:
		"BIG": big_count += 1
		"REG": reg_count += 1
		"AT": at_count += 1
	bonus_history.push_front({"kind":normalized,"games":current_games,"payout":payout})
	if bonus_history.size() > 12: bonus_history.pop_back()
	current_games = 0
	bonus_registered.emit(normalized)
	changed.emit()

func set_occupied(value: bool) -> void:
	is_occupied = value
	changed.emit()

func set_call_active(value: bool) -> void:
	if call_active == value: return
	call_active = value
	call_state_changed.emit(value)
	changed.emit()

func difference() -> int:
	return total_out-total_in
