shader_type canvas_item;
render_mode unshaded;

uniform bool is_smooth = true;
uniform float width : hint_range(0.0, 32.0) = 1.0;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform int pixel_size : hint_range(1, 10) = 4;
uniform int step_count : hint_range(1, 8) = 4;

varying vec4 modulate;


void vertex() {
	modulate = COLOR;
}


void fragment() {
	vec4 pixel_color = texture(TEXTURE, UV);
	vec4 final_color;

	if (pixel_color.a > 0.0) {
		final_color = modulate * pixel_color;
	}
	else {
		vec2 inv_texture_size = 1.0 / vec2(textureSize(TEXTURE, 0));
		float max_radius = max(1.0, width);

		vec2 uv_radius_step = inv_texture_size * (max_radius / float(pixel_size));

		vec4 outline_result = outline_color;
		outline_result.a = 0.0;

		// 8 Direction vectors (Normalized)
		vec2 directions[8] = {
		    vec2(1.0, 0.0), vec2(-1.0, 0.0),
		    vec2(0.0, 1.0), vec2(0.0, -1.0),
		    vec2(0.707, 0.707), vec2(-0.707, -0.707),
		    vec2(0.707, -0.707), vec2(-0.707, 0.707)
		};

		float accumulated_alpha = 0.0;
		float total_weight = 0.0;

		for (int i = 0; i < 8; i++) {
			for (int j = 1; j <= step_count; j++) {
				float current_dist_norm = float(j) / float(step_count);
				vec2 current_offset = directions[i] * uv_radius_step * current_dist_norm;
				vec2 sample_uv = UV + current_offset;

				if (texture(TEXTURE, sample_uv).a > 0.0) {
					float weight = (1.0 - current_dist_norm);
					accumulated_alpha += weight * max_radius;
					break;
			    }
			}
		}

		if (accumulated_alpha > 0.0) {
			if (is_smooth) {
				float intensity = clamp(accumulated_alpha / 8.0, 0.0, 1.0);
				outline_result.a = outline_color.a * intensity;
			} else {
				outline_result.a = outline_color.a;
			}
		}

		if (outline_result.a > 0.0) {
			final_color = modulate * outline_result;
		} else {
			final_color = vec4(0.0);
		}
	}
	COLOR = final_color;
}