class_name UPRGBaker
extends RefCounted
## Reads a terrain baked by UPTG, adds roads and writes a new self-contained .scn file.
## It reads only the file: UPRG contains no UPTG code. The input file is never changed.

const META_KEY: StringName = &"terrain_data"
const ROADS_FORMAT: int = 1


## Adds only roads. See [method bake_world].
static func bake(in_path: String, roads: Array[UPRGRoadConfig], out_path: String) -> Dictionary:
	if roads.is_empty():
		return _fail("no road to add")
	var world := UPRGWorldConfig.new()
	world.roads = roads
	return bake_world(in_path, world, out_path)


## Returns a Dictionary: [code]ok[/code], and [code]error[/code] on failure, or [code]path[/code],
## [code]bytes[/code], [code]roads[/code], [code]road_length[/code], [code]places[/code],
## [code]buildings[/code], [code]vertices_changed[/code].
static func bake_world(in_path: String, world: UPRGWorldConfig, out_path: String) -> Dictionary:
	if out_path.get_extension() != "scn":
		return _fail("the output file must end in .scn: %s" % out_path)
	var errors := world.validate()
	if not errors.is_empty():
		return _fail("; ".join(errors))
	var packed := ResourceLoader.load(in_path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		return _fail("cannot load the terrain: %s" % in_path)
	var root := packed.instantiate() as Node3D
	var result := _add_world(root, world, out_path)
	root.free()
	return result


static func _add_world(root: Node3D, world: UPRGWorldConfig, out_path: String) -> Dictionary:
	if root == null:
		return _fail("the file is not a baked terrain")
	var meta: Dictionary = root.get_meta(META_KEY, {})
	var grid := UPRGTerrainGrid.from_meta(meta)
	if grid == null:
		return _fail("the terrain has no supported terrain_data metadata")
	var mesh_node := root.get_node_or_null("Mesh") as MeshInstance3D
	var shape_node := root.get_node_or_null("Body/Shape") as CollisionShape3D
	if mesh_node == null or shape_node == null or not shape_node.shape is HeightMapShape3D:
		return _fail("the terrain needs a Mesh and a height map collision")

	var roads := world.roads
	var skin_errors := PackedStringArray()
	var plans: Array[UPRGRoadShape] = []
	var changed := 0
	var total_length := 0.0
	for edit in world.terrain_edits:
		changed += edit.apply(grid)
	for place in world.places:
		if not grid.is_inside(place.center, place.radius + place.blend):
			return _fail("place %s leaves the terrain or comes too close to its border" % place.place_name)
		UPRGPlaceBuilder.level_ground(place, grid)
	for road in roads:
		var plan := UPRGRoadShape.plan(road, grid)
		if plan == null:
			return _fail("a road leaves the terrain or comes too close to its border")
		changed += plan.apply_to_terrain(road, grid)
		total_length += (plan.path.size() - 1) * road.sample_spacing
		plans.append(plan)

	var road_paths: Array[PackedVector2Array] = []
	var road_clearances := PackedFloat32Array()
	for i in roads.size():
		road_paths.append(plans[i].path)
		road_clearances.append(roads[i].width * 0.5 + roads[i].shoulder + 2.0)

	var new_mesh := _rebuild_terrain_mesh(mesh_node.mesh as ArrayMesh, grid)
	if new_mesh == null:
		return _fail("the terrain mesh does not follow the grid order")
	mesh_node.mesh = new_mesh
	if world.skin != null:
		var terrain_material := new_mesh.surface_get_material(0) as StandardMaterial3D
		if terrain_material != null:
			terrain_material.albedo_color *= world.skin.terrain_tint
			var terrain_texture := UPRGSkin.load_texture(world.skin.terrain_texture_path, skin_errors)
			if terrain_texture != null:
				terrain_material.albedo_texture = terrain_texture
	var collision := HeightMapShape3D.new()
	collision.map_width = grid.cells_x + 1
	collision.map_depth = grid.cells_z + 1
	var scaled := PackedFloat32Array()
	scaled.resize(grid.heights.size())
	for i in grid.heights.size():
		scaled[i] = grid.heights[i] / grid.cell_size
	collision.map_data = scaled
	shape_node.shape = collision

	var group := Node3D.new()
	group.name = "Roads"
	root.add_child(group)
	group.owner = root
	var road_meta: Array[Dictionary] = []
	for i in roads.size():
		_add_road_nodes(group, root, "Road%d" % i, roads[i], plans[i], world.skin, skin_errors)
		road_meta.append({
			"path": plans[i].path,
			"heights": plans[i].heights,
			"width": roads[i].width,
			"sample_spacing": roads[i].sample_spacing,
		})
	var buildings_total := 0
	var place_meta: Array[Dictionary] = []
	var places_group := Node3D.new()
	places_group.name = "Places"
	root.add_child(places_group)
	places_group.owner = root
	for i in world.places.size():
		var place := world.places[i]
		var buildings := UPRGPlaceBuilder.plan_buildings(place, road_paths, road_clearances)
		buildings_total += buildings.size()
		_add_place_nodes(places_group, root, "Place%d" % i, world.skin, buildings, grid, skin_errors)
		place_meta.append({"name": place.place_name, "center": place.center, "radius": place.radius, "buildings": buildings.size()})
	if not skin_errors.is_empty():
		return _fail("; ".join(skin_errors))

	meta = meta.duplicate()
	meta.source_heights_checksum = meta.get("heights_checksum", 0)
	meta.heights = grid.heights
	meta.heights_checksum = _fnv1a(grid.heights.to_byte_array())
	meta.roads_format_version = ROADS_FORMAT
	meta.roads = road_meta
	meta.places = place_meta
	root.set_meta(META_KEY, meta)

	var scene := PackedScene.new()
	var pack_error := scene.pack(root)
	if pack_error != OK:
		return _fail("could not pack the scene (error %d)" % pack_error)
	var folder_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_path.get_base_dir()))
	if folder_error != OK:
		return _fail("could not create the output folder (error %d)" % folder_error)
	var save_error := ResourceSaver.save(scene, out_path, ResourceSaver.FLAG_COMPRESS)
	if save_error != OK:
		return _fail("could not save %s (error %d)" % [out_path, save_error])
	return {
		"ok": true,
		"path": out_path,
		"bytes": FileAccess.get_file_as_bytes(out_path).size(),
		"roads": roads.size(),
		"road_length": total_length,
		"places": world.places.size(),
		"buildings": buildings_total,
		"vertices_changed": changed,
	}


