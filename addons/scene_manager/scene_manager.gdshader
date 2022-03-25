shader_type canvas_item;

uniform sampler2D custom_texture;
uniform float cutoff: hint_range(0, 1) = 1;
uniform float smoothness: hint_range(0, 1) = 0.1;
uniform vec3 color = vec3(0, 0, 0);
uniform bool inverted = false;
uniform bool linear_fade = true;

void fragment() {
	if (!linear_fade) {
		float value = texture(custom_texture, UV).r;
		if (inverted) {
			value = 1.0 - value;
		}
		float alpha = smoothstep(cutoff, cutoff + smoothness, value * (1.0 - smoothness) + smoothness);
		COLOR = vec4(color.rgb, alpha);
	} else {
		COLOR = vec4(color.rgb, (1.0 - cutoff));
	}
}