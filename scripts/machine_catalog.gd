extends Node

const DEFAULT_MODEL_ID := "prototype_a"

var models: Dictionary = {
	"prototype_a": {
		"id": "prototype_a",
		"name": "遊創舎テストスロット",
		"category": "slot",
		"maker": "遊創舎",
		"purchase_price": 500000,
		"settings": [1, 2, 3, 4, 5, 6]
	}
}

func get_model(model_id: String) -> Dictionary:
	return models.get(model_id, {})

func get_default_model() -> Dictionary:
	return get_model(DEFAULT_MODEL_ID)
