
camera :: struct {
	FLY_SPEED :: 1.0;
    ROTATION_SPEED :: 0.3;
    ROTATION_SMOOTHING :: 0.3;
    
    Yaw, Pitch: float;
    RotationInput: float2;
    Position: float3;
    
    Rotation: quat;
    NegRotation: float4x4;
    View: float4x4;
};

UpdateCamera :: (Camera: *camera) {
	MoveInput: float3;
    
    MoveSpeed := Camera.FLY_SPEED;
    if KeyState(.SDL_SCANCODE_LSHIFT) MoveSpeed *= 10;
    
    MoveInput.x = KeyState(.SDL_SCANCODE_S) - KeyState(.SDL_SCANCODE_W);
    MoveInput.y = KeyState(.SDL_SCANCODE_A) - KeyState(.SDL_SCANCODE_D);
    MoveInput.z = KeyState(.SDL_SCANCODE_E) - KeyState(.SDL_SCANCODE_Q);
    MoveInput = Vec3Rotate(normalize(MoveInput), Camera.Rotation);
    
	Camera.Position += MoveInput * MoveSpeed * DeltaTime;
    
    Camera.RotationInput = Lerp(Camera.RotationInput, Mouse.Delta, Camera.ROTATION_SMOOTHING);
    Delta := Camera.RotationInput * Camera.ROTATION_SPEED;
    Camera.Yaw += Delta.x * Deg2Turn;
    Camera.Pitch += Delta.y * Deg2Turn;
    Camera.Pitch = clamp(Camera.Pitch, -89.0 * Deg2Turn, 89.0 * Deg2Turn);
    
    Yaw := QuatAxisAngle(.{0, 0, 1}, Camera.Yaw);
    Pitch := QuatAxisAngle(.{0, -1, 0}, Camera.Pitch);
    Camera.Rotation = Yaw * Pitch;
    
    Transform := Mat4Translation(Camera.Position) * Mat4Rotation(Camera.Rotation);
    Camera.View = Mat4Inverse(Transform);
}

#scope_file

#import "Basic";