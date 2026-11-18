shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

// Plasma beam surface for a 3D cylinder. The beam is built from three nested
// cylinders sharing this shader (outer glow / mid / white core), so one
// material per layer with different beam_color + intensity is all it takes.
// UV: u wraps around the cylinder, v runs 0 at the muzzle -> 1 at the tip
// (the cylinder's +Y maps to forward after the mesh node's -90 deg X rotation).

uniform vec4 beam_color : source_color = vec4(0.6, 0.25, 1.0, 1.0);
uniform float time = 0.0;
uniform float intensity = 1.0;
uniform float uv_scale = 1.0; // set from the script: beam length / 8
uniform float scroll_speed = 4.0;
uniform float noise_amount = 0.35;

varying vec2 uv;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void vertex() {
	uv = UV;
}

void fragment() {
	// Energy crawling along the beam: noise scrolls from muzzle to tip.
	float n = fbm(vec2(uv.x * 3.0, uv.y * uv_scale - time * scroll_speed));

	// Fade in at the muzzle, taper off at the tip so the end isn't a hard cut.
	float axial = smoothstep(0.0, 0.06, uv.y) * (1.0 - smoothstep(0.85, 1.0, uv.y));

	float a = axial * (0.65 + n * noise_amount) * intensity;
	ALBEDO = beam_color.rgb * (0.8 + n * 0.6);
	ALPHA = clamp(a, 0.0, 1.0);
}
