## Tests for UPTGSeed (criterion A7, seed part).
extends RefCounted


func run(t: Object) -> void:
	# Expected values computed independently (Python reference implementation).
	var vectors: Array = [
		[0, 1, 33350994],
		[12345, 1, 1868776673],
		[12345, 2, 1162198605],
		[2147483647, 3, 2090469116],
	]
	for v in vectors:
		var got: int = UPTGSeed.derive(v[0], v[1])
		t.check("A7 derive(%d, %d) == %d" % [v[0], v[1], v[2]], got == v[2], got)

	var in_range := true
	var distinct := {}
	for s in 200:
		for salt in [UPTGSeed.SALT_COASTLINE, UPTGSeed.SALT_TERRAIN, UPTGSeed.SALT_MOUNTAINS]:
			var d: int = UPTGSeed.derive(s * 7919, salt)
			if d < 0 or d > UPTGSeed.MAX_SEED:
				in_range = false
			distinct[d] = true
	t.check("A7 sub-seeds stay within 0..MAX_SEED", in_range)
	t.check("A7 sub-seeds are distinct for 600 (seed, salt) pairs", distinct.size() == 600, distinct.size())
	t.check("A7 salts give different sub-seeds for the same master seed",
		UPTGSeed.derive(12345, UPTGSeed.SALT_COASTLINE) != UPTGSeed.derive(12345, UPTGSeed.SALT_TERRAIN))

	# Noise sampling offsets (simplex noise is 0 at the origin for every seed)
	var offsets_ok := true
	for s in 200:
		for salt in [UPTGSeed.SALT_COASTLINE_OFFSET, UPTGSeed.SALT_TERRAIN_OFFSET]:
			var o: Vector2 = UPTGSeed.noise_offset(s * 7919, salt)
			for c in [o.x, o.y]:
				if c < UPTGSeed.NOISE_OFFSET_MIN or c > UPTGSeed.NOISE_OFFSET_MIN + 8191.0 or c != floorf(c):
					offsets_ok = false
	t.check("noise offsets are whole meters within NOISE_OFFSET_MIN..+8191", offsets_ok)
	t.check("coastline and terrain offsets differ for the same master seed",
		UPTGSeed.noise_offset(12345, UPTGSeed.SALT_COASTLINE_OFFSET) != UPTGSeed.noise_offset(12345, UPTGSeed.SALT_TERRAIN_OFFSET),
		"%s / %s" % [UPTGSeed.noise_offset(12345, UPTGSeed.SALT_COASTLINE_OFFSET), UPTGSeed.noise_offset(12345, UPTGSeed.SALT_TERRAIN_OFFSET)])
