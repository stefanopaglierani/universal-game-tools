## Tests for roads that close into a ring, on a synthetic baked terrain.
extends RefCounted

const BASE := preload("res://tests/test_world.gd")
const OUT_PATH := BASE.DIR + "/loop.scn"


func _ring() -> UPRGRoadConfig:
	var road := UPRGRoadConfig.new()
	road.closed = true
	var points := PackedVector2Array()
	for k in 8:
		var a := TAU * k / 8.0
		points.append(Vector2(cos(a), sin(a)) * 150.0)
	road.points = points
	return road


func run(t: Object) -> void:
	BASE.new()._write_terrain()
	var ring := _ring()
	var world := UPRGWorldConfig.new()
	var roads: Array[UPRGRoadConfig] = [ring]
	world.roads = roads
	var result: Dictionary = UPRGBaker.bake_world(BASE.IN_PATH, world, OUT_PATH)
	t.check("a ring bakes", result.ok, str(result))
	if not result.ok:
		return
	var root := (ResourceLoader.load(OUT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate() as Node3D
	var data: Dictionary = root.get_meta("terrain_data")
	var road: Dictionary = data.roads[0]
	var path: PackedVector2Array = road.path
	var heights: PackedFloat32Array = road.heights
	t.check("the ring is marked as closed", road.closed)
	t.check("the ring ends where it starts", path[0].is_equal_approx(path[path.size() - 1]) and is_equal_approx(heights[0], heights[heights.size() - 1]))
	t.check("the ring goes all the way round", path.size() * road.sample_spacing > TAU * 150.0 * 0.95, "%.0f m" % (path.size() * road.sample_spacing))
	var worst := 0.0
	var widest_gap := 0.0
	for i in range(1, path.size()):
		worst = maxf(worst, absf(heights[i] - heights[i - 1]) / road.sample_spacing)
		widest_gap = maxf(widest_gap, path[i].distance_to(path[i - 1]))
	t.check("the grade stays within the limit across the closing point", worst <= ring.max_grade + 0.001, "%.3f" % worst)
	t.check("positions stay evenly spaced across the closing point", widest_gap < road.sample_spacing * 1.5, "%.2f m" % widest_gap)
	var vertices: PackedVector3Array = (root.get_node("Roads/Road0") as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var seam := true
	for j in 4:
		seam = seam and vertices[j].is_equal_approx(vertices[vertices.size() - 4 + j])
	t.check("the surface closes without a gap", seam)
	root.free()

	var branch := UPRGRoadConfig.new()
	branch.points = PackedVector2Array([Vector2(0, 150), Vector2(0, 60), Vector2(0, -40)])
	var two: Array[UPRGRoadConfig] = [ring, branch]
	world.roads = two
	result = UPRGBaker.bake_world(BASE.IN_PATH, world, OUT_PATH)
	t.check("a road can end on a ring", result.ok and result.junctions == 1, str(result))
	var short := UPRGRoadConfig.new()
	short.closed = true
	short.points = PackedVector2Array([Vector2(0, 0), Vector2(50, 0)])
	t.check("a ring with two points is refused", not short.validate().is_empty())

	for f in [BASE.IN_PATH, OUT_PATH]:
		DirAccess.remove_absolute(f)
	DirAccess.remove_absolute(BASE.DIR)
