extends Control
## The UPWG window, made to be used by a child: two tabs (Create and Edit), a few big tools with
## pictures, only the options of the tool in use, a camera like the one of a game editor, and
## undo for everything.
##
## Mouse and keys in the 3D view:
##   right button held + W A S D (Q E)   look around and fly (Shift: faster)
##   mouse wheel                         move toward the mouse, or away
##   middle button, or left with Look    turn around the world
##   left button                         use the tool
##   Ctrl                                Raise digs, Dig raises, Water removes
##   Shift (while painting)              smooth instead
##   B + move the mouse, or B + wheel    brush size; Shift + B: strength
##   F                                   fly to the point under the mouse
##   1 to 8                              choose a tool; Ctrl+Z, Ctrl+Y undo and redo; Ctrl+S save

const PREVIEW_CELLS := 192
const REBUILD_DELAY := 0.25
const PROJECT_FILTER := "*.upwg.tres ; UPWG world"
const AUTOSAVE_PATH := "user://autosave.upwg.tres"
const AUTOSAVE_SECONDS := 120.0
## While a brush is held still, it keeps working this often (seconds).
const DAB_INTERVAL := 0.08
const ICON_DIR := "res://editor/icons/"
const DEFAULT_MATERIAL := preload("res://addons/uptg/materials/uptg_terrain_default.tres")
const YELLOW := Color(1.0, 0.82, 0.2)

const CREATE_TOOLS := ["World", "Land", "Mountains", "Clear"]
const EDIT_TOOLS := ["Look", "Raise", "Lower", "Smooth", "Flatten", "Roughen", "Lake", "River"]
const BRUSH_TOOLS := ["Raise", "Lower", "Smooth", "Flatten", "Roughen"]
const TOOL_ICONS := {
	"World": "globe", "Land": "map", "Mountains": "mountain-snow", "Clear": "eraser",
	"Look": "hand", "Raise": "mountain", "Lower": "shovel", "Smooth": "brush", "Flatten": "ruler",
	"Roughen": "sparkles", "Lake": "droplets", "River": "waves",
}
const TOOL_NAMES := {
	"World": "New world", "Land": "Land", "Mountains": "Mountains", "Clear": "Start over",
	"Look": "Look", "Raise": "Raise", "Lower": "Dig", "Smooth": "Smooth", "Flatten": "Flatten",
	"Roughen": "Bumpy", "Lake": "Lake", "River": "River",
}
const TOOL_HINTS := {
	"World": "Pick a world to start from, and how big it is.",
	"Land": "Change the shape of the land and its hills.",
	"Mountains": "Add big mountains and move them around.",
	"Clear": "Remove your work and start again.",
	"Look": "Drag with the left button to turn around the world. Wheel to come closer.",
	"Raise": "Hold the left button and move: the ground goes up. Hold Ctrl to dig.",
	"Lower": "Hold the left button and move: the ground goes down. Hold Ctrl to raise.",
	"Smooth": "Paint to make the ground soft and round.",
	"Flatten": "Paint to make the ground flat, at the height where you start.",
	"Roughen": "Paint to make the ground bumpy, like rocks.",
	"Lake": "Click to make a lake. It works on mountains too! Ctrl + click removes the closest water.",
	"River": "Click the points of the river, from the start to the sea. Right-click or Enter to finish, Esc to cancel.",
}
const TEMPLATE_ICONS := {"island": "tree-palm", "continent": "trees", "coast": "waves", "highlands": "mountain", "flat": "square"}
const SIZES := [[1024.0, "Small"], [4096.0, "Medium"], [8192.0, "Big"], [16384.0, "Huge"], [30720.0, "Giant"]]
const BRUSH_SIZES := [[15.0, "S"], [50.0, "M"], [150.0, "L"], [400.0, "XL"]]

var project: UPWGProject
var tab := "create"
var tool := "World"
var project_path := ""
var _dirty := false
var _autosave_wait := AUTOSAVE_SECONDS
var _shuffle := 0
var _rebuild_wait := -1.0
var _syncing := false
var _controls := {}
var _sections := {}
var _tool_buttons := {}
var _tab_buttons := {}
var _size_buttons := {}
var _shape_buttons := {}
var _brush_shape := "circle"
var _flatten_mode := UPRGTerrainEdit.LevelMode.BOTH
var _ground: MeshInstance3D
var _water: Node3D
var _sea: MeshInstance3D
var _cursor: MeshInstance3D
var _cursor_mesh: ImmediateMesh
var _markers: Node3D
var _camera: UPWGCamera
var _env: Environment
var _view: SubViewportContainer
var _status: Label
var _keys_hint: Label
var _language_button: Button
var _seed: SpinBox
var _mountain_count: SpinBox
var _dialog: FileDialog
var _dialog_action := ""
var _confirm: ConfirmationDialog
var _confirm_action: Callable
var _export_popup: PopupPanel
var _help: AcceptDialog
## Preview state: the configuration, its data, the grid the brush edits.
var _preview_config: UPTGConfig
var _preview_data: UPTGTerrainData
var _grid: UPRGTerrainGrid
## Brush state.
var _painting := false
var _stroke_tool := ""
var _stroke_start := 0
var _last_dab := Vector2.INF
var _dab_wait := 0.0
var _flatten_height := 0.0
var _hover := Vector3.INF
var _mouse_in_view := false
var _b_held := false
var _river_points := PackedVector2Array()
var _redo: Array = []


func _ready() -> void:
	UPWGI18n.install()
	get_tree().set_auto_accept_quit(false)
	_build_ui()
	new_world("island", 12345)
	_select_tab("create")
	if FileAccess.file_exists(AUTOSAVE_PATH) and not OS.has_feature("headless") and DisplayServer.get_name() != "headless":
		_ask(tr("Do you want to continue the world you were making last time?"), func() -> void: open_project(ProjectSettings.globalize_path(AUTOSAVE_PATH), false))


# ---------- World ----------

## Starts a new world from a template and a seed.
func new_world(template_id: String, seed_value: int) -> void:
	project = UPWGProject.from_template(template_id, seed_value)
	project_path = ""
	_after_load()
	_dirty = false
	_say(tr("A new world! Now change it with the tools on the left."))


