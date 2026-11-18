// Cel shader for scenery that can be shot full of holes. Each hole is a capsule
// in world space (start, end, radius): pixels inside are discarded, the rim is
// scorched and glows, and the hollow inside shows as charred back faces.
shader_type spatial;
render_mode specular_disabled, cull_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform int hole_n = 0;
uniform vec4 hole_a[32];   // xyz = start, w = radius
uniform vec4 hole_b[32];   // xyz = end
varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float burn = 0.0;
	for (int i = 0; i < hole_n; i++) {
		vec3 a = hole_a[i].xyz;
		vec3 ab = hole_b[i].xyz - a;
		float t = clamp(dot(wpos - a, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
		float d = length(wpos - (a + ab * t)) / max(hole_a[i].w, 0.001);
		if (d < 1.0) {
			discard;
		}
		burn = max(burn, 1.0 - smoothstep(1.0, 1.8, d));
	}
	vec3 n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	if (dot(n, VERTEX) > 0.0) {
		n = -n;
	}
	NORMAL = n;
	vec3 c = FRONT_FACING ? albedo.rgb : vec3(0.05, 0.045, 0.04);
	ALBEDO = mix(c, vec3(0.03), burn);
	EMISSION = vec3(1.0, 0.35, 0.05) * smoothstep(0.7, 1.0, burn) * 2.0;
	ROUGHNESS = 1.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(-0.02, 0.02, ndl) * 0.6 + smoothstep(0.55, 0.6, ndl) * 0.4;
	DIFFUSE_LIGHT += band * ATTENUATION * LIGHT_COLOR / PI;
}
