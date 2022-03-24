package main

import glfw "vendor:glfw"
import glm  "core:math/linalg/glsl"

Camera :: struct {
	eye:    glm.vec4,   // position
	centre: glm.vec3,   // target
	up:     glm.vec4,   // up

	eye_0:  glm.vec4,   // initial eye

	yaw_sens:   f32,
	pitch_sens: f32,
	zoom_sens: 	f32,

	aspect_ratio: f32,
}
camera: Camera

camera_new :: proc() -> (self: Camera) {
	self.yaw_sens   = 0.003
	self.pitch_sens = 0.004
	self.zoom_sens  = 0.005
	self.eye_0      = {0, 0.75, 5, 1}

	camera_reset(&self)
	return
}

camera_reset :: proc(self: ^Camera) {
	self.eye = self.eye_0

	right := glm.vec3{0, 1, 0}
	up    := glm.normalize(glm.cross(right, self.centre - self.eye.xyz))

	self.up  = {0, 0, 0, 1}
	self.up.xyz = ([3]f32)(up)
}

camera_fit_aabb :: proc(self: ^Camera, aabb: AABB) {
	scaled_eye := (aabb.max - aabb.min) * 0.75
	self.eye_0.xyz = ([3]f32)(scaled_eye)

	camera_reset(self)
}

camera_update :: proc(self: ^Camera, using input: Input) -> (updated: bool) {
	if scroll_delta != 0.0 {
		eye_delta := f32(scroll_delta) * 10 * self.zoom_sens * (self.centre - self.eye.xyz)
		eye_transform := glm.mat4Translate(eye_delta)
		self.eye = eye_transform * self.eye

		updated = true
	}

	if mouse_pressed[glfw.MOUSE_BUTTON_RIGHT] {
		switch {
		case keys_pressed[glfw.KEY_LEFT_CONTROL], keys_pressed[glfw.KEY_RIGHT_CONTROL]:
			// Zoom in/out
			eye_delta := f32(mouse_delta.y) * self.zoom_sens * (self.centre - self.eye.xyz)
			eye_transform := glm.mat4Translate(eye_delta)
			self.eye = eye_transform * self.eye
		
		
		case:
			// Move camera around
			// angle around up
			yaw           := -f32(mouse_delta.x) * self.yaw_sens
			yaw_transform := glm.mat4Rotate(self.up.xyz, yaw)

			right := glm.cross(self.centre - self.eye.xyz, glm.vec3(self.up.xyz))

			// angle around right
			pitch           := -f32(mouse_delta.y) * self.pitch_sens
			pitch_transform := glm.mat4Rotate(right, pitch)

			self.eye = pitch_transform * yaw_transform * self.eye
			self.up  = pitch_transform * yaw_transform * self.up
		}

		updated = true
	}

	if keys_pressed[glfw.KEY_SPACE] {
		camera_reset(self)
		updated = true
	}

	return
}

camera_model :: proc(self: Camera) -> glm.mat4 {
	return glm.identity(glm.mat4)
}

camera_view_projection :: proc(self: Camera) -> glm.mat4 {
	distance := 1 / glm.distance(self.centre, glm.vec3(self.eye.xyz))
	scale := glm.mat4Scale({distance, distance, distance})

	view := glm.mat4LookAt(self.eye.xyz, self.centre, self.up.xyz)

	projection := glm.mat4Ortho3d(
		left   = -self.aspect_ratio,
		right  = self.aspect_ratio,
		bottom = -1.0,
		top    = 1.0,
		near   = 0.001,
		far    = 1000.0,
	)

	return projection * view * scale
}