shader_type spatial;
// A simple sea: one flat quad at sea level with small moving waves in the normal.

uniform vec3 water_color : source_color = vec3(0.07, 0.36, 0.52);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float waves(vec2 p, float t) {
	return sin(dot(p, vec2(0.21, 0.13)) + t * 1.3) * 0.5 + sin(dot(p, vec2(-0.17, 0.29)) + t * 1.7) * 0.35;
}

void fragment() {
	vec2 p = world_pos.xz;
	float h = waves(p, TIME);
	vec3 n = normalize(vec3(waves(p + vec2(0.4, 0.0), TIME) - h, 1.0, waves(p + vec2(0.0, 0.4), TIME) - h));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	ALBEDO = water_color;
	ROUGHNESS = 0.15;
	SPECULAR = 0.6;
}
