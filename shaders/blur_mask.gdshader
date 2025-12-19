shader_type canvas_item;


uniform sampler2D screen_texture : hint_screen_texture, repeat_disable;
uniform float blur_amount = 1.0f;

void fragment() {
	if (COLOR.a > 0.0f) {
		COLOR = textureLod(screen_texture, UV, blur_amount);
	}
}
