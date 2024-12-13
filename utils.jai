
 FatalError :: (Format: string, Args: ..Any) {
    Builder: String_Builder;
    print_to_builder(*Builder, Format, ..Args);
    Message := builder_to_string(*Builder);
    SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Fatal error!", Message.data, null);
    exit(0);
}

FileReadString :: (f: *File, Arena: *arena) -> string {
    Count: int;
    file_read(f, *Count, size_of(int));
    
    Data := ArenaPushN(Arena, u8, xx Count);
    file_read(f, Data.data, Count);
    
    return .{Count, Data.data};
}

FileReadArray :: (f: *File, Arena: *arena, $T: Type, Count: int) -> [] T {
    Out := ArenaPushN(Arena, T, xx Count);
    file_read(f, Out.data, Count * size_of(T));
    return Out;
}

SdlGetError:: () -> string {
    return to_string(SDL_GetError());
}

SdlGetGpuDeviceDriver :: () -> string {
    return to_string(SDL_GetGPUDeviceDriver(GDevice));
}

IsEventType :: (Event: *SDL_Event, Type: SDL_EventType) -> bool {
    return Event.type == cast(u32) Type;
}

#scope_file

#import "Basic";