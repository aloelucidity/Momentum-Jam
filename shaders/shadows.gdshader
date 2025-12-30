shader_type canvas_item;


uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float light_angle : hint_range(0, 360) = 256.0;
uniform float shadow_length = 0.2;
uniform float shadow_softness = 0.5;
uniform float shadow_density = 1.0;
uniform int steps = 12;

uniform float ao_range = 8;
uniform float ao_strength = 0.5;

uniform float mask_bleed_threshold = 0.15;

// ambient
uniform vec4 ambient_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float ambient_brightness : hint_range(-1.0, 1.0) = 0.0;
uniform float ambient_contrast : hint_range(0.0, 3.0) = 1.0;
uniform float ambient_saturation : hint_range(0.0, 3.0) = 1.0;
uniform float ambient_hue : hint_range(-1.0, 1.0) = 0.0;

// shadow
uniform vec4 shadow_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float shadow_brightness : hint_range(-1.0, 1.0) = 0.0;
uniform float shadow_contrast : hint_range(0.0, 3.0) = 1.0;
uniform float shadow_saturation : hint_range(0.0, 3.0) = 1.0;
uniform float shadow_hue : hint_range(-1.0, 1.0) = 0.0;


// random noise
float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}


vec3 rgb2hsv(vec3 c) {
	float cMax = max(max(c.r, c.g), c.b);
	float cMin = min(min(c.r, c.g), c.b);
	float delta = cMax - cMin;

	float h = 0.0;
	if(delta < 0.00001) {
		h = 0.0;
	} else if(cMax == c.r) {
		h = mod(((c.g - c.b) / delta), 6.0);
	} else if(cMax == c.g) {
		h = ((c.b - c.r) / delta) + 2.0;
	} else {
		h = ((c.r - c.g) / delta) + 4.0;
	}
	h /= 6.0;
	if(h < 0.0) h += 1.0;

	float s = (cMax <= 0.0) ? 0.0 : (delta / cMax);
	float v = cMax;
	return vec3(h, s, v);
}

vec3 hsv2rgb(vec3 c) {
	float h = c.x * 6.0;
	float s = c.y;
	float v = c.z;

	float c_val = v * s;
	float x = c_val * (1.0 - abs(mod(h, 2.0) - 1.0));
	vec3 rgb;

	if (0.0 <= h && h < 1.0) {
		rgb = vec3(c_val, x, 0.0);
	} else if (1.0 <= h && h < 2.0) {
		rgb = vec3(x, c_val, 0.0);
	} else if (2.0 <= h && h < 3.0) {
		rgb = vec3(0.0, c_val, x);
	} else if (3.0 <= h && h < 4.0) {
		rgb = vec3(0.0, x, c_val);
	} else if (4.0 <= h && h < 5.0) {
		rgb = vec3(x, 0.0, c_val);
	} else if (5.0 <= h && h < 6.0) {
		rgb = vec3(c_val, 0.0, x);
	} else {
		rgb = vec3(0.0, 0.0, 0.0);
	}
	float m = v - c_val;
	return rgb + vec3(m);
}


vec3 adjust_color(vec3 rgb, float brightness, float contrast, float saturation, float hue, vec4 tint) {
	rgb = (rgb - 0.5) * contrast + 0.5 + brightness;

	vec3 hsv = rgb2hsv(rgb);

	hsv.x = mod(hsv.x + hue, 1.0);
	hsv.y *= saturation;

	rgb = hsv2rgb(hsv) * tint.rgb;
	return rgb;
}


void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 current_sdf_pos = screen_uv_to_sdf(uv);
	float current_dist = texture_sdf(current_sdf_pos);
	float final_alpha = 0.0;

	// if there's no occluders on screen, just forget it
	if (current_dist > 0.000001) {
		float ao = clamp(1.0 - (current_dist / ao_range), 0.0, 1.0);
		ao = pow(ao, 2.0) * ao_strength;

		float ang_rad = radians(light_angle);
		vec2 dir = vec2(cos(ang_rad), sin(ang_rad));
		float noise = hash(uv + TIME * 0.05);
		float shadow_accum = 0.0;

		for (int i = 0; i < steps; i++) {
			float progress = (float(i) + noise) / float(steps);
			progress *= shadow_length;

			vec2 sample_pos = screen_uv_to_sdf(uv + dir * progress);
			float d = texture_sdf(sample_pos);

			if (d < 0.01) {
				float falloff = 1.0 - progress / shadow_length;
				shadow_accum += falloff / float(steps);
			}
		}

		shadow_accum = pow(shadow_accum * shadow_softness, 0.8);
		shadow_accum = clamp(shadow_accum * shadow_density, 0.0, 1.0);

		final_alpha = max(shadow_accum, ao);
	}

	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	vec3 ambient_rgb = adjust_color(screen_color.rgb,
		ambient_brightness, ambient_contrast, ambient_saturation,
		ambient_hue, ambient_tint
	);
	vec3 shadow_rgb = adjust_color(screen_color.rgb,
		shadow_brightness, shadow_contrast, shadow_saturation,
		shadow_hue, shadow_tint
	);

	float alpha_mask = COLOR.a;
	float mask_brightness = (COLOR.r + COLOR.g + COLOR.b) / 3.0;
	float is_dark = step(mask_brightness, mask_bleed_threshold);
	alpha_mask = min(alpha_mask, 1.0 - is_dark);
	
	final_alpha *= 1.0 - alpha_mask;

	COLOR.rgb = mix(ambient_rgb, shadow_rgb, final_alpha);
	COLOR.a = 1.0;
}