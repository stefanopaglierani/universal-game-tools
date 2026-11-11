## Export of a small world in every format.
extends RefCounted

const FOLDER := "user://upwg_export_test"


func run(t: SceneTree) -> void:
	var project := UPWGProject.from_template("continent", 5)
	UPWGProject.set_size(project.terrain, 1024.0, 8.0)
	var folder := ProjectSettings.globalize_path(FOLDER)
	var result := UPWGExporter.export_world(project, folder)
	t.check("a world exports", result.ok, str(result.get("error", "")))
	if not result.ok:
		return
	for f in ["godot/world.scn", "godot/tiles/world.scn", "heightmap/height.r16", "heightmap/height.exr", "heightmap/height.json", "gltf/terrain.glb", "world.json"]:
		t.check("%s is written" % f, FileAccess.file_exists(folder.path_join(f)))
	var cells := project.terrain.grid_cells_x
	var raw := FileAccess.get_file_as_bytes(folder.path_join("heightmap/height.r16"))
	t.check("the RAW heightmap has one 16-bit value per vertex", raw.size() == (cells + 1) * (cells + 1) * 2, "%d bytes" % raw.size())
	var exr := Image.load_from_file(folder.path_join("heightmap/height.exr"))
	t.check("the EXR heightmap has the size of the grid", exr != null and exr.get_width() == cells + 1)
	var info: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("heightmap/height.json")))
	t.check("the heightmap says its height range", info.highest_m > info.lowest_m)
	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	t.check("the glTF file can be read back", gltf.append_from_file(folder.path_join("gltf/terrain.glb"), state) == OK and state.get_meshes().size() >= 1)
	var summary: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("world.json")))
	t.check("world.json lists the seed and the files", summary.seed == 5 and (summary.files as Array).size() >= 5)
	var world := (load(folder.path_join("godot/tiles/world.scn")) as PackedScene).instantiate()
	t.check("the tiles can be opened by a game", world.has_meta("terrain_data") and world.get_meta("terrain_data").has("tiles"))
	world.free()

	project.export_godot_single = false
	project.export_gltf = false
	_remove(folder)
	result = UPWGExporter.export_world(project, folder)
	t.check("formats can be left out", result.ok and not FileAccess.file_exists(folder.path_join("godot/world.scn")) and not FileAccess.file_exists(folder.path_join("gltf/terrain.glb")))
	project.terrain.coast_position = 0.01
	t.check("an impossible world is refused with a message", not UPWGExporter.export_world(project, folder).ok)
	_remove(folder)

	# Sizes: 30 km is accepted with up to 8192 cells per side; past 2048 the world is "large".
	var big := UPWGProject.from_template("island", 1)
	big.resize(30720.0, 1.0)
	t.check("a 30 km world is accepted", big.validate().is_empty() and is_equal_approx(big.terrain.get_size().x, 30720.0)
		and big.terrain.grid_cells_x <= UPTGConfig.MAX_CELLS_PER_AXIS, "%d cells of %.1f m" % [big.terrain.grid_cells_x, big.terrain.cell_size])
	t.check("its export detail is as fine as 8192 cells allow", big.is_large() and roundi(30720.0 / big.export_cell()) <= UPWGProject.MAX_EXPORT_CELLS
		and big.export_cell() <= 4.0, "%.2f m" % big.export_cell())
	big.resize(2048.0, 4.0)
	t.check("a small world is not large", not big.is_large() and big.detail_cell == 0.0)

	# The large export path, on a small world made "large" by a finer export cell.
	var large := UPWGProject.from_template("island", 8)
	UPWGProject.set_size(large.terrain, 1024.0, 16.0)
	large.detail_cell = 8.0
	var hill := UPRGTerrainEdit.new()
	hill.center = Vector2(-100, 50)
	hill.radius = 80.0
	hill.blend = 60.0
	hill.amount = 70.0
	large.world.terrain_edits.append(hill)
	var lake := UPRGWater.new()
	lake.points = PackedVector2Array([Vector2(-100, 50)])
	lake.size = 30.0
	lake.depth = 4.0
	lake.shore = 12.0
	large.world.water.append(lake)
	result = UPWGExporter.export_world(large, folder)
	t.check("a large world exports straight to tiles", result.ok and DirAccess.dir_exists_absolute(folder.path_join("godot/tiles"))
		and not FileAccess.file_exists(folder.path_join("godot/world.scn")), str(result.get("error", "")))
	if result.ok:
		raw = FileAccess.get_file_as_bytes(folder.path_join("heightmap/height.r16"))
		t.check("its heightmap has the export detail", raw.size() == 129 * 129 * 2, "%d bytes" % raw.size())
		var rest := (load(folder.path_join("godot/tiles/world.scn")) as PackedScene).instantiate()
		var meta: Dictionary = rest.get_meta("terrain_data")
		t.check("its tiles have the export detail, the brush strokes and the lake", meta.cell_size == 8.0 and meta.tiles.list.size() > 0
			and rest.has_node("Water/Lake0") and meta.water.size() == 1 and meta.water[0].level > 60.0, "lake level %.1f" % meta.water[0].level)
		rest.free()
		summary = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("world.json")))
		t.check("world.json explains what was written", summary.cell_m == 8.0 and (summary.notes as Array).size() >= 2)
		state = GLTFState.new()
		t.check("its glTF has the ground and the lake", gltf.append_from_file(folder.path_join("gltf/terrain.glb"), state) == OK and state.get_meshes().size() >= 2)
	_remove(folder)


static func _remove(folder: String) -> void:
	if not DirAccess.dir_exists_absolute(folder):
		return
	for f in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(f))
	for d in DirAccess.get_directories_at(folder):
		_remove(folder.path_join(d))
	DirAccess.remove_absolute(folder)
