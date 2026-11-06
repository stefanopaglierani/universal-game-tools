class_name UPTGConfig
extends Resource
## All parameters that define a UPTG terrain (architecture 0.2, section 5).
##
## Save it as a [code].tres[/code] preset. Values here are provisional defaults;
## the final island preset is tuned after the demo (decision D7).

## Collision representation built for the terrain (architecture 0.2, section 11).
enum CollisionMode {
	HEIGHTMAP, ## [HeightMapShape3D] (default).
	TRIMESH, ## [ConcavePolygonShape3D] built from the mesh triangles.
	NONE, ## No collision.
}

## Result of [method estimate_cost] (architecture 0.2, section 5.4).
enum CostLevel {
	OK, ## Normal generation.
	LARGE, ## Refused unless the caller explicitly allows large terrains.
	REJECTED, ## Always refused.
}

## Above this many cells a configuration is [constant CostLevel.LARGE] (512 x 512).
const MAX_CELLS_OK: int = 262144
## Same threshold when [member collision_mode] is [constant CollisionMode.TRIMESH] (256 x 256).
const MAX_CELLS_OK_TRIMESH: int = 65536
## Hard limit on the total number of cells (1024 x 1024).
const MAX_CELLS_HARD: int = 1048576
## Hard limit on cells per axis.
const MAX_CELLS_PER_AXIS: int = 1024
## Minimum cells per axis.
const MIN_CELLS_PER_AXIS: int = 2
## Estimated memory above which a configuration is [constant CostLevel.LARGE].
const MAX_BYTES_OK: int = 128 * 1024 * 1024
## Estimated memory above which a configuration is [constant CostLevel.REJECTED].
const MAX_BYTES_HARD: int = 512 * 1024 * 1024
## Memory estimate per vertex, in bytes: height field and mask (8), heightmap collision (4),
## mesh vertex buffers on the GPU (about 30) and the CPU arrays alive while the mesh is built (48),
## rounded up. Calibrated with the Milestone D measurements (documentation/TESTING.md).
const BYTES_PER_VERTEX: int = 112
## Memory estimate per cell for mesh indices, in bytes: GPU index buffer (24) and the CPU copy
## alive while the mesh is built (24). Calibrated in Milestone D.
const BYTES_PER_CELL: int = 48
## Extra memory per cell for TRIMESH collision, in bytes: faces plus the physics engine's own
## structures, measured at 320 bytes per cell in Milestone D.
const BYTES_PER_CELL_TRIMESH: int = 320
## The island coastline may not reach further than this normalized distance from the center.
const MAX_COAST_EXTENT: float = 0.9
## Octaves used by the coastline noise.
const COASTLINE_OCTAVES: int = 2

@export_group("Seed")
## Master seed. Every random stage derives its own sub-seed from it ([UPTGSeed]).
@export_range(0, 2147483647) var generation_seed: int = 12345

@export_group("Grid")
## Number of cells along X. Vertices along X = cells + 1.
@export_range(2, 1024) var grid_cells_x: int = 256
## Number of cells along Z. Vertices along Z = cells + 1.
@export_range(2, 1024) var grid_cells_z: int = 256
## Side of a square cell, in meters.
@export_range(0.25, 64.0, 0.01, "suffix:m") var cell_size: float = 4.0

@export_group("Sea")
## Height of the sea level.
@export_range(-1000.0, 1000.0, 0.01, "or_less", "or_greater", "suffix:m") var sea_level: float = 0.0
## Depth of the sea floor below [member sea_level] where the island mask is 0.
@export_range(0.5, 500.0, 0.1, "suffix:m") var sea_floor_depth: float = 20.0

@export_group("Island")
## Normalized radii of the base ellipse (0.1..0.85 per axis).
@export var island_radius: Vector2 = Vector2(0.6, 0.6)
## Strength of the coastline perturbation.
@export_range(0.0, 0.5, 0.001) var coastline_irregularity: float = 0.25
## Coastline noise frequency, in cycles per meter (about 1 / feature size).
@export_range(0.0001, 0.1, 0.0001) var coastline_noise_frequency: float = 0.004
## Normalized width of the land-to-sea transition.
@export_range(0.01, 0.8, 0.001) var coastline_falloff_width: float = 0.25

