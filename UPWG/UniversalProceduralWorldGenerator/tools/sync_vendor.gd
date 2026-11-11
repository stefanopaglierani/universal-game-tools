extends SceneTree
## Copies the generators UPWG is built on into this project. Run from the module folder after any
## change to UPTG, UPRG or UWR:
## godot --headless --path . -s res://tools/sync_vendor.gd
## tests/test_vendor.gd fails while the copies differ from their sources.

const SOURCES := [
	["../../UPTG/UniversalProceduralTerrainGenerator/addons/uptg", "addons/uptg"],
	["../../UPTG/UniversalProceduralTerrainGenerator/tools/uptg_baker.gd", "addons/uptg_tools/uptg_baker.gd"],
	["../../UPTG/UniversalProceduralTerrainGenerator/tools/uptg_baker.gd.uid", "addons/uptg_tools/uptg_baker.gd.uid"],
	["../../UPRG/UniversalProceduralRoadGenerator/addons/uprg", "addons/uprg"],
	["../../UWR/UniversalWorldReader/addons/uwr", "addons/uwr"],
]


func _initialize() -> void:
	var project := ProjectSettings.globalize_path("res://")
	var copied := 0
	for pair: Array in SOURCES:
		var from := project.path_join(pair[0]).simplify_path()
		var to := project.path_join(pair[1]).simplify_path()
		copied += _copy(from, to)
	print("SYNC %d files" % copied)
	quit(0)


static func _copy(from: String, to: String) -> int:
	if FileAccess.file_exists(from):
		DirAccess.make_dir_recursive_absolute(to.get_base_dir())
		DirAccess.copy_absolute(from, to)
		return 1
	var count := 0
	DirAccess.make_dir_recursive_absolute(to)
	for file_name in DirAccess.get_files_at(from):
		DirAccess.copy_absolute(from.path_join(file_name), to.path_join(file_name))
		count += 1
	for dir_name in DirAccess.get_directories_at(from):
		count += _copy(from.path_join(dir_name), to.path_join(dir_name))
	return count
