class_name UPTGTerrainData
extends RefCounted
## Result of a UPTG generation and official contract between UPTG and other
## systems (architecture 0.2, section 9). Treat it as read-only.
##
## All positions are in the local space of the terrain node: the terrain is
## centered on the origin, X and Z are horizontal, Y is height. Vertex
## [code](ix, iz)[/code] is stored at index [code]iz * vertex_count_x + ix[/code].
## Every cell is split along the diagonal from vertex [code](ix + 1, iz)[/code]
## to vertex [code](ix, iz + 1)[/code], the same diagonal used by
## [HeightMapShape3D] (verified in Milestone 0), so [method get_height_at]
## matches what is rendered and what collides.

## Version of the generation algorithm that produced the data.
const ALGORITHM_VERSION: int = 1

## Seed used for the generation.
var generation_seed: int = 0
## FNV-1a 32-bit checksum of the parameters that influence the heights.
var config_checksum: int = 0
## Cells along X.
var grid_cells_x: int = 0
## Cells along Z.
var grid_cells_z: int = 0
## Vertices along X (cells + 1).
var vertex_count_x: int = 0
## Vertices along Z (cells + 1).
var vertex_count_z: int = 0
## Side of a square cell, in meters.
var cell_size: float = 1.0
## Total size (X, Z) in meters.
var size: Vector2 = Vector2.ZERO
## Sea level height.
var sea_level: float = 0.0
## Depth of the sea floor below [member sea_level]; also returned outside the grid.
var sea_floor_depth: float = 0.0
## Lowest height in [member heights].
var min_height: float = 0.0
## Highest height in [member heights].
var max_height: float = 0.0
## Heights in local space, index [code]iz * vertex_count_x + ix[/code].
var heights: PackedFloat32Array = PackedFloat32Array()
## Island mask (0 = sea, 1 = inland) per vertex, same indexing as [member heights].
var land_mask: PackedFloat32Array = PackedFloat32Array()
## FNV-1a 32-bit checksum of [member heights] (computed on first access).
var heights_checksum: int:
	get:
		if _heights_checksum < 0:
			_heights_checksum = fnv1a32(heights.to_byte_array())
		return _heights_checksum

var _heights_checksum: int = -1


## Height of vertex ([param ix], [param iz]).
func get_vertex_height(ix: int, iz: int) -> float:
	return heights[iz * vertex_count_x + ix]


## Local position of vertex ([param ix], [param iz]).
func get_vertex_position(ix: int, iz: int) -> Vector3:
	return Vector3((ix - grid_cells_x * 0.5) * cell_size, heights[iz * vertex_count_x + ix], (iz - grid_cells_z * 0.5) * cell_size)


## Smooth vertex normal from central differences (one-sided at the borders), as used by the mesh.
func get_vertex_normal(ix: int, iz: int) -> Vector3:
	var x0: int = maxi(ix - 1, 0)
	var x1: int = mini(ix + 1, grid_cells_x)
	var z0: int = maxi(iz - 1, 0)
	var z1: int = mini(iz + 1, grid_cells_z)
	var dx: float = (heights[iz * vertex_count_x + x0] - heights[iz * vertex_count_x + x1]) / float(x1 - x0)
	var dz: float = (heights[z0 * vertex_count_x + ix] - heights[z1 * vertex_count_x + ix]) / float(z1 - z0)
	return Vector3(dx, cell_size, dz).normalized()


## True if the local point ([param x], [param z]) lies on the grid.
func is_inside(x: float, z: float) -> bool:
	return absf(x) <= size.x * 0.5 and absf(z) <= size.y * 0.5


## Height at the local point ([param x], [param z]), interpolated on the triangles.
## Outside the grid returns [code]sea_level - sea_floor_depth[/code].
func get_height_at(x: float, z: float) -> float:
	if not is_inside(x, z):
		return sea_level - sea_floor_depth
	return _interpolate(heights, x, z)


## Island mask at the local point, interpolated on the triangles (0 outside the grid).
func get_mask_at(x: float, z: float) -> float:
	if not is_inside(x, z):
		return 0.0
	return _interpolate(land_mask, x, z)


## Normal at the local point, interpolated from the vertex normals of the containing triangle.
func get_normal_at(x: float, z: float) -> Vector3:
	if not is_inside(x, z):
		return Vector3.UP
	var c := _locate(x, z)
	var cx: int = c[0]
	var cz: int = c[1]
	var fx: float = c[2]
	var fz: float = c[3]
	var n00 := get_vertex_normal(cx, cz)
	var n10 := get_vertex_normal(cx + 1, cz)
	var n01 := get_vertex_normal(cx, cz + 1)
	var n11 := get_vertex_normal(cx + 1, cz + 1)
	var n: Vector3
	if fx + fz <= 1.0:
		n = n00 + (n10 - n00) * fx + (n01 - n00) * fz
	else:
		n = n11 + (n01 - n11) * (1.0 - fx) + (n10 - n11) * (1.0 - fz)
	return n.normalized()


## True if the local point is on the grid and above [member sea_level].
func is_land_at(x: float, z: float) -> bool:
	return is_inside(x, z) and get_height_at(x, z) > sea_level


## FNV-1a 32-bit hash of [param bytes]. Stable across engine versions, unlike [method @GlobalScope.hash].
static func fnv1a32(bytes: PackedByteArray) -> int:
	var h: int = 2166136261
	for b in bytes:
		h = ((h ^ b) * 16777619) & 0xFFFFFFFF
	return h


## Returns [cx, cz, fx, fz]: cell indices and fractional position inside the cell.
func _locate(x: float, z: float) -> Array:
	var gx: float = x / cell_size + grid_cells_x * 0.5
	var gz: float = z / cell_size + grid_cells_z * 0.5
	var cx: int = clampi(int(floor(gx)), 0, grid_cells_x - 1)
	var cz: int = clampi(int(floor(gz)), 0, grid_cells_z - 1)
	return [cx, cz, clampf(gx - cx, 0.0, 1.0), clampf(gz - cz, 0.0, 1.0)]


func _interpolate(values: PackedFloat32Array, x: float, z: float) -> float:
	var c := _locate(x, z)
	var cx: int = c[0]
	var cz: int = c[1]
	var fx: float = c[2]
	var fz: float = c[3]
	var i00: int = cz * vertex_count_x + cx
	var v00: float = values[i00]
	var v10: float = values[i00 + 1]
	var v01: float = values[i00 + vertex_count_x]
	var v11: float = values[i00 + vertex_count_x + 1]
	# Triangles (00, 10, 01) and (10, 11, 01): diagonal from (ix + 1, iz) to (ix, iz + 1).
	if fx + fz <= 1.0:
		return v00 + fx * (v10 - v00) + fz * (v01 - v00)
	return v11 + (1.0 - fx) * (v01 - v11) + (1.0 - fz) * (v10 - v11)
