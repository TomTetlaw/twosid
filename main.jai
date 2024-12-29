
RealTime, GameTime, RealDeltaTime, DeltaTime: float;
GamePaused := false;

WINDOW_WIDTH :: 1366;
WINDOW_HEIGHT :: 768;

mouse :: struct {
    Delta: float2;
    Position: float2;
}

FrameKeys: [..] SDL_Scancode;
Mouse: mouse;

KeyPressed :: (c: SDL_Scancode) -> bool {
    for FrameKeys if it == c return true;
    return false;
}

KeyState :: (c: SDL_Scancode) -> float {
    if KeyStates[c] return 1.0;
    return 0.0;
}

GDevice: *SDL_GPUDevice;
GWindow: *SDL_Window;

entity_traveller :: struct {
    using #as Base: entity;
    
    ApproachSpeed := 5.0;
    GoalPosition: float3;
    LastUpdateTime: float;
    TimePerUpdate: float;
    
    HeightAboveGround := 3.0;
}

entity_man :: struct {
    using #as Base: entity;
    
    HeightAboveGround := 0.0;
}

entity_player :: struct {
    using #as Base: entity;
    
    using Physics: entity_physics;
    
    WalkSpeed :: 4.7;
    RunSpeed :: 9.6;
    CrouchSpeed :: 2.5;
    StandingHeight :: 6.0;
    CrouchingHeight :: 3.0;
    
    EyeHeight := 0.0;
    GoalEyeHeight := 0.0;
    
    using Collision: entity_collision;
}

