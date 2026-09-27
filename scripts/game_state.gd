extends Node

var world_initialized := false
var world_map_data: Array = []
var world_buildings: Dictionary = {}
var next_lot_id := 1
var next_building_id := 1
var selected_building_id := ""
var hall_states: Dictionary = {}

func store_world(map_data: Array, buildings: Dictionary, lot_id: int, building_id: int) -> void:
	world_map_data = map_data.duplicate(true)
	world_buildings = buildings.duplicate(true)
	next_lot_id = lot_id
	next_building_id = building_id
	world_initialized = true

func store_hall(building_id: String, map_data: Array, islands: Dictionary, next_island_id: int, machines: Dictionary = {}, next_machine_id: int = 1) -> void:
	hall_states[building_id] = {
		"map_data": map_data.duplicate(true),
		"islands": islands.duplicate(true),
		"next_island_id": next_island_id,
		"machines": machines.duplicate(true),
		"next_machine_id": next_machine_id
	}

func get_hall(building_id: String) -> Dictionary:
	return hall_states.get(building_id, {})

func clear_world() -> void:
	world_initialized = false
	world_map_data.clear()
	world_buildings.clear()
	next_lot_id = 1
	next_building_id = 1
	selected_building_id = ""