func open_project(path: String, remember_path := true) -> bool:
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as UPWGProject
	if loaded == null or loaded.terrain == null:
		_say(tr("This file is not a UPWG world: %s") % path.get_file())
		return false
	project = loaded
	if project.world == null:
		project.world = UPRGWorldConfig.new()
	project_path = path if remember_path else ""
	_after_load()
	_dirty = not remember_path
	_say(tr("Opened %s.") % path.get_file())
	return true


func _after_load() -> void:
	_shuffle = 0
	_redo.clear()
	_river_points.clear()
	_sync_controls()
	rebuild_preview()
	_camera.setup(project.terrain.get_size().x)
	_camera.frame_all()


func save_project(path: String) -> bool:
	if not path.ends_with(".upwg.tres"):
		path = path.get_basename() + ".upwg.tres"
	var error := ResourceSaver.save(project, path)
	if error == OK:
		project_path = path
		_dirty = false
		_say(tr("Saved %s.") % path.get_file())
	else:
		_say(tr("Could not save %s (error %d).") % [path, error])
	return error == OK


func export_to(folder: String) -> Dictionary:
	_say(tr("Building the world and writing the files... big worlds take a few minutes."))
	await get_tree().process_frame
	await get_tree().process_frame
	var result := UPWGExporter.export_world(project, folder)
	if result.ok:
		_say(tr("Done! %d files written to %s in %.0f seconds.") % [result.files.size(), folder, result.seconds])
	else:
		_say(tr("The export did not work: %s") % result.error)
	return result


## Builds the 3D preview now: the terrain with fewer cells than the final world, then every
## brush stroke, lake and river in order.
func rebuild_preview() -> void:
	_rebuild_wait = -1.0
	var errors := project.validate()
	if not errors.is_empty():
		_say(tr("This terrain cannot be built: %s") % "; ".join(errors))
		return
	_preview_config = project.terrain.duplicate(true) as UPTGConfig
	var side := _preview_config.get_size().x
	# Halve the grid until it is light enough: the cell still divides the world exactly.
	var cells := _preview_config.grid_cells_x
	var cell := _preview_config.cell_size
	while cells > PREVIEW_CELLS and cells % 2 == 0:
		cells /= 2
		cell *= 2.0
	_preview_data = UPTGHeightfieldGenerator.generate_heights(_preview_config, cell)
	if _preview_data == null:
		_say(tr("This terrain cannot be built."))
		return
	_grid = UPRGTerrainGrid.new()
	_grid.cells_x = _preview_data.grid_cells_x
	_grid.cells_z = _preview_data.grid_cells_z
	_grid.cell_size = _preview_data.cell_size
	_grid.sea_level = _preview_data.sea_level
	_grid.heights = _preview_data.heights.duplicate()
	for edit in project.world.terrain_edits:
		edit.apply(_grid)
	_rebuild_water()
	_update_ground()
	_sea.position.y = _preview_config.sea_level
	(_sea.mesh as PlaneMesh).size = Vector2(side * 3.0, side * 3.0)
	_sea.visible = _preview_config.land_shape != UPTGConfig.LandShape.CONTINENT
	_env.fog_density = 0.16 / side
	_camera.setup(side)


func _rebuild_water() -> void:
	for child in _water.get_children():
		child.queue_free()
	for body in project.world.water:
		var plan := UPRGWaterBuilder.dig(body, _grid)
		if not plan.ok:
			continue
		var surface := UPRGWaterBuilder.build_mesh(plan, _grid)
		if surface != null:
			var node := MeshInstance3D.new()
			node.mesh = surface
			_water.add_child(node)


func _update_ground() -> void:
	_preview_data.heights = _grid.heights.duplicate()
	_ground.mesh = UPTGMeshBuilder.build(_preview_data, _preview_config)
	_ground.material_override = DEFAULT_MATERIAL


func _mark_dirty() -> void:
	_dirty = true


# ---------- Tools ----------

## Chooses a tool of either tab.
func set_tool(tool_name: String) -> void:
	if tool_name in CREATE_TOOLS:
		_select_tab("create", tool_name)
	elif tool_name in EDIT_TOOLS:
		_select_tab("edit", tool_name)


func _select_tab(tab_name: String, tool_name := "") -> void:
	tab = tab_name
	var tools: Array = CREATE_TOOLS if tab == "create" else EDIT_TOOLS
	if tool_name == "":
		tool_name = tool if tool in tools else tools[0]
	tool = tool_name
	for name: String in _tab_buttons:
		(_tab_buttons[name] as Button).button_pressed = name == tab
	for name: String in _tool_buttons:
		var button := _tool_buttons[name] as Button
		button.visible = name in tools
		button.button_pressed = name == tool
	var section := _section_of(tool)
	for name: String in _sections:
		(_sections[name] as Control).visible = name == section
	(_controls["flatten_box"] as Control).visible = tool == "Flatten"
	(_controls["river_hint"] as Control).visible = tool == "River"
	_river_points.clear()
	_update_markers()
	_say(tr(TOOL_HINTS[tool]))
	_keys_hint.text = tr("Right button + W A S D: fly   ·   Wheel: closer   ·   B + mouse: brush size   ·   Ctrl+Z: undo")


static func _section_of(tool_name: String) -> String:
	if tool_name in BRUSH_TOOLS:
		return "brush"
	if tool_name in ["Lake", "River"]:
		return "water"
	return tool_name


func _brush() -> Dictionary:
	return {
		"radius": (_controls["brush_radius"] as HSlider).value,
		"strength": (_controls["brush_strength"] as HSlider).value,
		"softness": (_controls["brush_softness"] as HSlider).value,
	}


## One touch of the brush at [param at] (meters from the center). Usable without a mouse.
func dab(at: Vector2) -> void:
	if _grid == null:
		return
	var b := _brush()
	var edit := UPRGTerrainEdit.new()
	edit.center = at
	edit.radius = maxf(b.radius * (1.0 - b.softness), 0.5)
	edit.blend = maxf(b.radius * b.softness, 0.5)
	edit.square = _brush_shape == "square"
	match _stroke_tool if _painting else tool:
		"Raise":
			edit.kind = UPRGTerrainEdit.Kind.ADD
			edit.amount = b.strength
		"Lower":
			edit.kind = UPRGTerrainEdit.Kind.ADD
			edit.amount = -b.strength
		"Flatten":
			edit.kind = UPRGTerrainEdit.Kind.LEVEL
			edit.height = _flatten_height
			edit.level_mode = _flatten_mode
			edit.strength = clampf(b.strength / 5.0, 0.1, 1.0)
		"Smooth":
			edit.kind = UPRGTerrainEdit.Kind.SMOOTH
			edit.amount = clampf(b.strength / 10.0, 0.05, 1.0)
		"Roughen":
			edit.kind = UPRGTerrainEdit.Kind.ROUGHEN
			edit.amount = b.strength
			edit.bump_size = maxf(b.radius / 6.0, 2.0)
			edit.noise_seed = project.world.terrain_edits.size()
		_:
			return
	project.world.terrain_edits.append(edit)
	edit.apply(_grid)
	_update_ground()
	_last_dab = at
	_mark_dirty()


