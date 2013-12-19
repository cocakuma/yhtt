return [[
extern vec4 inset_color;
extern vec4 outset_color;
extern float inset_radius_sq;
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
{
	vec2 pos = vec2( texture_coords.x - 0.5, texture_coords.y - 0.5 ) * 2;
	float length_sq = pos.x * pos.x + pos.y * pos.y;
	if( length_sq <= inset_radius_sq )
	{
		return vec4(inset_color.rgb, 1.0);
	}
	else if( length_sq <= 1.0 )
	{
		return vec4(outset_color.rgb,1.0);
	}
	else
	{
		discard;
	}
}
]]