
 Zero :: (Memory: *void, Size: u64) {
    memset(Memory, 0, xx Size);
}

Zero :: (Memory: *void, Size: int) {
    memset(Memory, 0, Size);
}

Zero :: (Memory: *$T) {
    memset(Memory, 0, size_of(T));
}

Copy :: (Dest: *void, Source: *void, Size: u64) {
    memcpy(Dest, Source, xx Size);
}

Copy :: (Dest: *void, Source: *void, Size: int) {
    memcpy(Dest, Source, Size);
}

Copy :: (Dest: *$T, Source: *T) {
    memcpy(Dest, Source, size_of(T));
}

Set :: (Dest: *void, Value: u8, Size: u64) {
    memset(Dest, Value, xx Size);
}

Set :: (Dest: *void, Value: u8, Size: int) {
    memset(Dest, Value, Size);
}

MemCompare :: (a: *void, b: *void, Size: u64) -> s16 {
    return memcmp(a, b, xx Size);
}

MemCompare :: (a: *void, b: *void, Size: int) -> s16 {
    return memcmp(a, b, xx Size);
}

Format :: (Format: string, Args: ..Any) -> string {
    Builder: String_Builder;
    print_to_builder(*Builder, Format, ..Args);
    return builder_to_string(*Builder);
}

TFormat :: tprint;

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

TracyPlot :: (Name: string, Value: $T) {
    ___tracy_emit_plot(Name.data, cast(float64) Value);
}

GetHash :: get_hash;

Assert :: assert;

#scope_file

#import "Basic";
#import "Hash";