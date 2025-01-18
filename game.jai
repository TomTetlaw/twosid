
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

GPlayer: *entity_player;

entity_prop :: struct {
    using #as Base: entity;
    Base.Flags = .BLOCKING;
}

CreateProp :: (Path: string, Position: float3) -> *entity_prop {
    return CreateProp(LoadMesh(Path), Position);
}

CreateProp :: (Mesh: *mesh, Position: float3) -> *entity_prop {
    Prop := CreateEntity(entity_prop);
    Prop._Mesh = Mesh;
    
    Prop.Position = Position;
    Prop.Position.z = GetGroundHeight(Position);
    
    Prop.Bounds = Mesh.Bounds;
    
    return Prop;
}

entity_collider :: struct {
    using #as Base: entity;
    Base.Flags = .BLOCKING;
}

CreateCollider :: (Position: float3) -> *entity_collider {
    Entity := CreateEntity(entity_collider);
    Entity.Position = Position;
    Entity.Scale = xyz(3);
    return Entity;
}

entity_man :: struct {
    using #as Base: entity;
    Base.Flags = .BLOCKING;
    Base.MeshPath = "meshes/man.mesh";
    
    Patrol: entity_patrol;
    Patrol.AreaExtents = 150;
    Patrol.WaitTime = 3.0;
    Patrol.FollowSpeed = 6.0;
}

UpdateGame :: () {
    // These is only ever one player.
    if GEntityTypes.Player.Count > 0 {
        if !GPlayer GPlayer = DownCast(GEntityTypes.Player.First, entity_player);
        Player := GPlayer;
        
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
        
        Player.Camera.Position = Player.PositionAboveGround;
        UpdateCameraPlayer(*Player.Camera);
    }
    
    for GEntityTypes.Prop {
        Prop := DownCast(it, entity_prop);
        
        UpdateEntityBounds(Prop);
    }
    
    for GEntityTypes.Collider {
        Collider := DownCast(it, entity_collider);
        
        UpdateEntityBounds(Collider);
    }
    
    for GEntityTypes.Man {
        Man := DownCast(it, entity_man);
        
        PositionEntityAboveGround(Man);
        
        EntityPatrol(Man, *Man.Patrol);
        
        UpdateEntityBounds(Man);
    }
}

DrawGame :: () {
    for GEntityTypes.Prop {
        UpdateEntityDrawTransform(it, it.Position);
        DrawEntity(it);
    }
    
    for GEntityTypes.Man {
        UpdateEntityDrawTransform(it);
        DrawEntity(it);
    }
}

GetGameViewParams :: () -> view_parameters {
    if GPlayer {
        return GPlayer.Camera.ViewParameters;
    }
    
    return .{xyz(0.0), IdentityMatrix, IdentityMatrix};
}

InitGame :: () {
    TextFont = LoadDistanceFont("fonts/consolas.png");
}

#scope_file

TextFont: *sdf_font;

GameArena: arena;
