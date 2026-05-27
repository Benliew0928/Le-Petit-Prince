shader_type spatial;
render_mode unshaded, cull_front;

// ── Inverted Hull Outline ──
// Renders back faces pushed outward along normals.
// Apply as next_pass on any toon material.

uniform vec4 outline_color : source_color = vec4(0.15, 0.1, 0.05, 1.0);
uniform float outline_thickness : hint_range(0.0, 0.2) = 0.04;

void vertex() {
	// Push vertices outward along their normals
	VERTEX += NORMAL * outline_thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
