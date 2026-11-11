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
		var data: UPTGTerrainData = editor._preview_data
		t.check("the preview of %s is built" % id, data != null and data.grid_cells_x <= editor.PREVIEW_CELLS and editor._ground.mesh != null)

	editor.new_world("island", 3)
	var before: float = editor.project.terrain.terrain_noise_amplitude
	(editor._controls["terrain_noise_amplitude"] as HSlider).value = 77.0
	t.check("a slider changes the world", is_equal_approx(editor.project.terrain.terrain_noise_amplitude, 77.0) and before != 77.0)
	for i in 30:
		await t.process_frame
	t.check("the preview follows the slider", editor._rebuild_wait <= 0.0 and editor._preview_config.terrain_noise_amplitude == 77.0)
	(editor._controls["coastline_irregularity"] as HSlider).value = 0.5
	t.check("an island never grows past the edge", editor.project.validate().is_empty(), str(editor.project.validate()))
	editor._mountain_count.value = 4
	t.check("mountains can be added", editor.project.terrain.mountain_regions.size() == 4)

	# The brush: raise a hill where the mouse would be, then undo and redo it.
	editor.new_world("flat", 5)
	var spot := Vector2(100, -80)
	var ground: float = editor._grid.height_at(spot)
	editor.set_tool("Raise")
	(editor._controls["brush_radius"] as HSlider).value = 120
	(editor._controls["brush_strength"] as HSlider).value = 5
	editor.begin_stroke(spot)
	for k in 9:
		editor.dab(spot + Vector2(k, 0))
	editor.end_stroke()
	var raised: float = editor._grid.height_at(spot)
	t.check("the Raise brush lifts the ground", raised > ground + 30.0, "%.1f to %.1f m" % [ground, raised])
	t.check("one stroke is one undo step", editor.project.history.size() == 1 and editor.project.world.terrain_edits.size() == 10)
	editor.undo()
	t.check("undo removes the stroke", editor.project.world.terrain_edits.is_empty() and is_equal_approx(editor._grid.height_at(spot), ground))
	editor.redo()
	t.check("redo puts it back", is_equal_approx(editor._grid.height_at(spot), raised))
	editor.set_tool("Lower")
	editor.begin_stroke(Vector2(-150, 150))
	editor.end_stroke()
	t.check("the Lower brush digs", editor._grid.height_at(Vector2(-150, 150)) < ground)
	editor.set_tool("Flatten")
	editor.begin_stroke(spot + Vector2(60, 0))
	editor.dab(spot)
	editor.end_stroke()
	t.check("the Flatten brush levels to where it started", absf(editor._grid.height_at(spot) - editor._grid.height_at(spot + Vector2(60, 0))) < 3.0)

	# A lake on top of the hill and a river.
	editor.undo()
	var hilltop: float = editor._grid.height_at(spot)
	(editor._controls["water_size"] as HSlider).value = 40
	t.check("a lake can be placed on the hill", editor.add_lake(spot) and editor._water.get_child_count() == 1)
	t.check("the lake was dug at the hill top", editor._grid.height_at(spot) < hilltop - 3.0)
	(editor._controls["water_size"] as HSlider).value = 60
	t.check("a river can be drawn", editor.add_river(PackedVector2Array([Vector2(-400, -300), Vector2(-200, 0), Vector2(-300, 300)])))
	t.check("a lake too close to the edge is refused", not editor.add_lake(Vector2(1990, 0)))
	editor.undo()
	t.check("undo removes the river", editor.project.world.water.size() == 1)

	# The mouse finds the ground under it.
	var middle: Vector2 = editor._camera.get_viewport().get_visible_rect().size * 0.5
	var hit: Vector3 = editor.pick(middle)
	t.check("the mouse finds the ground", hit != Vector3.INF and absf(hit.y - editor._grid.height_at(Vector2(hit.x, hit.z))) < 1.0, str(hit))

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PATH.get_base_dir()))
	t.check("the editor saves the project", editor.save_project(ProjectSettings.globalize_path(PATH)))
	editor.new_world("flat", 1)
	t.check("the editor opens it again with its brush strokes and water", editor.open_project(ProjectSettings.globalize_path(PATH))
		and editor.project.world.water.size() == 1 and editor.project.world.terrain_edits.size() == 11 and editor.project.history.size() == 3)
	editor.clear_sculpting()
	t.check("Clear all removes strokes and water", editor.project.world.terrain_edits.is_empty() and editor.project.world.water.is_empty())
	t.check("a file that is not a world is refused", not editor.open_project(ProjectSettings.globalize_path("res://project.godot")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH.get_base_dir()))
	editor.queue_free()
