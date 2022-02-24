package main

import "core:strings"
import "core:bytes"
import "core:os"

import glm "core:math/linalg/glsl"

Triangle :: struct {
    normal:   glm.vec3,
    vertices: [3]glm.vec3,
}

generate_normal :: proc(vertices: [3]glm.vec3) -> (normal: glm.vec3) {
	XY := vertices.y - vertices.x
	YZ := vertices.z - vertices.y

	return glm.normalize(glm.cross(XY, YZ))
}

STL :: struct {
    triangles: [dynamic]Triangle,
}

@(private="file")
_stl_read_ascii :: proc(stl_data: string) -> (self: STL) {
	reader: strings.Reader
	strings.reader_init(&reader, stl_data)

	SOLID: any = nil
	NAME: any = nil
	NORMAL: any = nil
	OUTER: any = nil
	LOOP: any = nil
	VERTEX: any = nil
	ENDLOOP: any = nil
	ENDFACET: any = nil

	strings_read_variadic(&reader, SOLID, NAME)
	
	t: Triangle
	for {
		endsolid_or_facet: string
		defer delete(endsolid_or_facet)
		strings_read_variadic(&reader, endsolid_or_facet)
		if endsolid_or_facet == "endsolid" {
			break
		}

		strings_read_variadic(&reader, 
			NORMAL, t.normal,
			OUTER, LOOP, 
			VERTEX, t.vertices[0],
			VERTEX, t.vertices[1],
			VERTEX, t.vertices[2],
			ENDLOOP, ENDFACET)

		if t.normal == {} {
			t.normal = generate_normal(t.vertices)
		}
		append(&self.triangles, t)
	}
	return
}

@(private="file")
_stl_read_binary :: proc(stl_data: []byte) -> (self: STL) {
	reader: bytes.Reader
	bytes.reader_init(&reader, stl_data)

	HEADER :: Seek_N(80)
	count_triangles: u32

	binary_read_variadic(&reader, HEADER, count_triangles)
	if count_triangles == 0 {
		return
	}
	
	t: Triangle
	ATTRIBUTE_BYTE_COUNT :: Seek_N(2)

	for i in 0..<count_triangles {
		binary_read_variadic(&reader, t, ATTRIBUTE_BYTE_COUNT)

		if t.normal == {} {
			t.normal = generate_normal(t.vertices)
		}
		append(&self.triangles, t)
	}

	return
}

stl_read :: proc(file_path: string) -> (self: STL) {
	if bytes, ok := os.read_entire_file(file_path); ok {
		defer delete(bytes)

		if ascii := string(bytes); ascii[:5] == "solid" {
			self = _stl_read_ascii(ascii)
		}
		else {
			self = _stl_read_binary(bytes)
		}
	}

	return
}

stl_free :: proc(self: ^STL) {
	delete(self.triangles)
}