shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

uniform vec4 color_a:source_color;
uniform vec4 color_b:source_color;

uniform int num_colors = 2;

void fragment() {
	vec4 color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);

	float min_color_diff = 10000.0;
	vec4 closest_color = vec4(0.0,0.0,0.0,1.0);
	
	vec4 colors[2] = { color_a, color_b };
	
	if (color.r > 0.5) {
		COLOR = color_a;
	}
	else {
		COLOR = color_b;
	}
	
	//for(int i = 0; i < num_colors; ++i) {
		//float color_dist = distance(colors[i], color);
		//if(color_dist < min_color_diff) {
			//min_color_diff = color_dist;
			//closest_color = colors[i];
		//}
	//}
	//
	//COLOR.rgb = closest_color.rgb;
}