class_name UPTGTerrain
extends Node3D
## Runtime terrain node (architecture 0.2, section 12): the entry point for a game.
##
## Generates the height field from [member config], builds the mesh and shows it in a
## child [MeshInstance3D] named [code]UPTGMesh[/code]. Regeneration is atomic: the new
## terrain replaces the old one only when every step succeeds.
## Collision (child [code]UPTGBody[/code]) arrives in Milestone C.

## Emitted when [method generate] starts.
signal generation_started
## Emitted when a generation succeeds.
signal generation_finished(data: UPTGTerrainData)
## Emitted when a generation fails; the previous terrain is kept.
signal generation_failed(message: String)

const DEFAULT_MATERIAL: Material = preload("res://addons/uptg/materials/uptg_terrain_default.tres")
const MESH_NODE_NAME: StringName = &"UPTGMesh"

## Configuration (preset) to generate.
@export var config: UPTGConfig
## Generates in [method Node._ready].
@export var generate_on_ready: bool = true
## Optional material; when empty the default vertex-color material is used.
@export var material_override: Material
## Allows configurations whose cost level is LARGE (architecture section 5.4).
@export var allow_large_terrain: bool = false

var _data: UPTGTerrainData
var _mesh_instance: MeshInstance3D
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

	# Every step succeeded: swap the resources.
	_ensure_mesh_instance()
	_mesh_instance.mesh = mesh
	_mesh_instance.material_override = material_override if material_override != null else DEFAULT_MATERIAL
	_data = data
	var t_end: int = Time.get_ticks_usec()

	var cost: Dictionary = config.estimate_cost()
	_stats = {
		"heightfield_us": t_heightfield - t_start,
		"mesh_us": t_mesh - t_heightfield,
		"apply_us": t_end - t_mesh,
		"total_us": t_end - t_start,
		"vertices": data.vertex_count_x * data.vertex_count_z,
		"triangles": data.grid_cells_x * data.grid_cells_z * 2,
		"estimated_bytes": cost.estimated_bytes,
		"cost_level": cost.level,
	}
	generation_finished.emit(data)
	return true


## Removes the generated terrain.
func clear() -> void:
	if _mesh_instance != null:
		_mesh_instance.mesh = null
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
## (heightfield_us, mesh_us, apply_us, total_us), vertices, triangles, estimated_bytes, cost_level.
func get_last_stats() -> Dictionary:
	return _stats.duplicate()


func _ensure_mesh_instance() -> void:
	if _mesh_instance != null and is_instance_valid(_mesh_instance):
		return
	_mesh_instance = get_node_or_null(NodePath(MESH_NODE_NAME)) as MeshInstance3D
	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.name = MESH_NODE_NAME
		add_child(_mesh_instance)  # no owner: generated nodes are not saved in the scene


func _fail(message: String) -> bool:
	push_error("UPTG: " + message)
	generation_failed.emit(message)
	return false
