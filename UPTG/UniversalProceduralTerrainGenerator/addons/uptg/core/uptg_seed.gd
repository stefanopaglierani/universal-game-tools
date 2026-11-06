class_name UPTGSeed
extends RefCounted
## Deterministic sub-seed derivation for UPTG (architecture 0.2, section 7).
##
## Every random stage of the generator uses its own sub-seed, derived from the
## master [member UPTGConfig.generation_seed] and a fixed salt. The hash is a
## 32-bit integer mix ("lowbias32" variant) implemented with 16-bit split
## multiplications, so it never overflows GDScript's 64-bit integers and does
## not depend on [method String.hash] or [method @GlobalScope.hash], whose
## results are not guaranteed stable across engine versions.

## Salt for the coastline noise.
const SALT_COASTLINE: int = 1
## Salt for the terrain relief noise.
const SALT_TERRAIN: int = 2
## Reserved for random mountain placement (not used in v0.1).
const SALT_MOUNTAINS: int = 3
## Largest valid seed (31 bits, compatible with [member FastNoiseLite.seed]).
const MAX_SEED: int = 2147483647

const _MASK32: int = 0xFFFFFFFF


## Returns a sub-seed in the range 0..[constant MAX_SEED] for [param master_seed] and [param salt].
static func derive(master_seed: int, salt: int) -> int:
	var x: int = ((master_seed & _MASK32) ^ _mul32(salt & _MASK32, 0x9E3779B9)) & _MASK32
	x = _mul32(x ^ (x >> 16), 0x7FEB352D)
	x = _mul32(x ^ (x >> 15), 0x846CA68B)
	x = x ^ (x >> 16)
	return x & MAX_SEED


## (a * b) mod 2^32 for 32-bit unsigned inputs, without exceeding 2^63.
static func _mul32(a: int, b: int) -> int:
	var lo: int = (a & 0xFFFF) * b
	var hi: int = ((a >> 16) * b) & 0xFFFF
	return (lo + (hi << 16)) & _MASK32
