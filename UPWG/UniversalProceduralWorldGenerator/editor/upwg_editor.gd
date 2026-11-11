extends Control
## The UPWG window: choose a starting point and a seed, shape the terrain with sliders, sculpt it
## with a brush, add lakes and rivers, save the project and export the finished world.
## Look tool: drag to turn, wheel to zoom. Other tools: left button paints or places, right
## button drag turns, wheel zooms. Ctrl+Z undoes, Ctrl+Y redoes.

## The preview is built with at most this many cells per side, whatever the final detail.
const PREVIEW_CELLS := 192
const REBUILD_DELAY := 0.25
const PROJECT_FILTER := "*.upwg.tres ; UPWG world"
const TOOLS := ["Look", "Raise", "Lower", "Flatten", "Smooth", "Roughen", "Lake", "River"]
## While a brush is held still, it keeps working this often (seconds).
const DAB_INTERVAL := 0.08

var project: UPWGProject
var tool := "Look"
var _shuffle := 0
var _rebuild_wait := -1.0
var _syncing := false
var _controls := {}
var _ground: MeshInstance3D
var _water: Node3D
var _sea: MeshInstance3D
var _cursor: MeshInstance3D
var _markers: Node3D
var _camera: Camera3D
var _orbit := Vector2(0.7, 0.55)
var _distance := 2600.0
var _status: Label
var _template: OptionButton
var _seed: SpinBox
var _shape: OptionButton
var _mountain_count: SpinBox
var _tool_buttons := {}
var _dialog: FileDialog
var _dialog_action := ""
## Preview state: the configuration, its data, the grid the brush edits.
var _preview_config: UPTGConfig
var _preview_data: UPTGTerrainData
var _grid: UPRGTerrainGrid
## Brush state.
var _painting := false
var _stroke_start := 0
var _last_dab := Vector2.INF
var _dab_wait := 0.0
var _flatten_height := 0.0
var _hover := Vector3.INF
var _river_points := PackedVector2Array()
var _redo: Array = []
const DEFAULT_MATERIAL := preload("res://addons/uptg/materials/uptg_terrain_default.tres")


func _ready() -> void:
	_build_ui()
	new_world("island", 12345)


# ---------- World ----------

## Starts a new world from a template and a seed.
func new_world(template_id: String, seed_value: int) -> void:
	project = UPWGProject.from_template(template_id, seed_value)
	_after_load()
	_say("New %s, seed %d. Shape it, sculpt it, then Export." % [UPWGProject.TEMPLATE_NAMES[project.template], seed_value])


func open_project(path: String) -> bool:
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as UPWGProject
	if loaded == null or loaded.terrain == null:
		_say("Cannot open %s: it is not a UPWG world." % path)
		return false
	project = loaded
	if project.world == null:
		project.world = UPRGWorldConfig.new()
	_after_load()
	_say("Opened %s." % path.get_file())
	return true


func _after_load() -> void:
	_shuffle = 0
	_redo.clear()
	_river_points.clear()
	_sync_controls()
	rebuild_preview()


func save_project(path: String) -> bool:
	if not path.ends_with(".upwg.tres"):
		path = path.get_basename() + ".upwg.tres"
	var error := ResourceSaver.save(project, path)
	_say("Saved %s." % path.get_file() if error == OK else "Could not save %s (error %d)." % [path, error])
	return error == OK


func export_to(folder: String) -> Dictionary:
	_say("Building the world at full detail and writing the files...")
	await get_tree().process_frame
	var result := UPWGExporter.export_world(project, folder)
	if result.ok:
		_say("Exported %d items to %s in %.1f s." % [result.files.size(), folder, result.seconds])
	else:
		_say("Export failed: %s" % result.error)
	return result


