## Tests for road junctions and for the streets inside places, on a synthetic baked terrain.
extends RefCounted

const BASE := preload("res://tests/test_world.gd")
const OUT_PATH := BASE.DIR + "/network.scn"


func _road(points: Array[Vector2]) -> UPRGRoadConfig:
	var road := UPRGRoadConfig.new()
	road.points = PackedVector2Array(points)
	return road


func _world(road_list: Array[UPRGRoadConfig]) -> UPRGWorldConfig:
	var world := UPRGWorldConfig.new()
	world.roads = road_list
	return world


func _bake(road_list: Array[UPRGRoadConfig]) -> Dictionary:
	return UPRGBaker.bake_world(BASE.IN_PATH, _world(road_list), OUT_PATH)


func _load() -> Node3D:
	return (ResourceLoader.load(OUT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate() as Node3D


func _clockwise(mesh: ArrayMesh) -> bool:
	var arrays := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for i in range(0, index.size(), 3):
		if (v[index[i + 2]] - v[index[i]]).cross(v[index[i + 1]] - v[index[i]]).y < -0.000001:
			return false
	return true


## True when every outer edge point of the arm ends has a matching vertex in the junction.
func _joins(road_mesh: ArrayMesh, junction_mesh: ArrayMesh) -> int:
	var road_arrays := road_mesh.surface_get_arrays(0)
	var road_vertices: PackedVector3Array = road_arrays[Mesh.ARRAY_VERTEX]
	var used := {}
	for i: int in road_arrays[Mesh.ARRAY_INDEX]:
		used[i] = true
	var shared := 0
	for j: Vector3 in junction_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		for i: int in used:
			if road_vertices[i].is_equal_approx(j):
				shared += 1
				break
	return shared


func _max_grade(meta_road: Dictionary) -> float:
	var h: PackedFloat32Array = meta_road.heights
	var worst := 0.0
	for i in range(1, h.size()):
		worst = maxf(worst, absf(h[i] - h[i - 1]) / meta_road.sample_spacing)
	return worst


func _test_cross(t: Object) -> void:
	var a := _road([Vector2(-160, 40), Vector2(-60, 40), Vector2(60, 40), Vector2(160, 40)])
	var b := _road([Vector2(0, -130), Vector2(0, -40), Vector2(0, 120), Vector2(0, 170)])
	var result: Dictionary = _bake([a, b])
	t.check("two crossing roads bake", result.ok, str(result))
	if not result.ok:
		return
	t.check("one junction is found where they cross", result.junctions == 1, "%d junctions" % result.junctions)
	var root := _load()
	var data: Dictionary = root.get_meta("terrain_data")
	var junction: Dictionary = data.junctions[0]
	t.check("the junction is on the crossing", (junction.center as Vector2).distance_to(Vector2(0, 40)) < 1.0, str(junction.center))
	var surface := root.get_node("Roads/Junction0") as MeshInstance3D
	t.check("the junction has a surface and a collision", surface != null and surface.get_node("Body/Shape").shape is ConcavePolygonShape3D)
	t.check("the junction surface faces up", _clockwise(surface.mesh))
	t.check("the road surfaces face up", _clockwise((root.get_node("Roads/Road0") as MeshInstance3D).mesh))
	var ring_a := _joins((root.get_node("Roads/Road0") as MeshInstance3D).mesh, surface.mesh)
	var ring_b := _joins((root.get_node("Roads/Road1") as MeshInstance3D).mesh, surface.mesh)
	t.check("the junction shares its edge with both roads", ring_a == 8 and ring_b == 8, "%d and %d points" % [ring_a, ring_b])
	var both_flat := true
	for r: Dictionary in data.roads:
		var path: PackedVector2Array = r.path
		for i in path.size():
			if path[i].distance_to(junction.center) < junction.radius - r.sample_spacing:
				both_flat = both_flat and absf(r.heights[i] - junction.height) < 0.001
	t.check("both roads are at the junction height", both_flat, "%.2f m" % junction.height)
	t.check("the grades stay within the limit", _max_grade(data.roads[0]) <= a.max_grade + 0.001 and _max_grade(data.roads[1]) <= b.max_grade + 0.001,
		"%.3f and %.3f" % [_max_grade(data.roads[0]), _max_grade(data.roads[1])])
	var grid := UPRGTerrainGrid.from_meta(data)
	var under := grid.height_at(junction.center)
	t.check("the terrain stays under the junction", under < junction.height and under > junction.height - 0.5, "%.3f below" % (junction.height - under))
	root.free()


func _test_t(t: Object) -> void:
	var a := _road([Vector2(-160, 0), Vector2(-60, 0), Vector2(60, 0), Vector2(160, 0)])
	var b := _road([Vector2(20, 1), Vector2(20, 60), Vector2(20, 150)])
	var result: Dictionary = _bake([a, b])
	t.check("a road ending on another makes a junction", result.ok and result.junctions == 1, str(result))
	var c := _road([Vector2(20, -4), Vector2(20, 60), Vector2(20, 150)])
	result = _bake([a, c])
	t.check("a road that overshoots a little makes one too", result.ok and result.junctions == 1, str(result))
	var root := _load()
	var t_junction: Dictionary = root.get_meta("terrain_data").junctions[0]
	t.check("a T has three arms", t_junction.arms == 3, "%d arms" % t_junction.arms)
	root.free()
	var far := _road([Vector2(-160, 80), Vector2(0, 80), Vector2(160, 80)])
	result = _bake([a, far])
	t.check("roads that do not meet make no junction", result.ok and result.junctions == 0, str(result))


func _test_refused(t: Object) -> void:
	var a := _road([Vector2(-160, 0), Vector2(-60, 0), Vector2(60, 0), Vector2(160, 0)])
	var sharp := _road([Vector2(-150, -30), Vector2(0, 0), Vector2(150, 30)])
	t.check("a crossing that is too sharp is refused", not _bake([a, sharp]).ok)
	var near_one := _road([Vector2(0, -100), Vector2(0, 100)])
	var near_two := _road([Vector2(10, -100), Vector2(10, 100)])
	t.check("junctions too close on a road are refused", not _bake([a, near_one, near_two]).ok)


func _test_streets(t: Object) -> void:
	var main := _road([Vector2(-160, 60), Vector2(-60, 60), Vector2(60, 60), Vector2(160, 60)])
	var place := UPRGPlace.new()
	place.center = Vector2(0, -20)
	place.radius = 80.0
	place.blend = 20.0
	place.building_count = 14
	place.seed_value = 3
	place.streets = true
	var world := _world([main])
	var places: Array[UPRGPlace] = [place]
	world.places = places
	var result: Dictionary = UPRGBaker.bake_world(BASE.IN_PATH, world, OUT_PATH)
	t.check("a place with streets bakes", result.ok, str(result))
	if not result.ok:
		return
	t.check("the place gets several streets", result.streets >= 3, "%d streets" % result.streets)
	t.check("the given road stays the first", result.roads == 1)
	t.check("buildings are placed", result.buildings >= 8, "%d buildings" % result.buildings)
	var root := _load()
	var data: Dictionary = root.get_meta("terrain_data")
	t.check("streets are marked in the data", not data.roads[0].street and data.roads[1].street)
	var joined := {}
	for j: Dictionary in data.junctions:
		for r: int in j.roads:
			joined[r] = true
	t.check("every street is joined to the network", joined.size() == data.roads.size() and joined.has(0), "%d of %d" % [joined.size(), data.roads.size()])
	var vertices: PackedVector3Array = (root.get_node("Places/Place0") as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var nearest := INF
	for r: Dictionary in data.roads:
		var limit: float = r.width * 0.5 + 1.0
		for i in range(0, vertices.size(), 3):
			for p: Vector2 in r.path:
				nearest = minf(nearest, Vector2(vertices[i].x, vertices[i].z).distance_to(p) - limit)
	t.check("no building stands on a street", nearest > 0.0, "closest %.1f m beyond the shoulder" % nearest)
	var outward := true
	for b in range(0, vertices.size(), 42):
		var middle := Vector3.ZERO
		for i in 42:
			middle += vertices[b + i] / 42.0
		for i in range(0, 42, 3):
			var normal := (vertices[b + i + 2] - vertices[b + i]).cross(vertices[b + i + 1] - vertices[b + i])
			var centroid := (vertices[b + i] + vertices[b + i + 1] + vertices[b + i + 2]) / 3.0
			outward = outward and normal.dot(centroid - middle) > 0.0
	t.check("turned buildings still face outward", outward)
	for j in data.junctions.size():
		t.check("junction %d faces up" % j, _clockwise((root.get_node("Roads/Junction%d" % j) as MeshInstance3D).mesh))
	root.free()
	var first: int = result.bytes
	var again: Dictionary = UPRGBaker.bake_world(BASE.IN_PATH, world, OUT_PATH)
	t.check("the same seed gives the same streets", again.ok and again.streets == result.streets and absi(again.bytes - first) < 256)
	place.street_spacing = 5.0
	t.check("a street spacing too small is refused", not UPRGBaker.bake_world(BASE.IN_PATH, world, BASE.DIR + "/refused.scn").ok)


func run(t: Object) -> void:
	BASE.new()._write_terrain()
	_test_cross(t)
	_test_t(t)
	_test_refused(t)
	_test_streets(t)
	for f in [BASE.IN_PATH, OUT_PATH]:
		DirAccess.remove_absolute(f)
	DirAccess.remove_absolute(BASE.DIR)
