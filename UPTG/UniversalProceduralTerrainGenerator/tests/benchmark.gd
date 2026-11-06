## UPTG benchmark (architecture 0.2, section 13). Not a pass/fail test: it prints measurements.
## Run it with a window, so that the GPU memory of the mesh can be measured:
##   godot --path . -s res://tests/benchmark.gd
## Headless also works; GPU figures and the demo frame time are then reported as n/a.
extends SceneTree

const SIZES: Array[int] = [128, 256, 512]
const DEMO_FRAMES: int = 300


func _initialize() -> void:
	_run.call_deferred()


func _mem() -> float:
	return Performance.get_monitor(Performance.MEMORY_STATIC)


func _gpu() -> int:
	return RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_BUFFER_MEM_USED)


func _mb(bytes: float) -> String:
	return "%.1f MB" % (bytes / 1048576.0)


func _run() -> void:
	var headless: bool = DisplayServer.get_name() == "headless"
	print("UPTG benchmark - Godot %s - %s - %s" % [Engine.get_version_info().string, OS.get_name(),
		"headless" if headless else RenderingServer.get_video_adapter_name()])
	var holder := Node3D.new()
	root.add_child(holder)
	for n in SIZES:
		var c := UPTGConfig.new()
		c.grid_cells_x = n
		c.grid_cells_z = n
		var cost: Dictionary = c.estimate_cost()

		var m0: float = _mem()
		var t0: int = Time.get_ticks_usec()
		var data := UPTGHeightfieldGenerator.generate(c, true)
		var t_heightfield: int = Time.get_ticks_usec() - t0
		var mem_data: float = _mem() - m0

		var g0: int = _gpu()
		m0 = _mem()
		t0 = Time.get_ticks_usec()
		var mesh := UPTGMeshBuilder.build(data, c)
		var t_mesh: int = Time.get_ticks_usec() - t0
		var instance := MeshInstance3D.new()
		instance.mesh = mesh
		holder.add_child(instance)
		await process_frame
		await process_frame
		var mem_mesh: float = _mem() - m0
		var gpu_mesh: int = _gpu() - g0

		var lines: PackedStringArray = []
		for mode in [UPTGConfig.CollisionMode.HEIGHTMAP, UPTGConfig.CollisionMode.TRIMESH]:
			m0 = _mem()
			t0 = Time.get_ticks_usec()
			var shape := UPTGCollisionBuilder.build(data, mode)
			var t_build: int = Time.get_ticks_usec() - t0
			var body := StaticBody3D.new()
			var shape_node := CollisionShape3D.new()
			shape_node.shape = shape
			shape_node.scale = UPTGCollisionBuilder.get_shape_scale(data, mode)
			body.add_child(shape_node)
			t0 = Time.get_ticks_usec()
			holder.add_child(body)
			await physics_frame
			var t_register: int = Time.get_ticks_usec() - t0
			await physics_frame
			var mem_shape: float = _mem() - m0
			lines.append("  %s: build %.1f ms, add to world + 1 physics frame %.1f ms, memory %s" % [
				UPTGConfig.CollisionMode.keys()[mode], t_build / 1000.0, t_register / 1000.0, _mb(mem_shape)])
			holder.remove_child(body)
			body.free()
			shape = null

		print("\n%d x %d cells: %d vertices, %d triangles" % [n, n, cost.vertices, cost.triangles])
		print("  estimate: %s (HEIGHTMAP), %s (TRIMESH)" % [_mb(cost.estimated_bytes),
			_mb(cost.estimated_bytes + cost.cells * UPTGConfig.BYTES_PER_CELL_TRIMESH)])
		print("  height field: %.1f ms, memory %s" % [t_heightfield / 1000.0, _mb(mem_data)])
		print("  mesh: %.1f ms, CPU memory %s, GPU buffers %s" % [t_mesh / 1000.0, _mb(mem_mesh),
			"n/a" if headless else _mb(gpu_mesh)])
		for line in lines:
			print(line)
		holder.remove_child(instance)
		instance.free()
		mesh = null
		data = null

	if headless:
		print("\ndemo frame time: n/a (headless)")
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		var demo: Node = load("res://demo/uptg_demo.tscn").instantiate()
		root.add_child(demo)
		for i in 30:
			await process_frame
		var t0: int = Time.get_ticks_usec()
		for i in DEMO_FRAMES:
			await process_frame
		var avg_ms: float = (Time.get_ticks_usec() - t0) / 1000.0 / DEMO_FRAMES
		print("\ndemo frame time (256 x 256 default, %d frames, vsync off): %.2f ms (%.0f fps)" % [DEMO_FRAMES, avg_ms, 1000.0 / avg_ms])
	quit(0)