## Builds the 3D preview now: terrain with fewer cells than the final world, then every brush
## stroke, lake and river in order.
func rebuild_preview() -> void:
	_rebuild_wait = -1.0
	var errors := project.validate()
	if not errors.is_empty():
		_say("Cannot build this terrain: %s" % "; ".join(errors))
		return
	_preview_config = project.terrain.duplicate(true) as UPTGConfig
	var side := _preview_config.get_size().x
	UPWGProject.set_size(_preview_config, side, maxf(side / PREVIEW_CELLS, _preview_config.cell_size))
	_preview_data = UPTGHeightfieldGenerator.generate(_preview_config, true)
	if _preview_data == null:
		_say("Cannot build this terrain.")
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
	_distance = clampf(_distance, side * 0.3, side * 2.5)
	_place_camera()


func _rebuild_water() -> void:
	for child in _water.get_children():
		child.queue_free()
	for body in project.world.water:
		var plan := UPRGWaterBuilder.dig(body, _grid)
		if not plan.ok:
			_say("A lake or river could not be built: %s" % plan.error)
			continue
		var surface := UPRGWaterBuilder.build_mesh(plan, _grid)
		if surface != null:
			var node := MeshInstance3D.new()
			node.mesh = surface
			_water.add_child(node)


## The ground mesh from the current grid heights.
func _update_ground() -> void:
	_preview_data.heights = _grid.heights.duplicate()
	_ground.mesh = UPTGMeshBuilder.build(_preview_data, _preview_config)
	_ground.material_override = DEFAULT_MATERIAL


# ---------- Sculpting and water ----------

func set_tool(tool_name: String) -> void:
	tool = tool_name if tool_name in TOOLS else "Look"
	for name: String in _tool_buttons:
		(_tool_buttons[name] as Button).button_pressed = name == tool
	_river_points.clear()
	_update_markers()
	var help := {
		"Look": "Drag to turn around the world, wheel to zoom.",
		"Raise": "Hold the left button and move to raise the ground.",
		"Lower": "Hold the left button and move to lower the ground.",
		"Flatten": "Paint to flatten the ground to the height where you started.",
		"Smooth": "Paint to soften the ground.",
		"Roughen": "Paint to make the ground bumpy.",
		"Lake": "Click where the lake goes: it digs its basin and fills it, at any height.",
		"River": "Click to add points from the source to the mouth; right-click or Enter to finish, Esc to cancel.",
	}
	_say(help[tool])


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
	match tool:
		"Raise":
			edit.kind = UPRGTerrainEdit.Kind.ADD
			edit.amount = b.strength
		"Lower":
			edit.kind = UPRGTerrainEdit.Kind.ADD
			edit.amount = -b.strength
		"Flatten":
			edit.kind = UPRGTerrainEdit.Kind.LEVEL
			edit.height = _flatten_height
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


func begin_stroke(at: Vector2) -> void:
	_painting = true
	_stroke_start = project.world.terrain_edits.size()
	_flatten_height = _grid.height_at(at) - _grid.sea_level
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
	var test := _grid_copy()
	var plan := UPRGWaterBuilder.dig(body, test)
	if not plan.ok:
		_say("Cannot place it here: %s" % plan.error)
		return false
	project.world.water.append(body)
	project.history.append({"kind": "water", "count": 1})
	_redo.clear()
	rebuild_preview()
	_say("%s added. Ctrl+Z to undo." % ("Lake" if body.kind == UPRGWater.Kind.LAKE else "River"))
	return true


func undo() -> void:
	if project.history.is_empty():
		_say("Nothing to undo.")
		return
	var step: Dictionary = project.history.pop_back()
	var removed: Array = []
	var list: Array = project.world.terrain_edits if step.kind == "edits" else project.world.water
	for i in step.count:
		removed.push_front(list.pop_back())
	_redo.append({"kind": step.kind, "items": removed})
	rebuild_preview()
	_say("Undone.")


func redo() -> void:
	if _redo.is_empty():
		_say("Nothing to redo.")
		return
	var step: Dictionary = _redo.pop_back()
	for item in step.items:
		if step.kind == "edits":
			project.world.terrain_edits.append(item)
		else:
			project.world.water.append(item)
	project.history.append({"kind": step.kind, "count": step.items.size()})
	rebuild_preview()
	_say("Redone.")


