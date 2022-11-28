package main

import gl   "vendor:OpenGL"
import glm  "core:math/linalg/glsl"
import glfw "vendor:glfw"
import mu   "vendor:microui"

import "core:fmt"
import "core:container/queue"
import "core:strings"

mu_ctx: ^mu.Context
_main :: proc() -> (ok: bool = true) {
	g_camera = camera_new()

	window := window_new()
	defer window_free(window)

	shader_wireframe = shader_new("shaders/wireframe.vert", "shaders/wireframe.frag")
	defer shader_free(&shader_wireframe)

	shader_atlas = shader_new("shaders/atlas.vert", "shaders/atlas.frag")
	defer shader_free(&shader_atlas)

	r_init() or_return
	defer r_dispose()

	mu_ctx = new(mu.Context)
	defer free(mu_ctx)

	mu.init(mu_ctx)
	mu_ctx.text_width = #force_inline proc(font: mu.Font, text: string) -> i32 { return r_get_text_width(text) };
	mu_ctx.text_height = #force_inline proc(font: mu.Font) -> i32 { return r_get_text_height() };

	new_mesh("resources/teapot.stl")
	defer mesh_free(&g_stl_mesh)

	for glfw.WindowShouldClose(window) == false {
		glfw.PollEvents()
		defer queue.clear(&g_event_queue)

		input_process_events(&g_input, &g_event_queue)
		defer input_reset(&g_input)

		if camera_update(&g_camera, g_input) {
			shader_wireframe_update_uniforms(shader_wireframe, g_camera)
		}

		r_process_events(mu_ctx, &g_event_queue)
		render(window, mu_ctx)
	}

	return
}

render :: proc(window: glfw.WindowHandle, ctx: ^mu.Context) {
	mu.begin(ctx)
	{
		demo_window(ctx)
	}
	mu.end(ctx)

	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
	{
		mesh_draw(g_stl_mesh)
		r_process_commands(ctx)
	}
	glfw.SwapBuffers(window)
}

new_mesh :: proc(path: string) {
	if g_stl_mesh.vertex_count != 0 { // mesh is valid
		mesh_free(&g_stl_mesh)
	}

	stl := stl_read(path)
	{
		g_stl_mesh = mesh_from_stl(stl)
		g_stl_mesh.path = strings.clone(path)
		camera_fit_aabb(&g_camera, g_stl_mesh.aabb)
		shader_wireframe_update_uniforms(shader_wireframe, g_camera)
	}
	stl_free(&stl)

	mesh_upload(&g_stl_mesh)
}

demo_window :: proc(ctx: ^mu.Context) {
	button :: #force_inline proc(ctx: ^mu.Context, label: string) -> bool {
		return mu.button(ctx, label) == {.SUBMIT};
	}

	if mu.begin_window(ctx, "Controls", {120, 40, 500, 300}) {
		if mu.header(ctx, "Mesh", {.EXPANDED}) != {} {
			mu.layout_row(ctx, []i32{ -1 });
			mu.text(ctx, "RMB pan")
			mu.text(ctx, "MWheel/CTRL+RMB zoom")
			mu.text(ctx, "SPACE reset camera")
			mu.text(ctx, "Drag and drop *.STL to render")

			mu.layout_row(ctx, []i32{ 50, -1 });

			mu.label(ctx, "Vertices:")
			mu.text(ctx, fmt.tprintf("{}", g_stl_mesh.vertex_count))

			mu.label(ctx, "Size:")
			sz := g_stl_mesh.aabb.max - g_stl_mesh.aabb.min
			mu.text(ctx, fmt.tprintf("{} {} {}", sz.x, sz.y, sz.z))

			mu.label(ctx, "Path:")
			mu.text(ctx, g_stl_mesh.path)
		}

		mu.end_window(ctx)
	}
}