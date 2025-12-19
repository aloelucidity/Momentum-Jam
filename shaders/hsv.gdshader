shader_type canvas_item;

uniform float hue_shift       : hint_range(-1.0, 1.0) = 0.0;
uniform float saturation_mult : hint_range(0.0, 2.0) = 1.0;
uniform float value_mult      : hint_range(0.0, 2.0) = 1.0;
uniform float brightness_add  : hint_range(-1.0, 1.0) = 0.0;
uniform float contrast_mult   : hint_range(0.0, 2.0) = 1.0;

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

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec3 col = tex_color.rgb;

	col = (col - 0.5) * contrast_mult + 0.5 + brightness_add;

	vec3 hsv = rgb2hsv(col);

	hsv.x = mod(hsv.x + hue_shift, 1.0);

	hsv.y *= saturation_mult;
	hsv.z *= value_mult;

	col = hsv2rgb(hsv);

	COLOR = vec4(col, tex_color.a);
}
