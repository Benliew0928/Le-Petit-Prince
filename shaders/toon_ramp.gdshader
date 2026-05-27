shader_type spatial;

// ── Toon Ramp Cel Shader ──
// 3-step lighting: shadow → mid-tone → highlight
// With specular highlight and rim lighting

uniform vec4 base_color : source_color = vec4(0.5, 0.7, 0.4, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.2, 0.3, 0.12, 1.0);
uniform float shadow_threshold : hint_range(-1.0, 1.0) = 0.0;
uniform float shadow_smoothness : hint_range(0.0, 0.5) = 0.05;
uniform float specular_size : hint_range(0.0, 1.0) = 0.1;
uniform float specular_smoothness : hint_range(0.0, 0.5) = 0.05;
uniform float rim_width : hint_range(0.0, 1.0) = 0.4;
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.8, 1.0);

void fragment() {
	ALBEDO = base_color.rgb;
}

void light() {
	float NdotL = dot(NORMAL, LIGHT);

	// ── 3-step toon ramp ──
	// Shadow to mid-tone transition
	float shadow_factor = smoothstep(
		shadow_threshold - shadow_smoothness,
		shadow_threshold + shadow_smoothness,
		NdotL
	);
	vec3 toon = mix(shadow_color.rgb, ALBEDO, shadow_factor);

	// Mid-tone to highlight transition (subtle brightening)
	float highlight = smoothstep(0.45, 0.55, NdotL);
	toon = mix(toon, ALBEDO * 1.15, highlight * 0.3);

	// ── Specular highlight (toon-stepped) ──
	vec3 half_vec = normalize(LIGHT + VIEW);
	float NdotH = dot(NORMAL, half_vec);
	float spec = smoothstep(
		1.0 - specular_size - specular_smoothness,
		1.0 - specular_size + specular_smoothness,
		NdotH
	);
	toon = mix(toon, vec3(1.0), spec * 0.35);

	// ── Rim lighting ──
	float rim = 1.0 - dot(NORMAL, VIEW);
	float rim_mask = smoothstep(1.0 - rim_width, 1.0, rim);
	// Only show rim on lit side of the surface
	float rim_light_mask = max(0.0, NdotL * 0.5 + 0.5);
	toon += rim_color.rgb * rim_mask * rim_light_mask * 0.3;

	DIFFUSE_LIGHT += toon * ATTENUATION * LIGHT_COLOR;
}
