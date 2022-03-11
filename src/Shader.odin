package main

import fp "core:path/filepath"

import gl  "vendor:OpenGL"
import glm "core:math/linalg/glsl"

SHADER_LOC_POSITION    :: 0
SHADER_LOC_NORMAL      :: 1
SHADER_LOC_BARYCENTRIC :: 2

SHADER_U_MODEL      :: "u_model"
SHADER_U_VP         :: "u_view_projection"
SHADER_U_LINE_WIDTH :: "u_line_width"
SHADER_U_MESH_COLOR :: "u_mesh_color"

Shader :: struct {
	program: u32,
	uniforms: map[string]gl.Uniform_Info,
}
wireframe: Shader

shader_new :: proc() -> (self: Shader) {
	if program, ok := gl.load_shaders_file("shaders/wireframe.vert", "shaders/wireframe.frag"); ok == false {
		return
	}
	else {
		self.program = program
	}

	gl.UseProgram(self.program)
	self.uniforms = gl.get_uniforms_from_program(self.program)

	return
}

shader_update_uniforms :: proc(using self: Shader) {
	mesh_color: glm.vec3 = {0.7, 0.7, 0.7}
	gl.Uniform3fv(uniforms[SHADER_U_MESH_COLOR].location, 1, &mesh_color[0])

	line_width: f32 = 0.7
	gl.Uniform1f(uniforms[SHADER_U_LINE_WIDTH].location, line_width)

	model := camera_model(camera)
	gl.UniformMatrix4fv(uniforms[SHADER_U_MODEL].location, 1, false, &model[0, 0])

	view_projection := camera_view_projection(camera)
	gl.UniformMatrix4fv(uniforms[SHADER_U_VP].location, 1, false, &view_projection[0, 0])
}

shader_free :: proc(self: ^Shader) {
	gl.DeleteProgram(self.program)

	for _, uniform in self.uniforms {
		delete(uniform.name)
	}
	delete(self.uniforms)
}