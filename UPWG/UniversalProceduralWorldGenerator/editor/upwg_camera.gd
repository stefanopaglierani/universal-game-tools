class_name UPWGCamera
extends Camera3D
## The editor camera, used like the one of a game editor:
##   right button held   look around (turn the head)
##   W A S D, Q E        fly forward, left, back, right, down, up (Shift: faster)
##   mouse wheel         move toward the point under the mouse, or away from it
##   orbit()             turn around a point (the Look tool, or the middle button)
##   frame_all(), top_view(), focus(), zoom_step(): the buttons of the view.

## Look speed in radians per pixel.
const LOOK_SPEED := 0.005
## Fraction of the distance travelled by one wheel step.
const WHEEL_STEP := 0.15

## Side of the world in meters; the flying speed and the limits follow it.
var world_side := 2048.0
var yaw := 0.0
var pitch := -0.6


func _ready() -> void:
	near = 0.5
	far = 60000.0


func setup(side: float) -> void:
	world_side = side
	far = maxf(side * 4.0, 2000.0)


## Turns the head: [param relative] is the mouse movement in pixels.
func look(relative: Vector2) -> void:
	yaw -= relative.x * LOOK_SPEED
	pitch = clampf(pitch - relative.y * LOOK_SPEED, -1.55, 1.2)
	_apply()


## Flies along the view: [param move] is (right, up, back) in -1..1, [param ground] the height
## of the ground under the camera (the speed grows with the height above it).
func fly(move: Vector3, delta: float, ground: float, fast: bool) -> void:
	if move == Vector3.ZERO:
		return
	var height := maxf(position.y - ground, 5.0)
	var speed := clampf(height * 1.2, 15.0, world_side * 0.3) * (3.0 if fast else 1.0)
	var flat_forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var step := (right * move.x + Vector3.UP * move.y - flat_forward * move.z).normalized() * speed * delta
	position = _limit(position + step, ground)


## Moves toward [param target] (a point in the world) by one wheel step, or away from it when
## [param steps] is negative.
func zoom_step(target: Vector3, steps: float, ground: float) -> void:
	var to_target := target - position
	var distance := to_target.length()
	if distance < 0.01:
		return
	var travel := distance * WHEEL_STEP * steps
	if steps > 0.0:
		travel = minf(travel, distance - 3.0)
	position = _limit(position + to_target / distance * travel, ground)


## Turns around [param pivot] by the mouse movement [param relative], in pixels.
func orbit(pivot: Vector3, relative: Vector2, ground: float) -> void:
	var offset := position - pivot
	var turned := offset.rotated(Vector3.UP, -relative.x * LOOK_SPEED)
	var side := turned.cross(Vector3.UP).normalized()
	if side != Vector3.ZERO:
		var tilted := turned.rotated(side, relative.y * LOOK_SPEED)
		# Never go under the pivot or straight above it.
		var elevation := asin(clampf(tilted.normalized().y, -1.0, 1.0))
		if elevation > 0.05 and elevation < 1.5:
			turned = tilted
	position = _limit(pivot + turned, ground)
	look_toward(pivot)


## Shows the whole world from above at an angle.
func frame_all() -> void:
	position = Vector3(0.0, world_side * 0.55, world_side * 0.75)
	look_toward(Vector3.ZERO)


## Looks straight down on the whole world.
func top_view() -> void:
	position = Vector3(0.0, world_side * 1.1, 0.001)
	yaw = 0.0
	pitch = -1.55
	_apply()


## Flies to look at [param point] from a short distance.
func focus(point: Vector3, distance: float) -> void:
	var back := Vector3(sin(yaw), 0.0, cos(yaw)) * distance * 0.8 + Vector3.UP * distance * 0.6
	position = point + back
	look_toward(point)


func look_toward(point: Vector3) -> void:
	var direction := (point - position).normalized()
	if direction == Vector3.ZERO:
		return
	yaw = atan2(-direction.x, -direction.z)
	pitch = asin(clampf(direction.y, -1.0, 1.0))
	_apply()


func _apply() -> void:
	basis = Basis.from_euler(Vector3(pitch, yaw, 0.0))


## Keeps the camera above the ground and not too far from the world.
func _limit(p: Vector3, ground: float) -> Vector3:
	var reach := world_side * 1.5
	p.x = clampf(p.x, -reach, reach)
	p.z = clampf(p.z, -reach, reach)
	p.y = clampf(p.y, ground + 2.0, world_side * 2.0)
	return p
