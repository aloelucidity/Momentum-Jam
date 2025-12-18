shader_type canvas_item;


uniform vec2 global_pos;
uniform float influence: hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float offset: hint_range(0.0, 360.0, 1.0);

uniform float effect_scale: hint_range(0.0, 50.0, 0.001) = 4.0;
uniform float effect_divide: hint_range(0.1, 20.0, 0.1) = 1.0;

const float TWO_PI = 6.28318530718;

varying vec4 modulate;

void vertex() {
    modulate = COLOR;
}

vec3 hsv2rgb(vec3 _c) {
    vec4 _K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 _p = abs(fract(_c.xxx + _K.xyz) * 6.0 - _K.www);
    return _c.z * mix(_K.xxx, clamp(_p - _K.xxx, 0.0, 1.0), _c.y);
}

void fragment() {
	vec2 pos = vec2(0.5) - UV;
	float screen_offset = (global_pos.x + global_pos.y + SCREEN_UV.x + SCREEN_UV.y);
	COLOR.rgb += hsv2rgb(
		vec3(
			(
				(atan(pos.y, pos.x) + 
				radians(offset) + screen_offset * effect_scale
				) / TWO_PI / effect_divide
			) + 0.5, 
			(1.0 - influence) * length(pos * 4.0), 1.0 * influence)
		);
	COLOR *= modulate;
}