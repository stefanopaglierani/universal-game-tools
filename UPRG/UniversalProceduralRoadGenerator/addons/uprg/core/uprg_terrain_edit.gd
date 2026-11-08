class_name UPRGTerrainEdit
extends Resource
## One direct change to the terrain: a circular area raised, lowered or leveled.

enum Kind {
	ADD, ## Adds [member amount] meters (negative to lower).
	LEVEL, ## Sets the area to [member height].
}

@export var kind: Kind = Kind.ADD
## Center of the area, in meters from the terrain center, as (x, z).
@export var center: Vector2 = Vector2.ZERO
## Radius of the full effect.
@export_range(0.5, 2000.0, 0.5) var radius: float = 40.0
## Width of the soft edge beyond the radius.
@export_range(0.5, 500.0, 0.5) var blend: float = 30.0
## Meters to add, for ADD.
@export_range(-500.0, 500.0, 0.1) var amount: float = 10.0
## Height above the sea, for LEVEL.
@export_range(-200.0, 1000.0, 0.1) var height: float = 10.0


## Applies this edit to [param grid]. Returns the number of vertices changed.
func apply(grid: UPRGTerrainGrid) -> int:
	var changed := 0
	for iz in grid.cells_z + 1:
		for ix in grid.cells_x + 1:
			var d := Vector2(grid.vertex_x(ix), grid.vertex_z(iz)).distance_to(center)
			if d >= radius + blend:
				continue
			var k := 1.0 - smoothstep(0.0, 1.0, (d - radius) / blend) if d > radius else 1.0
			var i := grid.index(ix, iz)
			var target := grid.heights[i] + amount if kind == Kind.ADD else grid.sea_level + height
			grid.heights[i] = lerpf(grid.heights[i], target, k)
			changed += 1
	return changed
