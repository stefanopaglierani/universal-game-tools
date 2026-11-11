## Tests for cutting a baked world into tiles, on a synthetic baked terrain.
extends RefCounted

const BASE := preload("res://tests/test_world.gd")
const WORLD_IN := BASE.DIR + "/world_for_tiles.scn"
const OUT_DIR := BASE.DIR + "/tiles"
const CELLS := 32


func _load_tile(x: int, z: int) -> Node3D:
	return (ResourceLoader.load(OUT_DIR.path_join(UPRGTileBuilder.tile_file(x, z)), "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate() as Node3D


func _vertices(tile: Node3D, node_name: String) -> PackedVector3Array:
	return (tile.get_node(node_name) as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]


func run(t: Object) -> void:
	BASE.new()._write_terrain()
	var road := UPRGRoadConfig.new()
	road.points = PackedVector2Array([Vector2(-160, 40), Vector2(0, 40), Vector2(160, 40)])
	var world := UPRGWorldConfig.new()
	var roads: Array[UPRGRoadConfig] = [road]
	world.roads = roads
	var baked: Dictionary = UPRGBaker.bake_world(BASE.IN_PATH, world, WORLD_IN)
	t.check("the world for the tiles bakes", baked.ok, str(baked))
	var result: Dictionary = UPRGTileBuilder.split(WORLD_IN, OUT_DIR, CELLS)
	t.check("the world is cut into tiles", result.ok and result.tiles == 4, str(result))
	if not result.ok:
		return

	var left := _load_tile(0, 0)
	var right := _load_tile(1, 0)
	var near_count := (CELLS + 1) * (CELLS + 1)
	var near := _vertices(left, "Near")
	var far := _vertices(left, "Far")
	t.check("a tile has a detailed mesh", near.size() > near_count)
	t.check("the distant mesh is much lighter", far.size() < near.size() / 8, "%d and %d vertices" % [near.size(), far.size()])
	var near_node := left.get_node("Near") as MeshInstance3D
	var far_node := left.get_node("Far") as MeshInstance3D
	t.check("the two meshes take turns with distance", is_equal_approx(near_node.visibility_range_end, far_node.visibility_range_begin))

	var matched := 0
	for j in CELLS + 1:
		var a := near[j * (CELLS + 1) + CELLS] + left.position
		var b := near_vertices_at(right, j) + right.position
		if a.is_equal_approx(b):
			matched += 1
	t.check("neighbor tiles share the same border", matched == CELLS + 1, "%d of %d points" % [matched, CELLS + 1])

	var shape := left.get_node("Body/Shape") as CollisionShape3D
	var height_map := shape.shape as HeightMapShape3D
	t.check("each tile has its own collision", height_map != null and height_map.map_width == CELLS + 1)
	var corner := near[0]
	var data := height_map.map_data
	t.check("the collision matches the ground", is_equal_approx(data[0] * shape.scale.x, corner.y), "%.3f and %.3f" % [data[0] * shape.scale.x, corner.y])
	t.check("the tile has no external files", ResourceLoader.get_dependencies(OUT_DIR.path_join(UPRGTileBuilder.tile_file(0, 0))).is_empty())
	left.free()
	right.free()

	var rest := (ResourceLoader.load(OUT_DIR.path_join(UPRGTileBuilder.WORLD_FILE), "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate() as Node3D
	var data_out: Dictionary = rest.get_meta("terrain_data")
	t.check("the rest of the world keeps the roads", rest.has_node("Roads/Road0") and data_out.roads.size() == 1)
	t.check("the ground is only in the tiles", not rest.has_node("Mesh") and not rest.has_node("Body") and not data_out.has("heights"))
	t.check("the world lists its tiles", (data_out.tiles.list as Array).size() == 4 and is_equal_approx(data_out.tiles.size, CELLS * BASE.CELL))
	rest.free()

	t.check("a size that does not divide the grid is refused", not UPRGTileBuilder.split(WORLD_IN, OUT_DIR, 30).ok)

	result = UPRGTileBuilder.split(WORLD_IN, OUT_DIR, CELLS, true)
	t.check("road colors are written", result.ok, str(result))
	var tile := _load_tile(0, 1)
	var mesh := (tile.get_node("Near") as MeshInstance3D).mesh
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var on_road := 0.0
	var far_away := 1.0
	for i in vertices.size():
		var z := vertices[i].z + tile.position.z
		if absf(z - 40.0) < 2.0:
			on_road = maxf(on_road, colors[i].r)
		if absf(z - 40.0) > 30.0:
			far_away = minf(far_away, 1.0 - colors[i].r)
	t.check("red marks the ground next to the road only", on_road > 0.99 and far_away > 0.99, "%.2f on the road, %.2f far" % [on_road, 1.0 - far_away])
	tile.free()

	# Tiles straight from a height grid (worlds too big for one mesh): same ground as the baked tiles.
	var baked_tile := _load_tile(1, 1)
	var baked_near := _vertices(baked_tile, "Near")
	baked_tile.free()
	var packed := ResourceLoader.load(WORLD_IN, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var source := packed.instantiate() as Node3D
	var grid := UPRGTerrainGrid.from_meta(source.get_meta(UPRGBaker.META_KEY))
	var meta: Dictionary = (source.get_meta(UPRGBaker.META_KEY) as Dictionary).duplicate()
	source.free()
	var rest_root := Node3D.new()
	rest_root.name = "World"
	result = UPRGTileBuilder.split_grid(grid, rest_root, meta, OUT_DIR, CELLS, 8.0)
	rest_root.free()
	t.check("tiles can be written from a height grid", result.ok and result.tiles == 4, str(result))
	var grid_tile := _load_tile(1, 1)
	var grid_near := _vertices(grid_tile, "Near")
	var grid_body := grid_tile.get_node_or_null("Body/Shape") != null
	grid_tile.free()
	var same_ground := grid_near.size() == baked_near.size()
	for i in range(0, mini(grid_near.size(), baked_near.size()), 7):
		same_ground = same_ground and grid_near[i].is_equal_approx(baked_near[i])
	t.check("they have the same ground and a collision", same_ground and grid_body)
	var listed := (ResourceLoader.load(OUT_DIR.path_join(UPRGTileBuilder.WORLD_FILE), "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate() as Node3D
	t.check("and a world file that lists them", (listed.get_meta(UPRGBaker.META_KEY).tiles.list as Array).size() == 4)
	listed.free()

	for f in DirAccess.get_files_at(OUT_DIR):
		DirAccess.remove_absolute(OUT_DIR.path_join(f))
	DirAccess.remove_absolute(OUT_DIR)
	for f in [BASE.IN_PATH, WORLD_IN]:
		DirAccess.remove_absolute(f)
	DirAccess.remove_absolute(BASE.DIR)


func near_vertices_at(tile: Node3D, row: int) -> Vector3:
	return _vertices(tile, "Near")[row * (CELLS + 1)]
