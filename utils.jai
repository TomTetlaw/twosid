
fatal_error :: (format: string, args: ..Any) {
    builder: String_Builder;
    print_to_builder(*builder, format, ..args);
    message := builder_to_string(*builder);
    SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Fatal error!", message.data, null);
    exit(0);
}

file_read_string :: (file: *File, arena: *Arena) -> string {
    count: int;
    file_read(file, *count, size_of(int));
    
    data := arena_push_n(arena, u8, xx count);
    file_read(file, data.data, count);
    
    return .{count, data.data};
}

file_read_array :: (file: *File, arena: *Arena, $T: Type, count: int) -> [] T {
    out := arena_push_n(arena, T, xx count);
    file_read(file, out.data, count * size_of(T));
    
#if 0 {
        guard: u8;
        file_read(file, *guard, 1);
        assert(guard == #char "x");
    }
    
    
    return out;
}

sdl_get_error :: () -> string {
    return to_string(SDL_GetError());
}

sdl_get_gpu_device_driver :: (device: *SDL_GPUDevice) -> string {
    return to_string(SDL_GetGPUDeviceDriver(device));
}

is_event_type :: (event: *SDL_Event, type: SDL_EventType) -> bool {
    return event.type == cast(u32) type;
}

#scope_file

#import "Basic";