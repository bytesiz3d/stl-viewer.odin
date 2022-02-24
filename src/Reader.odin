package main

import "core:mem"
import "core:strings"
import "core:bytes"
import "core:strconv"

import glm "core:math/linalg/glsl"

strings_read_variadic :: proc(reader: ^strings.Reader, args: ..any) {
	for _, i in args {
		if args[i] == nil {
			delete(_read_to_whitespace(reader))
		}
		else {
			switch t_arg in &args[i] {
			case string: 
				_parse_string(reader, &t_arg)
			case glm.vec3:
				_parse_vec3(reader, &t_arg)
			case:
				assert(false, "Unsupported type")
			}
		}
	}
}

@(private="file")
_parse_string :: proc(reader: ^strings.Reader, out: ^string) {
	out^ = _read_to_whitespace(reader)
}

@(private="file")
_parse_vec3 :: proc(reader: ^strings.Reader, out: ^glm.vec3) {
	for i in 0..2 {
		word := _read_to_whitespace(reader)
		defer delete(word)

		if val, ok := strconv.parse_f32(word); ok {
			out[i] = val
		}
	}
}

@(private="file")
_read_to_whitespace :: proc(reader: ^strings.Reader) -> string {
	using strings
	builder: Builder
	defer destroy_builder(&builder)

	// Skip leading whitespace
	for {
		if r, count, err := reader_read_rune(reader); err == nil {
			if is_ascii_space(r) == false {
				reader_unread_rune(reader)
				break
			}
		}
	}

	for {
		if r, count, err := reader_read_rune(reader); err == nil {
			if is_ascii_space(r) == false { 
				write_rune_builder(&builder, r)
			}
			else {
				break
			}
			
		}
		else if err == .EOF {
			break
		}
	}

	return clone(to_string(builder))
}

Seek_N :: distinct i64

binary_read_variadic :: proc(reader: ^bytes.Reader, args: ..any) {
	for _, i in args {
		if args[i] == nil {
			assert(false, "Nothing to read into")
		}
		else {
			switch t_arg in args[i] {
			case Triangle, u32:
				slice := _read_enough_for_any(reader, t_arg)
				mem.copy(args[i].data, raw_data(slice), len(slice))
			
			case []byte:
				slice := _read_enough_for_slice(reader, t_arg)
				mem.copy(args[i].data, raw_data(slice), len(slice))

			case Seek_N:
				_read_n_bytes(reader, i64(t_arg))

			case:
				assert(false, "Unsupported type")
			}
		}
	}
}

@(private="file")
_read_enough_for_any :: proc(reader: ^bytes.Reader, v: any) -> []byte {
	size := type_info_of(v.id).size
	return _read_n_bytes(reader, i64(size))
}

@(private="file")
_read_enough_for_slice :: proc(reader: ^bytes.Reader, sl: []$T) -> []byte {
	size := len(sl) * size_of(T)
	return _read_n_bytes(reader, i64(size))
}

@(private="file")
_read_n_bytes :: proc(reader: ^bytes.Reader, n: i64) -> []byte {
	using bytes
	defer reader_seek(reader, n, .Current)

	start := reader.i
	remaining := i64(reader_length(reader))

	if remaining == n {
		return reader.s[start:]
	}
	else if remaining > n {
		return reader.s[start: start+n]
	}
	else {
		// Error
		return nil
	}
}
