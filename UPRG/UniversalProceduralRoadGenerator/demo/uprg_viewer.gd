extends Node3D
## Shows any baked world file: godot --path . res://demo/uprg_viewer.tscn -- --file=<world.scn>
## Drag to rotate, wheel to zoom.

var _yaw := 0.6
var _pitch := -0.55
var _distance := 900.0

@onready var _camera: Camera3D = $Camera


func _ready() -> void:
	var path := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--file="):
			path = a.substr(7)
	var info := Label.new()
	info.position = Vector2(12, 12)
	var layer := CanvasLayer.new()
	layer.add_child(info)
	add_child(layer)
	var packed := load(path) as PackedScene if not path.is_empty() else null
	if packed == null:
		info.text = "Start with -- --file=<world.scn>"
		return
	var world := packed.instantiate() as Node3D
	add_child(world)
	var meta: Dictionary = world.get_meta("terrain_data", {})
	var roads: Array = meta.get("roads", [])
	info.text = "%s\nSeed %s, %d road(s)\nDrag: rotate   Wheel: zoom" % [path.get_file(), str(meta.get("generation_seed", "?")), roads.size()]
	_update_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_yaw -= event.relative.x * 0.005
		_pitch = clampf(_pitch - event.relative.y * 0.005, -1.45, -0.05)
		_update_camera()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = maxf(_distance * 0.9, 10.0)
			_update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = minf(_distance * 1.1, 3000.0)
			_update_camera()


func _update_camera() -> void:
	var direction := Vector3(0, 0, 1).rotated(Vector3.RIGHT, _pitch).rotated(Vector3.UP, _yaw)
	_camera.global_position = direction * _distance
	_camera.look_at(Vector3.ZERO)
