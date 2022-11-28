package main

import "core:runtime"

import gl   "vendor:OpenGL"
import glm  "core:math/linalg/glsl"
import glfw "vendor:glfw"

import "core:mem"
import "core:fmt"
import "core:unicode/utf8"
import "core:container/queue"

Event_Key :: struct {
	action: enum {DOWN, UP},
	key: i32,
}
Event_Char :: struct {
	r: rune,
}
Event_Mouse_Button :: struct {
	action: enum {DOWN, UP},
	button: i32,
}
Event_Mouse_Move :: struct {
	pos: [2]f64,
}
Event_Mouse_Scroll :: struct {
	delta: f64,
}
Event_Drop :: struct {
	path: string,
}
Event :: union {
	Event_Key, Event_Char, Event_Mouse_Button, Event_Mouse_Move, Event_Mouse_Scroll, Event_Drop,
}

Input :: struct {
	mouse_pos:      [2]f64,
	mouse_pressed:  [8]bool,

	keys_pressed:  [512]bool,

	mouse_delta:   [2]f64,
	scroll_delta:  f64,
}
g_input: Input

Event_Queue :: queue.Queue(Event)
g_event_queue: Event_Queue

input_reset :: proc(input: ^Input) {
	input.mouse_delta = {}
	input.scroll_delta = {}
}

input_process_events :: proc(input: ^Input, event_queue: ^Event_Queue) {
	for i in 0..<queue.len(event_queue^) {
		#partial switch ev in queue.get(event_queue, i) {
		case Event_Key:
			input.keys_pressed[ev.key] = ev.action == .DOWN

		case Event_Mouse_Button:
			input.mouse_pressed[ev.button] = ev.action == .DOWN

		case Event_Mouse_Move:
			input.mouse_delta = ev.pos - input.mouse_pos
			input.mouse_pos = ev.pos

		case Event_Mouse_Scroll:
			input.scroll_delta = ev.delta
		}
	}
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

	g_camera.width, g_camera.height = 1280, 720
	g_camera.aspect_ratio = f32(g_camera.width)/f32(g_camera.height)

	queue.init(&g_event_queue)

	window := glfw.CreateWindow(g_camera.width, g_camera.height, "stl-viewer.odin", nil, nil)
	if window == nil {
		log_error("glfw.CreateWindow")
		return window
	}
	glfw.MakeContextCurrent(window)

	// Load OpenGL procedures
	gl.load_up_to(4, 0, glfw.gl_set_proc_address)

	gl.Viewport(0, 0, g_camera.width, g_camera.height)
	gl.ClearColor(0.5, 0.7, 1.0, 1.0)

	gl.Enable(gl.CULL_FACE)
	gl.CullFace(gl.BACK)

	gl.Enable(gl.DEPTH_TEST)
	gl.DepthFunc(gl.LEQUAL)

	gl.Enable(gl.BLEND);
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

	gl.Enable(gl.MULTISAMPLE)

	glfw.SetWindowSizeCallback(window, proc "cdecl" (window: glfw.WindowHandle, width, height: i32) {
		// Using the default context in a "cdecl" procedure
		context = runtime.default_context()
		gl.Viewport(0, 0, width, height)

		g_camera.aspect_ratio = f32(width)/f32(height)
		g_camera.width = width
		g_camera.height = height

		shader_wireframe_update_uniforms(shader_wireframe, g_camera)
		render(window, mu_ctx)
	})

	glfw.SetKeyCallback(window, proc "cdecl" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
		context = runtime.default_context()
		switch action {
		case glfw.PRESS:
			queue.push(&g_event_queue, Event_Key{ action = .DOWN, key = key })
		case glfw.RELEASE:
			queue.push(&g_event_queue, Event_Key{ action = .UP, key = key })
		}
	})

	glfw.SetCharCallback(window, proc "cdecl" (window: glfw.WindowHandle, codepoint: rune) {
		context = runtime.default_context()
		queue.push(&g_event_queue, Event_Char{codepoint})
	})

	glfw.SetMouseButtonCallback(window, proc "cdecl" (window: glfw.WindowHandle, button, action, mods: i32) {
		context = runtime.default_context()
		switch action {
		case glfw.PRESS:
			queue.push(&g_event_queue, Event_Mouse_Button{ action = .DOWN, button = button })
		case glfw.RELEASE:
			queue.push(&g_event_queue, Event_Mouse_Button{ action = .UP, button = button })
		}
	})

	g_input.mouse_pos.x, g_input.mouse_pos.y = glfw.GetCursorPos(window)
	glfw.SetCursorPosCallback(window, proc "cdecl" (window: glfw.WindowHandle, xpos, ypos: f64) {
		context = runtime.default_context()
		queue.push(&g_event_queue, Event_Mouse_Move{{xpos, ypos}})
	})

	glfw.SetScrollCallback(window, proc "cdecl" (window: glfw.WindowHandle, xoffset, yoffset: f64) {
		context = runtime.default_context()
		queue.push(&g_event_queue, Event_Mouse_Scroll{yoffset})
	})

	glfw.SetDropCallback(window, proc "cdecl" (window: glfw.WindowHandle, count: i32, paths: [^]cstring) {
		context = runtime.default_context()
		queue.push(&g_event_queue, Event_Drop{string(paths[0])})
	})

	return window
}

window_free :: proc(window: glfw.WindowHandle) {
	queue.destroy(&g_event_queue)
	glfw.Terminate()
}