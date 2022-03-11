package main

import "core:runtime"

import gl   "vendor:OpenGL"
import glm  "core:math/linalg/glsl"
import glfw "vendor:glfw"

Input :: struct {
	// TODO(bytesiz3d) unify input handling
	mouse_pos:     [2]f64,
	mouse_pressed: [8]bool,

	mouse_delta:   [2]f64,
	scroll_delta:  f64,
	keys_pressed:  [512]bool,
}
input: Input

input_reset :: proc(input: ^Input) {
	input.mouse_delta = {}
	input.scroll_delta = {}
	input.keys_pressed = {}
}

window_new :: proc() -> glfw.WindowHandle {
	if glfw.Init() == 0 {
		log_error("glfw.Init")
		return nil
	}

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 0)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.RESIZABLE, 1)
	glfw.WindowHint(glfw.SAMPLES, 8)

	window_width, window_height: i32 = 1280, 720
	camera.aspect_ratio = f32(window_width)/f32(window_height)

	window := glfw.CreateWindow(window_width, window_height, "Odin + GLFW + STL", nil, nil)
	if window == nil {
		log_error("glfw.CreateWindow")
		return window
	}
	glfw.MakeContextCurrent(window)

	// Load OpenGL procedures
	gl.load_up_to(4, 0, glfw.gl_set_proc_address)

	gl.Viewport(0, 0, window_width, window_height)
	gl.ClearColor(0.5, 0.7, 1.0, 1.0)

	gl.Enable(gl.CULL_FACE)
	gl.CullFace(gl.BACK)

	gl.Enable(gl.DEPTH_TEST)
	gl.DepthFunc(gl.LESS)

	gl.Enable(gl.MULTISAMPLE)

	glfw.SetWindowSizeCallback(window, proc "cdecl" (window: glfw.WindowHandle, width, height: i32) {
		// Using the default context in a "cdecl" procedure
		context = runtime.default_context()
		gl.Viewport(0, 0, width, height)

		camera.aspect_ratio = f32(width)/f32(height)

		shader_update_uniforms(wireframe)
		render(window)
	})

	glfw.SetKeyCallback(window, proc "cdecl" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
		context = runtime.default_context()
		if action == glfw.PRESS {
			input.keys_pressed[key] = true
		}
	})

	glfw.SetMouseButtonCallback(window, proc "cdecl" (window: glfw.WindowHandle, button, action, mods: i32) {
		context = runtime.default_context()
		switch action {
		case glfw.PRESS:
			input.mouse_pressed[button] = true
		case glfw.RELEASE:
			input.mouse_pressed[button] = false
		}
	})

	input.mouse_pos.x, input.mouse_pos.y = glfw.GetCursorPos(window)
	glfw.SetCursorPosCallback(window, proc "cdecl" (window: glfw.WindowHandle, xpos, ypos: f64) {
		context = runtime.default_context()
		new_pos := [2]f64{ xpos, ypos }

		input.mouse_delta = new_pos - input.mouse_pos
		input.mouse_pos = new_pos
	})

	glfw.SetScrollCallback(window, proc "cdecl" (window: glfw.WindowHandle, xoffset, yoffset: f64) {
		context = runtime.default_context()
		input.scroll_delta = yoffset
	})

	return window
}