#version 400
in vec3 v_barycentric;
out vec4 o_color;

uniform float u_line_width;
uniform vec3 u_mesh_color;

float edge_factor(vec3 vbc) {
	vec3 vbc_dash = dFdx(vbc) + dFdy(vbc);

	vec3 components = step(vbc_dash * u_line_width, vbc);

	// Return 0 if any component isn't past the edge
	return min(min(components.x, components.y), components.z);
}

void main() {
	vec3 black_if_edge = vec3(edge_factor(v_barycentric));
	vec3 color = min(black_if_edge, u_mesh_color);

	o_color = vec4(color, 1.0f);
}