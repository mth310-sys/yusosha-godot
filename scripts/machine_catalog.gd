extends Node

const DEFAULT_MODEL_ID := "prototype_a"
const MODEL_ORDER := ["prototype_a", "neo_a", "rush_at", "storm_at", "classic_slot"]

var models: Dictionary = {
	"prototype_a": {
		"id": "prototype_a",
		"name": "遊創舎テスト",
		"category": "Aタイプ",
		"maker": "遊創舎",
		"purchase_price": 500000,
		"popularity": 1.00,
		"volatility": 0.08,
		"body_color": "4056a1",
		"payout_rates": [0.965, 0.980, 0.995, 1.015, 1.040, 1.070]
	},
	"neo_a": {
		"id": "neo_a",
		"name": "ネオスターA",
		"category": "Aタイプ",
		"maker": "遊創舎",
		"purchase_price": 420000,
		"popularity": 0.95,
		"volatility": 0.06,
		"body_color": "2f8f83",
		"payout_rates": [0.970, 0.980, 0.990, 1.010, 1.030, 1.055]
	},
	"rush_at": {
		"id": "rush_at",
		"name": "ラッシュギア",
		"category": "AT",
		"maker": "遊創舎",
		"purchase_price": 650000,
		"popularity": 1.15,
		"volatility": 0.14,
		"body_color": "b34b4b",
		"payout_rates": [0.970, 0.985, 1.000, 1.025, 1.055, 1.100]
	},
	"storm_at": {
		"id": "storm_at",
		"name": "爆裂ストーム",
		"category": "荒波AT",
		"maker": "遊創舎",
		"purchase_price": 780000,
		"popularity": 1.25,
		"volatility": 0.22,
		"body_color": "8d4ca6",
		"payout_rates": [0.965, 0.980, 1.000, 1.030, 1.070, 1.120]
	},
	"classic_slot": {
		"id": "classic_slot",
		"name": "クラシック7",
		"category": "旧台",
		"maker": "遊創舎",
		"purchase_price": 180000,
		"popularity": 0.72,
		"volatility": 0.10,
		"body_color": "9a7738",
		"payout_rates": [0.955, 0.970, 0.985, 1.000, 1.020, 1.045]
	}
}

func get_model(model_id: String) -> Dictionary:
	return models.get(model_id, {})

func get_default_model() -> Dictionary:
	return get_model(DEFAULT_MODEL_ID)

func get_model_id_by_index(index: int) -> String:
	if index < 0 or index >= MODEL_ORDER.size():
		return DEFAULT_MODEL_ID
	return MODEL_ORDER[index]

func get_model_by_index(index: int) -> Dictionary:
	return get_model(get_model_id_by_index(index))
