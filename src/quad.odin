package main

import "core:fmt"
import "core:c"
import "core:runtime"

import gl   "vendor:OpenGL"
import glm  "core:math/linalg/glsl"
import glfw "vendor:glfw"

window_width, window_height, count_triangles: i32
main :: proc() {
	window := create_window()

	vao, vbo, ebo, program := load_shaders_and_data(window)
	defer {
		gl.DeleteBuffers(1, &ebo)
		gl.DeleteBuffers(1, &vbo)
		gl.DeleteVertexArrays(1, &vao)
		gl.DeleteProgram(program)
		glfw.Terminate()
	}

	gl.ClearColor(0.5, 0.7, 1.0, 1.0)
	gl.Viewport(0, 0, window_width, window_height)

	for glfw.WindowShouldClose(window) == false {
		glfw.PollEvents()
		render(window)
	}
}

render :: proc(window: glfw.WindowHandle) {
	gl.Clear(gl.COLOR_BUFFER_BIT)
	gl.DrawElements(gl.TRIANGLES, count_triangles, gl.UNSIGNED_SHORT, nil)
	glfw.SwapBuffers(window)
}

create_window :: proc() -> glfw.WindowHandle {
	if glfw.Init() == 0 {
		log_error("glfw.Init")
		return nil
	}

	// OpenGL 4.0
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 0)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.RESIZABLE, 1)

	window_width, window_height = 1280, 720
	window := glfw.CreateWindow(window_width, window_height, "Odin GLFW", nil, nil)
	if window == nil {
		log_error("glfw.CreateWindow")
		return window
	}
	glfw.MakeContextCurrent(window)

	glfw.SetWindowSizeCallback(window, proc "cdecl" (window: glfw.WindowHandle, width, height: i32) {
		// Using the default context in a "cdecl" procedure
		context = runtime.default_context()
		window_width = width
		window_height = height
		fmt.printf("resized ({}x{})\n", window_width, window_height)

		gl.Viewport(0, 0, window_width, window_height)
		render(window)
	})

	glfw.SetKeyCallback(window, proc "cdecl" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
		context = runtime.default_context()
		if action == glfw.PRESS {
			fmt.printf("pressed ({})\n", key)
		}
	})

	return window
}

load_shaders_and_data :: proc(window: glfw.WindowHandle) -> (vao, vbo, ebo, program: u32) {
	// Load OpenGL procedures
	gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	program_ok := false
	program, program_ok = gl.load_shaders_source(vertex_source, fragment_source)
	if program_ok == false {
		log_error("load_shaders_source")
		return
	}
	gl.UseProgram(program)

	Vertex :: struct {
		pos: glm.vec3,
		col: glm.vec4,
	}
	
	vertices := []Vertex{
		{{-0.5, +0.5, 0}, {1.0, 0.0, 0.0, 1.0}},
		{{-0.5, -0.5, 0}, {1.0, 1.0, 0.0, 1.0}},
		{{+0.5, -0.5, 0}, {0.0, 1.0, 0.0, 1.0}},
		{{+0.5, +0.5, 0}, {0.0, 0.0, 1.0, 1.0}},
	}
	
	indices := []u16{
		0, 1, 2,
		2, 3, 0,
	}
	count_triangles = i32(len(indices))

	// Upload data
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)
	
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(vertices)*size_of(vertices[0]), raw_data(vertices), gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, pos))
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 4, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, col))
	gl.EnableVertexAttribArray(1)
	
	gl.GenBuffers(1, &ebo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices)*size_of(indices[0]), raw_data(indices), gl.STATIC_DRAW)
	return
}

log_error :: proc(prefix: string) {
	desc, err := glfw.GetError()
	fmt.eprintln(prefix, "failed, err:", err, desc)
}

vertex_source := `#version 400
layout(location=0) in vec3 a_position;
layout(location=1) in vec4 a_color;

out vec4 v_color;

void main() {	
	gl_Position = vec4(a_position, 1.0f);
	v_color = a_color;
}
`
fragment_source := `#version 400
in vec4 v_color;
out vec4 o_color;

void main() {
	o_color = v_color;
}
`