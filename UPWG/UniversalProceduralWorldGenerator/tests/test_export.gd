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


static func _remove(folder: String) -> void:
	if not DirAccess.dir_exists_absolute(folder):
		return
	for f in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(f))
	for d in DirAccess.get_directories_at(folder):
		_remove(folder.path_join(d))
	DirAccess.remove_absolute(folder)
