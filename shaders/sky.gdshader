shader_type canvas_item;

uniform float cloudscale = 1.1;
uniform float speed = 0.01;
uniform float clouddark = 0.5;
uniform float cloudlight = 0.3;
uniform float cloudcover = 0.2;
uniform float cloudalpha = 8.0;
uniform float skytint = 0.5;
uniform vec3 skycolour1 = vec3(0.2, 0.4, 0.6);
uniform vec3 skycolour2 = vec3(0.4, 0.7, 1.0);
uniform mat2 m = mat2(vec2(1.6,1.2),vec2(-1.2,1.6));

uniform float waterscale = 1.1;
uniform vec3 watercolour1 = vec3(0.2, 0.4, 0.6);
uniform vec3 watercolour2 = vec3(0.4, 0.7, 1.0);

uniform float horizon = 0.6;
uniform float perspective = 0.2;

uniform sampler2D standard_noise_tex;


vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(in vec2 p) {
    const float K1 = 0.366025404;
    const float K2 = 0.211324865;
    vec2 i = floor(p + (p.x + p.y) * K1); 
    vec2 a = p - i + (i.x + i.y) * K2;
    vec2 o = step(a.yx, a.xy); 
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0 * K2;
    vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    vec3 h4 = h * h * h * h;
    vec3 n = h4 * vec3(dot(a, hash(i)), dot(b, hash(i + o)), dot(c, hash(i + 1.0)));
    return dot(n, vec3(70.0));       
}

float get_ridged_shape(vec2 uv, float time) {
    float r = 0.0;
    float weight = 0.8;
    for (int i=0; i<8; i++){
        r += abs(weight * noise(uv));
        uv = m * uv + time;
        weight *= 0.7;
    }
    return r;
}

float get_color_detail(vec2 uv, float time_c, float time_c1) {
    float c = 0.0;
    float weight = 0.4;
    vec2 uv_c = uv;
    for (int i=0; i<7; i++){
        c += weight * noise(uv_c);
        uv_c = m * uv_c + time_c;
        weight *= 0.6;
    }
    
    float c1 = 0.0;
    weight = 0.4;
    vec2 uv_c1 = uv;
    for (int i=0; i<7; i++){
        c1 += abs(weight * noise(uv_c1));
        uv_c1 = m * uv_c1 + time_c1;
        weight *= 0.6;
    }
    
    return c + c1;
}


void fragment() {
    vec2 res = 1.0 / TEXTURE_PIXEL_SIZE;
    vec2 p = UV.xy / res.xy;
    
    float vertical = p.y - horizon;
    bool is_water = vertical > 0.0; 
    
    vec2 uv_p = vec2((p.x - 0.5) / vertical, perspective / vertical);
    vec2 uv_screen = p * vec2(res.x / res.y, 1.0);

    float time_base = TIME * speed;
    
	float scale = is_water ? waterscale : cloudscale;
    float r = get_ridged_shape(uv_p * scale + (1.0 - time_base), time_base);
    float f = texture(standard_noise_tex, uv_screen * scale).r;
	f *= r + f;

    vec3 skycolour = mix(is_water ? watercolour2 : skycolour2, is_water ? watercolour1 : skycolour1, p.y);
    vec3 cloudcolour = vec3(1.1, 1.1, 0.9) * clamp((clouddark + cloudlight), 0.0, 1.0);

    float alpha = cloudcover + cloudalpha * f * r;
    vec3 result = mix(skycolour, clamp(skytint * skycolour + cloudcolour, 0.0, 1.0), clamp(alpha, 0.0, 1.0));

    COLOR.rgb = result; 
}