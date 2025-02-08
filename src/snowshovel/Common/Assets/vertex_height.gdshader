shader_type spatial;

uniform sampler2D snow_mask;
uniform vec2 mask_offset = vec2(0, 0);
uniform vec2 mask_scale = vec2(1, 1);

void vertex() {
	float snow_value = texture(snow_mask, (UV * mask_scale) + mask_offset).r;
	VERTEX.y = snow_value * VERTEX.y;
}

void fragment() {
	//float snow_value = texture(snow_mask,( UV * mask_scale) + mask_offset).r;
	ALBEDO = texture(snow_mask, UV * mask_scale + mask_offset).rgb; // mix(vec3(0,0,0), vec3(1,1,1), snow_value);
}