main :: () {
    CpuInfo := get_cpu_info();
    if !check_feature(CpuInfo.feature_leaves, x86_Feature_Flag.AVX) || !check_feature(CpuInfo.feature_leaves, x86_Feature_Flag.AVX2) {
        FatalError("CPU does not support AVX or AVX2, cringe ah ah cpu");
    }
    
    InitMemorySystem();
    
    if !SDL_Init(SDL_INIT_VIDEO) {
        FatalError("Failed to initialize SDL: %", SdlGetError());
    }
    
    WindowName := "twosid";
    GWindow = SDL_CreateWindow(WindowName.data, WINDOW_WIDTH, WINDOW_HEIGHT, 0);
    if !GWindow FatalError("Failed to create window: %", SdlGetError());
    
    ShaderFormats := cast(u32) SDL_GPU_SHADERFORMAT_DXIL | SDL_GPU_SHADERFORMAT_DXBC | SDL_GPU_SHADERFORMAT_SPIRV;
    GDevice = SDL_CreateGPUDevice(ShaderFormats, true, null);
    if !GDevice FatalError("Failed to create gpu Device: %", SdlGetError());
    
    if !SDL_ClaimWindowForGPUDevice(GDevice, GWindow) FatalError("Failed to claim window for GPU Device: %", SdlGetError());
    
    print("SDL_GPU Driver: %\n", SdlGetGpuDeviceDriver());
    
    InitShaderSystem();
    InitRenderer();
    InitTextureSystem();
    InitMeshSystem();
    InitTerrain();
    InitEntitySystem();
    
    KeyStates = SDL_GetKeyboardState(null);
    SDL_SetWindowRelativeMouseMode(GWindow, true);
    
    PlayerCamera: camera_player;
    FlyingCamera: camera_flying;
    ViewParameters: view_parameters;
    UseFlyingCamera := true;
    
    GameStartTime := current_time_monotonic();
    OldTime: Apollo_Time;
    
    for 0..199 {
        Entity := CreateEntity(entity_traveller);
        Entity.HeightAboveGround = 3.0;
        
        Entity.Mesh = LoadMesh("meshes/cube.mesh");
        Entity.Textures = ArenaPushN(*WorkingArena, *texture, .[LoadTexture("textures/bamboo_diffuse.png"), LoadTexture("textures/bamboo_normal.png"), LoadTexture("textures/bamboo_rmaoh.png")]);
        Entity.Colour = RandomFloat4();
        Entity.TimePerUpdate = 0.5 + RandomFloat(0.0, 2.0);
        Entity.ApproachSpeed = 0.25;
    }
    
    {
        Entity := CreateEntity(entity_man);
        Entity.Mesh = LoadMesh("meshes/man.mesh");
        Entity.AnimPlayer = CreateAnimPlayer(Entity.Mesh, LoadAnimation("meshes/man_run.anim"));
        AnimPlay(*Entity.AnimPlayer);
        Entity.Textures = ArenaPushN(*WorkingArena, *texture, .[LoadTexture("textures/uv_check.png"), LoadTexture("textures/unit_normal.png"), LoadTexture("textures/unit_rmaoh.png")]);
        Entity.HeightAboveGround = 0.0;
    }
    
    {
        Entity := CreateEntity(entity_player);
        Entity.CylinderAxis = .{0, 0, 1};
        Entity.CylinderRadius = 3.0;
        Entity.CylinderHeight = 6.0;
    }
    
    Quit := false;
    while !Quit {
        // update Time
        {
            Now := current_time_monotonic() - GameStartTime;
            Delta := Now - OldTime;
            OldTime = Now;
            
            RealTimeF64 = to_float64_seconds(Now);
            RealDeltaTimeF64 = to_float64_seconds(Delta);
            
            if GamePaused {
                DeltaTimeF64 = 0.0;
            } else {
                DeltaTimeF64 = RealDeltaTimeF64;
                GameTimeF64 += DeltaTimeF64;
            }
            
            RealTime = xx RealTimeF64;
            GameTime = xx GameTimeF64;
            RealDeltaTime = xx RealDeltaTimeF64;
            DeltaTime = xx DeltaTimeF64;
        }
        
        // update Mouse
        {
            x, y: float;
            SDL_GetMouseState(*x, *y);
            
            Pos := float2.{xx x, xx y};
            
            Mouse.Position.x = Pos.x;
            Mouse.Position.y = Pos.y;
        }
        
        // reset to Zero so the event can fill these for just one frame
        Mouse.Delta.x = 0;
        Mouse.Delta.y = 0;
        
        Quit = ProcessWindowEvents();
        if Quit break;
        
        if KeyPressed(.SDL_SCANCODE_F1) {
            UseFlyingCamera = !UseFlyingCamera;
            if UseFlyingCamera {
                FlyingCamera.Position = PlayerCamera.Position;
                FlyingCamera.Yaw = PlayerCamera.Yaw;
                FlyingCamera.Pitch = PlayerCamera.Pitch;
                FlyingCamera.Rotation = PlayerCamera.Rotation;
            }
        }
        
        if KeyPressed(.SDL_SCANCODE_F2) {
            GamePaused = !GamePaused;
        }
        
        if UseFlyingCamera {
            UpdateCameraFlying(*FlyingCamera);
            ViewParameters = FlyingCamera.ViewParameters;
        }
        
        for * EntityTypes.Traveller {
            if (GameTime - it.LastUpdateTime >= it.TimePerUpdate) {
                it.LastUpdateTime = GameTime;
                it.GoalPosition = float3.{
                    RandomFloat(-500.0, 500.0),
                    RandomFloat(-500.0, 500.0),
                    0.0
                };
            }
            
            it.Position = Approach(it.Position, it.GoalPosition, 1.0, DeltaTime * it.ApproachSpeed);
            
            PositionEntityAboveGround(it, it.HeightAboveGround);
            
            DrawEntity(it);
        }
        
        for * EntityTypes.Man {
            PositionEntityAboveGround(it, it.HeightAboveGround);
            UpdateEntityAnimation(it);
            DrawEntity(it);
        }
        
        for * EntityTypes.Player {
            MoveSpeed := it.WalkSpeed;
            if KeyState(.SDL_SCANCODE_LSHIFT) MoveSpeed = it.RunSpeed;
            
            EyeHeight := it.StandingHeight;
            if KeyState(.SDL_SCANCODE_LCTRL) {
                MoveSpeed = it.CrouchSpeed;
                EyeHeight = it.CrouchingHeight;
            }
            
            MoveInput: float2;
            MoveInput.x = KeyState(.SDL_SCANCODE_W) - KeyState(.SDL_SCANCODE_S);
            MoveInput.y = KeyState(.SDL_SCANCODE_A) - KeyState(.SDL_SCANCODE_D);
            MoveInput = RotateVector(MoveInput, PlayerCamera.Yaw);
            
            it.GoalVelocity = xyz(MoveInput * MoveSpeed, 0.0);
            
            IntegrateEntityPhysics(it, *it.Physics);
            
            HandleEntityMovementCollision(it, *it.Collision, .[]);
            
            it.GoalEyeHeight = EyeHeight;
            it.EyeHeight = Approach(it.EyeHeight, it.GoalEyeHeight, 8.0, DeltaTime * 10.0);
            PositionEntityAboveGround(it, it.EyeHeight);
            
            PlayerCamera.Position = it.DrawPosition;
            
            UpdateCameraPlayer(*PlayerCamera);
            if !UseFlyingCamera ViewParameters = PlayerCamera.ViewParameters;
        }
        
        DrawTerrain();
        
        DrawFrame(*ViewParameters);
        
        FrameKeys.count = 0;
        ArenaReset(*FrameArena);
        
#if PROFILE {
            EmitProfilingData();
        }
        
        GFrameNum += 1;
    }
}

ProcessWindowEvents :: () -> bool {
    Event: SDL_Event;
    while SDL_PollEvent(*Event) {
        if IsEventType(*Event, .SDL_EVENT_QUIT) return true;
        
        if IsEventType(*Event, .SDL_EVENT_KEY_DOWN) {
            if Event.key.scancode == .ESCAPE return true;
            array_add(*FrameKeys, Event.key.scancode);
        } else if IsEventType(*Event, .MOUSE_MOTION) {
            Mouse.Delta.x = xx Event.motion.xrel;
            Mouse.Delta.y = xx Event.motion.yrel;
        }
    }
    
    return false;
}

#scope_file

#import "Basic";
#import "String";
#import "File";
#import "File_Utilities";
#import "Process";
#import "Print_Vars";
#import "Machine_X64";

KeyStates: *bool;

RealTimeF64, GameTimeF64, RealDeltaTimeF64, DeltaTimeF64: float64;