extends Node3D
## UPTG collision test (criteria A8, A9). Needs running physics, so it is a scene:
##   godot --headless --path . --fixed-fps 60 res://tests/collision/collision_test.tscn
## Exit code: 0 when every check passes, 1 otherwise.
## To test the other physics backend, set physics/3d/physics_engine for the run
## (for example with a temporary override.cfg) and run the scene again.

## Maximum allowed distance between a ray hit and UPTGTerrainData.get_height_at() (D6).
const TOLERANCE: float = 0.01
const RAY_COUNT: int = 2000
const TERRAIN_OFFSET := Vector3(10.0, 3.0, -7.0)

var _checks: int = 0
var _failures: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	print("UPTG collision test - Godot %s - physics engine setting: %s" % [
		Engine.get_version_info().string, ProjectSettings.get_setting("physics/3d/physics_engine")])
	var square := _config(128, 128, 4.0)
	var wide := _config(96, 48, 2.5)
	for mode in [UPTGConfig.CollisionMode.HEIGHTMAP, UPTGConfig.CollisionMode.TRIMESH]:
		var label: String = UPTGConfig.CollisionMode.keys()[mode]
		await _test_rays("%s 128x128 cell 4" % label, square, mode)
		await _test_rays("%s 96x48 cell 2.5" % label, wide, mode)
	await _test_none()
	await _test_falling_bodies(UPTGConfig.CollisionMode.HEIGHTMAP)
	await _test_falling_bodies(UPTGConfig.CollisionMode.TRIMESH)
	await _test_capsule()
	print("\nSUMMARY checks=%d failures=%d" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _config(cells_x: int, cells_z: int, cell: float) -> UPTGConfig:
	var c := UPTGConfig.new()
	c.grid_cells_x = cells_x
	c.grid_cells_z = cells_z
	c.cell_size = cell
	return c


func _spawn_terrain(config: UPTGConfig, mode: UPTGConfig.CollisionMode) -> UPTGTerrain:
	var c: UPTGConfig = config.duplicate(true)
	c.collision_mode = mode
	var terrain := UPTGTerrain.new()
	terrain.generate_on_ready = false
	terrain.config = c
	terrain.position = TERRAIN_OFFSET
	add_child(terrain)
	terrain.generate()
	return terrain


func _remove(node: Node) -> void:
	remove_child(node)
	node.free()


# A8: vertical rays against UPTGTerrainData.get_height_at().
func _test_rays(label: String, config: UPTGConfig, mode: UPTGConfig.CollisionMode) -> void:
	var terrain := _spawn_terrain(config, mode)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var data := terrain.get_terrain_data()
	var space := get_world_3d().direct_space_state
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var max_err: float = 0.0
	var misses: int = 0
	var half: Vector2 = data.size * 0.4999
	for i in RAY_COUNT:
		var x: float = rng.randf_range(-half.x, half.x)
		var z: float = rng.randf_range(-half.y, half.y)
		var hit := _ray(space, Vector3(x, 0.0, z) + TERRAIN_OFFSET)
		if hit.is_empty():
			misses += 1
			continue
		var expected: float = data.get_height_at(x, z) + TERRAIN_OFFSET.y
		max_err = maxf(max_err, absf(hit.position.y - expected))
	_check("A8 %s: %d rays hit, max error under 1 cm" % [label, RAY_COUNT], misses == 0 and max_err < TOLERANCE,
		"misses %d, max error %.3f mm" % [misses, max_err * 1000.0])
	var outside := _ray(space, Vector3(data.size.x, 0.0, 0.0) + TERRAIN_OFFSET)
	_check("A8 %s: no collision outside the grid" % label, outside.is_empty())
	_remove(terrain)


func _test_none() -> void:
	var terrain := _spawn_terrain(_config(64, 64, 4.0), UPTGConfig.CollisionMode.NONE)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var hit := _ray(get_world_3d().direct_space_state, TERRAIN_OFFSET)
	_check("NONE: rays do not hit the terrain", hit.is_empty())
	_remove(terrain)


func _ray(space: PhysicsDirectSpaceState3D, at: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 1000.0, at + Vector3.DOWN * 1000.0)
	return space.intersect_ray(query)


# A9: spheres dropped on a grid of points come to rest on the surface.
func _test_falling_bodies(mode: UPTGConfig.CollisionMode) -> void:
	var label: String = UPTGConfig.CollisionMode.keys()[mode]
	var terrain := _spawn_terrain(_config(128, 128, 4.0), mode)
	var data := terrain.get_terrain_data()
	var radius: float = 0.5
	var bodies: Array[RigidBody3D] = []
	for gz in 5:
		for gx in 5:
			var x: float = (gx - 2) * data.size.x * 0.1
			var z: float = (gz - 2) * data.size.y * 0.1
			var body := RigidBody3D.new()
			var shape := CollisionShape3D.new()
			var sphere := SphereShape3D.new()
			sphere.radius = radius
			shape.shape = sphere
			body.add_child(shape)
			body.lock_rotation = true  # slide and stop instead of rolling away down the hills
			body.position = Vector3(x, data.get_height_at(x, z) + 5.0, z) + TERRAIN_OFFSET
			add_child(body)
			bodies.append(body)
	for i in 600:
		await get_tree().physics_frame
	var fallen: int = 0
	var max_gap: float = 0.0
	var max_speed: float = 0.0
	for body in bodies:
		var local: Vector3 = body.position - TERRAIN_OFFSET
		var surface: float = data.get_height_at(local.x, local.z)
		if local.y < surface - radius:
			fallen += 1
		# Sphere center above the surface along the normal: between 0 and radius / n.y + margin.
		var n: Vector3 = data.get_normal_at(local.x, local.z)
		var gap: float = (local.y - surface) * n.y - radius
		max_gap = maxf(max_gap, absf(gap))
		max_speed = maxf(max_speed, body.linear_velocity.length())
	_check("A9 %s: 25 spheres stay above the surface" % label, fallen == 0, "%d fell through" % fallen)
	_check("A9 %s: spheres rest on the surface (gap under 5 cm, speed under 0.5 m/s)" % label,
		max_gap < 0.05 and max_speed < 0.5, "max gap %.1f mm, max speed %.3f m/s" % [max_gap * 1000.0, max_speed])
	for body in bodies:
		_remove(body)
	_remove(terrain)


# A9: a capsule CharacterBody3D walks across the island without sinking.
func _test_capsule() -> void:
	var terrain := _spawn_terrain(_config(128, 128, 4.0), UPTGConfig.CollisionMode.HEIGHTMAP)
	var data := terrain.get_terrain_data()
	var character := CharacterBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	character.add_child(shape)
	var start := Vector2(-data.size.x * 0.2, 0.0)
	character.position = Vector3(start.x, data.get_height_at(start.x, start.y) + 1.0, start.y) + TERRAIN_OFFSET
	add_child(character)
	for i in 30:
		await get_tree().physics_frame
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var frames: int = 900  # 15 s at 5 m/s: up the mountain flank to the summit area
	var on_floor: int = 0
	var below: int = 0
	var max_slope: float = 0.0
	for i in frames:
		await get_tree().physics_frame
		character.velocity.x = 5.0
		character.velocity.z = 0.0
		if not character.is_on_floor():
			character.velocity.y -= gravity / 60.0
		character.move_and_slide()
		var local: Vector3 = character.position - TERRAIN_OFFSET
		var surface: float = data.get_height_at(local.x, local.z)
		if local.y - 0.9 < surface - 0.05:
			below += 1
		if character.is_on_floor():
			on_floor += 1
		max_slope = maxf(max_slope, rad_to_deg(acos(data.get_normal_at(local.x, local.z).y)))
	var travelled: float = character.position.x - (start.x + TERRAIN_OFFSET.x)
	_check("A9 capsule never sinks below the surface", below == 0, "%d frames below" % below)
	_check("A9 capsule walks across moderate slopes (on floor in 90% of frames, over 60 m)",
		on_floor >= frames * 0.9 and travelled > 60.0,
		"on floor %d/%d, travelled %.1f m, max slope %.1f deg" % [on_floor, frames, travelled, max_slope])
	_remove(character)
	_remove(terrain)


func _check(test_name: String, ok: bool, detail: Variant = "") -> void:
	_checks += 1
	if not ok:
		_failures += 1
	var suffix: String = "" if str(detail) == "" else " | " + str(detail)
	print("%s %s%s" % ["PASS" if ok else "FAIL", test_name, suffix])
