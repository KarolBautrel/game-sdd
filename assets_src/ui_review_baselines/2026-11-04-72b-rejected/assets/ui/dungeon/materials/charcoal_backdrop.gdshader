shader_type canvas_item;
render_mode unshaded;

// Continuous shading plus static, physical-pixel grain. No enlarged raster.
uniform vec4 edge_color : source_color = vec4(0.028,0.026,0.023,1.0);
uniform vec4 center_color : source_color = vec4(0.075,0.068,0.059,1.0);

void fragment() {
	float light = 1.0-smoothstep(0.10,0.75,length(UV-vec2(0.45,0.30)));
	float grain = fract(52.9829189*fract(dot(floor(FRAGCOORD.xy),vec2(0.06711056,0.00583715))))-0.5;
	COLOR = vec4(mix(edge_color.rgb,center_color.rgb,light)+vec3(grain*0.00045),1.0);
}