## Starts a brush stroke. [param invert]: Raise digs and Dig raises. [param smooth]: smooths
## instead, whatever the tool.
func begin_stroke(at: Vector2, invert := false, smooth := false) -> void:
	_painting = true
	_stroke_tool = tool
	if smooth:
		_stroke_tool = "Smooth"
	elif invert and tool == "Raise":
		_stroke_tool = "Lower"
	elif invert and tool == "Lower":
		_stroke_tool = "Raise"
	_stroke_start = project.world.terrain_edits.size()
	var fixed := _controls["flatten_fixed"] as CheckBox
	_flatten_height = (_controls["flatten_height"] as SpinBox).value if fixed.button_pressed else _grid.height_at(at) - _grid.sea_level
	if not fixed.button_pressed:
		(_controls["flatten_height"] as SpinBox).set_value_no_signal(snappedf(_flatten_height, 0.1))
	_redo.clear()
	dab(at)


func end_stroke() -> void:
	if not _painting:
		return
	_painting = false
	var count := project.world.terrain_edits.size() - _stroke_start
	if count > 0:
		project.history.append({"kind": "edits", "count": count})
	# Lakes and rivers are dug after the brush: rebuild so the preview matches the export.
	if not project.world.water.is_empty():
		rebuild_preview()


func add_lake(at: Vector2) -> bool:
	var lake := UPRGWater.new()
	lake.kind = UPRGWater.Kind.LAKE
	lake.points = PackedVector2Array([at])
	lake.size = (_controls["water_size"] as HSlider).value
	lake.depth = (_controls["water_depth"] as HSlider).value
	lake.shore = maxf(lake.size * 0.4, 6.0)
	return _add_water(lake)


func add_river(points: PackedVector2Array) -> bool:
	var river := UPRGWater.new()
	river.kind = UPRGWater.Kind.RIVER
	river.points = points
	river.size = (_controls["water_size"] as HSlider).value * 0.25
	river.depth = (_controls["water_depth"] as HSlider).value * 0.5
	river.shore = maxf(river.size, 6.0)
	return _add_water(river)


func _add_water(body: UPRGWater) -> bool:
	var plan := UPRGWaterBuilder.dig(body, _grid_copy())
	if not plan.ok:
		_say(tr("The water cannot go here: it is too close to the edge of the world."))
		return false
	project.world.water.append(body)
	project.history.append({"kind": "water", "count": 1})
	_redo.clear()
	rebuild_preview()
	_mark_dirty()
	_say(tr("Lake added! Ctrl+Z takes it away.") if body.kind == UPRGWater.Kind.LAKE else tr("River added! Ctrl+Z takes it away."))
	return true


## Removes the lake or river closest to [param at]. Can be undone.
func remove_water_near(at: Vector2) -> bool:
	var best := -1
	var best_distance := INF
	for i in project.world.water.size():
		for p in project.world.water[i].points:
			if p.distance_to(at) < best_distance:
				best_distance = p.distance_to(at)
				best = i
	if best < 0:
		_say(tr("There is no water to remove."))
		return false
	var removed: UPRGWater = project.world.water[best]
	project.world.water.remove_at(best)
	project.history.append({"kind": "water_removed", "count": 1, "item": removed, "index": best})
	_redo.clear()
	rebuild_preview()
	_mark_dirty()
	_say(tr("Water removed. Ctrl+Z brings it back."))
	return true


func undo() -> void:
	if project.history.is_empty():
		_say(tr("There is nothing to undo."))
		return
	var step: Dictionary = project.history.pop_back()
	if step.kind == "water_removed":
		project.world.water.insert(mini(step.index, project.world.water.size()), step.item)
		_redo.append(step)
	else:
		var removed: Array = []
		var list: Array = project.world.terrain_edits if step.kind == "edits" else project.world.water
		for i in step.count:
			removed.push_front(list.pop_back())
		_redo.append({"kind": step.kind, "items": removed})
	rebuild_preview()
	_mark_dirty()
	_say(tr("Undone."))


func redo() -> void:
	if _redo.is_empty():
		_say(tr("There is nothing to redo."))
		return
	var step: Dictionary = _redo.pop_back()
	if step.kind == "water_removed":
		project.world.water.erase(step.item)
		project.history.append(step)
	else:
		for item in step.items:
			if step.kind == "edits":
				project.world.terrain_edits.append(item)
			else:
				project.world.water.append(item)
		project.history.append({"kind": step.kind, "count": step.items.size()})
	rebuild_preview()
	_mark_dirty()
	_say(tr("Redone."))


func clear_sculpting() -> void:
	project.world.terrain_edits.clear()
	project.world.water.clear()
	project.history.clear()
	_redo.clear()
	rebuild_preview()
	_mark_dirty()
	_say(tr("All your brush work and water are gone. The land is as it was made."))


func _grid_copy() -> UPRGTerrainGrid:
	var copy := UPRGTerrainGrid.new()
	copy.cells_x = _grid.cells_x
	copy.cells_z = _grid.cells_z
	copy.cell_size = _grid.cell_size
	copy.sea_level = _grid.sea_level
	copy.heights = _grid.heights.duplicate()
	return copy


## The point of the ground under [param screen_pos] in the preview, or Vector3.INF.
func pick(screen_pos: Vector2) -> Vector3:
	if _grid == null:
		return Vector3.INF
	var origin := _camera.project_ray_origin(screen_pos)
	var direction := _camera.project_ray_normal(screen_pos)
	var step := _grid.cell_size * 0.5
	var t := 0.0
	var previous := 0.0
	while t < _camera.far:
		var p := origin + direction * t
		var flat := Vector2(p.x, p.z)
		if _grid.is_inside(flat, 0.0) and p.y <= _grid.height_at(flat):
			var low := previous
			var high := t
			for i in 10:
				var mid := (low + high) * 0.5
				var q := origin + direction * mid
				if q.y <= _grid.height_at(Vector2(q.x, q.z)):
					high = mid
				else:
					low = mid
			return origin + direction * high
		previous = t
		t += step
	return Vector3.INF


