shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

// ══════════════════════════════════════════════════════════════════════════════
//  ✦  Le Petit Prince — Volumetric Sun Billboard  ✦
// ══════════════════════════════════════════════════════════════════════════════
//  Apply to a SphereMesh (default radius 0.5). The billboard transform keeps
//  the mesh camera-facing while the fragment shader paints a realistic star
//  with animated plasma granulation, limb darkening, and a pulsing corona.
//
//  Make the mesh ~2× larger than the desired visible disc so the corona has
//  room to breathe. The disc itself occupies the inner ~52% of the radius.
// ══════════════════════════════════════════════════════════════════════════════

// ── Uniforms ─────────────────────────────────────────────────────────────────
uniform vec4  core_color       : source_color = vec4(1.0, 0.98, 0.9, 1.0);
uniform vec4  corona_color     : source_color = vec4(1.0, 0.6, 0.2, 1.0);
uniform float intensity        : hint_range(0.0, 30.0) = 12.0;
uniform float corona_size      : hint_range(0.0, 3.0)  = 1.5;
uniform float turbulence_speed : hint_range(0.0, 2.0)  = 0.3;

// ── Varying ──────────────────────────────────────────────────────────────────
// Model-space XY passed to fragment for screen-aligned radial distance.
varying vec2 disc_uv;

// ══════════════════════════════════════════════════════════════════════════════
//  Procedural Noise — no textures, no macros, no arrays
// ══════════════════════════════════════════════════════════════════════════════

// Fast 2D → 1D hash (same family as space_sky.gdshader)
float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// 2D → 2D hash for Voronoi cell jitter
vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

// Value noise with quintic Hermite interpolation
float value_noise(vec2 p) {
	vec2 ip = floor(p);
	vec2 fp = fract(p);
	vec2 u  = fp * fp * fp * (fp * (fp * 6.0 - 15.0) + 10.0);

	float a = hash21(ip);
	float b = hash21(ip + vec2(1.0, 0.0));
	float c = hash21(ip + vec2(0.0, 1.0));
	float d = hash21(ip + vec2(1.0, 1.0));

	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Fractal Brownian Motion — 5 octaves with domain rotation
float fbm5(vec2 p) {
	mat2 rot = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80));
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * value_noise(p);
		p  = rot * p * 2.0 + vec2(17.0, 31.0);
		a *= 0.5;
	}
	return v;
}

// Lighter FBM — 3 octaves for secondary details
float fbm3(vec2 p) {
	mat2 rot = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80));
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * value_noise(p);
		p  = rot * p * 2.0 + vec2(7.0, 13.0);
		a *= 0.5;
	}
	return v;
}

// ── Animated Voronoi — solar granulation (bubbling plasma cells) ─────────────
// Returns (cell_distance, cell_id_hash) for colour variation per cell.
vec2 solar_granulation(vec2 p, float t) {
	vec2 ip = floor(p);
	vec2 fp = fract(p);

	float min_dist  = 8.0;
	float cell_hash = 0.0;

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 h = hash22(ip + neighbor);
			// Animate cell centres — slow bubbling drift
			vec2 point = 0.5 + 0.35 * sin(t * 1.4 + h * TAU);
			vec2 diff  = neighbor + point - fp;
			float d    = dot(diff, diff);  // squared distance
			if (d < min_dist) {
				min_dist  = d;
				cell_hash = hash21(ip + neighbor + 99.0);
			}
		}
	}
	return vec2(sqrt(min_dist), cell_hash);
}

// ══════════════════════════════════════════════════════════════════════════════
//  Vertex — camera-facing billboard
// ══════════════════════════════════════════════════════════════════════════════
void vertex() {
	// Capture model-space position before billboard overwrite.
	// For a default SphereMesh (radius 0.5), xy ranges ±0.5.
	disc_uv = VERTEX.xy;

	// Billboard: replace model rotation with inverse view rotation,
	// keeping the model's world-space translation.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0],
		INV_VIEW_MATRIX[1],
		INV_VIEW_MATRIX[2],
		MODEL_MATRIX[3]
	);
}

