class_name UPRGTerrainEdit
extends Resource
## One direct change to the terrain in a round or square area with a soft edge: the brush strokes
## of an editor are lists of these.

enum Kind {
	ADD, ## Adds [member amount] meters (negative to lower).
	LEVEL, ## Sets the area to [member height] above the sea.
	SMOOTH, ## Moves the area toward the average of its neighbors; [member amount] is the strength, 0..1.
	ROUGHEN, ## Adds bumps up to [member amount] meters, from [member noise_seed].
}

## LEVEL: which ground moves toward [member height].
enum LevelMode {
	BOTH, ## Lowers what is above and raises what is below.
	DOWN_ONLY, ## Only lowers what is above.
	UP_ONLY, ## Only raises what is below.
}

@export var kind: Kind = Kind.ADD
## Center of the area, in meters from the terrain center, as (x, z).
@export var center: Vector2 = Vector2.ZERO
## Radius of the full effect.
@export_range(0.5, 2000.0, 0.5) var radius: float = 40.0
## Width of the soft edge beyond the radius.
@export_range(0.5, 500.0, 0.5) var blend: float = 30.0
## ADD: meters to add. SMOOTH: strength 0..1. ROUGHEN: height of the bumps.
@export_range(-500.0, 500.0, 0.1) var amount: float = 10.0
## Height above the sea, for LEVEL.
@export_range(-200.0, 1000.0, 0.1) var height: float = 10.0
## ROUGHEN: size of the bumps in meters, and the seed that places them.
@export_range(1.0, 500.0, 0.5) var bump_size: float = 12.0
@export var noise_seed: int = 0
## Square area instead of a round one (the radius is half the side).
@export var square: bool = false
## LEVEL: which ground moves, and how far toward [member height] (0..1).
@export var level_mode: LevelMode = LevelMode.BOTH
@export_range(0.0, 1.0, 0.01) var strength: float = 1.0


## Applies this edit to [param grid]. Returns the number of vertices changed.
func apply(grid: UPRGTerrainGrid) -> int:
	var reach := radius + blend
	var ix0 := clampi(floori((center.x - reach) / grid.cell_size + grid.cells_x / 2.0), 0, grid.cells_x)
	var ix1 := clampi(ceili((center.x + reach) / grid.cell_size + grid.cells_x / 2.0), 0, grid.cells_x)
	var iz0 := clampi(floori((center.y - reach) / grid.cell_size + grid.cells_z / 2.0), 0, grid.cells_z)
	var iz1 := clampi(ceili((center.y + reach) / grid.cell_size + grid.cells_z / 2.0), 0, grid.cells_z)
	var source := grid.heights
	if kind == Kind.SMOOTH:
		source = grid.heights.duplicate()
	var noise: FastNoiseLite
	if kind == Kind.ROUGHEN:
		noise = FastNoiseLite.new()
		noise.seed = noise_seed
		noise.frequency = 1.0 / bump_size
	var changed := 0
	for iz in range(iz0, iz1 + 1):
		for ix in range(ix0, ix1 + 1):
			var p := Vector2(grid.vertex_x(ix), grid.vertex_z(iz))
			var d := maxf(absf(p.x - center.x), absf(p.y - center.y)) if square else p.distance_to(center)
			if d >= reach:
				continue
			var k := 1.0 - smoothstep(0.0, 1.0, (d - radius) / blend) if d > radius else 1.0
			var i := grid.index(ix, iz)
			match kind:
				Kind.ADD:
					grid.heights[i] += amount * k
				Kind.LEVEL:
					var target := grid.sea_level + height
					var now := grid.heights[i]
					if (level_mode == LevelMode.DOWN_ONLY and now <= target) or (level_mode == LevelMode.UP_ONLY and now >= target):
						continue
					grid.heights[i] = lerpf(now, target, k * strength)
				Kind.SMOOTH:
					grid.heights[i] = lerpf(source[i], _average(source, grid, ix, iz), clampf(amount, 0.0, 1.0) * k)
				Kind.ROUGHEN:
					grid.heights[i] += noise.get_noise_2d(p.x, p.y) * amount * k
			changed += 1
	return changed


static func _average(h: PackedFloat32Array, grid: UPRGTerrainGrid, ix: int, iz: int) -> float:
	var total := 0.0
	var count := 0
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var x := ix + dx
			var z := iz + dz
			if x >= 0 and z >= 0 and x <= grid.cells_x and z <= grid.cells_z:
				total += h[grid.index(x, z)]
				count += 1
	return total / count
