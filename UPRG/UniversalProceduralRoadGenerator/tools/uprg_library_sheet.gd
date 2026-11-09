extends SceneTree
## Draws every object of the library in rows, to check that each one stands upright and at scale.
## godot --path . -s res://tools/uprg_library_sheet.gd -- --out=<picture base> [--library=<folder>]
## Writes <picture base>_<n>.png, one picture per row of kinds.

const PER_PAGE := 24


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "user://sheet"
	var library := "res://library"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--library="):
			library = a.substr(10)
	var items: Array = JSON.parse_string(FileAccess.get_file_as_string(library.path_join("index.json")))
	root.size = Vector2i(1600, 900)
	var world := Node3D.new()
	root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	world.add_child(sun)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.62, 0.7)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.7
	var environment := WorldEnvironment.new()
	environment.environment = env
	world.add_child(environment)
	var camera := Camera3D.new()
	camera.far = 5000.0
	world.add_child(camera)
	var layer := CanvasLayer.new()
	world.add_child(layer)
	var page := 0
	var start := 0
	while start < items.size():
		var group := Node3D.new()
		world.add_child(group)
		var labels := Control.new()
		layer.add_child(labels)
		var slice: Array = items.slice(start, start + PER_PAGE)
		var cols := 6
		var cell := 0.0
		for item: Dictionary in slice:
			var s: Array = item.size
			cell = maxf(cell, maxf(float(s[0]), maxf(float(s[1]), float(s[2]))))
		cell = maxf(cell * 1.15, 3.0)
		for i in slice.size():
			var item: Dictionary = slice[i]
			var instance := MeshInstance3D.new()
			instance.mesh = load(item.path)
			instance.position = Vector3((i % cols) * cell, 0, (i / cols) * cell)
			group.add_child(instance)
		var rows := ceili(slice.size() / float(cols))
		var center := Vector3((cols - 1) * cell * 0.5, 0, (rows - 1) * cell * 0.5)
		camera.position = center + Vector3(0, cell * 2.6, cell * 4.2)
		camera.look_at(center + Vector3.UP * cell * 0.2)
		await process_frame
		for i in slice.size():
			var item: Dictionary = slice[i]
			var at := Vector3((i % cols) * cell, 0, (i / cols) * cell)
			var label := Label.new()
			label.text = "%s %s %s" % [item.id, item.kind, str(item.size)]
			label.position = camera.unproject_position(at) + Vector2(-60, 4)
			label.add_theme_font_size_override("font_size", 11)
			labels.add_child(label)
		for i in 12:
			await process_frame
		root.get_texture().get_image().save_png("%s_%d.png" % [out, page])
		group.free()
		labels.free()
		start += PER_PAGE
		page += 1
	print("SHEET pages=%d items=%d" % [page, items.size()])
	quit(0)