// ══════════════════════════════════════════════════════════════════════════════
//  Fragment — volumetric star surface + corona
// ══════════════════════════════════════════════════════════════════════════════
void fragment() {
	// ── Radial coordinate ────────────────────────────────────────────────
	// Normalise so r = 0 at centre, r = 1 at equator edge of the sphere.
	// Default SphereMesh radius = 0.5  →  ×2.0 maps to [0, 1].
	float r     = length(disc_uv) * 2.0;
	float theta = atan(disc_uv.y, disc_uv.x);
	float t     = TIME * turbulence_speed;

	// ── Animated surface noise ───────────────────────────────────────────
	// Large-scale convection / turbulence
	float turb = fbm5(disc_uv * 6.0 + vec2(t * 0.7, t * 0.3));

	// Small-scale solar granulation (animated Voronoi cells)
	vec2 gran_info = solar_granulation(disc_uv * 12.0, t);
	float gran_dist = gran_info.x;   // distance to nearest cell centre
	float gran_id   = gran_info.y;   // per-cell hash for colour variation

	// Slight organic distortion of the disc edge
	float edge_noise = (turb - 0.5) * 0.06 + (gran_dist - 0.5) * 0.02;
	float r_noisy    = r + edge_noise;

	// ── Disc mask ────────────────────────────────────────────────────────
	float disc_edge = 0.52;
	float disc_soft = 0.08;
	float disc_mask = smoothstep(disc_edge + disc_soft,
	                             disc_edge - disc_soft, r_noisy);

	// ── Colour gradient  (centre → limb) ─────────────────────────────────
	vec3 c_white = vec3(1.0, 1.0, 1.0);
	vec3 c_gold  = vec3(1.0, 0.85, 0.4);
	vec3 c_amber = vec3(1.0, 0.50, 0.1);

	vec3 base_col = mix(c_white, c_gold,  smoothstep(0.0,  0.35, r));
	base_col      = mix(base_col, c_amber, smoothstep(0.25, 0.55, r));
	base_col     *= core_color.rgb;

	// Per-cell tint: some granules slightly orange, others near-white
	vec3 cell_tint = mix(vec3(1.0), vec3(1.0, 0.80, 0.50),
	                     gran_id * 0.35);
	base_col *= cell_tint;

	// ── Granulation brightness pattern ───────────────────────────────────
	// Cell edges (intergranular lanes) are dimmer; cell centres are bright
	float gran_brightness = smoothstep(0.0, 0.45, gran_dist);
	gran_brightness = 0.82 + 0.18 * gran_brightness;

	// ── Core brightness (HDR, centre > 15.0) ─────────────────────────────
	float core_glow = exp(-r * r * 6.0) * intensity * 1.3;

	// ── Limb darkening ───────────────────────────────────────────────────
	// Astrophysical: I(µ) ≈ 0.3 + 0.7 µ^0.55  where µ = cos(view angle)
	float mu   = sqrt(max(1.0 - pow(r_noisy / disc_edge, 2.0), 0.0));
	float limb = 0.30 + 0.70 * pow(max(mu, 0.0), 0.55);

	// ── Surface modulation ───────────────────────────────────────────────
	float surf_mod = 0.88 + 0.12 * turb;

	// ── Compose sun disc ─────────────────────────────────────────────────
	vec3 sun = base_col * core_glow * limb * surf_mod * gran_brightness
	         * disc_mask;

	// ── Chromospheric rim (bright edge ring) ─────────────────────────────
	// Gaussian peak right at the disc edge — mimics the chromosphere
	float rim_dist = (r_noisy - disc_edge) / 0.035;
	float rim      = exp(-rim_dist * rim_dist) * intensity * 0.20;
	vec3  rim_col  = mix(c_gold, corona_color.rgb, 0.6) * rim;
	sun += rim_col * disc_mask;

	// ══════════════════════════════════════════════════════════════════════
	//  Corona
	// ══════════════════════════════════════════════════════════════════════
	float cs = max(corona_size, 0.001);
	float cd = max(r_noisy - disc_edge + 0.05, 0.0);  // corona distance

	// Subtle temporal pulse
	float pulse = 1.0 + 0.06 * sin(TIME * 1.3)
	                   + 0.04 * sin(TIME * 2.9 + 0.7);

	// ── Inner corona: bright, compact golden glow ────────────────────────
	float inner_corona = exp(-cd * 6.0 / cs) * intensity * 0.35 * pulse;
	vec3  inner_col    = mix(c_gold, corona_color.rgb, 0.40);

	// ── Outer corona: softer, wider amber-orange glow ────────────────────
	float outer_corona = exp(-cd * 2.5 / cs) * intensity * 0.08 * pulse;
	vec3  outer_col    = mix(corona_color.rgb, vec3(1.0, 0.35, 0.05), 0.50);

	// ── Faint radial streamers ───────────────────────────────────────────
	float ray = fbm3(vec2(theta * 4.0 / TAU + t * 0.2,
	                      r * 4.0 - t * 0.9));
	ray = pow(ray, 2.5) * exp(-cd * 3.5 / cs) * intensity * 0.10;

	// Corona is most visible outside the disc body
	float corona_vis = 1.0 - disc_mask * 0.85;
	vec3  corona = (inner_col * inner_corona
	              + outer_col * outer_corona
	              + corona_color.rgb * ray) * corona_vis;

	// ══════════════════════════════════════════════════════════════════════
	//  Final composite
	// ══════════════════════════════════════════════════════════════════════
	vec3 color = sun + corona;

	// Alpha for additive blend (multiplier on the added colour)
	float alpha = disc_mask;
	alpha = max(alpha, exp(-cd * 2.0 / cs) * 0.9);   // corona alpha
	alpha *= smoothstep(1.8, 0.6, r);                 // outer edge fade

	// Reduce back-face contribution — a sphere has front + back faces
	// overlapping in screen space; without this the centre doubles up.
	float face = float(FRONT_FACING) * 0.85 + 0.15;
	color *= face;
	alpha *= face;

	ALBEDO = color;
	ALPHA  = alpha;
}