func _ground_under(p: Vector3) -> float:
	if _grid == null or not _grid.is_inside(Vector2(p.x, p.z), 0.0):
		return _preview_config.sea_level if _preview_config != null else 0.0
	return maxf(_grid.height_at(Vector2(p.x, p.z)), _grid.sea_level)


func _view_center_point() -> Vector3:
	var hit := pick(_view.size * 0.5)
	if hit != Vector3.INF:
		return hit
	return _camera.position - _camera.basis.z * clampf(_camera.position.y, 50.0, project.terrain.get_size().x)


# ---------- Interface ----------

func _build_ui() -> void:
	var look := Theme.new()
	look.default_font_size = 17
	theme = look
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 0)
	add_child(column)
	column.add_child(_build_top_bar())

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 0
	split.dragger_visibility = SplitContainer.DRAGGER_HIDDEN_COLLAPSED
	column.add_child(split)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 430
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	split.add_child(scroll)
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 8)
	scroll.add_child(panel)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	panel.add_child(grid)
	for tool_name: String in CREATE_TOOLS + EDIT_TOOLS:
		var button := _icon_button(TOOL_ICONS[tool_name], TOOL_NAMES[tool_name], TOOL_HINTS[tool_name], true)
		button.custom_minimum_size = Vector2(80, 76)
		button.pressed.connect(set_tool.bind(tool_name))
		grid.add_child(button)
		_tool_buttons[tool_name] = button
	panel.add_child(HSeparator.new())
	_build_world_section(panel)
	_build_land_section(panel)
	_build_mountains_section(panel)
	_build_clear_section(panel)
	_build_look_section(panel)
	_build_brush_section(panel)
	_build_water_section(panel)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size.y = 70
	_status.add_theme_color_override("font_color", YELLOW)
	# Messages are translated when they are written.
	_status.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	panel.add_child(HSeparator.new())
	panel.add_child(_status)

	var holder := Control.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(holder)
	_view = SubViewportContainer.new()
	_view.stretch = true
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.focus_mode = Control.FOCUS_ALL
	_view.gui_input.connect(_on_view_input)
	_view.mouse_entered.connect(func() -> void: _mouse_in_view = true)
	_view.mouse_exited.connect(func() -> void:
		_mouse_in_view = false
		_cursor.visible = false)
	holder.add_child(_view)
	var viewport := SubViewport.new()
	viewport.msaa_3d = Viewport.MSAA_4X
	_view.add_child(viewport)
	_build_scene(viewport)
	holder.add_child(_build_view_buttons())

	_keys_hint = Label.new()
	_keys_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_keys_hint.add_theme_font_size_override("font_size", 14)
	_keys_hint.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	column.add_child(_keys_hint)
	_build_dialogs()


func _build_top_bar() -> Control:
	var bar := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	bar.add_child(row)
	var items := [
		["file-plus", "New", "Start a new world", func() -> void: set_tool("World")],
		["folder-open", "Open", "Open a world you saved", func() -> void: _ask_path("open")],
		["save", "Save", "Save your world (Ctrl+S)", _save_shortcut],
		["package", "Export", "Make the files for a game or another program", _show_export],
	]
	for item in items:
		var button := _icon_button(item[0], item[1], item[2], false)
		button.pressed.connect(item[3])
		row.add_child(button)
	row.add_child(VSeparator.new())
	for item in [["undo-2", "Undo", "Take back the last change (Ctrl+Z)", undo], ["redo-2", "Redo", "Put it back (Ctrl+Y)", redo]]:
		var button := _icon_button(item[0], item[1], item[2], false)
		button.pressed.connect(item[3])
		row.add_child(button)
	row.add_child(VSeparator.new())
	for item in [["create", "sprout", "Create", "Make the world: its size, land and mountains"], ["edit", "brush", "Edit", "Shape the ground and add water with the mouse"]]:
		var button := _icon_button(item[1], item[2], item[3], true)
		button.add_theme_font_size_override("font_size", 20)
		button.custom_minimum_size.x = 130
		button.pressed.connect(_select_tab.bind(item[0]))
		row.add_child(button)
		_tab_buttons[item[0]] = button
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_language_button = _icon_button("languages", "Italiano", "Change the language", false)
	_language_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_language_button.pressed.connect(_toggle_language)
	row.add_child(_language_button)
	var help := _icon_button("circle-help", "Help", "How to use the editor", false)
	help.pressed.connect(func() -> void: _help.popup_centered())
	row.add_child(help)
	_update_language_button()
	return bar


func _build_view_buttons() -> Control:
	var box := HBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	box.position += Vector2(-8, 8)
	var items := [
		["plus", "Come closer", func() -> void: _camera.zoom_step(_view_center_point(), 2.0, _ground_under(_camera.position))],
		["minus", "Go farther", func() -> void: _camera.zoom_step(_view_center_point(), -2.0, _ground_under(_camera.position))],
		["house", "See the whole world", func() -> void: _camera.frame_all()],
		["eye", "Look from the sky", func() -> void: _camera.top_view()],
	]
	for item in items:
		var button := Button.new()
		button.icon = _icon(item[0])
		button.expand_icon = true
		button.custom_minimum_size = Vector2(48, 48)
		button.tooltip_text = item[1]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(item[2])
		box.add_child(button)
	return box


func _build_world_section(panel: Control) -> void:
	var box := _section(panel, "World", "Choose a world to start")
	var cards := GridContainer.new()
	cards.columns = 3
	box.add_child(cards)
	for id: String in UPWGProject.TEMPLATES:
		var card := _icon_button(TEMPLATE_ICONS[id], UPWGProject.TEMPLATE_NAMES[id], "Start a new world like this", false)
		card.custom_minimum_size = Vector2(104, 84)
		card.pressed.connect(_on_template.bind(id))
		cards.add_child(card)
	var surprise := _icon_button("dice-5", "Surprise me!", "A new world of the same kind, different every time", false)
	surprise.pressed.connect(func() -> void: _on_template(project.template, randi() % 1000000))
	cards.add_child(surprise)
	box.add_child(_small_title("How big?"))
	var sizes := HFlowContainer.new()
	var group := ButtonGroup.new()
	for item in SIZES:
		var button := Button.new()
		button.text = item[1]
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size = Vector2(62, 44)
		button.tooltip_text = "%s km" % str(snappedf(item[0] / 1000.0, 0.1))
		button.pressed.connect(func() -> void: _change("size", item[0]))
		sizes.add_child(button)
		_size_buttons[item[0]] = button
	box.add_child(sizes)
	var expert := _expert(box)
	_seed = SpinBox.new()
	_seed.max_value = 2147483647
	_seed.tooltip_text = "The number that makes this world. The same number gives the same world."
	_seed.value_changed.connect(func(v: float) -> void:
		if not _syncing:
			_on_template(project.template, int(v)))
	expert.add_child(_row("World number", _seed))
	_slider(expert, "size", "Size (m)", 512, UPWGProject.MAX_SIDE, 256)
	_slider(expert, "cell", "Detail (m per square)", 1, 32, 1)


