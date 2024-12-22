
 view_parameters :: struct {
    Position: float3;
    View: float4x4;
}

camera_flying :: struct {
	FLY_SPEED :: 10.0;
    ROTATION_SPEED :: 0.3;
    ROTATION_SMOOTHING :: 0.3;
    
    Yaw, Pitch: float;
    RotationInput: float2;
    
    Rotation: quat;
    Transform: float4x4;
    
    using ViewParameters: view_parameters;
};

camera_player :: struct {
    WALK_SPEED :: 4.7;
    RUN_SPEED :: 9.6;
    ROTATION_SPEED :: 0.3;
    ROTATION_SMOOTHING :: 0.3;
    EYE_HEIGHT :: 6.0;
    
    Yaw, Pitch: float;
    RotationInput: float2;
    
    Rotation: quat;
    
    using ViewParameters: view_parameters;
};

UpdateCameraPlayer :: (Camera: *camera_player, GroundHeight: float) {
	MoveInput: float2;
    
    MoveSpeed := Camera.WALK_SPEED;
    if KeyState(.SDL_SCANCODE_LSHIFT) MoveSpeed = Camera.RUN_SPEED;
    if KeyState(.SDL_SCANCODE_LCTRL) MoveSpeed /= 10.0;
    
    MoveInput.x = KeyState(.SDL_SCANCODE_W) - KeyState(.SDL_SCANCODE_S);
    MoveInput.y = KeyState(.SDL_SCANCODE_A) - KeyState(.SDL_SCANCODE_D);
    MoveInput = RotateVector(MoveInput, Camera.Yaw);
    
	Camera.Position += xyz(MoveInput * MoveSpeed * DeltaTime, 0.0);
    
    Camera.RotationInput = Lerp(Camera.RotationInput, Mouse.Delta, Camera.ROTATION_SMOOTHING);
    Delta := Camera.RotationInput * Camera.ROTATION_SPEED;
    Camera.Yaw = Camera.Yaw + Delta.x*Deg2Turn;
    Camera.Pitch = Camera.Pitch + Delta.y*Deg2Turn;
    Camera.Pitch = Clamp(Camera.Pitch, -0.25, 0.25);
    
    Yaw := QuatFromAxisAngle(.{0, 0, -1}, Camera.Yaw);
    Pitch := QuatFromAxisAngle(.{0, 1, 0}, Camera.Pitch);
    
    Camera.Rotation = Yaw * Pitch;
    
    ViewTransform := TranslationMatrix(Camera.Position + .{0, 0, GroundHeight + Camera.EYE_HEIGHT}) * RotationMatrix(Camera.Rotation);
    
    Camera.View = InverseMatrix(ViewTransform);
}

UpdateCameraFlying :: (Camera: *camera_flying) {
	MoveInput: float3;
    
    MoveSpeed := Camera.FLY_SPEED;
    if KeyState(.SDL_SCANCODE_LSHIFT) MoveSpeed *= 10;
    
    MoveInput.x = KeyState(.SDL_SCANCODE_W) - KeyState(.SDL_SCANCODE_S);
    MoveInput.y = KeyState(.SDL_SCANCODE_A) - KeyState(.SDL_SCANCODE_D);
    MoveInput.z = KeyState(.SDL_SCANCODE_E) - KeyState(.SDL_SCANCODE_Q);
    MoveInput = RotateVector(MoveInput, Camera.Rotation);
    
	Camera.Position += MoveInput * MoveSpeed * DeltaTime;
    
    Camera.RotationInput = Lerp(Camera.RotationInput, Mouse.Delta, Camera.ROTATION_SMOOTHING);
    Delta := Camera.RotationInput * Camera.ROTATION_SPEED;
    Camera.Yaw = Camera.Yaw + Delta.x*Deg2Turn;
    Camera.Pitch = Camera.Pitch + Delta.y*Deg2Turn;
    Camera.Pitch = Clamp(Camera.Pitch, -0.25, 0.25);
    
    Yaw := QuatFromAxisAngle(.{0, 0, -1}, Camera.Yaw);
    Pitch := QuatFromAxisAngle(.{0, 1, 0}, Camera.Pitch);
    
    Camera.Rotation = Yaw * Pitch;
    
    Camera.Transform = TranslationMatrix(Camera.Position) * RotationMatrix(Camera.Rotation);
    Camera.View = InverseMatrix(Camera.Transform);
}

#scope_file

#import "Basic";