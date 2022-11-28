#version 400

in vec2 v_uv;
out vec4 o_color;

uniform sampler2D u_texture;
uniform vec4 u_color;

void
main()
{
	o_color = u_color;

	float sampled_alpha = texture(u_texture, v_uv).r;
	o_color.a *= sampled_alpha;
}