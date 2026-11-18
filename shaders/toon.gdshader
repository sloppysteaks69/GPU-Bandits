// Flat-shaded, two-band cel shader. Normals come from screen-space derivatives,
// so every primitive reads as faceted low-poly.
shader_type spatial;
render_mode specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 emit : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emit_power = 0.0;

void fragment() {
	vec3 n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	if (dot(n, VERTEX) > 0.0) {
		n = -n;
	}
	NORMAL = n;
	ALBEDO = albedo.rgb;
	EMISSION = emit.rgb * emit_power;
	ROUGHNESS = 1.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(-0.02, 0.02, ndl) * 0.6 + smoothstep(0.55, 0.6, ndl) * 0.4;
	DIFFUSE_LIGHT += band * ATTENUATION * LIGHT_COLOR / PI;
}
