class_name UPTGTerrain
extends Node3D
## Runtime terrain node (architecture 0.2, section 12): the entry point for a game.
##
## Generates the height field from [member config], builds the mesh and the collision
## shape, and shows them in child nodes created on the first generation:
## [code]UPTGMesh[/code] ([MeshInstance3D]) and [code]UPTGBody[/code] ([StaticBody3D]) with
## [code]UPTGShape[/code] ([CollisionShape3D]). The children have no owner, so they are never
## saved in a scene. Regeneration is atomic: the new terrain replaces the old one only when
## every step succeeds; the resources are replaced, the nodes are kept.

## Emitted when [method generate] starts.
signal generation_started
## Emitted when a generation succeeds.
signal generation_finished(data: UPTGTerrainData)
## Emitted when a generation fails; the previous terrain is kept.
signal generation_failed(message: String)

const DEFAULT_MATERIAL: Material = preload("res://addons/uptg/materials/uptg_terrain_default.tres")
const MESH_NODE_NAME: StringName = &"UPTGMesh"
const BODY_NODE_NAME: StringName = &"UPTGBody"
const SHAPE_NODE_NAME: StringName = &"UPTGShape"

## Configuration (preset) to generate.
@export var config: UPTGConfig
## Generates in [method Node._ready].
@export var generate_on_ready: bool = true
## Optional material; when empty the default vertex-color material is used.
@export var material_override: Material
## Allows configurations whose cost level is LARGE (architecture section 5.4).
@export var allow_large_terrain: bool = false
## Physics layers of the terrain body.
@export_flags_3d_physics var collision_layer: int = 1:
	set(value):
		collision_layer = value
		if _body != null:
			_body.collision_layer = value
## Physics layers the terrain body scans.
@export_flags_3d_physics var collision_mask: int = 1:
	set(value):
		collision_mask = value
		if _body != null:
			_body.collision_mask = value

var _data: UPTGTerrainData
var _mesh_instance: MeshInstance3D
var _body: StaticBody3D
var _shape_node: CollisionShape3D
var _stats: Dictionary = {}


func _ready() -> void:
	if generate_on_ready:
		generate()


## Validates, generates and replaces the terrain. Returns [code]true[/code] on success.
## Synchronous: do not call it from physics callbacks.
func generate() -> bool:
	generation_started.emit()
	var t_start: int = Time.get_ticks_usec()
	var errors := UPTGHeightfieldGenerator.check(config, allow_large_terrain)
	if not errors.is_empty():
		return _fail("; ".join(errors))

	var data := UPTGHeightfieldGenerator.generate(config, allow_large_terrain)
	if data == null:
		return _fail("height field generation failed")
	var t_heightfield: int = Time.get_ticks_usec()

	var mesh := UPTGMeshBuilder.build(data, config)
	if mesh == null:
		return _fail("mesh generation failed")
	var t_mesh: int = Time.get_ticks_usec()

	var mode: UPTGConfig.CollisionMode = config.collision_mode
	var shape := UPTGCollisionBuilder.build(data, mode)
	if shape == null and mode != UPTGConfig.CollisionMode.NONE:
		return _fail("collision generation failed")
	var t_collision: int = Time.get_ticks_usec()

	# Every step succeeded: swap the resources.
	_ensure_children()
	_mesh_instance.mesh = mesh
	_mesh_instance.material_override = material_override if material_override != null else DEFAULT_MATERIAL
	_shape_node.shape = shape
	_shape_node.scale = UPTGCollisionBuilder.get_shape_scale(data, mode)
	_shape_node.disabled = shape == null
	_data = data
	var t_end: int = Time.get_ticks_usec()

	var cost: Dictionary = config.estimate_cost()
	_stats = {
		"heightfield_us": t_heightfield - t_start,
		"mesh_us": t_mesh - t_heightfield,
		"collision_us": t_collision - t_mesh,
		"apply_us": t_end - t_collision,
		"total_us": t_end - t_start,
		"vertices": data.vertex_count_x * data.vertex_count_z,
		"triangles": data.grid_cells_x * data.grid_cells_z * 2,
		"estimated_bytes": cost.estimated_bytes,
		"cost_level": cost.level,
		"collision_mode": mode,
	}
	generation_finished.emit(data)
	return true


## Removes the generated terrain.
func clear() -> void:
	if _mesh_instance != null:
		_mesh_instance.mesh = null
	if _shape_node != null:
		_shape_node.shape = null
		_shape_node.disabled = true
	_data = null
	_stats = {}


## Last successful result, or [code]null[/code].
func get_terrain_data() -> UPTGTerrainData:
	return _data


## Terrain height under the world position [param pos] (its Y is ignored), in world space.
## Assumes the node is not tilted (rotation only around Y, as for any terrain).
## Returns NAN when no terrain has been generated.
func get_height_at_world(pos: Vector3) -> float:
	if _data == null:
		return NAN
	var local: Vector3 = to_local(pos)
	var surface: Vector3 = to_global(Vector3(local.x, _data.get_height_at(local.x, local.z), local.z))
	return surface.y


## Statistics of the last successful generation: times in microseconds per phase
## (heightfield_us, mesh_us, collision_us, apply_us, total_us), vertices, triangles,
## estimated_bytes, cost_level, collision_mode.
func get_last_stats() -> Dictionary:
	return _stats.duplicate()


func _ensure_children() -> void:
	# No owner is set: generated nodes are not saved in the scene.
	if _mesh_instance == null or not is_instance_valid(_mesh_instance):
		_mesh_instance = get_node_or_null(NodePath(MESH_NODE_NAME)) as MeshInstance3D
		if _mesh_instance == null:
			_mesh_instance = MeshInstance3D.new()
			_mesh_instance.name = MESH_NODE_NAME
			add_child(_mesh_instance)
	if _body == null or not is_instance_valid(_body):
		_body = get_node_or_null(NodePath(BODY_NODE_NAME)) as StaticBody3D
		if _body == null:
			_body = StaticBody3D.new()
			_body.name = BODY_NODE_NAME
			add_child(_body)
		_body.collision_layer = collision_layer
		_body.collision_mask = collision_mask
	if _shape_node == null or not is_instance_valid(_shape_node):
		_shape_node = _body.get_node_or_null(NodePath(SHAPE_NODE_NAME)) as CollisionShape3D
		if _shape_node == null:
			_shape_node = CollisionShape3D.new()
			_shape_node.name = SHAPE_NODE_NAME
			_body.add_child(_shape_node)


func _fail(message: String) -> bool:
	push_error("UPTG: " + message)
	generation_failed.emit(message)
	return false
