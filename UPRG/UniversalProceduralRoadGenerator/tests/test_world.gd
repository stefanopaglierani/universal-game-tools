## Tests for terrain edits, places and skins, on a synthetic baked terrain.
extends RefCounted

const CELLS := 64
const CELL := 8.0
const DIR := "user://uprg_world_test"
const IN_PATH := DIR + "/terrain.scn"
const OUT_PATH := DIR + "/world.scn"
const IMAGE_PATH := DIR + "/skin.png"


func _terrain_heights() -> PackedFloat32Array:
	var heights := PackedFloat32Array()
	for iz in CELLS + 1:
		for ix in CELLS + 1:
			heights.append(20.0 + 3.0 * sin((ix - CELLS / 2.0) * 0.4) + 2.0 * cos((iz - CELLS / 2.0) * 0.3))
	return heights


func _write_terrain() -> void:
	var count := CELLS + 1
	var heights := _terrain_heights()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for iz in count:
		for ix in count:
			vertices.append(Vector3((ix - CELLS / 2.0) * CELL, heights[iz * count + ix], (iz - CELLS / 2.0) * CELL))
			normals.append(Vector3.UP)
			colors.append(Color.GREEN)
	for iz in CELLS:
		for ix in CELLS:
			var a := iz * count + ix
			indices.append_array([a, a + 1, a + count, a + 1, a + count + 1, a + count])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	mesh.surface_set_material(0, material)
	var collision := HeightMapShape3D.new()
	collision.map_width = count
	collision.map_depth = count
	var root := Node3D.new()
	root.name = "Terrain"
	root.set_meta("terrain_data", {"format_version": 1, "grid_cells_x": CELLS, "grid_cells_z": CELLS, "cell_size": CELL,
		"sea_level": 0.0, "sea_floor_depth": 20.0, "heights": heights})
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "Mesh"
	mesh_node.mesh = mesh
	root.add_child(mesh_node)
	mesh_node.owner = root
	var body := StaticBody3D.new()
	body.name = "Body"
	root.add_child(body)
	body.owner = root
	var shape := CollisionShape3D.new()
	shape.name = "Shape"
	shape.shape = collision
	body.add_child(shape)
	shape.owner = root
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	ResourceSaver.save(scene, IN_PATH, ResourceSaver.FLAG_COMPRESS)


func _world() -> UPRGWorldConfig:
	var world := UPRGWorldConfig.new()
	var raise := UPRGTerrainEdit.new()
	raise.center = Vector2(-120, -120)
	raise.radius = 30.0
	raise.blend = 20.0
	raise.amount = 25.0
	var level := UPRGTerrainEdit.new()
	level.kind = UPRGTerrainEdit.Kind.LEVEL
	level.center = Vector2(120, -120)
	level.radius = 30.0
	level.blend = 20.0
	level.height = 5.0
	var edits: Array[UPRGTerrainEdit] = [raise, level]
	world.terrain_edits = edits
	var place := UPRGPlace.new()
	place.center = Vector2(0, 100)
	place.radius = 70.0
	place.blend = 20.0
	place.building_count = 12
	place.seed_value = 7
	var places: Array[UPRGPlace] = [place]
	world.places = places
	var road := UPRGRoadConfig.new()
	road.points = PackedVector2Array([Vector2(-160, 100), Vector2(-60, 100), Vector2(60, 100), Vector2(160, 100)])
	var roads: Array[UPRGRoadConfig] = [road]
	world.roads = roads
	return world


