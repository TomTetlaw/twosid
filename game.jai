
entity_player :: struct {
    using #as Base: entity;
    
    using Physics: entity_physics;
    Physics.AccelTime = 0.5;
    
    using Collision: entity_collision;
    Collision.CylinderAxis = .{0, 0, 1};
    Collision.CylinderRadius = 3.0;
    Collision.CylinderHeight = 6.0;
    
    WalkSpeed :: 4.7;
    RunSpeed :: 9.6;
    CrouchSpeed :: 2.5;
    StandingHeight :: 6.0;
    CrouchingHeight :: 3.0;
    
    EyeHeight := 0.0;
    GoalEyeHeight := 0.0;
    
    Camera: camera_player;
}

entity_test1 :: struct {
    using #as Base: entity;
}

entity_test2 :: struct {
    using #as Base: entity;
}

entity_test3 :: struct {
    using #as Base: entity;
}

entity_test4 :: struct {
    using #as Base: entity;
}

UpdateGame :: () {
    for * :OnlyActiveEntities EntityTypes.Player {
        Player := it;
        
        MoveSpeed := Player.WalkSpeed;
        if KeyState(.SDL_SCANCODE_LSHIFT) MoveSpeed = Player.RunSpeed;
        
        EyeHeight := Player.StandingHeight;
        if KeyState(.SDL_SCANCODE_LCTRL) {
            MoveSpeed = Player.CrouchSpeed;
            EyeHeight = Player.CrouchingHeight;
        }
        
        MoveInput: float2;
        MoveInput.x = KeyState(.SDL_SCANCODE_W) - KeyState(.SDL_SCANCODE_S);
        MoveInput.y = KeyState(.SDL_SCANCODE_A) - KeyState(.SDL_SCANCODE_D);
        MoveInput = RotateVector(MoveInput, Player.Camera.Yaw);
        
        Player.GoalVelocity = xyz(MoveInput * MoveSpeed, 0.0);
        
        IntegrateEntityPhysics(Player, *Player.Physics);
        
        HandleEntityMovementCollision(Player, *Player.Collision);
        
        Player.GoalEyeHeight = EyeHeight;
        Player.EyeHeight = Approach(Player.EyeHeight, Player.GoalEyeHeight, 0.5);
        
        PositionEntityAboveGround(Player, Player.EyeHeight);
        
        Player.Camera.Position = Player.DrawPosition;
        UpdateCameraPlayer(*Player.Camera);
    }
}

DrawGame :: () {
    DrawTextSDF(.{25, 25}, TextFont, 16.0, tprint("%", GameTime));
}

GetGameViewParams :: () -> view_parameters {
    if EntityTypes.Player.Count > 0 {
        Player := EntityTypes.Player[0];
        return Player.Camera.ViewParameters;
    }
    
    return .{xyz(0.0), IdentityMatrix, IdentityMatrix};
}

InitGame :: () {
    TextFont = LoadDistanceFont("fonts/consolas.png");
}

#scope_file

TextFont: *sdf_font;