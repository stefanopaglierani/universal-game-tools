class_name UPWGProject
extends Resource
## A world being made in UPWG, in one file: everything needed to build it again and to export it.

const FORMAT := 1
## Largest world side in meters (15 km from the center to the edge).
const MAX_SIDE := 30720.0
## Largest number of cells per side of an exported world (UPTG heights only, ADR-0017).
const MAX_EXPORT_CELLS := 8192
## Starting points offered by "New world".
const TEMPLATES := ["island", "continent", "coast", "highlands", "flat"]
const TEMPLATE_NAMES := {
	"island": "Island",
	"continent": "Continent",
	"coast": "Coast",
	"highlands": "Highlands",
	"flat": "Flat land",
}

@export var format_version: int = FORMAT
@export var world_name: String = "New world"
@export var template: String = "island"
## The terrain (UPTG).
@export var terrain: UPTGConfig
## Brush strokes, lakes, rivers, roads, places and objects (UPRG).
@export var world: UPRGWorldConfig
## Cell of the exported world in meters, finer than [member terrain]'s cell when the world has
## more than 2048 cells per side (ADR-0017). 0 = the cell of [member terrain].
@export var detail_cell: float = 0.0
## Undo steps of the editor: {kind: "edits" or "water", count}, oldest first.
@export var history: Array = []
@export_group("Export")
@export var export_godot_single: bool = true
@export var export_godot_tiles: bool = true
@export var export_heightmap: bool = true
@export var export_gltf: bool = true


## A new world from a template and a seed. The same template and seed always give the same world.
static func from_template(template_id: String, seed_value: int) -> UPWGProject:
	var project := UPWGProject.new()
	project.template = template_id if template_id in TEMPLATES else "island"
	project.world_name = TEMPLATE_NAMES[project.template]
	var config := UPTGConfig.new()
	config.generation_seed = seed_value
	config.mountain_regions.clear()
	match project.template:
		"island":
			config.land_shape = UPTGConfig.LandShape.ISLAND
			config.land_base_height = 8.0
			config.terrain_noise_amplitude = 14.0
		"continent":
			config.land_shape = UPTGConfig.LandShape.CONTINENT
			config.land_base_height = 14.0
			config.terrain_noise_amplitude = 26.0
			config.terrain_noise_frequency = 0.004
		"coast":
			config.land_shape = UPTGConfig.LandShape.COAST
			config.land_base_height = 8.0
			config.terrain_noise_amplitude = 16.0
		"highlands":
			config.land_shape = UPTGConfig.LandShape.CONTINENT
			config.land_base_height = 30.0
			config.terrain_noise_amplitude = 60.0
			config.terrain_noise_frequency = 0.003
		"flat":
			config.land_shape = UPTGConfig.LandShape.CONTINENT
			config.land_base_height = 5.0
			config.terrain_noise_amplitude = 0.0
	project.terrain = config
	set_size(config, 2048.0, 4.0)
	var mountains := {"island": 1, "continent": 2, "coast": 1, "highlands": 5, "flat": 0}
	place_mountains(config, mountains[project.template], 0, 120.0 if project.template != "highlands" else 220.0, 0.18)
	project.world = UPRGWorldConfig.new()
	return project


## Sets the side of the square world in meters and the size of a cell (smaller is more detailed).
## The grid is limited by UPTG to UPTGConfig.MAX_CELLS_PER_AXIS cells per side, so the cell grows when needed.
static func set_size(config: UPTGConfig, side: float, cell: float) -> void:
	var cells := int(round(side / cell / 4.0)) * 4
	while cells > UPTGConfig.MAX_CELLS_PER_AXIS:
		cell *= 2.0
		cells = int(round(side / cell / 4.0)) * 4
	config.cell_size = cell
	config.grid_cells_x = maxi(cells, 8)
	config.grid_cells_z = maxi(cells, 8)


## Sets the side of the world and the wanted cell. The terrain keeps at most 2048 cells per side
## (it is what the preview and small exports use); a finer cell is kept in [member detail_cell]
## for the export, up to [constant MAX_EXPORT_CELLS] cells per side.
func resize(side: float, cell: float) -> void:
	side = clampf(side, 64.0, MAX_SIDE)
	set_size(terrain, side, cell)
	var detail := terrain.cell_size
	var cells := terrain.grid_cells_x
	while detail * 0.5 >= cell - 0.001 and cells * 2 <= MAX_EXPORT_CELLS:
		detail *= 0.5
		cells *= 2
	detail_cell = detail if detail < terrain.cell_size else 0.0


## Cell of the exported world in meters.
func export_cell() -> float:
	return detail_cell if detail_cell > 0.0 else terrain.cell_size


## True when the world is exported in tiles straight from its heights, without one scene.
func is_large() -> bool:
	return export_cell() < terrain.cell_size - 0.0001


## Puts [param count] mountains at places chosen from the seed and [param shuffle]: a different
## shuffle moves them, the same one puts them back.
static func place_mountains(config: UPTGConfig, count: int, shuffle: int, peak: float, radius: float) -> void:
	config.mountain_regions.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([config.generation_seed, shuffle, "mountains"])
	var inner := 0.2 if config.land_shape == UPTGConfig.LandShape.ISLAND else 0.08
	for i in count:
		var region := UPTGMountainRegion.new()
		var center := Vector2(rng.randf_range(inner, 1.0 - inner), rng.randf_range(inner, 1.0 - inner))
		if config.land_shape == UPTGConfig.LandShape.COAST:
			# Mountains stay on the land side of the coast.
			center.y = rng.randf_range(0.08, config.coast_position * 0.75)
		region.center = center
		region.radius = radius * rng.randf_range(0.8, 1.2)
		region.peak_height = peak * rng.randf_range(0.7, 1.0)
		config.mountain_regions.append(region)


## Every problem that would stop the world from being built. Empty when it is fine.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if terrain == null:
		errors.append("the world has no terrain")
		return errors
	errors.append_array(terrain.validate())
	if detail_cell > 0.0:
		var cells := roundi(terrain.get_size().x / detail_cell)
		if absf(cells * detail_cell - terrain.get_size().x) > 0.01 or cells > MAX_EXPORT_CELLS:
			errors.append("the export detail of %.2f m does not fit this world" % detail_cell)
	return errors
