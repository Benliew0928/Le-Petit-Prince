shader_type sky;

// ══════════════════════════════════════════════════════════════════════════════
//  ✦  Le Petit Prince — Deep Space Skybox  ✦
// ══════════════════════════════════════════════════════════════════════════════
//  A fully procedural cosmic sky: star fields, nebula clouds, sun with corona.
//  "On ne voit bien qu'avec le cœur. L'essentiel est invisible pour les yeux."
// ══════════════════════════════════════════════════════════════════════════════

// ── Uniforms ─────────────────────────────────────────────────────────────────
uniform vec3  sun_direction = vec3(0.0, 0.4, -1.0);
uniform float sun_energy    : hint_range(0.0, 5.0) = 1.0;
uniform vec4  sun_color     : source_color = vec4(1.0, 0.95, 0.8, 1.0);
uniform float star_brightness : hint_range(0.0, 3.0) = 1.0;
uniform float nebula_intensity : hint_range(0.0, 2.0) = 0.4;
uniform float time_scale    : hint_range(0.0, 2.0) = 1.0;

// ── Hash / Noise Primitives ──────────────────────────────────────────────────
// Fast 2D → float hash (no textures, no arrays, no macros)
float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

// Value noise 2D (smooth interpolated)
float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	// Quintic Hermite for smoother interpolation
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));

	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Value noise 3D
float value_noise_3d(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

	float n000 = hash31(i);
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));

	float n00 = mix(n000, n100, u.x);
	float n01 = mix(n001, n101, u.x);
	float n10 = mix(n010, n110, u.x);
	float n11 = mix(n011, n111, u.x);

	float n0 = mix(n00, n10, u.y);
	float n1 = mix(n01, n11, u.y);

	return mix(n0, n1, u.z);
}

// ── Fractal Brownian Motion ──────────────────────────────────────────────────
float fbm(vec2 p, int octaves) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	float lacunarity = 2.0;
	float gain = 0.5;

	for (int i = 0; i < octaves; i++) {
		value += amplitude * value_noise(p * frequency);
		frequency *= lacunarity;
		amplitude *= gain;
	}
	return value;
}