func _build_land_section(panel: Control) -> void:
	var box := _section(panel, "Land", "The land")
	var shapes := HBoxContainer.new()
	var group := ButtonGroup.new()
	for item in [[UPTGConfig.LandShape.ISLAND, "tree-palm", "Island"], [UPTGConfig.LandShape.CONTINENT, "trees", "Land"], [UPTGConfig.LandShape.COAST, "waves", "Coast"]]:
		var button := _icon_button(item[1], item[2], "", true)
		button.button_group = group
		button.custom_minimum_size = Vector2(100, 76)
		button.pressed.connect(func() -> void: _change("land_shape", item[0]))
		shapes.add_child(button)
		_shape_buttons[item[0]] = button
	box.add_child(shapes)
	_slider(box, "terrain_noise_amplitude", "Hills: how high", 0, 200, 1)
	_slider(box, "hill_size", "Hills: how wide", 40, 1000, 10)
	_slider(box, "land_base_height", "Land above the sea", 0, 120, 1)
	_slider(box, "island_width", "Island: how big", 0.2, 0.85, 0.01)
	_slider(box, "coast_position", "Coast: where", 0.2, 0.9, 0.01)
	var expert := _expert(box)
	_slider(expert, "coastline_irregularity", "Coast: how wiggly", 0, 0.5, 0.01)
	_slider(expert, "sea_floor_depth", "Sea: how deep (m)", 1, 100, 1)


func _build_mountains_section(panel: Control) -> void:
	var box := _section(panel, "Mountains", "Mountains")
	var count_row := HBoxContainer.new()
	_mountain_count = SpinBox.new()
	_mountain_count.max_value = 16
	_mountain_count.value_changed.connect(func(_v: float) -> void: _remake_mountains())
	var less := _icon_only("minus", "One less")
	less.pressed.connect(func() -> void: _mountain_count.value -= 1)
	var more := _icon_only("plus", "One more")
	more.pressed.connect(func() -> void: _mountain_count.value += 1)
	count_row.add_child(less)
	count_row.add_child(_mountain_count)
	count_row.add_child(more)
	box.add_child(_row("How many", count_row))
	_slider(box, "mountain_height", "How high (m)", 0, 600, 5)
	_slider(box, "mountain_size", "How wide", 0.05, 0.45, 0.01)
	var move := _icon_button("dice-5", "Move the mountains", "Put the mountains in other places", false)
	move.pressed.connect(func() -> void:
		_shuffle += 1
		_remake_mountains())
	box.add_child(move)
	box.add_child(_note("Tip: in Edit, the Raise tool makes your own mountains where you want."))


func _build_clear_section(panel: Control) -> void:
	var box := _section(panel, "Clear", "Start over")
	var undo_work := _icon_button("eraser", "Remove my brush work and water", "The land goes back to how it was made", false)
	undo_work.pressed.connect(func() -> void: _ask(tr("Remove all your brush work, lakes and rivers?"), clear_sculpting))
	box.add_child(undo_work)
	var flat := _icon_button("square", "A flat world", "Start again from flat land", false)
	flat.pressed.connect(_on_template.bind("flat"))
	box.add_child(flat)


func _build_look_section(panel: Control) -> void:
	var box := _section(panel, "Look", "Look around")
	box.add_child(_note("Left button: turn around the world.\nRight button + W A S D: fly like a bird. Q and E: down and up. Shift: faster.\nWheel: come closer to what is under the mouse.\nF: fly to the point under the mouse."))


func _build_brush_section(panel: Control) -> void:
	var box := _section(panel, "brush", "Brush")
	var sizes := HBoxContainer.new()
	for item in BRUSH_SIZES:
		var button := Button.new()
		button.text = item[1]
		button.custom_minimum_size = Vector2(56, 44)
		button.tooltip_text = "%.0f m" % (item[0] * 2.0)
		button.pressed.connect(func() -> void: (_controls["brush_radius"] as HSlider).value = item[0])
		sizes.add_child(button)
	box.add_child(_row("Size", sizes))
	_slider(box, "brush_radius", "Size (m)", 5, 3000, 5, false)
	_slider(box, "brush_strength", "Strength", 0.1, 10, 0.1, false)
	_slider(box, "brush_softness", "Soft edge", 0, 1, 0.05, false)
	(_controls["brush_radius"] as HSlider).value = 50
	(_controls["brush_strength"] as HSlider).value = 2
	(_controls["brush_softness"] as HSlider).value = 0.6
	var shapes := HBoxContainer.new()
	var group := ButtonGroup.new()
	for item in [["circle", "circle", "Round brush"], ["square", "square", "Square brush"]]:
		var button := _icon_only(item[1], item[2])
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = item[0] == _brush_shape
		button.pressed.connect(func() -> void:
			_brush_shape = item[0]
			_show_cursor())
		shapes.add_child(button)
	box.add_child(_row("Shape", shapes))
	var flatten := VBoxContainer.new()
	_controls["flatten_box"] = flatten
	box.add_child(flatten)
	var modes := HBoxContainer.new()
	var mode_group := ButtonGroup.new()
	for item in [[UPRGTerrainEdit.LevelMode.BOTH, "Both"], [UPRGTerrainEdit.LevelMode.DOWN_ONLY, "Only lower"], [UPRGTerrainEdit.LevelMode.UP_ONLY, "Only raise"]]:
		var button := Button.new()
		button.text = item[1]
		button.toggle_mode = true
		button.button_group = mode_group
		button.button_pressed = item[0] == _flatten_mode
		button.pressed.connect(func() -> void: _flatten_mode = item[0])
		modes.add_child(button)
	flatten.add_child(_row("Flatten", modes))
	var fixed := CheckBox.new()
	fixed.text = "Always the same height"
	fixed.tooltip_text = "Off: the height where you start. On: the height written here."
	_controls["flatten_fixed"] = fixed
	var height := SpinBox.new()
	height.min_value = -200
	height.max_value = 1000
	height.step = 0.1
	height.suffix = "m"
	_controls["flatten_height"] = height
	flatten.add_child(fixed)
	flatten.add_child(_row("Height", height))


