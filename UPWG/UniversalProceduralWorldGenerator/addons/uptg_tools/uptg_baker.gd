class_name UPTGBaker
extends RefCounted
## Development tool: writes a generated terrain to one self-contained scene file (.scn).
##
## The file holds only Godot built-in nodes and resources (mesh, material, collision shape) and the
## terrain data as metadata, with no script and no reference to UPTG. A game opens it without UPTG.
## This class lives outside addons/uptg/ and uses the generator's public functions, unchanged.

## Version of the layout of the baked file and of its "terrain_data" metadata.
const FORMAT_VERSION: int = 1
## Metadata key on the root node of the baked scene.
const META_KEY: StringName = &"terrain_data"


## Generates [param config] and saves it to [param out_path], which must end in ".scn".
## Returns a Dictionary: [code]ok[/code], and [code]error[/code] on failure, or [code]path[/code],
## [code]bytes[/code], [code]vertices[/code], [code]triangles[/code], [code]heights_checksum[/code].
static func bake(config: UPTGConfig, out_path: String, allow_large: bool = false) -> Dictionary:
	if out_path.get_extension() != "scn":
		return _fail("the output file must end in .scn: %s" % out_path)
	var errors := UPTGHeightfieldGenerator.check(config, allow_large)
	if not errors.is_empty():
		return _fail("; ".join(errors))

	var data := UPTGHeightfieldGenerator.generate(config, allow_large)
	if data == null:
		return _fail("height field generation failed")
	var mesh := UPTGMeshBuilder.build(data, config)
	if mesh == null:
		return _fail("mesh generation failed")
	var mode: UPTGConfig.CollisionMode = config.collision_mode
	var shape := UPTGCollisionBuilder.build(data, mode)
	if shape == null and mode != UPTGConfig.CollisionMode.NONE:
		return _fail("collision generation failed")
	# duplicate() clears the resource path, so the material is stored inside the file.
	mesh.surface_set_material(0, UPTGTerrain.DEFAULT_MATERIAL.duplicate())

	var root := _build_scene(data, mesh, shape, UPTGCollisionBuilder.get_shape_scale(data, mode))
	var scene := PackedScene.new()
	var pack_error := scene.pack(root)
	root.free()
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
		"vertices": data.vertex_count_x * data.vertex_count_z,
		"triangles": data.grid_cells_x * data.grid_cells_z * 2,
		"heights_checksum": data.heights_checksum,
	}


static func _build_scene(data: UPTGTerrainData, mesh: ArrayMesh, shape: Shape3D, shape_scale: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "Terrain"
	root.set_meta(META_KEY, {
		"format_version": FORMAT_VERSION,
		"algorithm_version": UPTGTerrainData.ALGORITHM_VERSION,
		"generation_seed": data.generation_seed,
		"config_checksum": data.config_checksum,
		"heights_checksum": data.heights_checksum,
		"grid_cells_x": data.grid_cells_x,
		"grid_cells_z": data.grid_cells_z,
		"cell_size": data.cell_size,
		"sea_level": data.sea_level,
		"sea_floor_depth": data.sea_floor_depth,
		"heights": data.heights,
	})
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "Mesh"
	mesh_node.mesh = mesh
	root.add_child(mesh_node)
	mesh_node.owner = root
	if shape != null:
		var body := StaticBody3D.new()
		body.name = "Body"
		root.add_child(body)
		body.owner = root
		var shape_node := CollisionShape3D.new()
		shape_node.name = "Shape"
		shape_node.shape = shape
		shape_node.scale = shape_scale
		body.add_child(shape_node)
		shape_node.owner = root
	return root


static func _fail(message: String) -> Dictionary:
	push_error("UPTG bake: " + message)
	return {"ok": false, "error": message}
