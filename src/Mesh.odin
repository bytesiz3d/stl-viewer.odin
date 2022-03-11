package main

import gl  "vendor:OpenGL"
import glm "core:math/linalg/glsl"

AABB :: struct {
	min, max: glm.vec3,
}

Mesh :: struct {
	vertices: [dynamic]glm.vec3,
	normals:  [dynamic]glm.vec3,
	indices:  [dynamic]u32,

	aabb: AABB,

	vb_handle: u32,
	nb_handle: u32,
	eb_handle: u32,

	vertex_array: u32,
}
mesh: Mesh

mesh_from_stl :: proc(stl: STL) -> (self: Mesh) {
	index_map: map[glm.vec3]u32
	defer delete(index_map)

	self.aabb.min = stl.triangles[0].vertices[0]
	self.aabb.max = stl.triangles[0].vertices[0]

	for triangle in stl.triangles {
		for vertex in triangle.vertices {
			if idx, ok := index_map[vertex]; ok == false {
				new_i := u32(len(self.vertices))
				index_map[vertex] = new_i

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
				append(&self.indices, new_i)
			}
			else {
				append(&self.indices, idx)
			}
		}
	}

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
	
	buffer_data(&self.eb_handle, self.indices, gl.ELEMENT_ARRAY_BUFFER)
	gl.BindVertexArray(0)
	delete(self.indices)
}

mesh_draw :: proc(self: Mesh) {
	gl.BindVertexArray(self.vertex_array)
	gl.DrawElements(gl.TRIANGLES, i32(len(self.indices)), gl.UNSIGNED_INT, nil)
	gl.BindVertexArray(0)
}

mesh_free :: proc(self: ^Mesh) {
	gl.DeleteBuffers(1, &self.vb_handle)
	gl.DeleteBuffers(1, &self.nb_handle)
	gl.DeleteBuffers(1, &self.eb_handle)

	gl.DeleteVertexArrays(1, &self.vertex_array)
}