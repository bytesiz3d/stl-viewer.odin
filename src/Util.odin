package main

import "core:fmt"
import "core:mem"

import gl 	"vendor:OpenGL"
import glfw "vendor:glfw"

log_error :: proc(prefix: string) {
	desc, err := glfw.GetError()
	fmt.eprintln(prefix, "failed, err:", err, desc)
}

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	_main()

	for _, leak in track.allocation_map {
		fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
	}
	for bad_free in track.bad_free_array {
		fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
	}
}