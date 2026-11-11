## Brush edits (smooth, roughen, bounded areas) and water: lakes at any height and rivers.
extends RefCounted

const BASE := preload("res://tests/test_world.gd")
const OUT_PATH := BASE.DIR + "/water.scn"


func _grid() -> UPRGTerrainGrid:
	var grid := UPRGTerrainGrid.new()
	grid.cells_x = 64
	grid.cells_z = 64
	grid.cell_size = 8.0
	grid.sea_level = 0.0
	grid.heights = BASE.new()._terrain_heights()
	return grid


func run(t: Object) -> void:
	var grid := _grid()
	var far := grid.heights[grid.index(2, 2)]
	var raise := UPRGTerrainEdit.new()
	raise.center = Vector2(0, 0)
	raise.radius = 20.0
	raise.blend = 10.0
	raise.amount = 15.0
	raise.apply(grid)
	t.check("an edit only touches its own area", is_equal_approx(grid.heights[grid.index(2, 2)], far))

	var box := _grid()
	var square := UPRGTerrainEdit.new()
	square.square = true
	square.radius = 40.0
	square.blend = 0.5
	square.amount = 10.0
	var corner_before := box.height_at(Vector2(36, 36))
	square.apply(box)
	t.check("a square edit reaches its corners", box.height_at(Vector2(36, 36)) > corner_before + 9.0)
	var shelf := _grid()
	var down := UPRGTerrainEdit.new()
	down.kind = UPRGTerrainEdit.Kind.LEVEL
	down.level_mode = UPRGTerrainEdit.LevelMode.DOWN_ONLY
	down.radius = 300.0
	down.square = true
	var low_before := INF
	var high_before := -INF
	for h in shelf.heights:
		low_before = minf(low_before, h)
		high_before = maxf(high_before, h)
	down.height = (low_before + high_before) * 0.5
	var high_after := -INF
	down.apply(shelf)
	for h in shelf.heights:
		high_after = maxf(high_after, h)
	var low_after := INF
	for h in shelf.heights:
		low_after = minf(low_after, h)
	t.check("flatten DOWN_ONLY lowers the high ground and keeps the low ground", high_after <= down.height + 0.01 and is_equal_approx(low_after, low_before), "%.2f to %.2f, low %.2f" % [high_before, high_after, low_after])

	var bumpy := _grid()
	var before := _roughness(bumpy, 32, 32)
	var rough := UPRGTerrainEdit.new()
	rough.kind = UPRGTerrainEdit.Kind.ROUGHEN
	rough.radius = 80.0
	rough.amount = 6.0
	rough.bump_size = 10.0
	rough.apply(bumpy)
	var rougher := _roughness(bumpy, 32, 32)
	t.check("ROUGHEN makes the ground bumpier", rougher > before * 1.5, "%.2f to %.2f" % [before, rougher])
	var smooth := UPRGTerrainEdit.new()
	smooth.kind = UPRGTerrainEdit.Kind.SMOOTH
	smooth.radius = 80.0
	smooth.amount = 1.0
	for k in 6:
		smooth.apply(bumpy)
	t.check("SMOOTH makes it smoother again", _roughness(bumpy, 32, 32) < rougher * 0.6, "%.2f" % _roughness(bumpy, 32, 32))
	var again := _grid()
	rough.apply(again)
	t.check("the same bumps come back from the same seed", again.heights == _roughened_copy(rough))

	# A lake on top of a hill: the water stays up there.
	var hill := _grid()
	var top := UPRGTerrainEdit.new()
	top.kind = UPRGTerrainEdit.Kind.ADD
	top.center = Vector2(60, 60)
	top.radius = 70.0
	top.blend = 60.0
	top.amount = 80.0
	top.apply(hill)
	var lake := UPRGWater.new()
	lake.points = PackedVector2Array([Vector2(60, 60)])
	lake.size = 30.0
	lake.depth = 5.0
	lake.shore = 12.0
	var plan := UPRGWaterBuilder.dig(lake, hill)
	t.check("a lake can sit on a hill", plan.ok and plan.level > 60.0, "level %.1f m" % plan.get("level", 0.0))
	t.check("the lake is deep at its center", hill.height_at(Vector2(60, 60)) < plan.level - 4.0)
	var holds := true
	for k in 24:
		var a := TAU * k / 24.0
		holds = holds and hill.height_at(Vector2(60, 60) + Vector2(cos(a), sin(a)) * 45.0) >= plan.level
	t.check("the rim of the lake is above the water", holds)
	var surface := UPRGWaterBuilder.build_mesh(plan, hill)
	var flat := surface != null
	if flat:
		for v: Vector3 in surface.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			flat = flat and is_equal_approx(v.y, plan.level) and Vector2(v.x, v.z).distance_to(Vector2(60, 60)) < 60.0
	t.check("the lake water is flat and stays in its basin", flat)

	var valley := _grid()
	var river := UPRGWater.new()
	river.kind = UPRGWater.Kind.RIVER
	river.points = PackedVector2Array([Vector2(-200, -150), Vector2(-50, -20), Vector2(100, 60), Vector2(200, 180)])
	river.size = 8.0
	river.depth = 2.0
	river.shore = 6.0
	var flow := UPRGWaterBuilder.dig(river, valley)
	var downhill: bool = flow.ok
	for i in range(1, flow.levels.size()):
		downhill = downhill and flow.levels[i] <= flow.levels[i - 1]
	t.check("a river only flows downhill", downhill)
	var under := true
	for i in range(0, flow.path.size(), 5):
		under = under and valley.height_at(flow.path[i]) < flow.levels[i]
	t.check("the river bed is under the water all along", under)

	BASE.new()._write_terrain()
	var world := UPRGWorldConfig.new()
	var waters: Array[UPRGWater] = [lake, river]
	world.water = waters
	var edits: Array[UPRGTerrainEdit] = [top]
	world.terrain_edits = edits
	var result: Dictionary = UPRGBaker.bake_world(BASE.IN_PATH, world, OUT_PATH)
	t.check("a world with water bakes", result.ok and result.water == 2, str(result))
	if result.ok:
		var root := (ResourceLoader.load(OUT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate() as Node3D
		t.check("the world file has the water surfaces and their data", root.has_node("Water/Lake0") and root.has_node("Water/River1")
			and (root.get_meta("terrain_data").water as Array).size() == 2)
		t.check("the water needs no other file", ResourceLoader.get_dependencies(OUT_PATH).is_empty())
		root.free()
	var dry := UPRGWater.new()
	dry.kind = UPRGWater.Kind.RIVER
	dry.points = PackedVector2Array([Vector2(0, 0)])
	t.check("a river with one point is refused", not dry.validate().is_empty())
	for f in [BASE.IN_PATH, OUT_PATH]:
		DirAccess.remove_absolute(f)
	DirAccess.remove_absolute(BASE.DIR)


func _roughened_copy(edit: UPRGTerrainEdit) -> PackedFloat32Array:
	var grid := _grid()
	edit.apply(grid)
	return grid.heights


## Average height difference between neighbors around a vertex.
static func _roughness(grid: UPRGTerrainGrid, cx: int, cz: int) -> float:
	var total := 0.0
	var count := 0
	for iz in range(cz - 8, cz + 8):
		for ix in range(cx - 8, cx + 8):
			total += absf(grid.heights[grid.index(ix + 1, iz)] - grid.heights[grid.index(ix, iz)])
			count += 1
	return total / count
