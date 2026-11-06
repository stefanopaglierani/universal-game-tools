## Tests for the UPTGTerrain node: generation, atomic replacement, signals and
## repeated regeneration (criteria A5b, A10).
extends RefCounted

var _finished: int = 0
var _failed: int = 0


func _small(seed_value: int = 12345) -> UPTGConfig:
	var c := UPTGConfig.new()
	c.generation_seed = seed_value
	c.grid_cells_x = 96
	c.grid_cells_z = 64
	c.cell_size = 8.0
	return c


func run(t: Object) -> void:
	var tree := t as SceneTree
	var terrain := UPTGTerrain.new()
	terrain.generate_on_ready = false
	terrain.config = _small()
	terrain.generation_finished.connect(func(_d: UPTGTerrainData) -> void: _finished += 1)
	terrain.generation_failed.connect(func(_m: String) -> void: _failed += 1)
	tree.root.add_child(terrain)

	t.check("no terrain before generate()", terrain.get_terrain_data() == null and terrain.get_child_count() == 0)
	t.check("generate() succeeds", terrain.generate())
	var mesh_node := terrain.get_node_or_null("UPTGMesh") as MeshInstance3D
	t.check("creates one child MeshInstance3D named UPTGMesh", mesh_node != null and terrain.get_child_count() == 1 and mesh_node.mesh != null)
	t.check("generated child has no owner (not saved in scenes)", mesh_node != null and mesh_node.owner == null)
	t.check("default material is used", mesh_node != null and mesh_node.material_override == UPTGTerrain.DEFAULT_MATERIAL)
	t.check("generation_finished emitted once", _finished == 1 and _failed == 0)
	var stats: Dictionary = terrain.get_last_stats()
	t.check("stats report times, vertices, triangles and cost",
		stats.has("heightfield_us") and stats.has("mesh_us") and stats.has("total_us") and stats.vertices == 97 * 65 and stats.triangles == 96 * 64 * 2 and stats.cost_level == UPTGConfig.CostLevel.OK, stats)

	# World-space query
	terrain.position = Vector3(100.0, 5.0, -50.0)
	var data := terrain.get_terrain_data()
	var p := data.get_vertex_position(30, 20)
	var world_h: float = terrain.get_height_at_world(Vector3(p.x + 100.0, 999.0, p.z - 50.0))
	t.check("get_height_at_world() follows the node position", absf(world_h - (p.y + 5.0)) < 1e-3, "%.4f vs %.4f" % [world_h, p.y + 5.0])
	terrain.position = Vector3.ZERO

	# A failed generation keeps the previous terrain (atomic replacement).
	var old_mesh: Mesh = mesh_node.mesh
	var old_data := terrain.get_terrain_data()
	terrain.config.cell_size = -1.0
	var ok_invalid: bool = terrain.generate()
	t.check("invalid configuration: generate() fails and keeps the previous terrain",
		not ok_invalid and mesh_node.mesh == old_mesh and terrain.get_terrain_data() == old_data and _failed == 1)
	terrain.config.cell_size = 8.0
	terrain.config.grid_cells_x = 600
	terrain.config.grid_cells_z = 600
	var ok_large: bool = terrain.generate()
	t.check("A5b LARGE without allow_large_terrain: refused, previous terrain kept",
		not ok_large and mesh_node.mesh == old_mesh and terrain.get_terrain_data() == old_data and _failed == 2)
	terrain.config = _small()

	# A10: 20 consecutive regenerations do not add nodes or keep growing memory.
	for i in 3:
		terrain.config.generation_seed = 1000 + i
		terrain.generate()
	var nodes_before: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var objects_before: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var resources_before: int = int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	var memory_before: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	var all_ok := true
	for i in 20:
		terrain.config.generation_seed = 2000 + i
		if not terrain.generate():
			all_ok = false
	var nodes_after: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var objects_after: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var resources_after: int = int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	var memory_after: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	t.check("A10 20 regenerations succeed", all_ok and terrain.get_child_count() == 1)
	t.check("A10 node count unchanged after 20 regenerations", nodes_after == nodes_before, "%d -> %d" % [nodes_before, nodes_after])
	t.check("A10 object and resource counts unchanged", objects_after == objects_before and resources_after == resources_before,
		"objects %d -> %d, resources %d -> %d" % [objects_before, objects_after, resources_before, resources_after])
	t.check("A10 static memory does not keep growing (under 1 MB over 20 regenerations)", memory_after - memory_before < 1048576.0,
		"%.1f KB" % ((memory_after - memory_before) / 1024.0))

	terrain.clear()
	t.check("clear() removes mesh and data", mesh_node.mesh == null and terrain.get_terrain_data() == null)
	tree.root.remove_child(terrain)
	terrain.free()
