shader_type canvas_item;


uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform bool is_additive = false;
uniform float blur_radius : hint_range(0.0, 100.0) = 5.0;
uniform int sample_count : hint_range(3, 9) = 5;

varying vec4 modulate;

void vertex() {
    modulate = COLOR;
}

void fragment() {
	vec4 blurred_color = vec4(0.0);
	float total_weight = 0.0;

	float center = float(sample_count - 1) * 0.5;
	float spread = blur_radius / center;

	for (float x = 0.0; x < float(sample_count); x++) {
		for (float y = 0.0; y < float(sample_count); y++) {
			// sample between pixels for hardware filtering
			vec2 offset = vec2(x - center, y - center) * spread;

			// gaussian weights
			float dist_sq = dot(offset, offset);
			float weight = exp(-dist_sq / (2.0 * blur_radius * blur_radius));
			
			vec4 sample = texture(TEXTURE, UV + offset * TEXTURE_PIXEL_SIZE);
			blurred_color.rgb += sample.rgb * sample.a * weight;
			blurred_color.a += sample.a * weight;
			total_weight += weight;
		}
	}
	
	if (blurred_color.a > 0.0) {
		blurred_color.rgb /= blurred_color.a;
	}
	
	blurred_color.a /= total_weight;
	
	if (is_additive) {
		vec4 screen_color = texture(screen_texture, SCREEN_UV);
		vec3 effect_color = blurred_color.rgb * modulate.rgb * modulate.a * blurred_color.a;
		
		COLOR.rgb = 1.0 - (1.0 - screen_color.rgb) * (1.0 - effect_color);
		COLOR.a = screen_color.a;
	}
	else {
		COLOR = blurred_color * modulate;
	}
}