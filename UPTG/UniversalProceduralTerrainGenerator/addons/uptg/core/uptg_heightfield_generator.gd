class_name UPTGHeightfieldGenerator
extends RefCounted
## Pure height-field generator (architecture 0.2, sections 4 and 8).
##
## Static functions only: no state, no scene tree, no rendering or physics
## resources. Same configuration + same build + same platform = same result.

## Maximum normalized distance (max(|u|, |v|)) where the edge band starts.
const EDGE_BAND_START: float = 0.9


## Validation and cost check. Returns the errors that prevent generation
## (empty when generation may proceed). [param allow_large] permits
## [constant UPTGConfig.CostLevel.LARGE] configurations.
static func check(config: UPTGConfig, allow_large: bool = false) -> PackedStringArray:
	var errors := PackedStringArray()
	if config == null:
		errors.append("missing UPTGConfig")
		return errors
	errors.append_array(config.validate())
	var cost: Dictionary = config.estimate_cost()
	match cost.level:
		UPTGConfig.CostLevel.REJECTED:
			errors.append("configuration rejected by the cost protection: %d cells, about %d MB estimated" % [cost.cells, cost.estimated_bytes / 1048576])
		UPTGConfig.CostLevel.LARGE:
			if not allow_large:
				errors.append("large configuration (%d cells, about %d MB estimated): enable allow_large_terrain to generate it" % [cost.cells, cost.estimated_bytes / 1048576])
	return errors


## Generates the height field. Returns [code]null[/code] and reports the errors
## with [method @GlobalScope.push_error] when [method check] fails.
static func generate(config: UPTGConfig, allow_large: bool = false) -> UPTGTerrainData:
	var errors := check(config, allow_large)
	if not errors.is_empty():
		for e in errors:
			push_error("UPTG: " + e)
		return null

	var cells_x: int = config.grid_cells_x
	var cells_z: int = config.grid_cells_z
	var vx: int = cells_x + 1
	var vz: int = cells_z + 1
	var cell: float = config.cell_size
	var size := config.get_size()
	var half_x: float = size.x * 0.5
	var half_z: float = size.y * 0.5

	var coast := _make_noise(UPTGSeed.derive(config.generation_seed, UPTGSeed.SALT_COASTLINE),
		config.coastline_noise_frequency, UPTGConfig.COASTLINE_OCTAVES, 2.0, 0.5)
	var relief := _make_noise(UPTGSeed.derive(config.generation_seed, UPTGSeed.SALT_TERRAIN),
		config.terrain_noise_frequency, config.noise_octaves, config.noise_lacunarity, config.noise_gain)

	var coast_offset := UPTGSeed.noise_offset(config.generation_seed, UPTGSeed.SALT_COASTLINE_OFFSET)
	var relief_offset := UPTGSeed.noise_offset(config.generation_seed, UPTGSeed.SALT_TERRAIN_OFFSET)

	# Mountain regions converted to local meters once.
	var m_centers := PackedVector2Array()
	var m_radii := PackedFloat32Array()
	var m_peaks := PackedFloat32Array()
	var m_falloffs := PackedFloat32Array()
	var min_side: float = minf(size.x, size.y)
	for region in config.mountain_regions:
		m_centers.append(Vector2((region.center.x - 0.5) * size.x, (region.center.y - 0.5) * size.y))
		m_radii.append(region.radius * min_side)
		m_peaks.append(region.peak_height)
		m_falloffs.append(region.falloff)
	var m_count: int = m_centers.size()

	var shape: UPTGConfig.LandShape = config.land_shape
	var coast_line: float = config.coast_position * 2.0 - 1.0
	var rx: float = config.island_radius.x
	var rz: float = config.island_radius.y
	var irregularity: float = config.coastline_irregularity
	var inner: float = 1.0 - config.coastline_falloff_width
	var amplitude: float = config.terrain_noise_amplitude
	var base: float = config.land_base_height
	var min_land: float = config.min_land_height
	var sea_floor: float = config.sea_level - config.sea_floor_depth
	var sea: float = config.sea_level

	var heights := PackedFloat32Array()
	heights.resize(vx * vz)
	var mask_values := PackedFloat32Array()
	mask_values.resize(vx * vz)
	var h_min: float = INF
	var h_max: float = -INF

	for iz in vz:
		var z: float = (iz - cells_z * 0.5) * cell
		var v: float = z / half_z
		var row: int = iz * vx
		for ix in vx:
			var x: float = (ix - cells_x * 0.5) * cell
			var u: float = x / half_x
			var mask: float = 1.0
			if shape == UPTGConfig.LandShape.ISLAND:
				mask = _shape_mask(coast, x + coast_offset.x, z + coast_offset.y, u, v, rx, rz, irregularity, inner)
			elif shape == UPTGConfig.LandShape.COAST:
				mask = _coast_mask(coast, x + coast_offset.x, z + coast_offset.y, v, coast_line, irregularity, config.coastline_falloff_width)
			var h: float = sea_floor
			if mask > 0.0:
				var hills: float = clampf(relief.get_noise_2d(x + relief_offset.x, z + relief_offset.y), -1.0, 1.0) * amplitude
				var mount: float = 0.0
				for m in m_count:
					var t: float = 1.0 - clampf(Vector2(x, z).distance_to(m_centers[m]) / m_radii[m], 0.0, 1.0)
					if t > 0.0:
						mount = maxf(mount, m_peaks[m] * pow(smoothstep(0.0, 1.0, t), m_falloffs[m]))
				var land: float = maxf(base + hills + mount, min_land)
				h = lerpf(sea_floor, sea + land, mask)
			heights[row + ix] = h
			mask_values[row + ix] = mask
			h_min = minf(h_min, h)
			h_max = maxf(h_max, h)

	var data := UPTGTerrainData.new()
	data.generation_seed = config.generation_seed
	data.config_checksum = UPTGTerrainData.fnv1a32(var_to_bytes(config.get_height_parameters()))
	data.grid_cells_x = cells_x
	data.grid_cells_z = cells_z
	data.vertex_count_x = vx
	data.vertex_count_z = vz
	data.cell_size = cell
	data.size = size
	data.sea_level = sea
	data.sea_floor_depth = config.sea_floor_depth
	data.min_height = h_min
	data.max_height = h_max
	data.heights = heights
	data.land_mask = mask_values
	return data


