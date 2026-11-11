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

	# Ctrl turns Raise into Dig; Shift smooths; the square brush reaches its corners.
	editor.set_tool("Raise")
	var spot2 := Vector2(-300, -300)
	var level: float = editor._grid.height_at(spot2)
	editor.begin_stroke(spot2, true)
	editor.end_stroke()
	t.check("Ctrl makes Raise dig", editor._grid.height_at(spot2) < level - 1.0)
	editor.begin_stroke(spot2, false, true)
	editor.end_stroke()
	t.check("Shift paints with Smooth", editor.project.world.terrain_edits.back().kind == UPRGTerrainEdit.Kind.SMOOTH)
	editor._brush_shape = "square"
	editor.begin_stroke(Vector2(300, 300))
	editor.end_stroke()
	t.check("the square brush is used", editor.project.world.terrain_edits.back().square)
	editor._brush_shape = "circle"
	editor.set_tool("Flatten")
	editor._flatten_mode = UPRGTerrainEdit.LevelMode.UP_ONLY
	editor.begin_stroke(Vector2(300, 300))
	editor.end_stroke()
	t.check("Flatten keeps its mode", editor.project.world.terrain_edits.back().level_mode == UPRGTerrainEdit.LevelMode.UP_ONLY)
	editor._flatten_mode = UPRGTerrainEdit.LevelMode.BOTH
	for k in 4:
		editor.undo()

	# Water can be removed near a click, and brought back.
	var waters: int = editor.project.world.water.size()
	t.check("Ctrl + click removes the closest water", editor.remove_water_near(spot) and editor.project.world.water.size() == waters - 1)
	editor.undo()
	t.check("and undo brings it back", editor.project.world.water.size() == waters)

	# Tabs show only the tools and options of the tool in use.
	editor.set_tool("Mountains")
	t.check("the Create tab shows its tools only", editor.tab == "create" and editor._tool_buttons["World"].visible and not editor._tool_buttons["Raise"].visible
		and editor._sections["Mountains"].visible and not editor._sections["brush"].visible)
	editor.set_tool("Smooth")
	t.check("the Edit tab shows the brush options", editor.tab == "edit" and editor._sections["brush"].visible and not editor._sections["Mountains"].visible
		and not editor._controls["flatten_box"].visible)

	# The camera: flying, coming closer, looking from the sky.
	var cam: UPWGCamera = editor._camera
	cam.frame_all()
	var start: Vector3 = cam.position
	cam.fly(Vector3(0, 0, -1), 0.5, 0.0, false)
	t.check("W flies forward", cam.position.distance_to(start) > 1.0 and cam.position.y >= 2.0)
	var target := Vector3(0, editor._grid.height_at(Vector2.ZERO), 0)
	var far_away: float = cam.position.distance_to(target)
	cam.zoom_step(target, 1.0, 0.0)
	t.check("the wheel comes closer to the mouse", cam.position.distance_to(target) < far_away)
	cam.top_view()
	t.check("the sky view looks straight down", (-cam.basis.z).y < -0.99)
	cam.look(Vector2(100, 0))
	t.check("the right button turns the head", (-cam.basis.z).y < 0.0)

	# Languages: every text of the window has an Italian version, and the switch changes it.
	var missing: Array[String] = []
	for node in editor.find_children("*", "Control", true, false):
		var control := node as Control
		if control.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED or control.get_window() != editor.get_window():
			continue
		for text: String in [control.get("text") if control.get("text") is String else "", control.tooltip_text]:
			if text.length() > 2 and not UPWGI18n.ITALIAN.has(text) and not text[0].is_valid_int():
				missing.append(text)
	t.check("every text has an Italian version", missing.is_empty(), str(missing.slice(0, 5)))
	TranslationServer.set_locale("it")
	t.check("in Italian the tools speak Italian", editor.tr("Dig") == "Scava" and editor._tool_buttons["Lower"].get_tooltip(Vector2.ZERO) != "")
	TranslationServer.set_locale("en")

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PATH.get_base_dir()))
	t.check("the editor saves the project", editor.save_project(ProjectSettings.globalize_path(PATH)))
	editor.new_world("flat", 1)
	t.check("the editor opens it again with its brush strokes and water", editor.open_project(ProjectSettings.globalize_path(PATH))
		and editor.project.world.water.size() == 1 and editor.project.world.terrain_edits.size() == 11 and editor.project.history.size() == 3, "%d edits, %d steps" % [editor.project.world.terrain_edits.size(), editor.project.history.size()])
	editor.clear_sculpting()
	t.check("Clear all removes strokes and water", editor.project.world.terrain_edits.is_empty() and editor.project.world.water.is_empty())
	t.check("a file that is not a world is refused", not editor.open_project(ProjectSettings.globalize_path("res://project.godot")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH.get_base_dir()))
	editor.queue_free()
