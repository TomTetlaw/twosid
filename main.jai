
RealTime, GameTime, RealDeltaTime, DeltaTime: float;
GamePaused := false;

WINDOW_WIDTH :: 1366;
WINDOW_HEIGHT :: 768;

mouse :: struct {
    Delta: float2;
    Position: float2;
    LeftDown, RightDown: bool;
    
    DragStart: float2;
    DragLength: float;
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
    
    InitShaderSystem();
    InitRenderer();
    InitTextureSystem();
    InitMeshSystem();
    InitTerrain();
    InitEntitySystem();
    InitEditor();
    InitUISystem();
    InitGame();
    
    KeyStates = SDL_GetKeyboardState(null);
    
    UseFlyingCamera := true;
    
    GameStartTime := current_time_monotonic();
    OldTime: Apollo_Time;
    
    Font := LoadFont("fonts/consolas.ttf", 32.0);
    DistanceFont := LoadDistanceFont("fonts/inconsolata.png");
    
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
            Buttons := SDL_GetMouseState(*x, *y);
            
            Pos := float2.{xx x, xx y};
            
            Mouse.Position.x = Pos.x;
            Mouse.Position.y = Pos.y;
            
            Mouse.LeftDown = (Buttons & (1 << (SDL_BUTTON_LEFT-1))) != 0;
            Mouse.RightDown = (Buttons & (1 << (SDL_BUTTON_RIGHT-1))) != 0;
            
            if Mouse.LeftDown {
                Mouse.DragLength = Length(Mouse.Position - Mouse.DragStart);
            } else {
                Mouse.DragLength = 0;
                Mouse.DragStart = .{0, 0};
            }
        }
        
        // reset to Zero so the event can fill these for just one frame
        Mouse.Delta.x = 0;
        Mouse.Delta.y = 0;
        
        Quit = ProcessWindowEvents();
        if Quit break;
        
        if KeyPressed(.SDL_SCANCODE_F2) {
            GamePaused = !GamePaused;
        }
        
        if KeyPressed(.SDL_SCANCODE_F5) {
            ToggleEditor();
            if !GEditorOpen {
                UseFlyingCamera = false;
                SDL_SetWindowRelativeMouseMode(GWindow, true);
            } else {
                UseFlyingCamera = true;
                SDL_SetWindowRelativeMouseMode(GWindow, false);
            }
        }
        
        if UseFlyingCamera {
            
        }
        
        HandleUIInput();
        UpdateEditor();
        UpdateGame();
        
        DrawEditor();
        DrawGame();
        DrawTerrain();
        DrawUI();
        
        ViewParameters: view_parameters;
        
        if UseFlyingCamera {
            ViewParameters = GetEditorViewParams();
        } else {
            ViewParameters = GetGameViewParams();
        }
        
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
        } else if IsEventType(*Event, .SDL_EVENT_MOUSE_MOTION) {
            Mouse.Delta.x = xx Event.motion.xrel;
            Mouse.Delta.y = xx Event.motion.yrel;
        } else if IsEventType(*Event, .SDL_EVENT_MOUSE_BUTTON_DOWN) {
            Mouse.DragStart = float2.{xx Event.button.x, xx Event.button.y};
            EditorMouseInput(Event.button.button, true);
        } else if IsEventType(*Event, .SDL_EVENT_MOUSE_BUTTON_UP) {
            EditorMouseInput(Event.button.button, false);
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