func clear_sculpting() -> void:
	project.world.terrain_edits.clear()
	project.world.water.clear()
	project.history.clear()
	_redo.clear()
	rebuild_preview()
	_say("All brush strokes, lakes and rivers removed.")


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


# ---------- Interface ----------

func _build_ui() -> void:
	var split := HSplitContainer.new()
	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	split.split_offset = 400
	add_child(split)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 400
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	split.add_child(scroll)
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 6)
	scroll.add_child(panel)

	_title(panel, "UPWG  ·  World editor")
	_title(panel, "1. Start", true)
	_template = OptionButton.new()
	for id in UPWGProject.TEMPLATES:
		_template.add_item(UPWGProject.TEMPLATE_NAMES[id])
	panel.add_child(_row("Start from", _template))
	_seed = SpinBox.new()
	_seed.max_value = 2147483647
	_seed.value = 12345
	_seed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var dice := Button.new()
	dice.text = "Random"
	dice.pressed.connect(func() -> void: _seed.value = randi() % 1000000)
	var seed_box := HBoxContainer.new()
	seed_box.add_child(_seed)
	seed_box.add_child(dice)
	panel.add_child(_row("Seed", seed_box))
	var create := Button.new()
	create.text = "New world"
	create.pressed.connect(func() -> void: new_world(UPWGProject.TEMPLATES[_template.selected], int(_seed.value)))
	panel.add_child(create)

	_title(panel, "2. Terrain", true)
	_shape = OptionButton.new()
	for shape_name in ["Island", "Continent", "Coast"]:
		_shape.add_item(shape_name)
	_shape.item_selected.connect(func(index: int) -> void: _change("land_shape", index))
	panel.add_child(_row("Land", _shape))
	_slider(panel, "size", "World size (m)", 512, 16384, 256)
	_slider(panel, "cell", "Detail: cell (m)", 1, 32, 1)
	_slider(panel, "land_base_height", "Land height (m)", 0, 120, 1)
	_slider(panel, "terrain_noise_amplitude", "Hills height (m)", 0, 200, 1)
	_slider(panel, "hill_size", "Hills width (m)", 40, 1000, 10)
	_slider(panel, "island_width", "Island width", 0.2, 0.85, 0.01)
	_slider(panel, "coastline_irregularity", "Coast roughness", 0, 0.5, 0.01)
	_slider(panel, "coast_position", "Coast line", 0.2, 0.9, 0.01)
	_slider(panel, "sea_floor_depth", "Sea depth (m)", 1, 100, 1)

	_title(panel, "3. Mountains", true)
	_mountain_count = SpinBox.new()
	_mountain_count.max_value = 16
	_mountain_count.value_changed.connect(func(_v: float) -> void: _remake_mountains())
	panel.add_child(_row("How many", _mountain_count))
	_slider(panel, "mountain_height", "Height (m)", 0, 600, 5)
	_slider(panel, "mountain_size", "Width", 0.05, 0.45, 0.01)
	var move := Button.new()
	move.text = "Move the mountains"
	move.pressed.connect(func() -> void:
		_shuffle += 1
		_remake_mountains())
	panel.add_child(move)

	_title(panel, "4. Sculpt and water", true)
	var grid := GridContainer.new()
	grid.columns = 4
	for tool_name in TOOLS:
		var button := Button.new()
		button.text = tool_name
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(set_tool.bind(tool_name))
		grid.add_child(button)
		_tool_buttons[tool_name] = button
	panel.add_child(grid)
	_slider(panel, "brush_radius", "Brush size (m)", 5, 1000, 5, false)
	_slider(panel, "brush_strength", "Strength", 0.1, 10, 0.1, false)
	_slider(panel, "brush_softness", "Soft edge", 0, 1, 0.05, false)
	_slider(panel, "water_size", "Lake size (m)", 10, 1000, 5, false)
	_slider(panel, "water_depth", "Water depth (m)", 1, 40, 0.5, false)
	(_controls["brush_radius"] as HSlider).value = 60
	(_controls["brush_strength"] as HSlider).value = 2
	(_controls["brush_softness"] as HSlider).value = 0.6
	(_controls["water_size"] as HSlider).value = 80
	(_controls["water_depth"] as HSlider).value = 6
	var edit_buttons := HBoxContainer.new()
	for pair in [["Undo", undo], ["Redo", redo], ["Clear all", clear_sculpting]]:
		var button := Button.new()
		button.text = pair[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(pair[1])
		edit_buttons.add_child(button)
	panel.add_child(edit_buttons)

	_title(panel, "5. Save and export", true)
	for pair in [["export_godot_single", "Godot: one scene file"], ["export_godot_tiles", "Godot: tiles for big worlds"],
			["export_heightmap", "Heightmap: RAW 16-bit and EXR"], ["export_gltf", "glTF mesh (any 3D program)"]]:
		var check := CheckBox.new()
		check.text = pair[1]
		check.toggled.connect(func(on: bool) -> void: project.set(pair[0], on))
		_controls[pair[0]] = check
		panel.add_child(check)
	var buttons := HBoxContainer.new()
	for pair in [["Open...", "open"], ["Save...", "save"], ["Export...", "export"]]:
		var button := Button.new()
		button.text = pair[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_ask_path.bind(pair[1]))
		buttons.add_child(button)
	panel.add_child(buttons)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size.y = 60
	panel.add_child(_status)

	var view_box := SubViewportContainer.new()
	view_box.stretch = true
	view_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view_box.gui_input.connect(_on_view_input)
	view_box.mouse_exited.connect(func() -> void: _cursor.visible = false)
	split.add_child(view_box)
	var viewport := SubViewport.new()
	viewport.msaa_3d = Viewport.MSAA_4X
	view_box.add_child(viewport)
	_build_scene(viewport)

	_dialog = FileDialog.new()
	_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_dialog.use_native_dialog = true
	_dialog.file_selected.connect(_on_path_chosen)
	_dialog.dir_selected.connect(_on_path_chosen)
	add_child(_dialog)
	set_tool("Look")


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
	var ring := TorusMesh.new()
	ring.inner_radius = 0.94
	ring.outer_radius = 1.0
	ring.rings = 48
	_cursor.mesh = ring
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(1.0, 0.85, 0.2)
	glow.no_depth_test = true
	_cursor.material_override = glow
	_cursor.visible = false
	world.add_child(_cursor)
	_markers = Node3D.new()
	world.add_child(_markers)
	_camera = Camera3D.new()
	_camera.far = 60000.0
	world.add_child(_camera)


func _title(parent: Control, text: String, section := false) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18 if section else 22)
	if section:
		parent.add_child(HSeparator.new())
	parent.add_child(label)