## Island mask (section 8.2): 0 = sea, 1 = inland. [param u], [param v] are normalized to -1..1;
## [param x], [param z] are the noise sampling coordinates (position plus offset, in meters).
static func _shape_mask(coast: FastNoiseLite, x: float, z: float, u: float, v: float,
		rx: float, rz: float, irregularity: float, inner: float) -> float:
	var edge: float = 1.0 - smoothstep(EDGE_BAND_START, 1.0, maxf(absf(u), absf(v)))
	if edge <= 0.0:
		return 0.0
	var d: float = sqrt((u / rx) * (u / rx) + (v / rz) * (v / rz))
	# The perturbed distance is at least d * (1 - irregularity): skip the noise when that is already at sea.
	if d * (1.0 - irregularity) >= 1.0:
		return 0.0
	var c: float = clampf(coast.get_noise_2d(x, z), -1.0, 1.0)
	var d_pert: float = d * (1.0 + irregularity * c)
	return (1.0 - smoothstep(inner, 1.0, d_pert)) * edge


## Coast mask: 1 on the -Z side, 0 on the +Z side, with the line at [param line] (normalized -1..1)
## moved by the coastline noise. [param width] is the normalized width of the land-to-sea transition.
static func _coast_mask(coast: FastNoiseLite, x: float, z: float, v: float, line: float, irregularity: float, width: float) -> float:
	var c: float = clampf(coast.get_noise_2d(x, z), -1.0, 1.0)
	var shifted: float = v + irregularity * c
	return 1.0 - smoothstep(line - width, line, shifted)


static func _make_noise(noise_seed: int, frequency: float, octaves: int, lacunarity: float, gain: float) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = noise_seed
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = octaves
	n.fractal_lacunarity = lacunarity
	n.fractal_gain = gain
	n.frequency = frequency
	return n
