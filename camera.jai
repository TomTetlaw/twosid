
Camera :: struct {
	FLY_SPEED :: 1.0;
    ROTATION_SPEED :: 0.3;
    ROTATION_SMOOTHING :: 0.3;
    
    yaw, pitch: float;
    rotation_input: Vec2;
    position: Vec3;
    
    rotation: Quaternion;
    neg_rotation: Mat4;
    view: Mat4;
};

update_camera :: (camera : *Camera) {
	move_input: Vec3;
    
    move_speed := Camera.FLY_SPEED;
    if key_state(.SDL_SCANCODE_LSHIFT) move_speed *= 10;
    
    move_input.x = key_state(.SDL_SCANCODE_S) - key_state(.SDL_SCANCODE_W);
    move_input.y = key_state(.SDL_SCANCODE_A) - key_state(.SDL_SCANCODE_D);
    move_input.z = key_state(.SDL_SCANCODE_E) - key_state(.SDL_SCANCODE_Q);
    move_input = vec3_rotate(normalize(move_input), camera.rotation);
    
	camera.position += move_input * move_speed * delta_time;
    
    camera.rotation_input = lerp(camera.rotation_input, mouse.delta, Camera.ROTATION_SMOOTHING);
    delta := camera.rotation_input * Camera.ROTATION_SPEED;
    camera.yaw += delta.x * deg2turn;
    camera.pitch += delta.y * deg2turn;
    camera.pitch = clamp(camera.pitch, -89.0 * deg2turn, 89.0 * deg2turn);
    
    yaw := quat_axis_angle(.{0, 0, 1}, camera.yaw);
    pitch := quat_axis_angle(.{0, -1, 0}, camera.pitch);
    camera.rotation = yaw * pitch;
    
    transform := mat4_translation(camera.position) * mat4_rotation(camera.rotation);
    camera.view = mat4_inverse(transform);
}

#scope_file

#import "Basic";