float fbm_3d(vec3 p, int octaves) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;

	for (int i = 0; i < octaves; i++) {
		value += amplitude * value_noise_3d(p * frequency);
		frequency *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

// ── Spherical UV from direction ──────────────────────────────────────────────
vec2 dir_to_uv(vec3 dir) {
	float phi   = atan(dir.z, dir.x);          // [-PI, PI]
	float theta = asin(clamp(dir.y, -1.0, 1.0)); // [-PI/2, PI/2]
	return vec2(phi / TAU + 0.5, theta / PI + 0.5);
}

// ══════════════════════════════════════════════════════════════════════════════
//  1. DEEP SPACE BACKGROUND
// ══════════════════════════════════════════════════════════════════════════════
vec3 deep_space_background(vec3 dir) {
	// Directional Milky Way band — a broad band tilted across the sky
	// Band axis: roughly diagonal, not aligned with horizon
	vec3 band_axis = normalize(vec3(0.3, 0.1, 1.0));
	float band = abs(dot(dir, band_axis));
	// Wider, softer band
	float band_glow = exp(-band * band * 3.0);

	// Base colors
	vec3 deep_navy   = vec3(0.039, 0.039, 0.180);  // #0a0a2e
	vec3 dark_purple = vec3(0.102, 0.039, 0.243);   // #1a0a3e
	vec3 void_black  = vec3(0.008, 0.005, 0.020);

	// Gradient based on band proximity + some vertical variation
	float vertical = dir.y * 0.5 + 0.5;
	vec3 base = mix(void_black, deep_navy, vertical * 0.3 + band_glow * 0.15);
	base = mix(base, dark_purple, band_glow * 0.35);

	// Very subtle large-scale colour variation (breaks uniformity)
	vec2 uv = dir_to_uv(dir);
	float large_noise = value_noise(uv * 3.0 + 42.0);
	base += vec3(0.02, 0.008, 0.035) * large_noise;

	return base;
}

// ══════════════════════════════════════════════════════════════════════════════
//  2. STAR FIELDS — THREE LAYERS
// ══════════════════════════════════════════════════════════════════════════════

// Tiny dim stars (thousands) — point-like, slight brightness variation
float star_layer_tiny(vec3 dir, float t) {
	vec2 uv = dir_to_uv(dir);
	float scale = 300.0;
	vec2 grid = floor(uv * scale);
	vec2 local = fract(uv * scale) - 0.5;

	float rng = hash21(grid);
	// Only ~35% of cells have a star
	if (rng > 0.35) return 0.0;

	// Star position jitter within cell
	vec2 offset = hash22(grid) - 0.5;
	offset *= 0.7;
	float d = length(local - offset);

	// Point-like falloff
	float star = smoothstep(0.02, 0.0, d);

	// Brightness variation
	float brightness = 0.3 + 0.7 * hash21(grid + 100.0);

	// Twinkle
	float phase = hash21(grid + 200.0) * TAU;
	float twinkle = 0.7 + 0.3 * sin(t * (1.5 + rng * 2.0) + phase);

	return star * brightness * twinkle;
}

// Medium stars (hundreds) — slightly larger, soft glow halos
float star_layer_medium(vec3 dir, float t) {
	vec2 uv = dir_to_uv(dir);
	float scale = 120.0;
	vec2 grid = floor(uv * scale);
	vec2 local = fract(uv * scale) - 0.5;

	float rng = hash21(grid + 500.0);
	if (rng > 0.18) return 0.0;

	vec2 offset = hash22(grid + 500.0) - 0.5;
	offset *= 0.6;
	float d = length(local - offset);

	// Core + halo
	float core = smoothstep(0.03, 0.0, d);
	float halo = smoothstep(0.12, 0.0, d) * 0.25;
	float star = core + halo;

	float brightness = 0.5 + 0.5 * hash21(grid + 600.0);
	float phase = hash21(grid + 700.0) * TAU;
	float twinkle = 0.75 + 0.25 * sin(t * (1.0 + rng * 1.5) + phase);

	return star * brightness * twinkle * 1.4;
}

// Bright stars (few dozen) — large, with cross diffraction spikes
vec3 star_layer_bright(vec3 dir, float t) {
	vec2 uv = dir_to_uv(dir);
	float scale = 40.0;
	vec2 grid = floor(uv * scale);
	vec2 local = fract(uv * scale) - 0.5;

	float rng = hash21(grid + 1000.0);
	if (rng > 0.08) return vec3(0.0);

	vec2 offset = hash22(grid + 1000.0) - 0.5;
	offset *= 0.5;
	vec2 delta = local - offset;
	float d = length(delta);

	// Core
	float core = smoothstep(0.04, 0.0, d) * 3.0;
	// Outer glow
	float glow = smoothstep(0.18, 0.0, d) * 0.3;

	// Cross-shaped diffraction spikes
	float spike_h = exp(-abs(delta.y) * 60.0) * exp(-abs(delta.x) * 8.0);
	float spike_v = exp(-abs(delta.x) * 60.0) * exp(-abs(delta.y) * 8.0);
	float spikes = (spike_h + spike_v) * 0.6;

	float brightness = 0.7 + 0.3 * hash21(grid + 1100.0);
	float phase = hash21(grid + 1200.0) * TAU;
	float twinkle = 0.8 + 0.2 * sin(t * (0.8 + rng) + phase);

	float intensity = (core + glow + spikes) * brightness * twinkle;

	// Subtle colour tint per bright star (blue-white to warm yellow)
	float color_rng = hash21(grid + 1300.0);
	vec3 star_tint = mix(
		vec3(0.7, 0.8, 1.0),  // Cool blue-white
		vec3(1.0, 0.92, 0.7), // Warm golden
		color_rng
	);

	return intensity * star_tint;
}

// ══════════════════════════════════════════════════════════════════════════════
//  3. NEBULA CLOUDS (FBM, multi-layer, Hubble-like colours)
// ══════════════════════════════════════════════════════════════════════════════
vec3 nebula_clouds(vec3 dir, float t) {
	// We project onto spherical coords, then layer FBM at different scales
	vec2 uv = dir_to_uv(dir);

	// Slow drift for organic feel
	float drift = t * 0.008;

	// ── Layer 1: Deep purple/magenta wisps ──
	float n1 = fbm(uv * 4.0 + vec2(drift, -drift * 0.7), 6);
	n1 = smoothstep(0.38, 0.75, n1);
	vec3 c1 = vec3(0.35, 0.05, 0.45) * n1;  // Deep magenta-purple

	// ── Layer 2: Teal/cyan filaments ──
	float n2 = fbm(uv * 5.5 + vec2(-drift * 1.2, drift * 0.5) + 100.0, 5);
	n2 = smoothstep(0.42, 0.78, n2);
	vec3 c2 = vec3(0.05, 0.30, 0.40) * n2;  // Deep teal

	// ── Layer 3: Warm rose / emission nebula ──
	float n3 = fbm(uv * 3.0 + vec2(drift * 0.6, drift * 1.1) + 200.0, 6);
	n3 = smoothstep(0.40, 0.80, n3);
	vec3 c3 = vec3(0.50, 0.08, 0.25) * n3;  // Warm rose-magenta

	// ── Layer 4: Faint golden dust band ──
	float n4 = fbm(uv * 7.0 + vec2(drift * 0.3, -drift * 0.9) + 300.0, 4);
	n4 = smoothstep(0.50, 0.85, n4);
	vec3 c4 = vec3(0.35, 0.25, 0.08) * n4;  // Faint gold dust

	// Combine with 3D FBM mask to add depth variation
	float depth_mask = fbm_3d(dir * 2.5 + vec3(drift * 0.2), 3);
	depth_mask = smoothstep(0.25, 0.65, depth_mask);

	vec3 nebula = (c1 + c2 + c3 + c4) * (0.5 + 0.5 * depth_mask);

	// Concentrate nebula near the Milky Way band
	vec3 band_axis = normalize(vec3(0.3, 0.1, 1.0));
	float band_proximity = 1.0 - abs(dot(dir, band_axis));
	float band_mask = smoothstep(0.2, 0.8, band_proximity);
	nebula *= band_mask;

	return nebula;
}

// ══════════════════════════════════════════════════════════════════════════════
//  4. SUN DISC, CORONA & GOD RAYS
// ══════════════════════════════════════════════════════════════════════════════
vec3 sun_and_corona(vec3 dir, vec3 sun_dir, float energy, vec3 s_color, float t) {
	float cos_angle = dot(dir, sun_dir);
	float angle = acos(clamp(cos_angle, -1.0, 1.0));

	// ── Inner core: blindingly bright ──
	float core_radius = 0.018;
	float core = smoothstep(core_radius, core_radius * 0.3, angle);
	// Super-bright HDR value to trigger bloom
	vec3 core_color = vec3(1.0, 0.98, 1.0) * core * 15.0;

	// ── Middle corona: golden amber glow ──
	float mid_start = 0.05;
	float mid_end = 0.15;
	float mid = smoothstep(mid_end, mid_start, angle);
	mid = mid * mid;  // quadratic falloff
	vec3 mid_color = vec3(1.0, 0.85, 0.5) * mid * 3.0;

	// ── Outer corona: deep amber, very wide soft glow ──
	float outer_falloff = exp(-angle * 4.0) * 0.8;
	vec3 outer_color = vec3(1.0, 0.65, 0.3) * outer_falloff;

	// Extremely wide atmospheric scatter
	float scatter = exp(-angle * 1.5) * 0.15;
	vec3 scatter_color = vec3(1.0, 0.80, 0.55) * scatter;

	// ── God rays: angular noise-modulated radial streaks ──
	// Project direction onto plane perpendicular to sun
	vec3 to_sun = sun_dir;
	vec3 perp1 = normalize(cross(to_sun, vec3(0.0, 1.0, 0.0)));
	// Handle degenerate case when sun is straight up/down
	if (length(cross(to_sun, vec3(0.0, 1.0, 0.0))) < 0.001) {
		perp1 = normalize(cross(to_sun, vec3(1.0, 0.0, 0.0)));
	}
	vec3 perp2 = normalize(cross(to_sun, perp1));

	float ray_u = dot(dir, perp1);
	float ray_v = dot(dir, perp2);
	float ray_angle = atan(ray_v, ray_u);

	// Streaky noise pattern for god rays
	float ray_noise = 0.0;
	ray_noise += sin(ray_angle * 8.0 + t * 0.3) * 0.3;
	ray_noise += sin(ray_angle * 13.0 - t * 0.2) * 0.2;
	ray_noise += sin(ray_angle * 21.0 + t * 0.15) * 0.15;
	ray_noise += sin(ray_angle * 34.0 - t * 0.1) * 0.1;
	ray_noise = max(ray_noise, 0.0);

	// Rays fade with distance from sun
	float ray_mask = exp(-angle * 6.0);
	// Don't show rays in the core (it's already bright enough)
	ray_mask *= smoothstep(0.02, 0.08, angle);
	vec3 ray_color = vec3(1.0, 0.85, 0.6) * ray_noise * ray_mask * 1.5;

	// ── Combine ──
	vec3 sun_total = core_color + mid_color + outer_color + scatter_color + ray_color;
	sun_total *= s_color * energy;

	return sun_total;
}

// ══════════════════════════════════════════════════════════════════════════════
//  5. SUBTLE COSMIC DUST & DEPTH
// ══════════════════════════════════════════════════════════════════════════════
vec3 cosmic_dust(vec3 dir, float t) {
	// Very faint, large-scale wispy structures that add depth
	float n = fbm_3d(dir * 1.5 + vec3(t * 0.005, 0.0, -t * 0.003), 4);
	n = smoothstep(0.4, 0.7, n) * 0.04;
	return vec3(0.15, 0.10, 0.25) * n;
}

// ══════════════════════════════════════════════════════════════════════════════
//  MAIN SKY FUNCTION
// ══════════════════════════════════════════════════════════════════════════════
void sky() {
	vec3 dir = normalize(EYEDIR);
	float t = TIME * time_scale;
	vec3 sun_dir = normalize(sun_direction);

	// ── 1. Deep space background ──
	vec3 col = deep_space_background(dir);

	// ── 2. Cosmic dust (very subtle depth) ──
	col += cosmic_dust(dir, t);

	// ── 3. Nebula clouds (cached to avoid double FBM evaluation) ──
	vec3 nebula = nebula_clouds(dir, t) * nebula_intensity;
	col += nebula;

	// ── 4. Star fields ──
	float tiny   = star_layer_tiny(dir, t);
	float medium = star_layer_medium(dir, t);
	vec3  bright = star_layer_bright(dir, t);

	// Dim stars behind bright nebula regions + near sun bloom
	float nebula_mask = length(nebula);
	float sun_angle = acos(clamp(dot(dir, sun_dir), -1.0, 1.0));
	float sun_proximity_dim = smoothstep(0.0, 0.4, sun_angle); // fade stars near sun
	float star_dim = (1.0 - clamp(nebula_mask * 2.0, 0.0, 0.7)) * sun_proximity_dim;

	vec3 star_color_cool = vec3(0.8, 0.85, 1.0);  // Slight blue tint for tiny/medium
	col += tiny * star_color_cool * star_brightness * star_dim;
	col += medium * vec3(0.95, 0.92, 1.0) * star_brightness * star_dim;
	col += bright * star_brightness * star_dim;

	// ── 5. Sun disc, corona & god rays ──
	col += sun_and_corona(dir, sun_dir, sun_energy, sun_color.rgb, t);

	// ── Final output ──
	COLOR = col;
}

