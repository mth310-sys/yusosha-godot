extends Node3D

const TILE_SIZE: float = 1.0
const BITA_SEATED_Y: float = 0.45

func _ready() -> void:
	# Character-structure development only. Eita remains the standing reference;
	# Bita tests the same articulated body in a seated pose beside him.
	name = "CharacterPreview"
	position = Vector3(-7.5,0.0,-9.5)

	var eita := PachirouCustomerCharacter.new()
	eita.name = "Eita"
	add_child(eita)
	eita.build()
	eita.set_standing_pose()

	var bita := PachirouCustomerCharacter.new()
	bita.name = "Bita"
	bita.position = Vector3(TILE_SIZE,BITA_SEATED_Y,0.0)
	add_child(bita)
	bita.build()
	bita.set_seated_pose()