static func _rebuild_terrain_mesh(old: ArrayMesh, grid: UPRGTerrainGrid) -> ArrayMesh:
	var arrays := old.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	if vertices.size() != grid.heights.size():
		return null
	for iz in grid.cells_z + 1:
		for ix in grid.cells_x + 1:
			var i := grid.index(ix, iz)
			if not is_equal_approx(vertices[i].x, grid.vertex_x(ix)) or not is_equal_approx(vertices[i].z, grid.vertex_z(iz)):
				return null
			vertices[i].y = grid.heights[i]
			normals[i] = grid.normal_at_vertex(ix, iz)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# duplicate() clears the resource path, so the material stays inside the new file.
	mesh.surface_set_material(0, old.surface_get_material(0).duplicate())
	return mesh


static func _add_place_nodes(group: Node3D, root: Node3D, place_name: String, skin: UPRGSkin, buildings: Array[Dictionary],
		grid: UPRGTerrainGrid, errors: PackedStringArray) -> void:
	var uv_size := skin.building_uv_size if skin != null else 4.0
	var mesh := UPRGPlaceBuilder.build_mesh(buildings, grid, uv_size)
	if mesh == null:
		return
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	if skin != null:
		material.albedo_texture = UPRGSkin.load_texture(skin.building_texture_path, errors)
	mesh.surface_set_material(0, material)
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = place_name
	mesh_node.mesh = mesh
	group.add_child(mesh_node)
	mesh_node.owner = root
	var body := StaticBody3D.new()
	body.name = "Body"
	mesh_node.add_child(body)
	body.owner = root
	var shape_node := CollisionShape3D.new()
	shape_node.name = "Shape"
	var faces: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape_node.shape = shape
	body.add_child(shape_node)
	shape_node.owner = root


static func _add_road_nodes(group: Node3D, root: Node3D, road_name: String, road: UPRGRoadConfig, plan: UPRGRoadShape,
		skin: UPRGSkin, errors: PackedStringArray) -> void:
	var mesh := UPRGRoadBuilder.build_mesh(road, plan, skin, errors)
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = road_name
	mesh_node.mesh = mesh
	group.add_child(mesh_node)
	mesh_node.owner = root
	var body := StaticBody3D.new()
	body.name = "Body"
	mesh_node.add_child(body)
	body.owner = root
	var shape_node := CollisionShape3D.new()
	shape_node.name = "Shape"
	shape_node.shape = UPRGRoadBuilder.build_collision(mesh)
	body.add_child(shape_node)
	shape_node.owner = root


static func _fnv1a(bytes: PackedByteArray) -> int:
	var h := 0x811C9DC5
	for b in bytes:
		h = ((h ^ b) * 0x01000193) & 0xFFFFFFFF
	return h


static func _fail(message: String) -> Dictionary:
	push_error("UPRG bake: " + message)
	return {"ok": false, "error": message}
