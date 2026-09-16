extends Node3D

const OLD_GRID_SIZE: int = 18
const NEW_GRID_SIZE: int = 22
const TILE_SIZE: float = 1.0

func _ready() -> void:
	_build_outer_ring()

func _build_outer_ring() -> void:
	var old_half: float = float(OLD_GRID_SIZE - 1) * 0.5
	var new_half: float = float(NEW_GRID_SIZE - 1) * 0.5
	for z in range(NEW_GRID_SIZE):
		for x in range(NEW_GRID_SIZE):
			var world_x: float = float(x) - new_half
			var world_z: float = float(z) - new_half
			# The original 18x18 floor remains untouched. Add only the two-cell perimeter.
			if absf(world_x) <= old_half and absf(world_z) <= old_half:
				continue
			var tile: MeshInstance3D = MeshInstance3D.new()
			var mesh: BoxMesh = BoxMesh.new()
			mesh.size = Vector3(TILE_SIZE, 0.04, TILE_SIZE)
			tile.mesh = mesh
			tile.position = Vector3(world_x, -0.02, world_z)
			var shade: float = 0.72 if (x + z) % 2 == 0 else 0.58
			tile.material_override = _material(Color(shade, shade, shade))
			add_child(tile)

func _material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	return material
