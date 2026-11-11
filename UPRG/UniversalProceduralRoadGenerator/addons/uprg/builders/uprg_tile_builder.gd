class_name UPRGTileBuilder
extends RefCounted
## Cuts the terrain of a baked world into square tiles that a game loads while the player drives.
## Each tile has a detailed mesh, a light mesh for the distance, and its own collision.
## What is left of the world (roads, places, objects, data) goes in world.scn.

const WORLD_FILE := "world.scn"
## The light mesh keeps one vertex out of this many along each side.
const FAR_STEP := 4
## Walls hanging from the edge of each mesh, to hide the gaps between detail levels.
const SKIRT := 8.0
## Distance from the tile at which the light mesh replaces the detailed one.
const NEAR_RANGE := 480.0
## A tile whose ground is all this far under the sea is not written.
const UNDER_SEA := 0.5
## With road colors: width of the strip beside the pavement where the red channel fades to 0.
const VERGE := 5.0


## Returns {ok, tiles, skipped, bytes, tile_size} or {ok: false, error}.
## With [param road_colors] the vertex colors no longer hold the terrain colors: the red channel
## is 1 next to the roads and 0 away from them, for a game shader that textures the ground itself.
static func split(in_path: String, out_dir: String, tile_cells: int, road_colors: bool = false) -> Dictionary:
	var packed := ResourceLoader.load(in_path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		return _fail("cannot load the world: %s" % in_path)
	var root := packed.instantiate() as Node3D
	var result := _split(root, out_dir, tile_cells, road_colors)
	root.free()
	return result


static func _split(root: Node3D, out_dir: String, tile_cells: int, road_colors: bool) -> Dictionary:
	var meta: Dictionary = root.get_meta(UPRGBaker.META_KEY, {})
	var grid := UPRGTerrainGrid.from_meta(meta)
	var mesh_node := root.get_node_or_null("Mesh") as MeshInstance3D
	if grid == null or mesh_node == null:
		return _fail("the file is not a baked world")
	if tile_cells < FAR_STEP or grid.cells_x % tile_cells != 0 or grid.cells_z % tile_cells != 0 or tile_cells % FAR_STEP != 0:
		return _fail("%d cells per tile do not divide the %d x %d grid" % [tile_cells, grid.cells_x, grid.cells_z])
	var folder_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	if folder_error != OK:
		return _fail("could not create the output folder (error %d)" % folder_error)
	var source := mesh_node.mesh.surface_get_arrays(0)
	if road_colors:
		source[Mesh.ARRAY_COLOR] = _road_colors(grid, meta.get("roads", []))
	var material := mesh_node.mesh.surface_get_material(0)
	var written: Array[Vector2i] = []
	var bytes := 0
	var skipped := 0
	for tz in grid.cells_z / tile_cells:
		for tx in grid.cells_x / tile_cells:
			if _under_sea(grid, tx, tz, tile_cells):
				skipped += 1
				continue
			var tile := _make_tile(grid, source, tx, tz, tile_cells)
			var scene := PackedScene.new()
			var pack_error := scene.pack(tile)
			tile.free()
			var path := out_dir.path_join(tile_file(tx, tz))
			if pack_error != OK or ResourceSaver.save(scene, path, ResourceSaver.FLAG_COMPRESS) != OK:
				return _fail("could not save %s" % path)
			written.append(Vector2i(tx, tz))
			bytes += FileAccess.get_file_as_bytes(path).size()

	for child_name: String in ["Mesh", "Body"]:
		var child := root.get_node_or_null(child_name)
		if child != null:
			root.remove_child(child)
			child.free()
	var tile_size := tile_cells * grid.cell_size
	meta = meta.duplicate()
	meta.erase("heights")
	meta.tiles = {"size": tile_size, "origin": Vector2(-grid.cells_x, -grid.cells_z) * grid.cell_size * 0.5, "list": written}
	meta.terrain_material = material
	root.set_meta(UPRGBaker.META_KEY, meta)
	var world := PackedScene.new()
	var world_path := out_dir.path_join(WORLD_FILE)
	if world.pack(root) != OK or ResourceSaver.save(world, world_path, ResourceSaver.FLAG_COMPRESS) != OK:
		return _fail("could not save %s" % world_path)
	bytes += FileAccess.get_file_as_bytes(world_path).size()
	return {"ok": true, "tiles": written.size(), "skipped": skipped, "bytes": bytes, "tile_size": tile_size}


static func tile_file(tx: int, tz: int) -> String:
	return "tile_%d_%d.scn" % [tx, tz]


static func _road_colors(grid: UPRGTerrainGrid, roads: Array) -> PackedColorArray:
	var near := PackedFloat32Array()
	near.resize(grid.heights.size())
	for road: Dictionary in roads:
		var inner: float = road.width * 0.5 + 1.0
		var outer := inner + VERGE
		var reach := int(ceil(outer / grid.cell_size))
		for p: Vector2 in road.path:
			var cx := roundi(p.x / grid.cell_size + grid.cells_x / 2.0)
			var cz := roundi(p.y / grid.cell_size + grid.cells_z / 2.0)
			for iz in range(maxi(cz - reach, 0), mini(cz + reach, grid.cells_z) + 1):
				for ix in range(maxi(cx - reach, 0), mini(cx + reach, grid.cells_x) + 1):
					var d := Vector2(grid.vertex_x(ix), grid.vertex_z(iz)).distance_to(p)
					var i := grid.index(ix, iz)
					near[i] = maxf(near[i], 1.0 - smoothstep(inner, outer, d))
	var colors := PackedColorArray()
	colors.resize(near.size())
	for i in near.size():
		colors[i] = Color(near[i], 0.0, 0.0, 1.0)
	return colors


static func _under_sea(grid: UPRGTerrainGrid, tx: int, tz: int, tile_cells: int) -> bool:
	var limit := grid.sea_level - UNDER_SEA
	for iz in range(tz * tile_cells, (tz + 1) * tile_cells + 1):
		for ix in range(tx * tile_cells, (tx + 1) * tile_cells + 1):
			if grid.heights[grid.index(ix, iz)] >= limit:
				return false
	return true


static func _make_tile(grid: UPRGTerrainGrid, source: Array, tx: int, tz: int, tile_cells: int) -> Node3D:
	var tile := Node3D.new()
	tile.name = "Tile_%d_%d" % [tx, tz]
	tile.position = Vector3(grid.vertex_x(tx * tile_cells), 0.0, grid.vertex_z(tz * tile_cells))
	var near := MeshInstance3D.new()
	near.name = "Near"
	near.mesh = _mesh(grid, source, tx, tz, tile_cells, 1, tile.position)
	near.visibility_range_end = NEAR_RANGE
	_add(tile, near, tile)
	var far := MeshInstance3D.new()
	far.name = "Far"
	far.mesh = _mesh(grid, source, tx, tz, tile_cells, FAR_STEP, tile.position)
	far.visibility_range_begin = NEAR_RANGE
	far.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(tile, far, tile)
	var body := StaticBody3D.new()
	body.name = "Body"
	_add(tile, body, tile)
	var shape_node := CollisionShape3D.new()
	shape_node.name = "Shape"
	var shape := HeightMapShape3D.new()
	shape.map_width = tile_cells + 1
	shape.map_depth = tile_cells + 1
	var scaled := PackedFloat32Array()
	for iz in range(tz * tile_cells, (tz + 1) * tile_cells + 1):
		for ix in range(tx * tile_cells, (tx + 1) * tile_cells + 1):
			scaled.append(grid.heights[grid.index(ix, iz)] / grid.cell_size)
	shape.map_data = scaled
	shape_node.shape = shape
	shape_node.scale = Vector3.ONE * grid.cell_size
	shape_node.position = Vector3(tile_cells * grid.cell_size * 0.5, 0.0, tile_cells * grid.cell_size * 0.5)
	_add(body, shape_node, tile)
	return tile


static func _add(parent: Node, child: Node, root: Node) -> void:
	parent.add_child(child)
	child.owner = root


static func _mesh(grid: UPRGTerrainGrid, source: Array, tx: int, tz: int, tile_cells: int, step: int, origin: Vector3) -> ArrayMesh:
	var from_normals: PackedVector3Array = source[Mesh.ARRAY_NORMAL]
	var from_colors: Variant = source[Mesh.ARRAY_COLOR]
	var from_uvs: Variant = source[Mesh.ARRAY_TEX_UV]
	var count := tile_cells / step + 1
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var add_vertex := func(ix: int, iz: int, drop: float) -> void:
		var i := grid.index(ix, iz)
		vertices.append(Vector3(grid.vertex_x(ix) - origin.x, grid.heights[i] - drop, grid.vertex_z(iz) - origin.z))
		normals.append(from_normals[i])
		if from_colors != null:
			colors.append((from_colors as PackedColorArray)[i])
		if from_uvs != null:
			uvs.append((from_uvs as PackedVector2Array)[i])
	for j in count:
		for i in count:
			add_vertex.call(tx * tile_cells + i * step, tz * tile_cells + j * step, 0.0)
	var indices := PackedInt32Array()
	for j in count - 1:
		for i in count - 1:
			var a := j * count + i
			indices.append_array([a, a + 1, a + count, a + 1, a + count + 1, a + count])
	# Walls around the border, seen from both sides.
	var border: Array[Vector2i] = []
	for i in count - 1:
		border.append(Vector2i(i, 0))
	for j in count - 1:
		border.append(Vector2i(count - 1, j))
	for i in range(count - 1, 0, -1):
		border.append(Vector2i(i, count - 1))
	for j in range(count - 1, 0, -1):
		border.append(Vector2i(0, j))
	var first_low := vertices.size()
	for b in border:
		add_vertex.call(tx * tile_cells + b.x * step, tz * tile_cells + b.y * step, SKIRT)
	for n in border.size():
		var high0 := border[n].y * count + border[n].x
		var next := border[(n + 1) % border.size()]
		var high1 := next.y * count + next.x
		var low0 := first_low + n
		var low1 := first_low + (n + 1) % border.size()
		indices.append_array([high0, high1, low0, high1, low1, low0, high0, low0, high1, high1, low0, low1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	if from_colors != null:
		arrays[Mesh.ARRAY_COLOR] = colors
	if from_uvs != null:
		arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _fail(message: String) -> Dictionary:
	push_error("UPRG tiles: " + message)
	return {"ok": false, "error": message}