func _build_water_section(panel: Control) -> void:
	var box := _section(panel, "water", "Water")
	_slider(box, "water_size", "Lake size (m)", 10, 2000, 5, false)
	_slider(box, "water_depth", "Water depth (m)", 1, 40, 0.5, false)
	(_controls["water_size"] as HSlider).value = 80
	(_controls["water_depth"] as HSlider).value = 6
	var hint := _note("The river goes where you click. It always flows down.")
	_controls["river_hint"] = hint
	box.add_child(hint)


func _build_dialogs() -> void:
	_dialog = FileDialog.new()
	_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_dialog.use_native_dialog = true
	_dialog.file_selected.connect(_on_path_chosen)
	_dialog.dir_selected.connect(_on_path_chosen)
	add_child(_dialog)
	_confirm = ConfirmationDialog.new()
	_confirm.ok_button_text = "Yes"
	_confirm.cancel_button_text = "No"
	_confirm.confirmed.connect(func() -> void:
		if _confirm_action.is_valid():
			_confirm_action.call())
	add_child(_confirm)
	_export_popup = PopupPanel.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_export_popup.add_child(box)
	box.add_child(_small_title("What do you want to make?"))
	for pair in [["export_godot_single", "Godot: one scene file"], ["export_godot_tiles", "Godot: pieces for big worlds"],
			["export_heightmap", "Heightmap images (Unity, Unreal, Blender)"], ["export_gltf", "3D model glTF (any program)"]]:
		var check := CheckBox.new()
		check.text = pair[1]
		check.toggled.connect(func(on: bool) -> void: project.set(pair[0], on))
		_controls[pair[0]] = check
		box.add_child(check)
	var go := _icon_button("folder-open", "Choose the folder and export", "", false)
	go.pressed.connect(func() -> void:
		_export_popup.hide()
		_ask_path("export"))
	box.add_child(go)
	add_child(_export_popup)
	_help = AcceptDialog.new()
	_help.title = "Help"
	_help.dialog_text = "1. Create: pick a world, its size, the land and the mountains.\n2. Edit: choose a tool and paint on the world with the left button.\n\nRight button + W A S D: fly.  Wheel: come closer.\nCtrl: Raise digs, Dig raises.  Shift: smooth.\nB + mouse or wheel: brush size.  Shift + B: strength.\nF: fly to the mouse.  1 to 8: tools.\nCtrl+Z: undo.  Ctrl+Y: redo.  Ctrl+S: save."
	add_child(_help)


func _build_scene(viewport: SubViewport) -> void:
	var world := Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.fog_enabled = true
	env.fog_density = 0.00008
	_env = env
	environment.environment = env
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 12000.0
	world.add_child(sun)
	_ground = MeshInstance3D.new()
	world.add_child(_ground)
	_water = Node3D.new()
	world.add_child(_water)
	_sea = MeshInstance3D.new()
	_sea.mesh = PlaneMesh.new()
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.1, 0.38, 0.55)
	water.roughness = 0.2
	_sea.material_override = water
	world.add_child(_sea)
	_cursor = MeshInstance3D.new()
	_cursor_mesh = ImmediateMesh.new()
	_cursor.mesh = _cursor_mesh
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = YELLOW
	glow.no_depth_test = true
	glow.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cursor.material_override = glow
	_cursor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cursor.visible = false
	world.add_child(_cursor)
	_markers = Node3D.new()
	world.add_child(_markers)
	_camera = UPWGCamera.new()
	world.add_child(_camera)


func _icon(name: String) -> Texture2D:
	return load(ICON_DIR + name + ".svg") as Texture2D


## A button with a picture above its words.
func _icon_button(icon_name: String, text: String, hint: String, toggle: bool) -> Button:
	var button := Button.new()
	button.icon = _icon(icon_name)
	button.text = text
	button.tooltip_text = hint
	button.toggle_mode = toggle
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.expand_icon = false
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_constant_override("icon_max_width", 34)
	return button


func _icon_only(icon_name: String, hint: String) -> Button:
	var button := Button.new()
	button.icon = _icon(icon_name)
	button.tooltip_text = hint
	button.custom_minimum_size = Vector2(44, 44)
	button.expand_icon = true
	button.focus_mode = Control.FOCUS_NONE
	return button


func _section(panel: Control, key: String, title: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 22)
	box.add_child(label)
	panel.add_child(box)
	_sections[key] = box
	return box


## A part that only grown-ups need, closed at the start.
func _expert(parent: Control) -> VBoxContainer:
	var toggle := Button.new()
	toggle.text = "More options"
	toggle.toggle_mode = true
	toggle.flat = true
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle.focus_mode = Control.FOCUS_NONE
	parent.add_child(toggle)
	var box := VBoxContainer.new()
	box.visible = false
	parent.add_child(box)
	toggle.toggled.connect(func(on: bool) -> void: box.visible = on)
	return box


func _small_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	return label


func _note(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)
	label.modulate = Color(1, 1, 1, 0.8)
	return label


