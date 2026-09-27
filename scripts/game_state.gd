extends Node

var world_initialized := false
var world_map_data: Array = []
var world_buildings: Dictionary = {}
var next_lot_id := 1
var next_building_id := 1
var selected_building_id := ""

func store_world(map_data: Array, buildings: Dictionary, lot_id: int, building_id: int) -> void:
	world_map_data = map_data.duplicate(true)
	world_buildings = buildings.duplicate(true)
	next_lot_id = lot_id
	next_building_id = building_id
	world_initialized = true

func clear_world() -> void:
	world_initialized = false
	world_map_data.clear()
	world_buildings.clear()
	next_lot_id = 1
	next_building_id = 1
	selected_building_id = ""
