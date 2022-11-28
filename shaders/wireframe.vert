#version 400
layout(location=0) in vec3 a_position;
layout(location=1) in vec3 a_normal;
layout(location=2) in vec3 a_barycentric;

out vec3 v_barycentric;

uniform mat4 u_model;
uniform mat4 u_view_projection;

void
main()
{
	gl_Position = u_view_projection * u_model * vec4(a_position, 1.0f);
	v_barycentric = a_barycentric;
}