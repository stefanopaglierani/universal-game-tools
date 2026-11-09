## Tests for world dressing on a synthetic terrain and a small synthetic library.
extends RefCounted

const CELLS := 64
const CELL := 8.0
const DIR := "user://uprg_dressing_test"
const IN_PATH := DIR + "/terrain.scn"
const OUT_PATH := DIR + "/world.scn"
const LIB := DIR + "/library"


func _mesh(size: float) -> ArrayMesh:
	var box := BoxMesh.new()
	box.size = Vector3.ONE * size
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.surface_get_arrays(0))
	mesh.surface_set_material(0, StandardMaterial3D.new())
	return mesh


func _write_library() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LIB))
	var index: Array[Dictionary] = []
	var n := 1
	for kind in ["house", "tree", "bush", "rock", "lamp", "barrier", "prop", "yard"]:
		var path := "%s/%s.res" % [LIB, kind]
		ResourceSaver.save(_mesh(4.0), path)
		index.append({"id": "%03d" % n, "n": n, "kind": kind, "path": path, "size": [4.0, 4.0, 4.0], "triangles": 12,
			"model": "Model %s" % kind, "author": "Author", "license": "CC BY 4.0", "source": "Test", "link": "https://example.test"})
		n += 1
	var file := FileAccess.open(LIB + "/index.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(index))
	file.close()


func _write_terrain() -> void:
	var count := CELLS + 1
	var heights := PackedFloat32Array()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for iz in count:
		for ix in count:
			heights.append(20.0)
			vertices.append(Vector3((ix - CELLS / 2.0) * CELL, 20.0, (iz - CELLS / 2.0) * CELL))
			normals.append(Vector3.UP)
	for iz in CELLS:
		for ix in CELLS:
			var a := iz * count + ix
			indices.append_array([a, a + 1, a + count, a + 1, a + count + 1, a + count])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, StandardMaterial3D.new())
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
	ResourceSaver.save(scene, IN_PATH, ResourceSaver.FLAG_COMPRESS)


func _world() -> UPRGWorldConfig:
	var world := UPRGWorldConfig.new()
	var place := UPRGPlace.new()
	place.center = Vector2(0, 100)
	place.radius = 60.0
	place.building_count = 6
	var places: Array[UPRGPlace] = [place]
	world.places = places
	var road := UPRGRoadConfig.new()
	road.points = PackedVector2Array([Vector2(-160, -60), Vector2(0, -40), Vector2(160, -60)])
	var roads: Array[UPRGRoadConfig] = [road]
	world.roads = roads
	var dressing := UPRGDressing.new()
	dressing.library_path = LIB
	world.dressing = dressing
	return world


func _instances(root: Node3D) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for node in root.get_node("Dressing").find_children("*", "MultiMeshInstance3D", true, false):
		var mm := (node as MultiMeshInstance3D).multimesh
		var buffer := mm.buffer
		for i in mm.instance_count:
			out.append(Vector3(buffer[i * 12 + 3], buffer[i * 12 + 7], buffer[i * 12 + 11]))
	return out


func run(t: Object) -> void:
	_write_library()
	_write_terrain()
	var world := _world()
	var result: Dictionary = UPRGBaker.bake_world(IN_PATH, world, OUT_PATH)
	t.check("a dressed world bakes", result.ok, str(result.get("dressing", result.get("error"))))
	if not result.ok:
		return
	t.check("models stay inside the world file", ResourceLoader.get_dependencies(OUT_PATH).is_empty(),
		str(ResourceLoader.get_dependencies(OUT_PATH)))
	var root := (ResourceLoader.load(OUT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate() as Node3D
	var instances := _instances(root)
	t.check("plants, rocks and roadside objects are placed", instances.size() > 50 and result.dressing.roadside > 0, "%d objects" % instances.size())

	var path: PackedVector2Array = root.get_meta("terrain_data").roads[0].path
	var on_road := 0
	for p in instances:
		for s in path:
			if Vector2(p.x, p.z).distance_to(s) < world.roads[0].width * 0.5:
				on_road += 1
				break
	t.check("nothing stands on the pavement", on_road == 0, "%d on the road" % on_road)
	var in_place := 0
	for p in instances:
		if Vector2(p.x, p.z).distance_to(world.places[0].center) < world.places[0].radius:
			in_place += 1
	t.check("scattered objects leave the places free", in_place == 0, "%d inside" % in_place)
	var furthest := 0.0
	for p in instances:
		furthest = maxf(furthest, absf(p.y - 20.0))
	t.check("objects sit on the ground", furthest < 0.6, "furthest %.2f m" % furthest)
	var spread := 0.0
	for p in instances:
		spread = maxf(spread, Vector2(p.x, p.z).length())
	t.check("objects are spread over the terrain", spread > 200.0, "up to %.0f m from the center" % spread)

	var place := root.get_node("Places/Place0")
	var buildings := 0
	var boxes := 0
	for child in place.get_children():
		if str(child.name).begins_with("Building"):
			buildings += 1
	for shape in place.get_node("Body").get_children():
		if (shape as CollisionShape3D).shape is BoxShape3D:
			boxes += 1
	t.check("places use library models with solid boxes", buildings > 0 and buildings == boxes, "%d buildings" % buildings)
	var groups := root.get_node("Dressing").find_children("*", "MultiMeshInstance3D", true, false)
	t.check("objects disappear at a distance", groups.all(func(n: Node) -> bool: return (n as MultiMeshInstance3D).visibility_range_end > 0.0))
	t.check("solid objects have collision", root.get_node("Dressing/Solids").get_child_count() > 0)
	root.free()

	var credits_path := OUT_PATH.get_basename() + ".credits.md"
	var credits := FileAccess.get_file_as_string(credits_path)
	t.check("the credits list the models used", credits.contains("Model house") and credits.contains("CC BY 4.0"))
	t.check("the credits skip what was not used", not credits.contains("Model pine"))

	var first: int = result.dressing.instances
	var again: Dictionary = UPRGBaker.bake_world(IN_PATH, world, OUT_PATH)
	t.check("the same seed gives the same dressing", again.ok and again.dressing.instances == first)

	var missing := _world()
	missing.dressing.library_path = DIR + "/nothing"
	t.check("a missing library is refused", not UPRGBaker.bake_world(IN_PATH, missing, DIR + "/refused.scn").ok)

	for f in DirAccess.get_files_at(LIB):
		DirAccess.remove_absolute(LIB.path_join(f))
	DirAccess.remove_absolute(LIB)
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))
	DirAccess.remove_absolute(DIR)
