shader_type spatial;
// Ground of a tiled world: grass, rock on steep slopes, sand by the sea, gravel next to the roads.
// The tiles carry the closeness to a road in the red vertex color (UPRG --road-colors).
// Plain colors by default; textures are optional and mapped from above.

uniform bool use_textures = false;
uniform sampler2D grass_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D sand_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D gravel_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float texture_scale = 0.06;
uniform vec3 grass_color : source_color = vec3(0.36, 0.52, 0.23);
uniform vec3 rock_color : source_color = vec3(0.46, 0.44, 0.41);
uniform vec3 sand_color : source_color = vec3(0.82, 0.75, 0.55);
uniform vec3 gravel_color : source_color = vec3(0.52, 0.49, 0.44);
uniform float sea_level = 0.0;
// Sand reaches this high above the sea.
uniform float beach_height = 2.0;

varying vec3 world_pos;
varying vec3 world_normal;
varying float road_near;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	road_near = COLOR.r;
}

vec3 layer(sampler2D tex, vec3 color) {
	return use_textures ? texture(tex, world_pos.xz * texture_scale).rgb : color;
}

void fragment() {
	float slope = 1.0 - world_normal.y;
	float rock_w = smoothstep(0.22, 0.42, slope);
	float sand_w = 1.0 - smoothstep(beach_height - 1.0, beach_height + 1.0, world_pos.y - sea_level);
	// Large soft patches, so that big plains do not look flat.
	float patches = sin(world_pos.x * 0.013) * sin(world_pos.z * 0.017) * 0.5 + 0.5;
	vec3 col = layer(grass_texture, grass_color) * mix(0.86, 1.1, patches);
	col = mix(col, layer(sand_texture, sand_color), sand_w * (1.0 - rock_w));
	col = mix(col, layer(rock_texture, rock_color), rock_w);
	col = mix(col, layer(gravel_texture, gravel_color), road_near * (1.0 - rock_w));
	float depth = sea_level - world_pos.y;
	col = mix(col, col * vec3(0.55, 0.75, 0.8), smoothstep(0.0, 6.0, depth));
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.3;
}
