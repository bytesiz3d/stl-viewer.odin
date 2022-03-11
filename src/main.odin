package main

import win32 "core:sys/win32"

import gl   "vendor:OpenGL"
import glm  "core:math/linalg/glsl"
import glfw "vendor:glfw"

uniforms: map[string]gl.Uniform_Info

_main :: proc() {
	stl: STL
	if path, ok := win32.select_file_to_open(filters={ "STL Files", "*.STL" }); ok == false {
		return
	}
	else {
		stl = stl_read(path)
		defer stl_free(&stl)

		mesh = mesh_from_stl(stl)
	}

	camera = camera_new()
	camera_fit_aabb(&camera, mesh.aabb)

	window := window_new()
	defer glfw.Terminate()

	program, program_ok := gl.load_shaders_source(vertex_source, fragment_source)
	if program_ok == false {
		log_error("load_shaders_source")
		return
	}
	gl.UseProgram(program)
	defer gl.DeleteProgram(program)

	uniforms = gl.get_uniforms_from_program(program)
	defer {
		for _, uniform in uniforms {
			delete(uniform.name)
		}
		delete(uniforms)
	}	
	update_uniforms()

	mesh_upload(&mesh)
	defer mesh_free(&mesh)

	for glfw.WindowShouldClose(window) == false {
		glfw.PollEvents()

		if camera_update(&camera, input) {
			update_uniforms()
		}
		input_reset(&input)

		render(window)
	}
}

render :: proc(window: glfw.WindowHandle) {
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	mesh_draw(mesh)

	glfw.SwapBuffers(window)
}

update_uniforms :: proc() {
	model := camera_model(camera)
	gl.UniformMatrix4fv(uniforms[SHADER_U_MODEL].location, 1, false, &model[0, 0])

	view_projection := camera_view_projection(camera)
	gl.UniformMatrix4fv(uniforms[SHADER_U_VP].location, 1, false, &view_projection[0, 0])
}