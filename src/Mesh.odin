package main

import gl  "vendor:OpenGL"
import glm "core:math/linalg/glsl"

AABB :: struct {
	min, max: glm.vec3,
}

Mesh :: struct {
	vertices: [dynamic]glm.vec3,
	normals:  [dynamic]glm.vec3,
	bccs:	  [dynamic]glm.vec3,

	aabb: AABB,

	vb_handle: u32,
	nb_handle: u32,
	bb_handle: u32,

	vertex_count: u32,
	vertex_array: u32,
}
mesh: Mesh

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
				for i in 0..2 {
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
	gl.VertexAttribPointer(SHADER_LOC_POSITION, 3, gl.FLOAT, false, size_of(self.vertices[0]), 0)
	gl.EnableVertexAttribArray(SHADER_LOC_POSITION)
	delete(self.vertices)

	buffer_data(&self.nb_handle, self.normals, gl.ARRAY_BUFFER)
	gl.VertexAttribPointer(SHADER_LOC_NORMAL, 3, gl.FLOAT, false, size_of(self.normals[0]), 0)
	gl.EnableVertexAttribArray(SHADER_LOC_NORMAL)
	delete(self.normals)

	buffer_data(&self.bb_handle, self.bccs, gl.ARRAY_BUFFER)
	gl.VertexAttribPointer(SHADER_LOC_BARYCENTRIC, 3, gl.FLOAT, false, size_of(self.bccs[0]), 0)
	gl.EnableVertexAttribArray(SHADER_LOC_BARYCENTRIC)
	delete(self.bccs)
}

mesh_draw :: proc(self: Mesh) {
	gl.BindVertexArray(self.vertex_array)

	gl.DrawArrays(gl.TRIANGLES, 0, i32(self.vertex_count))

	gl.BindVertexArray(0)
}

mesh_free :: proc(self: ^Mesh) {
	gl.DeleteBuffers(1, &self.vb_handle)
	gl.DeleteBuffers(1, &self.nb_handle)
	gl.DeleteBuffers(1, &self.bb_handle)

	gl.DeleteVertexArrays(1, &self.vertex_array)
}