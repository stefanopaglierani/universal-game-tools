## The copies of UPTG, UPRG and UWR inside UPWG must match their sources (tools/sync_vendor.gd).
extends RefCounted

const SYNC := preload("res://tools/sync_vendor.gd")


func run(t: SceneTree) -> void:
	var project := ProjectSettings.globalize_path("res://")
	for pair: Array in SYNC.SOURCES:
		var from := project.path_join(pair[0]).simplify_path()
		var to := project.path_join(pair[1]).simplify_path()
		var different := _differences(from, to)
		t.check("%s matches its source" % pair[1], different.is_empty(), ", ".join(different))


static func _differences(from: String, to: String) -> PackedStringArray:
	var out := PackedStringArray()
	if FileAccess.file_exists(from):
		if not FileAccess.file_exists(to) or FileAccess.get_md5(from) != FileAccess.get_md5(to):
			out.append(to.get_file())
		return out
	for file_name in DirAccess.get_files_at(from):
		var copy := to.path_join(file_name)
		if not FileAccess.file_exists(copy) or FileAccess.get_md5(from.path_join(file_name)) != FileAccess.get_md5(copy):
			out.append(file_name)
	for dir_name in DirAccess.get_directories_at(from):
		out.append_array(_differences(from.path_join(dir_name), to.path_join(dir_name)))
	return out
