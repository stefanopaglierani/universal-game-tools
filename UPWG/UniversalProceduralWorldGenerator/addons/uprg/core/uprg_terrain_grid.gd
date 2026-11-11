class_name UPRGTerrainGrid
extends RefCounted
## Editable copy of the heights of a baked terrain (metadata "terrain_data", format 1).

const SUPPORTED_FORMAT: int = 1

var cells_x: int
var cells_z: int
var cell_size: float
var sea_level: float
var heights: PackedFloat32Array


## Returns the grid, or null when the metadata is missing or of another format.
static func from_meta(meta: Dictionary) -> UPRGTerrainGrid:
	if meta.get("format_version", -1) != SUPPORTED_FORMAT:
		return null
	var grid := UPRGTerrainGrid.new()
	grid.cells_x = meta.grid_cells_x
	grid.cells_z = meta.grid_cells_z
	grid.cell_size = meta.cell_size
	grid.sea_level = meta.sea_level
	grid.heights = (meta.heights as PackedFloat32Array).duplicate()
	if grid.heights.size() != (grid.cells_x + 1) * (grid.cells_z + 1):
		return null
	return grid


func index(ix: int, iz: int) -> int:
	return iz * (cells_x + 1) + ix


func vertex_x(ix: int) -> float:
	return (ix - cells_x / 2.0) * cell_size


func vertex_z(iz: int) -> float:
	return (iz - cells_z / 2.0) * cell_size


## True when (x, z) is at least [param margin] meters inside the grid.
func is_inside(p: Vector2, margin: float) -> bool:
	return absf(p.x) <= cells_x * cell_size * 0.5 - margin and absf(p.y) <= cells_z * cell_size * 0.5 - margin


## Height at (x, z) on the terrain triangles, with the same diagonal as the mesh and the collision.
func height_at(p: Vector2) -> float:
	var gx := p.x / cell_size + cells_x / 2.0
	var gz := p.y / cell_size + cells_z / 2.0
	var ix := clampi(int(floor(gx)), 0, cells_x - 1)
	var iz := clampi(int(floor(gz)), 0, cells_z - 1)
	var fx := gx - ix
	var fz := gz - iz
	var h00 := heights[index(ix, iz)]
	var h10 := heights[index(ix + 1, iz)]
	var h01 := heights[index(ix, iz + 1)]
	var h11 := heights[index(ix + 1, iz + 1)]
	if fx + fz <= 1.0:
		return h00 + fx * (h10 - h00) + fz * (h01 - h00)
	return h11 + (1.0 - fx) * (h01 - h11) + (1.0 - fz) * (h10 - h11)


## Unit normal of vertex (ix, iz), from central differences as in the UPTG mesh.
func normal_at_vertex(ix: int, iz: int) -> Vector3:
	var left := heights[index(maxi(ix - 1, 0), iz)]
	var right := heights[index(mini(ix + 1, cells_x), iz)]
	var back := heights[index(ix, maxi(iz - 1, 0))]
	var front := heights[index(ix, mini(iz + 1, cells_z))]
	var span_x := cell_size * (mini(ix + 1, cells_x) - maxi(ix - 1, 0))
	var span_z := cell_size * (mini(iz + 1, cells_z) - maxi(iz - 1, 0))
	return Vector3((left - right) / span_x, 1.0, (back - front) / span_z).normalized()
