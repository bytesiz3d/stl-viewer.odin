package main

import win32 "core:sys/win32"

import gl   "vendor:OpenGL"
import glm  "core:math/linalg/glsl"
import glfw "vendor:glfw"

_main :: proc() {
	if path, ok := win32.select_file_to_open(
		filters={ "STL Files", "*.STL" },
		flags=win32.OPEN_FLAGS | win32.OFN_NOCHANGEDIR,
	); ok == false {
		return
	}
	else {
		stl := stl_read(path)
		defer stl_free(&stl)

		mesh = mesh_from_stl(stl)
	}

	camera = camera_new()

	window := window_new()
	defer glfw.Terminate()

	wireframe = shader_new()
	defer shader_free(&wireframe)

	camera_fit_aabb(&camera, mesh.aabb)
	shader_update_uniforms(wireframe)

	mesh_upload(&mesh)
	defer mesh_free(&mesh)

	for glfw.WindowShouldClose(window) == false {
		glfw.PollEvents()

		if camera_update(&camera, input) {
			shader_update_uniforms(wireframe)
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