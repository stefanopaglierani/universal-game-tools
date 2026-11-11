extends Node3D
## Flies over a world. Mouse drag turns, W A S D move, Shift goes faster, Q and E go down and up.
## Run: godot --path . res://demo/uwr_demo.tscn -- --world=<world.scn>
## With --tour the camera flies along the first road by itself; --shot=<file.png> saves a
## picture after 8 seconds and quits.

const DEFAULT_WORLD := "res://tests/data/tiled/world.scn"
const SPEED := 40.0

@onready var world: UWRWorld = $World
@onready var camera: Camera3D = $Camera
@onready var info: Label = $Info
var _yaw := 0.0
var _pitch := -0.3
var _tour := false
var _tour_t := 0.0
var _shot := ""
var _time := 0.0


func _ready() -> void:
	var path := DEFAULT_WORLD
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--world="):
			path = a.substr(8)
		elif a == "--tour":
			_tour = true
		elif a.begins_with("--shot="):
			_shot = a.substr(7)
	world.sea_size = 20000.0
	var start := Vector3(0, 80, 0)
	var road_points: Array = []
	var packed := load(path) as PackedScene
	if packed != null:
		var preview := packed.instantiate()
		road_points = (preview.get_meta(UWRWorld.META_KEY, {}) as Dictionary).get("roads", [])
		preview.free()
	if not road_points.is_empty():
		var first: Dictionary = road_points[0]
		start = Vector3(first.path[0].x, first.heights[0] + 30.0, first.path[0].y)
	camera.position = start
	if not world.load_world(path, start):
		info.text = "Cannot open %s" % path


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_yaw -= event.relative.x * 0.004
		_pitch = clampf(_pitch - event.relative.y * 0.004, -1.5, 1.5)


func _process(delta: float) -> void:
	if _tour and not world.roads().is_empty():
		_fly_tour(delta)
	else:
		var move := Vector3(Input.get_axis(&"ui_left", &"ui_right"), 0, Input.get_axis(&"ui_up", &"ui_down"))
		move.x += float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
		move.z += float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
		move.y = float(Input.is_key_pressed(KEY_E)) - float(Input.is_key_pressed(KEY_Q))
		var speed := SPEED * (4.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
		camera.rotation = Vector3(_pitch, _yaw, 0)
		camera.position += camera.global_transform.basis * move * speed * delta
	info.text = "FPS %d   tiles %d   %s" % [Engine.get_frames_per_second(), world.loaded_tiles().size(), world.world_file]
	_time += delta
	if not _shot.is_empty() and _time > 8.0:
		get_viewport().get_texture().get_image().save_png(_shot)
		print("SHOT %s tiles=%d" % [_shot, world.loaded_tiles().size()])
		get_tree().quit()


func _fly_tour(delta: float) -> void:
	var road: Dictionary = world.roads()[0]
	var path: PackedVector2Array = road.path
	var heights: PackedFloat32Array = road.heights
	_tour_t += delta * 60.0 / road.sample_spacing
	var i := int(_tour_t) % path.size()
	var j := (i + 15) % path.size()
	camera.position = Vector3(path[i].x, heights[i] + 12.0, path[i].y)
	camera.look_at(Vector3(path[j].x, heights[j] + 4.0, path[j].y))
