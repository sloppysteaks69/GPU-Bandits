// Energy shield around a pilot's ship. Invisible until something hits it; then
// a light-blue hexagon lattice flashes at the impact point and a ripple runs
// outward over the bubble. Up to four impacts can be rippling at once.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 hits[4];      // xyz = impact direction in the ship's own space, w = age in seconds (< 0 = unused)
uniform float over = 0.0;       // SHIELD OVERCHARGE: 0 off .. 1 full 200% shield, crackles
uniform float strength = 1.0;   // shield left, 0..1: blue when full, red when failing
varying vec3 lp;

void vertex() {
	lp = VERTEX;
}

// 0 at a hexagon's edge, rising to 0.5 at its centre.
float hex_edge(vec2 p) {
	vec2 s = vec2(1.0, 1.7320508);
	vec2 a = mod(p, s) - s * 0.5;
	vec2 b = mod(p - s * 0.5, s) - s * 0.5;
	vec2 g = abs(dot(a, a) < dot(b, b) ? a : b);
	return 0.5 - max(g.x, dot(g, vec2(0.5, 0.8660254)));
}

void fragment() {
	vec3 n = normalize(lp);
	float glow = 0.0;
	for (int i = 0; i < 4; i++) {
		float age = hits[i].w;
		if (age >= 0.0 && age < 0.9) {
			float ang = acos(clamp(dot(n, hits[i].xyz), -1.0, 1.0));
			float ring = exp(-pow((ang - age * 4.2) / 0.24, 2.0));          // the travelling ripple
			float core = exp(-ang * ang / 0.45) * exp(-age * 5.0);          // the flash where it landed
			glow += (ring + core * 1.5) * (1.0 - age / 0.9);
		}
	}
	// Nearly gone: the field flickers faintly on its own and wobbling holes
	// open up in it, growing as the last of the shield drains away.
	float weak = 1.0 - clamp(strength / 0.35, 0.0, 1.0);
	float wob = sin(n.x * 5.0 + TIME * 2.6) * sin(n.y * 6.0 - TIME * 2.1) + sin(n.z * 7.0 + TIME * 3.3) * 0.6;
	float hole = smoothstep(0.9 - weak * 1.3, 1.1 - weak * 1.3, wob) * step(0.001, weak);
	glow += weak * 0.22 * (0.7 + 0.3 * sin(TIME * 17.0)) * step(0.001, strength);
	vec2 uv = vec2(atan(n.x, n.z) * 3.2, asin(clamp(n.y, -1.0, 1.0)) * 4.2);
	float line = 1.0 - smoothstep(0.03, 0.09, hex_edge(uv));
	float a = glow * (0.18 + 0.82 * line) * (1.0 - hole);
	vec3 tint = mix(vec3(1.0, 0.2, 0.15), vec3(0.45, 0.85, 1.0), smoothstep(0.0, 0.8, strength));
	if (over > 0.0) {
		// thin lightning veins that writhe over the bubble, plus a faint lit lattice
		float v1 = sin(n.x * 9.0 + sin(n.y * 7.0 + TIME * 11.0) * 1.6 + TIME * 6.0) * sin(n.z * 8.0 - TIME * 9.0 + sin(n.x * 5.0 + TIME * 4.0) * 2.0);
		float v2 = sin(n.y * 11.0 - TIME * 13.0 + sin(n.z * 6.0) * 2.2) * sin(n.x * 10.0 + TIME * 7.0);
		float vein = (1.0 - smoothstep(0.0, 0.07, abs(v1))) + (1.0 - smoothstep(0.0, 0.05, abs(v2))) * 0.7;
		float flick = 0.55 + 0.45 * sin(TIME * 43.0 + n.y * 17.0);
		a += over * (0.05 + 0.12 * line + vein * 0.85 * flick);
		tint = mix(tint, vec3(0.75, 0.6, 1.0), over * 0.6);
	}
	ALBEDO = tint * 1.8;
	ALPHA = clamp(a, 0.0, 1.0);
}
