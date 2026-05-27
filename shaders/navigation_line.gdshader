shader_type spatial;
render_mode unshaded, depth_draw_opaque, cull_disabled, blend_mix;

uniform vec4 line_color : source_color = vec4(1.0, 0.88, 0.25, 1.0);
uniform vec4 glow_color : source_color = vec4(1.0, 0.55, 0.05, 1.0);
uniform float speed : hint_range(-10.0, 10.0) = 4.5;
uniform float dash_frequency : hint_range(0.1, 100.0) = 40.0;
uniform float pulse_speed : hint_range(0.1, 10.0) = 3.0;

void fragment() {
	// Scroll the coordinates along Y (V direction)
	float scroll = TIME * speed;
	float v_val = UV.y - scroll;
	
	// Create animated chevrons/pulse along the line
	float flow = sin(v_val * dash_frequency * 0.1) * 0.5 + 0.5;
	
	// Glowing color interpolation
	vec3 final_color = mix(glow_color.rgb, line_color.rgb, flow);
	
	// Soft edge-fading (U direction - UV.x runs from 0 to 1 across the ribbon)
	// A standard sine-wave profile makes the ribbon look round and glowing in the center
	float edge_fade = sin(UV.x * 3.14159);
	edge_fade = pow(edge_fade, 2.0); // Make it slightly sharper in the middle
	
	// Soft start-end fading using COLOR.r (which holds normalized path progress [0, 1])
	float path_progress = COLOR.r;
	float start_fade = smoothstep(0.0, 0.04, path_progress);
	float end_fade = smoothstep(1.0, 0.96, path_progress);
	float fade = start_fade * end_fade;
	
	// Dynamic glow pulsing over time
	float pulse = sin(TIME * pulse_speed) * 0.15 + 0.85;
	
	ALBEDO = final_color;
	ALPHA = edge_fade * fade * pulse * mix(0.4, 0.95, flow);
}
