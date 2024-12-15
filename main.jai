
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

main :: () {
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
    
    KeyStates = SDL_GetKeyboardState(null);
    SDL_SetWindowRelativeMouseMode(GWindow, true);
    
    Camera: camera;
    
    GameStartTime := current_time_monotonic();
    OldTime: Apollo_Time;
    
    TerrainMesh := LoadMesh("meshes/terrain.mesh");
    
    TerrainTextures: arena_array(*texture);
    ArrayAdd(*TerrainTextures, LoadTexture("textures/grass_diffuse.png"));
    ArrayAdd(*TerrainTextures, LoadTexture("textures/grass_normal.png"));
    ArrayAdd(*TerrainTextures, LoadTexture("textures/grass_rmaoh.png"));
    
    SphereMesh := LoadMesh("meshes/sphere.mesh");
    SpherePosition: float3;
    
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
        
        UpdateCamera(*Camera);
        
        t0 := current_time_monotonic();
        
        Ray := GetRayFromCamera(*Camera);
        
        TriangleCount := TerrainMesh.Indices.count / 3;
        
        Transform := ScaleMatrix(.{25, 25, 25}) * TranslationMatrix(.{0, 0, -5});
        
        ClosestPoint := float3.{99999, 99999, 99999};
        ClosestDistance := 99999.0;
        for 0..TriangleCount-1 {
            Triangle := triangle.{
                (Transform * xyzw(TerrainMesh.Positions[TerrainMesh.Indices[it*3+0]], 1.0)).xyz,
                (Transform * xyzw(TerrainMesh.Positions[TerrainMesh.Indices[it*3+1]], 1.0)).xyz,
                (Transform * xyzw(TerrainMesh.Positions[TerrainMesh.Indices[it*3+2]], 1.0)).xyz
            };
            
            Hit := RayTriangleIntersection(Ray, Triangle);
            if Hit.Intersected {
                if Hit.T < ClosestDistance {
                    SpherePosition = Hit.Point;
                    ClosestDistance = Hit.T;
                }
            }
        }
        
        t1 := current_time_monotonic();
        print("time: %\n", to_float64_seconds(t1-t0));
        
        Command: draw_command_mesh;
        Command.Flags = 0;
        Command.Mesh = TerrainMesh;
        Command.Textures = TerrainTextures;
        Command.Instance.Transform = ScaleMatrix(.{25, 25, 25}) * TranslationMatrix(.{0, 0, -5});
        Command.Instance.DiffuseColour = .{1, 1, 1, 1};
        Command.Instance.MaterialParams = .{1, 1, 1, 100};
        
        AddDrawCommand(*Command);
        
        Command.Flags = .DEBUG;
        Command.Mesh = SphereMesh;
        Command.Instance.Transform = TranslationMatrix(SpherePosition);
        Command.Instance.DiffuseColour = .{1, 1, 1, 1};
        Command.Instance.MaterialParams = .{1, 1, 1, 1};
        AddDrawCommand(*Command);
        
        DrawFrame(*Camera);
        
        FrameKeys.count = 0;
        ArenaReset(*FrameArena);
        
        //memory_visualizer_per_frame_update();
        //Tracy.FrameMark();
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

#import "Basic";// () (MEMORY_DEBUGGER = true);
#import "String";
#import "File";
#import "File_Utilities";
#import "Process";
#import "Print_Vars";
Tracy :: #import "jai-tracy" (IMPORT_MODE = .CLIENT);

KeyStates: *bool;

RealTimeF64, GameTimeF64, RealDeltaTimeF64, DeltaTimeF64: float64;