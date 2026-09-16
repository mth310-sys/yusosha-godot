extends Node3D

const GRID_SIZE: int = 14
const TILE_SIZE: float = 1.0

func _ready() -> void:
	_build_floor()

func _build_floor() -> void:
	for z in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(TILE_SIZE, 0.04, TILE_SIZE)
			tile.mesh = mesh
			tile.position = _cell_to_world(Vector2i(x, z)) + Vector3(0.0, -0.02, 0.0)
			var material := StandardMaterial3D.new()
			var shade: float = 0.72 if (x + z) % 2 == 0 else 0.58
			material.albedo_color = Color(shade, shade, shade)
			tile.material_override = material
			$World.add_child(tile)

func _cell_to_world(cell: Vector2i) -> Vector3:
	var half: float = float(GRID_SIZE - 1) * 0.5
	return Vector3(float(cell.x) - half, 0.0, float(cell.y) - half)