@export_group("Relief")
## Average inland height above [member sea_level].
@export_range(0.0, 500.0, 0.1, "suffix:m") var land_base_height: float = 8.0
## Minimum inland height above [member sea_level]; prevents inland lakes in v0.1.
@export_range(0.0, 50.0, 0.1, "suffix:m") var min_land_height: float = 2.5
## Relief noise frequency, in cycles per meter.
@export_range(0.0001, 0.1, 0.0001) var terrain_noise_frequency: float = 0.006
## Amplitude of the hills.
@export_range(0.0, 500.0, 0.1, "suffix:m") var terrain_noise_amplitude: float = 10.0
## Fractal octaves of the relief noise.
@export_range(1, 8) var noise_octaves: int = 4
## Fractal lacunarity of the relief noise.
@export_range(1.0, 4.0, 0.01) var noise_lacunarity: float = 2.0
## Fractal gain of the relief noise.
@export_range(0.0, 1.0, 0.01) var noise_gain: float = 0.5

@export_group("Mountains")
## Mountain regions (at most 16).
@export var mountain_regions: Array[UPTGMountainRegion] = []

@export_group("Collision")
## Collision representation built by the terrain node.
@export var collision_mode: CollisionMode = CollisionMode.HEIGHTMAP

@export_group("Appearance")
## Meters covered by one UV repetition.
@export_range(0.1, 1000.0, 0.1, "suffix:m") var uv_tile_size: float = 8.0
## Vertex color near the sea.
@export var sand_color: Color = Color(0.76, 0.70, 0.50)
## Vertex color of the inland.
@export var grass_color: Color = Color(0.35, 0.50, 0.25)
## Vertex color of steep or high ground.
@export var rock_color: Color = Color(0.45, 0.43, 0.40)
## Height band above [member sea_level] colored as sand.
@export_range(0.0, 50.0, 0.1, "suffix:m") var beach_height: float = 1.5
## Slope above which the color tends to rock.
@export_range(0.0, 90.0, 0.1, "suffix:°") var rock_slope_degrees: float = 38.0
## Height above which the color tends to rock.
@export_range(0.0, 2000.0, 0.1, "suffix:m") var rock_height: float = 60.0


func _init() -> void:
	# Provisional default: one central mountain. A loaded preset replaces this list.
	mountain_regions.append(UPTGMountainRegion.new())


## Vertices along X.
func get_vertex_count_x() -> int:
	return grid_cells_x + 1


## Vertices along Z.
func get_vertex_count_z() -> int:
	return grid_cells_z + 1


## Terrain size (X, Z) in meters.
func get_size() -> Vector2:
	return Vector2(grid_cells_x * cell_size, grid_cells_z * cell_size)


## Returns the list of validation errors (empty when valid). Does not check the cost; see [method estimate_cost].
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if generation_seed < 0 or generation_seed > UPTGSeed.MAX_SEED:
		errors.append("generation_seed must be within 0..%d (got %d)" % [UPTGSeed.MAX_SEED, generation_seed])
	_check_int(errors, "grid_cells_x", grid_cells_x, MIN_CELLS_PER_AXIS, MAX_CELLS_PER_AXIS)
	_check_int(errors, "grid_cells_z", grid_cells_z, MIN_CELLS_PER_AXIS, MAX_CELLS_PER_AXIS)
	_check_float(errors, "cell_size", cell_size, 0.25, 64.0)
	if not is_finite(sea_level):
		errors.append("sea_level must be a finite number")
	_check_float(errors, "sea_floor_depth", sea_floor_depth, 0.5, 500.0)
	_check_float(errors, "island_radius.x", island_radius.x, 0.1, 0.85)
	_check_float(errors, "island_radius.y", island_radius.y, 0.1, 0.85)
	_check_float(errors, "coastline_irregularity", coastline_irregularity, 0.0, 0.5)
	_check_float(errors, "coastline_noise_frequency", coastline_noise_frequency, 0.0001, 0.1)
	_check_float(errors, "coastline_falloff_width", coastline_falloff_width, 0.01, 0.8)
	_check_float(errors, "land_base_height", land_base_height, 0.0, 500.0)
	_check_float(errors, "min_land_height", min_land_height, 0.0, 50.0)
	_check_float(errors, "terrain_noise_frequency", terrain_noise_frequency, 0.0001, 0.1)
	_check_float(errors, "terrain_noise_amplitude", terrain_noise_amplitude, 0.0, 500.0)
	_check_int(errors, "noise_octaves", noise_octaves, 1, 8)
	_check_float(errors, "noise_lacunarity", noise_lacunarity, 1.0, 4.0)
	_check_float(errors, "noise_gain", noise_gain, 0.0, 1.0)
	_check_float(errors, "uv_tile_size", uv_tile_size, 0.1, 1000.0)
	_check_float(errors, "beach_height", beach_height, 0.0, 50.0)
	_check_float(errors, "rock_slope_degrees", rock_slope_degrees, 0.0, 90.0)
	_check_float(errors, "rock_height", rock_height, 0.0, 2000.0)
	# Coastline constraint (section 5.3): the perturbed coast must stay inside the edge band.
	if is_finite(island_radius.x) and is_finite(island_radius.y) and is_finite(coastline_irregularity) \
			and coastline_irregularity >= 0.0 and coastline_irregularity < 1.0:
		var extent: float = maxf(island_radius.x, island_radius.y) / (1.0 - coastline_irregularity)
		if extent > MAX_COAST_EXTENT + 1e-6:
			errors.append("island too large for its coastline_irregularity: max(island_radius) / (1 - coastline_irregularity) = %.3f, must be <= %.1f" % [extent, MAX_COAST_EXTENT])
	if mountain_regions.size() > 16:
		errors.append("at most 16 mountain_regions are allowed (got %d)" % mountain_regions.size())
	for i in mountain_regions.size():
		var region: UPTGMountainRegion = mountain_regions[i]
		if region == null:
			errors.append("mountain_regions[%d] is empty" % i)
		else:
			errors.append_array(region.validate("mountain_regions[%d]" % i))
	return errors


