package main

import gl  "vendor:OpenGL"
import glm "core:math/linalg/glsl"

AABB :: struct {
	min, max: glm.vec3,
}

Mesh :: struct {
	vertices: [dynamic]glm.vec3,
	normals:  [dynamic]glm.vec3,
	bccs:     [dynamic]glm.vec3,

	aabb: AABB,

	vb_handle: u32,
	nb_handle: u32,
	bb_handle: u32,

	vertex_count: u32,
	vertex_array: u32,

	path: string,
}
g_stl_mesh: Mesh

Rect :: struct {
	x1, y1, x2, y2: f32
}

mesh_from_stl :: proc(stl: STL) -> (self: Mesh) {
	index_map: map[glm.vec3]u32
	defer delete(index_map)

	self.aabb.min = stl.triangles[0].vertices[0]
	self.aabb.max = stl.triangles[0].vertices[0]

	bccs: [3]glm.vec3 = {
		{1, 0, 0}, {0, 1, 0}, {0, 0, 1},
	}

	for triangle in stl.triangles {
		for vertex, i in triangle.vertices {
				for i in 0..=2 {
					if vertex[i] < self.aabb.min[i] {
						self.aabb.min[i] = vertex[i]
					}
					else if vertex[i] > self.aabb.max[i] {
						self.aabb.max[i] = vertex[i]
					}
				}

			append(&self.vertices, vertex)
			append(&self.normals, triangle.normal)
			append(&self.bccs, bccs[i])
		}
	}

	self.vertex_count = u32(len(self.vertices))
	return
}

mesh_upload :: proc(self: ^Mesh) {
	gl.GenVertexArrays(1, &self.vertex_array)
	gl.BindVertexArray(self.vertex_array)

	buffer_data :: proc(handle: ^u32, buffer: [dynamic]$T, buffer_type: u32) {
		gl.GenBuffers(1, handle)
		gl.BindBuffer(buffer_type, handle^)
		gl.BufferData(buffer_type, len(buffer) * size_of(T), raw_data(buffer), gl.STATIC_DRAW)
	}

	buffer_data(&self.vb_handle, self.vertices, gl.ARRAY_BUFFER)
	LOC_POSITION :: 0
	gl.VertexAttribPointer(LOC_POSITION, 3, gl.FLOAT, false, size_of(self.vertices[0]), 0)
	gl.EnableVertexAttribArray(LOC_POSITION)
	delete(self.vertices)

	buffer_data(&self.nb_handle, self.normals, gl.ARRAY_BUFFER)
	LOC_NORMAL :: 1
	gl.VertexAttribPointer(LOC_NORMAL, 3, gl.FLOAT, false, size_of(self.normals[0]), 0)
	gl.EnableVertexAttribArray(LOC_NORMAL)
	delete(self.normals)

	buffer_data(&self.bb_handle, self.bccs, gl.ARRAY_BUFFER)
	LOC_BARYCENTRIC :: 2
	gl.VertexAttribPointer(LOC_BARYCENTRIC, 3, gl.FLOAT, false, size_of(self.bccs[0]), 0)
	gl.EnableVertexAttribArray(LOC_BARYCENTRIC)
	delete(self.bccs)
}

mesh_draw :: proc(self: Mesh) {
	gl.BindVertexArray(self.vertex_array)
	defer gl.BindVertexArray(0)

	gl.UseProgram(shader_wireframe.program)
	gl.DrawArrays(gl.TRIANGLES, 0, i32(self.vertex_count))
}

mesh_free :: proc(self: ^Mesh) {
	gl.DeleteBuffers(1, &self.vb_handle)
	gl.DeleteBuffers(1, &self.nb_handle)
	gl.DeleteBuffers(1, &self.bb_handle)

	gl.DeleteVertexArrays(1, &self.vertex_array)

	delete(self.path)
	self^ = {}
}

Quad_Mesh :: struct {
	vao, vbo: u32,
}

quad_mesh_new :: proc() -> (self: Quad_Mesh) {
	// VBO
	gl.GenBuffers(1, &self.vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, self.vbo)

	data := [?]f32 {
		// Position          UV
		-0.5, +0.5,          0.0, 0.0, // 0
		-0.5, -0.5,          0.0, 0.0, // 1
		+0.5, -0.5,          0.0, 0.0, // 2
		+0.5, -0.5,          0.0, 0.0, // 2
		+0.5, +0.5,          0.0, 0.0, // 3
		-0.5, +0.5,          0.0, 0.0, // 0
	}
	gl.BufferData(gl.ARRAY_BUFFER, len(data) * size_of(f32), raw_data(data[:]), gl.DYNAMIC_DRAW)

	// VAO
	gl.GenVertexArrays(1, &self.vao)
	gl.BindVertexArray(self.vao)
	defer gl.BindVertexArray(0)

	// Attribs
	LOC_POSITION :: 0
	gl.VertexAttribPointer(LOC_POSITION, 2, gl.FLOAT, false, 4 * size_of(f32), 0)
	gl.EnableVertexAttribArray(LOC_POSITION)

	LOC_UV :: 1
	gl.VertexAttribPointer(LOC_UV, 2, gl.FLOAT, false, 4 * size_of(f32), 2 * size_of(f32))
	gl.EnableVertexAttribArray(LOC_UV)

	return self
}

quad_mesh_draw :: proc(self: Quad_Mesh, texture_rect, screen_rect: Rect) {
	uv_0 := [2]f32{texture_rect.x1, texture_rect.y1}
	uv_1 := [2]f32{texture_rect.x1, texture_rect.y2}
	uv_2 := [2]f32{texture_rect.x2, texture_rect.y2}
	uv_3 := [2]f32{texture_rect.x2, texture_rect.y1}

	screen_to_ndc := camera_screen_to_ndc(g_camera)

	pos_0 := screen_to_ndc * [4]f32{screen_rect.x1, screen_rect.y1, 0.0, 1.0 }
	pos_1 := screen_to_ndc * [4]f32{screen_rect.x1, screen_rect.y2, 0.0, 1.0 }
	pos_2 := screen_to_ndc * [4]f32{screen_rect.x2, screen_rect.y2, 0.0, 1.0 }
	pos_3 := screen_to_ndc * [4]f32{screen_rect.x2, screen_rect.y1, 0.0, 1.0 }

	data := [?]f32 {
		// Position          UV
		pos_0.x, pos_0.y,    uv_0.x, uv_0.y, // 0
		pos_1.x, pos_1.y,    uv_1.x, uv_1.y, // 1
		pos_2.x, pos_2.y,    uv_2.x, uv_2.y, // 2
		pos_2.x, pos_2.y,    uv_2.x, uv_2.y, // 2
		pos_3.x, pos_3.y,    uv_3.x, uv_3.y, // 3
		pos_0.x, pos_0.y,    uv_0.x, uv_0.y, // 0
	}

	gl.BindBuffer(gl.ARRAY_BUFFER, self.vbo);
	defer gl.BindBuffer(gl.ARRAY_BUFFER, 0);
	gl.BufferSubData(gl.ARRAY_BUFFER, 0, len(data) * size_of(f32), raw_data(data[:]))

	gl.BindVertexArray(self.vao)
	defer gl.BindVertexArray(0)

	gl.UseProgram(shader_atlas.program)
	gl.DrawArrays(gl.TRIANGLES, 0, 6);
}

quad_mesh_free :: proc(self: ^Quad_Mesh) {
	gl.DeleteBuffers(1, &self.vao)
	gl.DeleteVertexArrays(1, &self.vbo)
}