## Tests for UPRG on a synthetic baked terrain, so that the suite needs no UPTG code.
extends RefCounted

const CELLS := 64
const CELL := 8.0
const IN_PATH := "user://uprg_test/terrain.scn"
const OUT_PATH := "user://uprg_test/with_road.scn"


func _height(x: float, z: float) -> float:
	return 20.0 + x * 0.05 + 6.0 * sin(z * 0.03)


## Writes a file with the layout of the UPTG bake tool (format 1).
func _write_terrain(format_version: int = 1) -> void:
	var count := CELLS + 1
	var heights := PackedFloat32Array()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for iz in count:
		for ix in count:
			var x := (ix - CELLS / 2.0) * CELL
			var z := (iz - CELLS / 2.0) * CELL
			heights.append(_height(x, z))
			vertices.append(Vector3(x, _height(x, z), z))
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
	mesh.surface_set_material(0, StandardMaterial3D.new())
	var collision := HeightMapShape3D.new()
	collision.map_width = count
	collision.map_depth = count
	var root := Node3D.new()
	root.name = "Terrain"
	root.set_meta("terrain_data", {
		"format_version": format_version, "heights_checksum": 1, "grid_cells_x": CELLS, "grid_cells_z": CELLS,
		"cell_size": CELL, "sea_level": 0.0, "sea_floor_depth": 20.0, "heights": heights,
	})
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
	shape.scale = Vector3.ONE * CELL
	body.add_child(shape)
	shape.owner = root
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(IN_PATH.get_base_dir()))
	ResourceSaver.save(scene, IN_PATH, ResourceSaver.FLAG_COMPRESS)


func _road() -> UPRGRoadConfig:
	var road := UPRGRoadConfig.new()
	road.points = PackedVector2Array([Vector2(-140, -60), Vector2(-40, 20), Vector2(60, -30), Vector2(140, 40)])
	return road


func _has_script(node: Node) -> bool:
	if node.get_script() != null:
		return true
	for c in node.get_children():
		if _has_script(c):
			return true
	return false


func run(t: Object) -> void:
	_write_terrain()
	var road := _road()
	var input_size := FileAccess.get_file_as_bytes(IN_PATH).size()
	var result: Dictionary = UPRGBaker.bake(IN_PATH, [road] as Array[UPRGRoadConfig], OUT_PATH)
	t.check("bake writes the file", result.ok and FileAccess.file_exists(OUT_PATH), str(result))
	if not result.ok:
		return
	t.check("the input file is not changed", FileAccess.get_file_as_bytes(IN_PATH).size() == input_size)
	t.check("the result depends on no other file", ResourceLoader.get_dependencies(OUT_PATH).is_empty())
	var scene := ResourceLoader.load(OUT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var root := scene.instantiate() as Node3D
	t.check("no node of the result has a script", not _has_script(root))

	var meta: Dictionary = root.get_meta("terrain_data")
	var grid := UPRGTerrainGrid.from_meta(meta)
	var plan: Dictionary = meta.roads[0]
	var path: PackedVector2Array = plan.path
	var profile: PackedFloat32Array = plan.heights

	var spacing_ok := true
	for i in range(1, path.size() - 1):
		spacing_ok = spacing_ok and absf(path[i].distance_to(path[i - 1]) - road.sample_spacing) < 0.1
	t.check("cross-sections are evenly spaced", spacing_ok, "%d cross-sections" % path.size())
	t.check("the road starts and ends at its control points", path[0].distance_to(road.points[0]) < 0.01
		and path[path.size() - 1].distance_to(road.points[road.points.size() - 1]) < road.sample_spacing)
	var steepest := 0.0
	for i in range(1, profile.size()):
		steepest = maxf(steepest, absf(profile[i] - profile[i - 1]) / road.sample_spacing)
	t.check("the grade respects max_grade", steepest <= road.max_grade + 0.001, "steepest %.3f" % steepest)

	var flat_error := 0.0
	var far_error := 0.0
	var flat_count := 0
	var reach := road.width * 0.5 + road.shoulder
	for iz in CELLS + 1:
		for ix in CELLS + 1:
			var v := Vector2(grid.vertex_x(ix), grid.vertex_z(iz))
			var nearest := INF
			var target := 0.0
			for i in path.size():
				var d := v.distance_to(path[i])
				if d < nearest:
					nearest = d
					target = profile[i]
			var h := grid.heights[grid.index(ix, iz)]
			if nearest < reach - road.sample_spacing:
				flat_count += 1
				flat_error = maxf(flat_error, absf(h - (target - road.sink)))
			elif nearest > reach + CELL * 1.5 + road.blend + road.sample_spacing:
				far_error = maxf(far_error, absf(h - _height(v.x, v.y)))
	t.check("the terrain under the road follows it, just below the pavement", flat_count > 0 and flat_error < 0.12,
		"%d vertices, max error %.3f m" % [flat_count, flat_error])
	t.check("the terrain far from the road is unchanged", far_error < 0.0001, "max change %.5f m" % far_error)

	var mesh_node := root.get_node("Mesh") as MeshInstance3D
	var vertices: PackedVector3Array = mesh_node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var mesh_error := 0.0
	for i in vertices.size():
		mesh_error = maxf(mesh_error, absf(vertices[i].y - grid.heights[i]))
	t.check("the terrain mesh matches the edited heights", mesh_error < 0.0001)
	var shape := (root.get_node("Body/Shape") as CollisionShape3D).shape as HeightMapShape3D
	var shape_error := 0.0
	for i in grid.heights.size():
		shape_error = maxf(shape_error, absf(shape.map_data[i] * CELL - grid.heights[i]))
	t.check("the terrain collision matches the edited heights", shape_error < 0.0001)

	var road_node := root.get_node_or_null("Roads/Road0") as MeshInstance3D
	t.check("the road has a mesh and a collision", road_node != null
		and road_node.get_node("Body/Shape").shape is ConcavePolygonShape3D)
	var road_arrays: Array = road_node.mesh.surface_get_arrays(0)
	var rv: PackedVector3Array = road_arrays[Mesh.ARRAY_VERTEX]
	var ri: PackedInt32Array = road_arrays[Mesh.ARRAY_INDEX]
	var clockwise := true
	for i in range(0, ri.size(), 3):
		clockwise = clockwise and (rv[ri[i + 2]] - rv[ri[i]]).cross(rv[ri[i + 1]] - rv[ri[i]]).y > 0.0
	t.check("road triangles are clockwise seen from above", clockwise, "%d triangles" % (ri.size() / 3))
	t.check("the road is 4 points wide at every cross-section", rv.size() == path.size() * 4)
	root.free()

	var outside := _road()
	outside.points[0] = Vector2(-400, 0)
	t.check("a road outside the terrain is refused", not UPRGBaker.bake(IN_PATH, [outside] as Array[UPRGRoadConfig], OUT_PATH.replace("with", "no")).ok)
	var short := UPRGRoadConfig.new()
	t.check("a road without points is refused", not UPRGBaker.bake(IN_PATH, [short] as Array[UPRGRoadConfig], OUT_PATH.replace("with", "no")).ok)
	_write_terrain(99)
	t.check("an unknown file format is refused", not UPRGBaker.bake(IN_PATH, [_road()] as Array[UPRGRoadConfig], OUT_PATH.replace("with", "no")).ok)
	t.check("a refused bake writes no file", not FileAccess.file_exists(OUT_PATH.replace("with", "no")))

	DirAccess.remove_absolute(IN_PATH)
	DirAccess.remove_absolute(OUT_PATH)
	DirAccess.remove_absolute(IN_PATH.get_base_dir())
