package main

import fp "core:path/filepath"

import gl  "vendor:OpenGL"
import glm "core:math/linalg/glsl"

Shader :: struct {
	program: u32,
	uniforms: map[string]gl.Uniform_Info,
}
shader_new :: proc(vs_path, fs_path: string) -> (self: Shader) {
	if program, ok := gl.load_shaders_file(vs_path, fs_path); ok == false {
		// TODO: Error log
		return
	}
	else {
		self.program = program
	}

	gl.UseProgram(self.program)
	self.uniforms = gl.get_uniforms_from_program(self.program)

	return
}

shader_wireframe: Shader
shader_wireframe_update_uniforms :: proc(using self: Shader, camera: Camera) {
	gl.UseProgram(program)

	mesh_color: glm.vec3 = {0.7, 0.7, 0.7}
	gl.Uniform3fv(uniforms["u_mesh_color"].location, 1, &mesh_color[0])

	line_width: f32 = 0.7
	gl.Uniform1f(uniforms["u_line_width"].location, line_width)

	model := camera_model(camera)
	gl.UniformMatrix4fv(uniforms["u_model"].location, 1, false, &model[0, 0])

	view_projection := camera_view_projection(camera)
	gl.UniformMatrix4fv(uniforms["u_view_projection"].location, 1, false, &view_projection[0, 0])
}

shader_atlas: Shader
shader_atlas_update_uniforms :: proc(using self: Shader, color: [4]f32) {
	gl.UseProgram(program)
	gl.Uniform4f(uniforms["u_color"].location, color.r, color.g, color.b, color.a)
}

shader_free :: proc(self: ^Shader) {
	gl.DeleteProgram(self.program)

	for _, uniform in self.uniforms {
		delete(uniform.name)
	}
	delete(self.uniforms)
}