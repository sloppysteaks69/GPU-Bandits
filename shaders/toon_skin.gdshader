// Cel shader for the textured, skinned boss: two-band lighting, faceted
// normals, posterized texture, plus battle damage. Damage is a 3D texture in
// the body's bind-pose space (looked up through the vertex colour, which holds
// each vertex's rest position), so holes stay put on the body as it animates.
shader_type spatial;
render_mode specular_disabled, cull_disabled;

uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform sampler3D dmg : filter_linear, repeat_disable;
uniform float dmg_on = 0.0;
uniform float posterize = 7.0;
varying vec3 bind_uvw;

void vertex() {
	bind_uvw = COLOR.rgb;
}

void fragment() {
	float v = 0.0;
	if (dmg_on > 0.5) {
		v = texture(dmg, bind_uvw).r;
		if (v > 0.5) {
			discard;
		}
	}
	vec3 n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	if (dot(n, VERTEX) > 0.0) {
		n = -n;
	}
	NORMAL = n;
	vec3 c = texture(tex, UV).rgb;
	c = floor(c * posterize + 0.5) / posterize;
	if (!FRONT_FACING) {
		c = vec3(0.07, 0.03, 0.03);   // the hollow inside, seen through a hole
	}
	ALBEDO = mix(c, vec3(0.03), smoothstep(0.06, 0.45, v));
	EMISSION = vec3(1.0, 0.35, 0.05) * smoothstep(0.28, 0.5, v) * 2.5;
	ROUGHNESS = 1.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(-0.02, 0.02, ndl) * 0.6 + smoothstep(0.55, 0.6, ndl) * 0.4;
	DIFFUSE_LIGHT += band * ATTENUATION * LIGHT_COLOR / PI;
}