func _row(text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = 120
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


func _slider(parent: Control, key: String, text: String, low: float, high: float, step: float, terrain := true) -> void:
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.custom_minimum_size = Vector2(140, 32)
	slider.focus_mode = Control.FOCUS_NONE
	var value := Label.new()
	value.custom_minimum_size.x = 56
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	slider.value_changed.connect(func(v: float) -> void:
		value.text = str(snappedf(v, step))
		if terrain:
			_change(key, v)
		else:
			_show_cursor())
	var row := _row(text, slider)
	row.add_child(value)
	parent.add_child(row)
	_controls[key] = slider


## Puts the project's values into the controls without triggering changes.
func _sync_controls() -> void:
	_syncing = true
	var t := project.terrain
	_seed.value = t.generation_seed
	var values := {
		"size": t.get_size().x, "cell": project.export_cell(), "land_base_height": t.land_base_height,
		"terrain_noise_amplitude": t.terrain_noise_amplitude, "hill_size": 1.0 / t.terrain_noise_frequency,
		"island_width": t.island_radius.x, "coastline_irregularity": t.coastline_irregularity,
		"coast_position": t.coast_position, "sea_floor_depth": t.sea_floor_depth,
		"mountain_height": t.mountain_regions[0].peak_height if not t.mountain_regions.is_empty() else 120.0,
		"mountain_size": t.mountain_regions[0].radius if not t.mountain_regions.is_empty() else 0.18,
	}
	for key: String in values:
		(_controls[key] as HSlider).value = values[key]
	_mountain_count.value = t.mountain_regions.size()
	for key in ["export_godot_single", "export_godot_tiles", "export_heightmap", "export_gltf"]:
		(_controls[key] as CheckBox).button_pressed = project.get(key)
	_show_land_rows()
	_syncing = false


func _show_land_rows() -> void:
	var t := project.terrain
	(_shape_buttons[t.land_shape] as Button).button_pressed = true
	(_controls["island_width"] as Control).get_parent().visible = t.land_shape == UPTGConfig.LandShape.ISLAND
	(_controls["coast_position"] as Control).get_parent().visible = t.land_shape == UPTGConfig.LandShape.COAST
	(_controls["coastline_irregularity"] as Control).get_parent().visible = t.land_shape != UPTGConfig.LandShape.CONTINENT
	var side := t.get_size().x
	for size: float in _size_buttons:
		(_size_buttons[size] as Button).set_pressed_no_signal(absf(size - side) < 1.0)


func _change(key: String, value: float) -> void:
	if _syncing:
		return
	var t := project.terrain
	match key:
		"land_shape":
			t.land_shape = int(value) as UPTGConfig.LandShape
		"size":
			project.resize(value, (_controls["cell"] as HSlider).value)
			_camera.setup(t.get_size().x)
			_camera.frame_all()
		"cell":
			project.resize(t.get_size().x, value)
		"hill_size":
			t.terrain_noise_frequency = 1.0 / value
		"island_width":
			t.island_radius = Vector2(value, value)
		"mountain_height", "mountain_size":
			_remake_mountains()
			return
		_:
			t.set(key, value)
	# An island coast may not reach the edge of the map: keep the width within what the roughness allows.
	var widest := UPTGConfig.MAX_COAST_EXTENT * (1.0 - t.coastline_irregularity)
	if t.island_radius.x > widest:
		t.island_radius = Vector2(widest, widest)
	if key in ["size", "cell"]:
		_syncing = true
		(_controls["size"] as HSlider).value = t.get_size().x
		_syncing = false
		_say(tr("The world is %.1f km from side to side, with squares of %.1f m.") % [t.get_size().x / 1000.0, project.export_cell()])
	_show_land_rows()
	_mark_dirty()
	_rebuild_wait = REBUILD_DELAY


func _remake_mountains() -> void:
	if _syncing:
		return
	UPWGProject.place_mountains(project.terrain, int(_mountain_count.value), _shuffle,
		(_controls["mountain_height"] as HSlider).value, (_controls["mountain_size"] as HSlider).value)
	_mark_dirty()
	_rebuild_wait = REBUILD_DELAY


func _on_template(template_id: String, seed_value := -1) -> void:
	var seed_number := seed_value if seed_value >= 0 else int(_seed.value)
	if _dirty:
		_ask(tr("Start a new world? What you made and did not save will be lost."), new_world.bind(template_id, seed_number))
	else:
		new_world(template_id, seed_number)


# ---------- Every frame, keys and mouse ----------

func _process(delta: float) -> void:
	if _rebuild_wait > 0.0:
		_rebuild_wait -= delta
		if _rebuild_wait <= 0.0:
			rebuild_preview()
	if _painting and _hover != Vector3.INF:
		_dab_wait -= delta
		if _dab_wait <= 0.0:
			_dab_wait = DAB_INTERVAL
			dab(Vector2(_hover.x, _hover.z))
	_fly(delta)
	if _dirty:
		_autosave_wait -= delta
		if _autosave_wait <= 0.0:
			_autosave_wait = AUTOSAVE_SECONDS
			ResourceSaver.save(project, AUTOSAVE_PATH)


func _fly(delta: float) -> void:
	if not _mouse_in_view or _typing() or Input.is_key_pressed(KEY_CTRL) or _b_held:
		return
	var move := Vector3(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_E)) - float(Input.is_key_pressed(KEY_Q)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
	if move != Vector3.ZERO:
		_camera.fly(move, delta, _ground_under(_camera.position), Input.is_key_pressed(KEY_SHIFT))
		_show_cursor()


func _typing() -> bool:
	var focus := get_viewport().gui_get_focus_owner()
	return focus is LineEdit or focus is TextEdit


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _dirty:
			ResourceSaver.save(project, AUTOSAVE_PATH)
			_ask(tr("Your world is not saved. Close anyway? A copy is kept and offered next time."), func() -> void: get_tree().quit())
		else:
			get_tree().quit()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null:
		return
	if key.keycode == KEY_B:
		_b_held = key.pressed
		return
	if not key.pressed or key.echo or _typing():
		return
	if key.ctrl_pressed and key.keycode == KEY_Z:
		undo()
	elif key.ctrl_pressed and key.keycode == KEY_Y:
		redo()
	elif key.ctrl_pressed and key.keycode == KEY_S:
		_save_shortcut()
	elif key.keycode in [KEY_ENTER, KEY_KP_ENTER] and tool == "River":
		_finish_river()
	elif key.keycode == KEY_ESCAPE:
		_river_points.clear()
		_update_markers()
	elif key.keycode == KEY_F and _hover != Vector3.INF:
		_camera.focus(_hover, maxf(_brush().radius * 6.0, 80.0))
	elif key.keycode >= KEY_1 and key.keycode <= KEY_8 and not key.ctrl_pressed:
		set_tool(EDIT_TOOLS[key.keycode - KEY_1])


func _on_view_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _b_held:
			if Input.is_key_pressed(KEY_SHIFT):
				var strength := _controls["brush_strength"] as HSlider
				strength.value = strength.value * exp(motion.relative.x * 0.01)
			else:
				var radius := _controls["brush_radius"] as HSlider
				radius.value = radius.value * exp(motion.relative.x * 0.01)
			return
		if motion.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			_camera.look(motion.relative)
		elif motion.button_mask & MOUSE_BUTTON_MASK_MIDDLE or (tool == "Look" and motion.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_camera.orbit(_view_center_point(), motion.relative, _ground_under(_camera.position))
		_hover = pick(motion.position)
		_show_cursor()
		if _painting and _hover != Vector3.INF:
			var at := Vector2(_hover.x, _hover.z)
			if at.distance_to(_last_dab) > _brush().radius * 0.25:
				_dab_wait = DAB_INTERVAL
				dab(at)
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and button.pressed:
			var steps := 1.0 if button.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
			if _b_held:
				var slider := _controls["brush_strength" if Input.is_key_pressed(KEY_SHIFT) else "brush_radius"] as HSlider
				slider.value = slider.value * (1.15 if steps > 0.0 else 1.0 / 1.15)
				return
			var target := pick(button.position)
			if target == Vector3.INF:
				target = _view_center_point()
			_camera.zoom_step(target, steps, _ground_under(_camera.position))
			_hover = pick(button.position)
			_show_cursor()
		elif button.button_index == MOUSE_BUTTON_LEFT:
			_view.grab_focus()
			_on_left_button(button.pressed, pick(button.position), button.ctrl_pressed, button.shift_pressed)
		elif button.button_index == MOUSE_BUTTON_RIGHT and not button.pressed and tool == "River" and _river_points.size() >= 2:
			_finish_river()


func _on_left_button(pressed: bool, hit: Vector3, ctrl: bool, shift: bool) -> void:
	if tool == "Look" or tab == "create":
		return
	if not pressed:
		end_stroke()
		return
	if hit == Vector3.INF:
		return
	var at := Vector2(hit.x, hit.z)
	match tool:
		"Lake":
			if ctrl:
				remove_water_near(at)
			else:
				add_lake(at)
		"River":
			if ctrl:
				remove_water_near(at)
				return
			_river_points.append(at)
			_update_markers()
			_say(tr("River: %d points. Right-click or Enter when it reaches the end.") % _river_points.size())
		_:
			begin_stroke(at, ctrl, shift)


func _finish_river() -> void:
	if _river_points.size() < 2:
		_say(tr("A river needs at least 2 points."))
		return
	var points := _river_points.duplicate()
	_river_points.clear()
	_update_markers()
	add_river(points)


func _update_markers() -> void:
	if _markers == null:
		return
	for child in _markers.get_children():
		child.queue_free()
	for p in _river_points:
		var dot := MeshInstance3D.new()
		var ball := SphereMesh.new()
		var r := maxf(_grid.cell_size * 1.5, 4.0) if _grid != null else 4.0
		ball.radius = r
		ball.height = r * 2.0
		dot.mesh = ball
		dot.material_override = _cursor.material_override
		dot.position = Vector3(p.x, _grid.height_at(p) + r, p.y)
		_markers.add_child(dot)


## Draws the brush outline on the ground under the mouse: a ring (or square) at the full size and
## a thinner one where the full effect ends.
func _show_cursor() -> void:
	if _cursor == null:
		return
	var visible_now := _hover != Vector3.INF and tab == "edit" and tool != "Look" and _grid != null
	_cursor.visible = visible_now
	if not visible_now:
		return
	_cursor_mesh.clear_surfaces()
	var center := Vector2(_hover.x, _hover.z)
	var radius: float
	var inner := -1.0
	var square := false
	if tool == "Lake":
		radius = (_controls["water_size"] as HSlider).value
	elif tool == "River":
		radius = (_controls["water_size"] as HSlider).value * 0.125
	else:
		var b := _brush()
		radius = b.radius
		inner = b.radius * (1.0 - b.softness)
		square = _brush_shape == "square"
	var width := maxf(radius * 0.04, _grid.cell_size * 0.25)
	_cursor_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_outline(center, radius, width, square)
	if inner > width * 2.0:
		_outline(center, inner, width * 0.5, square)
	_cursor_mesh.surface_end()


func _outline(center: Vector2, radius: float, width: float, square: bool) -> void:
	var points := PackedVector2Array()
	var count := 64
	for k in count:
		var a := TAU * k / count
		var dir := Vector2(cos(a), sin(a))
		if square:
			dir /= maxf(absf(dir.x), absf(dir.y))
		points.append(center + dir * radius)
	for k in count:
		var a := points[k]
		var b := points[(k + 1) % count]
		var a_in := center + (a - center) * (1.0 - width / radius)
		var b_in := center + (b - center) * (1.0 - width / radius)
		var lift := 0.6
		var v := [a, b, a_in, b_in].map(func(p: Vector2) -> Vector3: return Vector3(p.x, maxf(_grid.height_at(p), _grid.sea_level) + lift, p.y))
		for i in [0, 1, 2, 1, 3, 2]:
			_cursor_mesh.surface_add_vertex(v[i])


# ---------- Files, language, dialogs ----------

func _save_shortcut() -> void:
	if project_path != "":
		save_project(project_path)
	else:
		_ask_path("save")


func _show_export() -> void:
	_export_popup.popup_centered()


func _ask(text: String, action: Callable) -> void:
	_confirm.dialog_text = text
	_confirm_action = action
	_confirm.popup_centered()


func _ask_path(action: String) -> void:
	_dialog_action = action
	_dialog.clear_filters()
	match action:
		"open":
			_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			_dialog.add_filter(PROJECT_FILTER)
		"save":
			_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			_dialog.add_filter(PROJECT_FILTER)
			_dialog.current_file = project.world_name.to_snake_case() + ".upwg.tres"
		"export":
			_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	_dialog.popup_centered_ratio(0.6)


func _on_path_chosen(path: String) -> void:
	match _dialog_action:
		"open":
			if _dirty:
				_ask(tr("Open another world? What you made and did not save will be lost."), open_project.bind(path))
			else:
				open_project(path)
		"save":
			save_project(path)
		"export":
			export_to(path)


func _toggle_language() -> void:
	UPWGI18n.set_language("en" if TranslationServer.get_locale().begins_with("it") else "it")
	_update_language_button()
	_select_tab(tab, tool)


func _update_language_button() -> void:
	# The button shows the language you get by pressing it.
	_language_button.text = "English" if TranslationServer.get_locale().begins_with("it") else "Italiano"


func _say(text: String) -> void:
	if _status != null:
		_status.text = text
	print("[UPWG] " + text)
