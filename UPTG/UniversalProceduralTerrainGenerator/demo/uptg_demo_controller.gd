extends Node3D
## UPTG demo (architecture 0.2, Milestone B).
##
## Generates an island at startup and lets you change the seed, regenerate,
## toggle the wireframe and orbit the camera. The water plane at sea level, the
## sky, the light and the camera belong to the demo only, not to the addon.

const ORBIT_SPEED: float = 0.005
const ZOOM_STEP: float = 1.1
const MIN_PITCH: float = -1.45
const MAX_PITCH: float = -0.05

@onready var _terrain: UPTGTerrain = $Terrain

var _camera: Camera3D
var _water: MeshInstance3D
var _seed_box: SpinBox
var _wireframe: CheckBox
var _info: Label
var _rng := RandomNumberGenerator.new()
var _yaw: float = 0.6
var _pitch: float = -0.55
var _distance: float = 0.0
var _rotating: bool = false


func _enter_tree() -> void:
	# Needed before any mesh is created, so that the wireframe view can draw them.
	RenderingServer.set_debug_generate_wireframes(true)


func _ready() -> void:
	_rng.randomize()
	if _terrain.config == null:
		_terrain.config = UPTGConfig.new()
	_terrain.generation_finished.connect(_on_generation_finished)
	_terrain.generation_failed.connect(_on_generation_failed)
	_build_environment()
	_build_camera()
	_build_water()
	_build_ui()
	_regenerate()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		match button.button_index:
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				_rotating = button.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if button.pressed:
					_distance /= ZOOM_STEP
					_update_camera()
			MOUSE_BUTTON_WHEEL_DOWN:
				if button.pressed:
					_distance *= ZOOM_STEP
					_update_camera()
	elif event is InputEventMouseMotion and _rotating:
		var motion := event as InputEventMouseMotion
		_yaw -= motion.relative.x * ORBIT_SPEED
		_pitch = clampf(_pitch - motion.relative.y * ORBIT_SPEED, MIN_PITCH, MAX_PITCH)
		_update_camera()


func _regenerate() -> void:
	_terrain.config.generation_seed = int(_seed_box.value)
	_terrain.generate()


func _on_random_seed() -> void:
	_seed_box.value = _rng.randi_range(0, UPTGSeed.MAX_SEED)
	_regenerate()


func _on_wireframe_toggled(enabled: bool) -> void:
	get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME if enabled else Viewport.DEBUG_DRAW_DISABLED


func _on_generation_finished(data: UPTGTerrainData) -> void:
	var plane := _water.mesh as PlaneMesh
	plane.size = data.size * 3.0
	_water.position = Vector3(0.0, data.sea_level, 0.0)
	if _distance <= 0.0:
		_distance = maxf(data.size.x, data.size.y) * 0.9
	_camera.far = maxf(data.size.x, data.size.y) * 6.0
	_update_camera()
	var s: Dictionary = _terrain.get_last_stats()
	_info.text = "\n".join([
		"Seed %d" % data.generation_seed,
		"Grid %d x %d cells, cell %.2f m (%.0f x %.0f m)" % [data.grid_cells_x, data.grid_cells_z, data.cell_size, data.size.x, data.size.y],
		"Vertices %d, triangles %d" % [s.vertices, s.triangles],
		"Height field %.1f ms, mesh %.1f ms, total %.1f ms" % [s.heightfield_us / 1000.0, s.mesh_us / 1000.0, s.total_us / 1000.0],
		"Heights %.1f .. %.1f m, sea level %.1f m" % [data.min_height, data.max_height, data.sea_level],
		"Estimated memory %.1f MB (%s)" % [s.estimated_bytes / 1048576.0, UPTGConfig.CostLevel.keys()[s.cost_level]],
		"Heights checksum %08x" % data.heights_checksum,
	])


func _on_generation_failed(message: String) -> void:
	_info.text = "Generation failed: %s" % message


func _update_camera() -> void:
	var offset: Vector3 = Vector3(0.0, 0.0, _distance).rotated(Vector3.RIGHT, _pitch).rotated(Vector3.UP, _yaw)
	_camera.position = offset
	_camera.look_at(Vector3.ZERO)


func _build_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	# Sea-colored ground, so that the horizon beyond the water plane reads as open sea.
	sky_material.ground_bottom_color = Color(0.08, 0.2, 0.32)
	sky_material.ground_horizon_color = Color(0.45, 0.58, 0.68)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 3000.0
	add_child(sun)


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.near = 0.5
	add_child(_camera)
	_camera.make_current()


func _build_water() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.32, 0.5, 0.7)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.15
	var plane := PlaneMesh.new()
	plane.material = material
	_water = MeshInstance3D.new()
	_water.name = "Water"
	_water.mesh = plane
	add_child(_water)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(12.0, 12.0)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)

	var title := Label.new()
	title.text = "UPTG demo"
	box.add_child(title)

	var seed_row := HBoxContainer.new()
	box.add_child(seed_row)
	var seed_label := Label.new()
	seed_label.text = "Seed"
	seed_row.add_child(seed_label)
	_seed_box = SpinBox.new()
	_seed_box.min_value = 0
	_seed_box.max_value = UPTGSeed.MAX_SEED
	_seed_box.step = 1
	_seed_box.rounded = true
	_seed_box.custom_minimum_size.x = 160.0
	_seed_box.value = _terrain.config.generation_seed
	seed_row.add_child(_seed_box)

	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	var regenerate := Button.new()
	regenerate.text = "Regenerate"
	regenerate.pressed.connect(_regenerate)
	buttons.add_child(regenerate)
	var random_seed := Button.new()
	random_seed.text = "Random seed"
	random_seed.pressed.connect(_on_random_seed)
	buttons.add_child(random_seed)

	_wireframe = CheckBox.new()
	_wireframe.text = "Wireframe"
	_wireframe.toggled.connect(_on_wireframe_toggled)
	box.add_child(_wireframe)

	_info = Label.new()
	box.add_child(_info)

	var help := Label.new()
	help.text = "Drag: rotate   Wheel: zoom"
	help.modulate = Color(1.0, 1.0, 1.0, 0.7)
	box.add_child(help)
