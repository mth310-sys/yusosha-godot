extends Node3D

const TILE_SIZE: float = 1.0

func _ready() -> void:
	# Character-structure development only. Keep AI/seat tests parked until the
	# articulated body is visually approved.
	name = "CharacterPreview"
	position = Vector3(-7.5,0.0,-9.5)

	var eita := PachirouCustomerCharacter.new()
	eita.name = "Eita"
	add_child(eita)
	eita.build()
	eita.set_standing_pose()

	var bita := PachirouCustomerCharacter.new()
	bita.name = "Bita"
	bita.position = Vector3(TILE_SIZE,0.0,0.0)
	add_child(bita)
	bita.build()
	bita.set_standing_pose()
