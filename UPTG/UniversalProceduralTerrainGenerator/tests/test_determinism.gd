## Tests for UPTGHeightfieldGenerator and UPTGTerrainData (criteria A7, A11, A12).
extends RefCounted

const PRESET_PATH := "user://uptg_test_preset.tres"


func _small(seed_value: int = 12345) -> UPTGConfig:
	var c := UPTGConfig.new()
	c.generation_seed = seed_value
	c.grid_cells_x = 96
	c.grid_cells_z = 64
	c.cell_size = 8.0
	return c


func run(t: Object) -> void:
	var a := UPTGHeightfieldGenerator.generate(_small())
	var b := UPTGHeightfieldGenerator.generate(_small())
	t.check("generate() returns data for a valid configuration", a != null and b != null)
	if a == null or b == null:
		return

	# A7: determinism
	t.check("A7 same configuration and seed give identical heights", a.heights == b.heights)
	t.check("A7 same configuration and seed give the same checksums",
		a.heights_checksum == b.heights_checksum and a.config_checksum == b.config_checksum, "%d / %d" % [a.heights_checksum, a.config_checksum])
	var other := UPTGHeightfieldGenerator.generate(_small(54321))
	t.check("A7 a different seed changes the heights checksum", other.heights_checksum != a.heights_checksum)
	t.check("A7 a different seed changes the config checksum", other.config_checksum != a.config_checksum)
	t.check("A7 FNV-1a reference value", UPTGTerrainData.fnv1a32("hello".to_utf8_buffer()) == 0x4F9F2CAB,
		"%x" % UPTGTerrainData.fnv1a32("hello".to_utf8_buffer()))

	# Contract shape
	t.check("data dimensions match the grid", a.vertex_count_x == 97 and a.vertex_count_z == 65 and a.heights.size() == 97 * 65 and a.land_mask.size() == 97 * 65)
	t.check("data size is cells * cell_size", a.size == Vector2(768.0, 512.0), a.size)
	t.check("ALGORITHM_VERSION is 1", UPTGTerrainData.ALGORITHM_VERSION == 1)
	var finite := true
	for h in a.heights:
		if not is_finite(h):
			finite = false
	t.check("all heights are finite", finite)
	t.check("min/max heights are consistent", a.min_height <= a.max_height and a.min_height == a.sea_level - a.sea_floor_depth, "%.3f .. %.3f" % [a.min_height, a.max_height])

	# A11: the whole border is sea floor (below sea level)
	var border_ok := true
	for iz in a.vertex_count_z:
		for ix in a.vertex_count_x:
			if ix == 0 or iz == 0 or ix == a.grid_cells_x or iz == a.grid_cells_z:
				if a.get_vertex_height(ix, iz) != a.sea_level - a.sea_floor_depth:
					border_ok = false
	t.check("A11 every border vertex is at sea_level - sea_floor_depth", border_ok)

	# The island exists: land above sea level, mask 1 inland, mountain raises the center
	var land := 0
	for h in a.heights:
		if h > a.sea_level:
			land += 1
	t.check("an island exists (vertices above sea level)", land > 0, "%d of %d vertices" % [land, a.heights.size()])
	t.check("center is land with full mask", a.is_land_at(0.0, 0.0) and a.get_mask_at(0.0, 0.0) > 0.99, "h=%.3f mask=%.3f" % [a.get_height_at(0.0, 0.0), a.get_mask_at(0.0, 0.0)])
	var flat := _small()
	flat.mountain_regions.clear()
	var no_mountain := UPTGHeightfieldGenerator.generate(flat)
	t.check("the mountain region raises the center", a.get_height_at(0.0, 0.0) > no_mountain.get_height_at(0.0, 0.0) + 10.0,
		"%.2f vs %.2f" % [a.get_height_at(0.0, 0.0), no_mountain.get_height_at(0.0, 0.0)])

	# Queries
	var max_err := 0.0
	for iz in range(0, a.vertex_count_z, 7):
		for ix in range(0, a.vertex_count_x, 5):
			var p := a.get_vertex_position(ix, iz)
			max_err = maxf(max_err, absf(a.get_height_at(p.x, p.z) - p.y))
	t.check("get_height_at() matches vertex heights at vertices", max_err < 1e-4, max_err)
	var p00 := a.get_vertex_position(40, 30)
	var p10 := a.get_vertex_position(41, 30)
	var p01 := a.get_vertex_position(40, 31)
	var mid := (p10 + p01) * 0.5
	t.check("get_height_at() follows the (ix+1, iz)-(ix, iz+1) diagonal", absf(a.get_height_at(mid.x, mid.z) - mid.y) < 1e-4, absf(a.get_height_at(mid.x, mid.z) - mid.y))
	t.check("outside the grid returns the sea floor", a.get_height_at(10000.0, 0.0) == a.sea_level - a.sea_floor_depth and not a.is_inside(10000.0, 0.0))
	var n := a.get_normal_at(0.0, 0.0)
	t.check("get_normal_at() returns a unit upward normal", absf(n.length() - 1.0) < 1e-4 and n.y > 0.0, n)

	# World coordinates: halving the cell size and doubling the cells keeps the heights at shared points.
	var coarse := _small()
	coarse.grid_cells_x = 48
	coarse.grid_cells_z = 32
	coarse.cell_size = 16.0
	var cd := UPTGHeightfieldGenerator.generate(coarse)
	var shared_ok := true
	for iz in cd.vertex_count_z:
		for ix in cd.vertex_count_x:
			if cd.get_vertex_height(ix, iz) != a.get_vertex_height(ix * 2, iz * 2):
				shared_ok = false
	t.check("resolution changes detail, not shape (identical heights at shared points)", shared_ok)

	# A12: preset round trip
	var preset := _small()
	preset.mountain_regions[0].center = Vector2(0.3, 0.6)
	preset.mountain_regions[0].peak_height = 70.0
	var err := ResourceSaver.save(preset, PRESET_PATH)
	t.check("A12 preset saved as .tres", err == OK, err)
	var loaded := ResourceLoader.load(PRESET_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as UPTGConfig
	t.check("A12 preset reloaded as UPTGConfig with its mountain region", loaded != null and loaded.mountain_regions.size() == 1 and loaded.mountain_regions[0].peak_height == 70.0)
	if loaded != null:
		var d1 := UPTGHeightfieldGenerator.generate(preset)
		var d2 := UPTGHeightfieldGenerator.generate(loaded)
		t.check("A12 reloaded preset generates identical terrain", d1.heights_checksum == d2.heights_checksum and d1.config_checksum == d2.config_checksum)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PRESET_PATH))

	# Timing (information only; full measurements in Milestone D)
	for cells in [128, 256]:
		var c := UPTGConfig.new()
		c.grid_cells_x = cells
		c.grid_cells_z = cells
		var t0: int = Time.get_ticks_usec()
		var d := UPTGHeightfieldGenerator.generate(c)
		var gen_ms: float = (Time.get_ticks_usec() - t0) / 1000.0
		t0 = Time.get_ticks_usec()
		var _cs: int = d.heights_checksum
		var sum_ms: float = (Time.get_ticks_usec() - t0) / 1000.0
		t.info("timing %dx%d (default config)" % [cells, cells], "height field %.1f ms, heights checksum %.1f ms" % [gen_ms, sum_ms])