## Estimates the cost of generating this configuration, without generating anything
## (architecture 0.2, section 5.4). Returns a [Dictionary] with the keys
## [code]cells[/code], [code]vertices[/code], [code]triangles[/code], [code]noise_samples[/code],
## [code]estimated_bytes[/code] and [code]level[/code] (a [enum CostLevel]).
func estimate_cost() -> Dictionary:
	var cx: int = maxi(grid_cells_x, 0)
	var cz: int = maxi(grid_cells_z, 0)
	var cells: int = cx * cz
	var vertices: int = (cx + 1) * (cz + 1)
	var bytes: int = vertices * BYTES_PER_VERTEX + cells * BYTES_PER_CELL
	if collision_mode == CollisionMode.TRIMESH:
		bytes += cells * BYTES_PER_CELL_TRIMESH
	var ok_cells: int = MAX_CELLS_OK_TRIMESH if collision_mode == CollisionMode.TRIMESH else MAX_CELLS_OK
	var level: CostLevel = CostLevel.OK
	if cx > MAX_CELLS_PER_AXIS or cz > MAX_CELLS_PER_AXIS or cells > MAX_CELLS_HARD or bytes > MAX_BYTES_HARD:
		level = CostLevel.REJECTED
	elif cells > ok_cells or bytes > MAX_BYTES_OK:
		level = CostLevel.LARGE
	return {
		"cells": cells,
		"vertices": vertices,
		"triangles": 2 * cells,
		"noise_samples": vertices * (noise_octaves + COASTLINE_OCTAVES),
		"estimated_bytes": bytes,
		"level": level,
	}


## Ordered list of every parameter that influences the heights (used for the config checksum).
func get_height_parameters() -> Array:
	var regions: Array = []
	for region in mountain_regions:
		if region != null:
			regions.append([region.center, region.radius, region.peak_height, region.falloff])
	return [
		generation_seed, grid_cells_x, grid_cells_z, cell_size,
		sea_level, sea_floor_depth,
		island_radius, coastline_irregularity, coastline_noise_frequency, coastline_falloff_width,
		land_base_height, min_land_height, terrain_noise_frequency, terrain_noise_amplitude,
		noise_octaves, noise_lacunarity, noise_gain,
		regions,
	]


static func _check_float(errors: PackedStringArray, name: String, value: float, min_value: float, max_value: float) -> void:
	if not is_finite(value) or value < min_value or value > max_value:
		errors.append("%s must be within %s..%s (got %s)" % [name, min_value, max_value, value])


static func _check_int(errors: PackedStringArray, name: String, value: int, min_value: int, max_value: int) -> void:
	if value < min_value or value > max_value:
		errors.append("%s must be within %d..%d (got %d)" % [name, min_value, max_value, value])
