extends Control
## The UPWG window: choose a starting point and a seed, shape the terrain with sliders while a
## 3D preview follows, save the project, and export the finished world.
## Drag in the preview to turn around the world, use the wheel to zoom.

## The preview is built with at most this many cells per side, whatever the final detail.
const PREVIEW_CELLS := 192
const REBUILD_DELAY := 0.25
const PROJECT_FILTER := "*.upwg.tres ; UPWG world"

var project: UPWGProject
var _shuffle := 0
var _rebuild_wait := -1.0
var _syncing := false
var _controls := {}
var _preview_terrain: UPTGTerrain
var _sea: MeshInstance3D
var _camera: Camera3D
var _orbit := Vector2(0.7, 0.55)
var _distance := 2600.0
var _status: Label
var _template: OptionButton
var _seed: SpinBox
var _shape: OptionButton
var _mountain_count: SpinBox
var _dialog: FileDialog
var _dialog_action := ""


func _ready() -> void:
	_build_ui()
	new_world("island", 12345)


# ---------- World ----------

## Starts a new world from a template and a seed.
func new_world(template_id: String, seed_value: int) -> void:
	project = UPWGProject.from_template(template_id, seed_value)
	_shuffle = 0
	_sync_controls()
	rebuild_preview()
	_say("New %s, seed %d. Move the sliders, then Export." % [UPWGProject.TEMPLATE_NAMES[project.template], seed_value])


func open_project(path: String) -> bool:
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as UPWGProject
	if loaded == null or loaded.terrain == null:
		_say("Cannot open %s: it is not a UPWG world." % path)
		return false
	project = loaded
	_sync_controls()
	rebuild_preview()
	_say("Opened %s." % path.get_file())
	return true


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


## Builds the 3D preview now, with fewer cells than the final world.
func rebuild_preview() -> void:
	_rebuild_wait = -1.0
	var errors := project.validate()
	if not errors.is_empty():
		_say("Cannot build this terrain: %s" % "; ".join(errors))
		return
	var preview := project.terrain.duplicate(true) as UPTGConfig
	var side := preview.get_size().x
	UPWGProject.set_size(preview, side, maxf(side / PREVIEW_CELLS, preview.cell_size))
	preview.collision_mode = UPTGConfig.CollisionMode.NONE
	_preview_terrain.config = preview
	_preview_terrain.generate()
	_sea.position.y = preview.sea_level
	(_sea.mesh as PlaneMesh).size = Vector2(side * 3.0, side * 3.0)
	_sea.visible = preview.land_shape != UPTGConfig.LandShape.CONTINENT
	_distance = clampf(_distance, side * 0.3, side * 2.5)
	_place_camera()


# ---------- Interface ----------

func _build_ui() -> void:
	var split := HSplitContainer.new()
	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	split.split_offset = 380
	add_child(split)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 380
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
	_slider(panel, "size", "World size (m)", 512, 8192, 256)
	_slider(panel, "cell", "Detail: cell (m)", 1, 16, 1)
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

	_title(panel, "4. Save and export", true)
	for pair in [["export_godot_single", "Godot: one scene file"], ["export_godot_tiles", "Godot: tiles for big worlds"],
			["export_heightmap", "Heightmap: RAW 16-bit and EXR"], ["export_gltf", "glTF mesh (any 3D program)"]]:
		var check := CheckBox.new()
		check.text = pair[1]
		check.name = pair[0]
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
	env.fog_density = 0.00015
	environment.environment = env
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 6000.0
	world.add_child(sun)
	_preview_terrain = UPTGTerrain.new()
	_preview_terrain.generate_on_ready = false
	world.add_child(_preview_terrain)
	_sea = MeshInstance3D.new()
	_sea.mesh = PlaneMesh.new()
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.1, 0.38, 0.55)
	water.roughness = 0.2
	_sea.material_override = water
	world.add_child(_sea)
	_camera = Camera3D.new()
	_camera.far = 40000.0
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


func _slider(parent: Control, key: String, text: String, low: float, high: float, step: float) -> void:
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


func _on_view_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_orbit.x -= event.relative.x * 0.006
		_orbit.y = clampf(_orbit.y + event.relative.y * 0.006, 0.08, 1.45)
		_place_camera()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance *= 0.9
			_place_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance *= 1.1
			_place_camera()


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
