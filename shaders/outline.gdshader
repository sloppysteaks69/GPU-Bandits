// Full-screen ink outline from depth discontinuities (the cel-shader layer).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_never, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
uniform float thickness = 1.6;
uniform vec4 line_color : source_color = vec4(0.02, 0.02, 0.06, 1.0);

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 px = thickness / VIEWPORT_SIZE;
	float c = texture(depth_tex, SCREEN_UV).r;
	float l = texture(depth_tex, SCREEN_UV - vec2(px.x, 0.0)).r;
	float r = texture(depth_tex, SCREEN_UV + vec2(px.x, 0.0)).r;
	float u = texture(depth_tex, SCREEN_UV - vec2(0.0, px.y)).r;
	float d = texture(depth_tex, SCREEN_UV + vec2(0.0, px.y)).r;
	// Raw depth is linear in screen space on a plane, so its Laplacian is ~0 on
	// flat surfaces (no false lines on the floor) and large at silhouettes.
	float lap = abs(l + r - 2.0 * c) + abs(u + d - 2.0 * c);
	float m = max(max(max(l, r), max(u, d)), c);
	float e = smoothstep(0.02, 0.06, lap / max(m, 1e-7));
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;
	ALBEDO = mix(col, line_color.rgb, e * line_color.a);
}
