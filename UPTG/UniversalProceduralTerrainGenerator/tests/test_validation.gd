## Tests for UPTGConfig validation and cost protection (criteria A5 and A5b).
extends RefCounted


func run(t: Object) -> void:
	var def := UPTGConfig.new()
	t.check("A5 default configuration is valid", def.validate().is_empty(), def.validate())
	t.check("A5 default configuration has one mountain region", def.mountain_regions.size() == 1)
	var preset := load("res://addons/uptg/presets/uptg_island_default.tres") as UPTGConfig
	t.check("island preset loads, is valid and matches the defaults",
		preset != null and preset.validate().is_empty() and var_to_bytes(preset.get_height_parameters()) == var_to_bytes(def.get_height_parameters()))

	# Each case: [description, Callable that breaks a fresh config, expected text in an error]
	var cases: Array = [
		["negative seed", func(c: UPTGConfig) -> void: c.generation_seed = -1, "generation_seed"],
		["seed above 31 bits", func(c: UPTGConfig) -> void: c.generation_seed = 2147483648, "generation_seed"],
		["1 cell on X", func(c: UPTGConfig) -> void: c.grid_cells_x = 1, "grid_cells_x"],
		["1025 cells on Z", func(c: UPTGConfig) -> void: c.grid_cells_z = 1025, "grid_cells_z"],
		["cell_size 0", func(c: UPTGConfig) -> void: c.cell_size = 0.0, "cell_size"],
		["sea_level NaN", func(c: UPTGConfig) -> void: c.sea_level = NAN, "sea_level"],
		["sea_floor_depth infinite", func(c: UPTGConfig) -> void: c.sea_floor_depth = INF, "sea_floor_depth"],
		["island_radius.x 0.9", func(c: UPTGConfig) -> void: c.island_radius = Vector2(0.9, 0.5), "island_radius.x"],
		["coastline constraint", func(c: UPTGConfig) -> void: c.island_radius = Vector2(0.75, 0.75), "coastline_irregularity"],
		["noise_octaves 0", func(c: UPTGConfig) -> void: c.noise_octaves = 0, "noise_octaves"],
		["noise_gain 2", func(c: UPTGConfig) -> void: c.noise_gain = 2.0, "noise_gain"],
		["null mountain region", func(c: UPTGConfig) -> void: c.mountain_regions.append(null), "mountain_regions[1] is empty"],
		["region center outside 0..1", func(c: UPTGConfig) -> void: c.mountain_regions[0].center = Vector2(1.5, 0.5), "mountain_regions[0]: center"],
		["region radius 0", func(c: UPTGConfig) -> void: c.mountain_regions[0].radius = 0.0, "mountain_regions[0]: radius"],
		["17 mountain regions", func(c: UPTGConfig) -> void:
			for i in 16:
				c.mountain_regions.append(UPTGMountainRegion.new()), "at most 16"],
	]
	for case in cases:
		var c := UPTGConfig.new()
		case[1].call(c)
		var errors: PackedStringArray = c.validate()
		var found := false
		for e in errors:
			if e.contains(case[2]):
				found = true
		t.check("A5 rejects %s" % case[0], found, errors)

	# Generation refuses an invalid configuration and returns null.
	var bad := UPTGConfig.new()
	bad.cell_size = -1.0
	t.check("A5 check() reports the invalid configuration", not UPTGHeightfieldGenerator.check(bad).is_empty())
	t.check("A5 generate() returns null for an invalid configuration", UPTGHeightfieldGenerator.generate(bad) == null)
	t.check("A5 check() reports a missing configuration", not UPTGHeightfieldGenerator.check(null).is_empty())

	# A5b: cost levels, computed without generating.
	var levels: Array = [
		[512, 512, UPTGConfig.CollisionMode.HEIGHTMAP, UPTGConfig.CostLevel.OK],
		[513, 512, UPTGConfig.CollisionMode.HEIGHTMAP, UPTGConfig.CostLevel.LARGE],
		[1024, 1024, UPTGConfig.CollisionMode.HEIGHTMAP, UPTGConfig.CostLevel.LARGE],
		[1025, 64, UPTGConfig.CollisionMode.HEIGHTMAP, UPTGConfig.CostLevel.REJECTED],
		[256, 256, UPTGConfig.CollisionMode.TRIMESH, UPTGConfig.CostLevel.OK],
		[257, 256, UPTGConfig.CollisionMode.TRIMESH, UPTGConfig.CostLevel.LARGE],
	]
	for l in levels:
		var c := UPTGConfig.new()
		c.grid_cells_x = l[0]
		c.grid_cells_z = l[1]
		c.collision_mode = l[2]
		var cost: Dictionary = c.estimate_cost()
		t.check("A5b %dx%d %s -> %s" % [l[0], l[1], UPTGConfig.CollisionMode.keys()[l[2]], UPTGConfig.CostLevel.keys()[l[3]]],
			cost.level == l[3], "%s, %d MB" % [UPTGConfig.CostLevel.keys()[cost.level], cost.estimated_bytes / 1048576])

	var large := UPTGConfig.new()
	large.grid_cells_x = 600
	large.grid_cells_z = 600
	t.check("A5b LARGE refused without allow_large", not UPTGHeightfieldGenerator.check(large).is_empty())
	t.check("A5b LARGE accepted with allow_large", UPTGHeightfieldGenerator.check(large, true).is_empty(), UPTGHeightfieldGenerator.check(large, true))
	var t0: int = Time.get_ticks_usec()
	var refused := UPTGHeightfieldGenerator.generate(large)
	var refused_us: int = Time.get_ticks_usec() - t0
	t.check("A5b generate() refuses LARGE without generating (null, under 50 ms)", refused == null and refused_us < 50000, "%d us" % refused_us)

	var rejected := UPTGConfig.new()
	rejected.grid_cells_x = 2000
	t.check("A5b REJECTED refused even with allow_large", not UPTGHeightfieldGenerator.check(rejected, true).is_empty())