func _load_world() -> Node3D:
	return (ResourceLoader.load(OUT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate() as Node3D


func _height_at(root: Node3D, x: float, z: float) -> float:
	var grid := UPRGTerrainGrid.from_meta(root.get_meta("terrain_data"))
	return grid.height_at(Vector2(x, z))


func run(t: Object) -> void:
	_write_terrain()
	var world := _world()
	var result: Dictionary = UPRGBaker.bake_world(IN_PATH, world, OUT_PATH)
	t.check("the world description bakes", result.ok, str(result))
	if not result.ok:
		return
	t.check("the result depends on no other file", ResourceLoader.get_dependencies(OUT_PATH).is_empty())
	var root := _load_world()
	var original := _terrain_heights()
	var grid := UPRGTerrainGrid.from_meta(root.get_meta("terrain_data"))

	var raised_i := grid.index(int(-120 / CELL + CELLS / 2.0), int(-120 / CELL + CELLS / 2.0))
	t.check("ADD raises the area by the amount", absf(grid.heights[raised_i] - original[raised_i] - 25.0) < 0.001,
		"%.3f m" % (grid.heights[raised_i] - original[raised_i]))
	var level_i := grid.index(int(120 / CELL + CELLS / 2.0), int(-120 / CELL + CELLS / 2.0))
	t.check("LEVEL sets the area to the height", absf(grid.heights[level_i] - 5.0) < 0.001, "%.3f m" % grid.heights[level_i])
	var far_i := grid.index(CELLS - 2, 2)
	t.check("the terrain outside the edits is unchanged", is_equal_approx(grid.heights[far_i], original[far_i]))

	var places: Array = root.get_meta("terrain_data").places
	t.check("the place is recorded with its buildings", places.size() == 1 and places[0].buildings == result.buildings and result.buildings > 0,
		"%d buildings" % result.buildings)
	var place_node := root.get_node_or_null("Places/Place0") as MeshInstance3D
	t.check("the place has a mesh and a collision", place_node != null and place_node.get_node("Body/Shape").shape is ConcavePolygonShape3D)
	var vertices: PackedVector3Array = place_node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var path: PackedVector2Array = (root.get_meta("terrain_data").roads[0]).path
	var nearest := INF
	for i in range(0, vertices.size(), 6):
		for p in path:
			nearest = minf(nearest, Vector2(vertices[i].x, vertices[i].z).distance_to(p))
	t.check("no building stands on the road", nearest > world.roads[0].width * 0.5 + world.roads[0].shoulder, "closest %.1f m" % nearest)
	# Each building is 14 triangles: front faces must look away from its center.
	var outward := true
	for b in range(0, vertices.size(), 42):
		var middle := Vector3.ZERO
		for i in 42:
			middle += vertices[b + i] / 42.0
		for i in range(0, 42, 3):
			var normal := (vertices[b + i + 2] - vertices[b + i]).cross(vertices[b + i + 1] - vertices[b + i])
			var centroid := (vertices[b + i] + vertices[b + i + 1] + vertices[b + i + 2]) / 3.0
			outward = outward and normal.dot(centroid - middle) > 0.0
	t.check("building faces look outward", outward, "%d triangles" % (vertices.size() / 3))
	root.free()

	var first := FileAccess.get_file_as_bytes(OUT_PATH).size()
	result = UPRGBaker.bake_world(IN_PATH, world, OUT_PATH)
	root = _load_world()
	var again: Array = root.get_meta("terrain_data").places
	t.check("the same seed gives the same number of buildings", again[0].buildings == places[0].buildings and absi(first - result.bytes) < 256)
	root.free()

	var image := Image.create(4, 4, false, Image.FORMAT_RGB8)
	image.fill(Color.ORANGE)
	image.save_png(IMAGE_PATH)
	var skin := UPRGSkin.new()
	skin.road_texture_path = IMAGE_PATH
	skin.terrain_texture_path = IMAGE_PATH
	skin.building_texture_path = IMAGE_PATH
	skin.terrain_tint = Color(0.5, 0.5, 0.5)
	world.skin = skin
	result = UPRGBaker.bake_world(IN_PATH, world, OUT_PATH)
	t.check("a skin bakes", result.ok, str(result))
	t.check("images stay inside the file", ResourceLoader.get_dependencies(OUT_PATH).is_empty())
	root = _load_world()
	var terrain_material := (root.get_node("Mesh") as MeshInstance3D).mesh.surface_get_material(0) as StandardMaterial3D
	var road_material := (root.get_node("Roads/Road0") as MeshInstance3D).mesh.surface_get_material(0) as StandardMaterial3D
	var place_material := (root.get_node("Places/Place0") as MeshInstance3D).mesh.surface_get_material(0) as StandardMaterial3D
	t.check("terrain, road and buildings use the images", terrain_material.albedo_texture != null and road_material.albedo_texture != null and place_material.albedo_texture != null)
	t.check("the terrain tint is applied", is_equal_approx(terrain_material.albedo_color.r, 0.5))
	root.free()

	skin.road_texture_path = DIR + "/missing.png"
	t.check("a missing image is refused", not UPRGBaker.bake_world(IN_PATH, world, DIR + "/refused.scn").ok)
	t.check("a refused bake writes no file", not FileAccess.file_exists(DIR + "/refused.scn"))
	var empty := UPRGWorldConfig.new()
	t.check("an empty world description is refused", not UPRGBaker.bake_world(IN_PATH, empty, DIR + "/refused.scn").ok)
	var far_place := _world()
	far_place.places[0].center = Vector2(500, 500)
	t.check("a place outside the terrain is refused", not UPRGBaker.bake_world(IN_PATH, far_place, DIR + "/refused.scn").ok)

	for f in [IN_PATH, OUT_PATH, IMAGE_PATH]:
		DirAccess.remove_absolute(f)
	DirAccess.remove_absolute(DIR)
