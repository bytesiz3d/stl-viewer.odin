package main

SHADER_LOC_POSITION :: 0
SHADER_LOC_NORMAL   :: 1

SHADER_U_MODEL :: "u_model"
SHADER_U_VP    :: "u_view_projection"

vertex_source := `#version 400
layout(location=0) in vec3 a_position;
layout(location=1) in vec3 a_normal;

out vec4 v_color;
uniform mat4 u_model;
uniform mat4 u_view_projection;

void main() {	
	gl_Position = u_view_projection * u_model * vec4(a_position, 1.0f);
	v_color = vec4(a_normal, 1.0f);
}
`

fragment_source := `#version 400
in vec4 v_color;
out vec4 o_color;

void main() {
	o_color = v_color;
}
`