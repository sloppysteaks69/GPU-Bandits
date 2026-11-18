shader_type spatial;
render_mode specular_disabled;

uniform vec4 col_a : source_color = vec4(0.10, 0.32, 0.36, 1.0);
uniform vec4 col_b : source_color = vec4(0.07, 0.24, 0.30, 1.0);
uniform vec4 ring : source_color = vec4(0.95, 0.75, 0.2, 1.0);
uniform float arena_r = 430.0;
varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 g = floor(wp.xz / 40.0);
	float chk = mod(g.x + g.y, 2.0);
	vec3 c = mix(col_a.rgb, col_b.rgb, chk);
	float d = length(wp.xz);
	c = mix(c, ring.rgb, step(abs(d - arena_r), 4.0));
	c = mix(c, ring.rgb, step(abs(d - 150.0), 2.0));
	c *= d > arena_r ? 0.55 : 1.0;
	ALBEDO = c;
	ROUGHNESS = 1.0;
}
