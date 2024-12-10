
real_time, game_time, real_delta_time, delta_time: float;
game_paused := false;

WINDOW_WIDTH :: 1366;
WINDOW_HEIGHT :: 768;

Mouse :: struct {
    delta: Vec2;
    position: Vec2;
}

frame_keys: [..] SDL_Scancode;
mouse: Mouse;

key_pressed :: (code: SDL_Scancode) -> bool {
    for frame_keys if it == code return true;
    return false;
}

key_state :: (code: SDL_Scancode) -> float {
    return ifx key_states[code] then 1.0 else 0.0;
}

g_device: *SDL_GPUDevice;
g_window: *SDL_Window;

main :: () {
    if !SDL_Init(SDL_INIT_VIDEO) {
        fatal_error("Failed to initialize SDL: %", sdl_get_error());
    }
    
    window_name := "twosid";
    g_window = SDL_CreateWindow(window_name.data, WINDOW_WIDTH, WINDOW_HEIGHT, 0);
    if !g_window fatal_error("Failed to create window: %", sdl_get_error());
    
    shader_formats := cast(u32) SDL_GPU_SHADERFORMAT_DXIL | SDL_GPU_SHADERFORMAT_DXBC | SDL_GPU_SHADERFORMAT_SPIRV;
    g_device = SDL_CreateGPUDevice(shader_formats, true, null);
    if !g_device fatal_error("Failed to create gpu device: %", sdl_get_error());
    
    if !SDL_ClaimWindowForGPUDevice(g_device, g_window) fatal_error("Failed to claim window for GPU device: %", sdl_get_error());
    
    print("SDL_GPU Driver: %\n", sdl_get_gpu_device_driver(g_device));
    
    init_memory_system();
    init_shader_system();
    init_renderer();
    init_texture_system();
    init_mesh_system();
    
    key_states = SDL_GetKeyboardState(null);
    SDL_SetWindowRelativeMouseMode(g_window, true);
    
    camera: Camera;
    
    old_time = current_time_monotonic();
    quit := false;
    while !quit {
        // reset to zero so the event can fill these for just one frame
        mouse.delta.x = 0;
        mouse.delta.y = 0;
        
        quit = process_window_events();
        if quit break;
        
        // update time
        {
            now := current_time_monotonic();
            delta := now - old_time;
            
            real_time_f64 = to_float64_seconds(now);
            real_delta_time_f64 = to_float64_seconds(delta);
            
            if game_paused {
                delta_time_f64 = 0.0;
            } else {
                delta_time_f64 = real_delta_time_f64;
                game_time_f64 += delta_time_f64;
            }
            
            real_time = xx real_time_f64;
            game_time = xx game_time_f64;
            real_delta_time = xx real_delta_time_f64;
            delta_time = xx delta_time_f64;
            
            old_time = now;
        }
        
        // update mouse
        {
            x, y: float;
            SDL_GetMouseState(*x, *y);
            
            pos := Vec2.{xx x, xx y};
            
            mouse.position.x = pos.x;
            mouse.position.y = pos.y;
        }
        
        update_camera(*camera);
        
        draw_frame(*camera);
        
        frame_keys.count = 0;
        arena_reset(*frame_arena);
    }
}

process_window_events :: () -> bool {
    event: SDL_Event;
    while SDL_PollEvent(*event) {
        if is_event_type(*event, .SDL_EVENT_QUIT) return true;
        
        if is_event_type(*event, .SDL_EVENT_KEY_DOWN) {
            if event.key.scancode == .ESCAPE return true;
            array_add(*frame_keys, event.key.scancode);
        } else if is_event_type(*event, .MOUSE_MOTION) {
            mouse.delta.x = xx event.motion.xrel;
            mouse.delta.y = xx event.motion.yrel;
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

key_states: *bool;

old_time: Apollo_Time;
real_time_f64, game_time_f64, real_delta_time_f64, delta_time_f64: float64;