func _row(text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = 140
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


func _slider(parent: Control, key: String, text: String, low: float, high: float, step: float, terrain := true) -> void:
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.custom_minimum_size.x = 150
	var value := Label.new()
	value.custom_minimum_size.x = 60
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slider.value_changed.connect(func(v: float) -> void:
		value.text = str(snappedf(v, step))
		if terrain:
			_change(key, v))
	var row := _row(text, slider)
	row.add_child(value)
	row.name = key
	parent.add_child(row)
	_controls[key] = slider


## Puts the project's values into the controls without triggering changes.
func _sync_controls() -> void:
	_syncing = true
	var t := project.terrain
	_template.selected = UPWGProject.TEMPLATES.find(project.template)
	_seed.value = t.generation_seed
	_shape.selected = t.land_shape
	var values := {
		"size": t.get_size().x, "cell": t.cell_size, "land_base_height": t.land_base_height,
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
	_show_shape_rows()
	_syncing = false


func _show_shape_rows() -> void:
	var shape := project.terrain.land_shape
	(_controls["island_width"] as Control).get_parent().visible = shape == UPTGConfig.LandShape.ISLAND
	(_controls["coast_position"] as Control).get_parent().visible = shape == UPTGConfig.LandShape.COAST
	(_controls["coastline_irregularity"] as Control).get_parent().visible = shape != UPTGConfig.LandShape.CONTINENT


func _change(key: String, value: float) -> void:
	if _syncing:
		return
	var t := project.terrain
	match key:
		"land_shape":
			t.land_shape = int(value) as UPTGConfig.LandShape
			_show_shape_rows()
		"size":
			UPWGProject.set_size(t, value, t.cell_size)
		"cell":
			UPWGProject.set_size(t, t.get_size().x, value)
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
	_rebuild_wait = REBUILD_DELAY


func _remake_mountains() -> void:
	if _syncing:
		return
	UPWGProject.place_mountains(project.terrain, int(_mountain_count.value), _shuffle,
		(_controls["mountain_height"] as HSlider).value, (_controls["mountain_size"] as HSlider).value)
	_rebuild_wait = REBUILD_DELAY


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


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	if key.ctrl_pressed and key.keycode == KEY_Z:
		undo()
	elif key.ctrl_pressed and key.keycode == KEY_Y:
		redo()
	elif tool == "River" and key.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		_finish_river()
	elif key.keycode == KEY_ESCAPE:
		_river_points.clear()
		_update_markers()


func _on_view_input(event: InputEvent) -> void:
	var turning: bool = event is InputEventMouseMotion and bool(
		(event.button_mask & MOUSE_BUTTON_MASK_RIGHT) or (tool == "Look" and event.button_mask & MOUSE_BUTTON_MASK_LEFT))
	if turning:
		_orbit.x -= event.relative.x * 0.006
		_orbit.y = clampf(_orbit.y + event.relative.y * 0.006, 0.08, 1.45)
		_place_camera()
		return
	if event is InputEventMouseMotion:
		_hover = pick(event.position)
		_show_cursor()
		if _painting and _hover != Vector3.INF:
			var at := Vector2(_hover.x, _hover.z)
			if at.distance_to(_last_dab) > _brush().radius * 0.25:
				_dab_wait = DAB_INTERVAL
				dab(at)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_distance *= 0.9
			_place_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_distance *= 1.1
			_place_camera()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_on_left_button(event.pressed, pick(event.position))
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and tool == "River" and _river_points.size() >= 2:
			_finish_river()


func _on_left_button(pressed: bool, hit: Vector3) -> void:
	if tool == "Look":
		return
	if not pressed:
		end_stroke()
		return
	if hit == Vector3.INF:
		return
	var at := Vector2(hit.x, hit.z)
	match tool:
		"Lake":
			add_lake(at)
		"River":
			_river_points.append(at)
			_update_markers()
			_say("River: %d points. Right-click or Enter to finish." % _river_points.size())
		_:
			begin_stroke(at)


func _finish_river() -> void:
	if _river_points.size() < 2:
		_say("A river needs at least 2 points.")
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


func _show_cursor() -> void:
	var visible_now := _hover != Vector3.INF and tool != "Look"
	_cursor.visible = visible_now
	if visible_now:
		var r: float = _brush().radius if tool not in ["Lake", "River"] else (_controls["water_size"] as HSlider).value * (1.0 if tool == "Lake" else 0.25)
		_cursor.position = _hover + Vector3.UP * 0.5
		_cursor.scale = Vector3(r, maxf(r * 0.05, 1.0), r)


func _place_camera() -> void:
	var offset := Vector3(cos(_orbit.y) * sin(_orbit.x), sin(_orbit.y), cos(_orbit.y) * cos(_orbit.x)) * _distance
	_camera.position = offset
	_camera.look_at(Vector3.ZERO)


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
			open_project(path)
		"save":
			save_project(path)
		"export":
			export_to(path)


func _say(text: String) -> void:
	if _status != null:
		_status.text = text
	print("[UPWG] " + text)
