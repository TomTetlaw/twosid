
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
    Prop.Mesh = Mesh;
    
    Grey := LoadTexture("textures/grey.png");
    Prop.Textures = ArenaPushN(*GameArena, *texture, .[Grey, Grey, Grey]);
    
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
    Patrol.AreaExtents = #run MakeRandomValue(50, 200);
    Patrol.WaitTime = #run MakeRandomValue(3.0, 5.0);
}

UpdateGame :: () {
    if GamePaused return;
    
    GAllEntities = BuildEntityArray();
    
    // These is only ever one player.
    if EntityTypes.Player.Count > 0 {
        if !GPlayer GPlayer = *EntityTypes.Player[0];
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
    
    for * :OnlyActiveEntities EntityTypes.Prop {
        UpdateEntityBounds(it);
    }
    
    for * :OnlyActiveEntities EntityTypes.Collider {
        UpdateEntityBounds(it);
    }
    
    for * :OnlyActiveEntities EntityTypes.Man {
        UpdateEntityBounds(it);
        
        PositionEntityAboveGround(it);
        
        EntityPatrol(it, *it.Patrol);
    }
}

DrawGame :: () {
    for EntityTypes.Prop {
        UpdateEntityDrawTransform(it, it.Position);
        DrawEntity(it);
    }
    
    for EntityTypes.Man {
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

GAllEntities: [] *entity;

#scope_file

TextFont: *sdf_font;

GameArena: arena;