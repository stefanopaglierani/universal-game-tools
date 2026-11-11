## The editor window, driven without a person: new worlds, sliders, preview, save and open.
extends RefCounted

const PATH := "user://upwg_editor_test/world.upwg.tres"


func run(t: SceneTree) -> void:
	var editor: Control = (load("res://editor/upwg_editor.tscn") as PackedScene).instantiate()
	t.root.add_child(editor)
	await t.process_frame
	t.check("the editor opens with a world", editor.project != null and editor.project.terrain != null)
	for id in UPWGProject.TEMPLATES:
		editor.new_world(id, 99)
		var data: UPTGTerrainData = editor._preview_terrain.get_terrain_data()
		t.check("the preview of %s is built" % id, data != null and data.grid_cells_x <= editor.PREVIEW_CELLS)

	editor.new_world("island", 3)
	var before: float = editor.project.terrain.terrain_noise_amplitude
	(editor._controls["terrain_noise_amplitude"] as HSlider).value = 77.0
	t.check("a slider changes the world", is_equal_approx(editor.project.terrain.terrain_noise_amplitude, 77.0) and before != 77.0)
	for i in 30:
		await t.process_frame
	t.check("the preview follows the slider", editor._rebuild_wait <= 0.0 and editor._preview_terrain.config.terrain_noise_amplitude == 77.0)
	(editor._controls["coastline_irregularity"] as HSlider).value = 0.5
	t.check("an island never grows past the edge", editor.project.validate().is_empty(), str(editor.project.validate()))
	editor._mountain_count.value = 4
	t.check("mountains can be added", editor.project.terrain.mountain_regions.size() == 4)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PATH.get_base_dir()))
	t.check("the editor saves the project", editor.save_project(ProjectSettings.globalize_path(PATH)))
	editor.new_world("flat", 1)
	t.check("the editor opens it again", editor.open_project(ProjectSettings.globalize_path(PATH)) and editor.project.terrain.mountain_regions.size() == 4)
	t.check("a file that is not a world is refused", not editor.open_project(ProjectSettings.globalize_path("res://project.godot")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH.get_base_dir()))
	editor.queue_free()
