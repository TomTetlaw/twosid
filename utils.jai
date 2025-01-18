
Write :: (F: *File, Value: $T) {
    file_write(F, *Value, size_of(T));
}

Write :: (F: *File, Value: string) {
    file_write(F, *Value.count, size_of(int));
    file_write(F, Value.data, Value.count);
}

Read :: (F: *File, Value: *$T) {
    file_read(<<F, Value, size_of(T));
}

Read :: (F: *File, Value: *string) {
    Count := 0;
    file_read(<<F, *Count, size_of(int));
    S := ArenaAllocString(*WorldArena, Count);
    file_read(<<F, S.data, Count);
    Value.* = S;
}

GetHash :: (V: float4, Seed: u32) -> u32 {
    Hash := GetHash(<< (cast (*u32) *V.x), Seed);
    Hash = GetHash(<< (cast (*u32) *V.x), Hash);
    Hash = GetHash(<< (cast (*u32) *V.x), Hash);
    Hash = GetHash(<< (cast (*u32) *V.x), Hash);
    return Hash;
}

PrintVars :: print_vars;

linked_list :: struct($T: Type) {
    First, Last: *T;
    Count: int;
}

AddToLinkedList :: (List: *linked_list($T), Value: *T) {
    if !List.First {
        List.First = Value;
        List.Last = Value;
    } else {
        List.Last.Next = Value;
        Value.Prev = List.Last;
        List.Last = Value;
    }
    
    List.Count += 1;
}

ResetLinkedList :: (List: *linked_list($T)) {
    List.First = null;
    List.Last = null;
    List.Count = 0;
}

for_expansion :: (List: *linked_list($T), Body: Code, Flags: For_Flags) #expand {
    Value := List.First;
    
#if Flags & .REVERSE {
        Value = List.Last;
    }
    
    while Value {
#if Flags & .POINTER {
            `it := Value;
        } else {
            `it := <<Value;
        }
        
        `it_index := Value - List.Last;
        
#if Flags & .REVERSE {
            Value = Value.Prev;
        } else {
            Value = Value.Next;
        }
        
#insert Body;
    }
}

TAny :: (Value: *$T) -> Any {
    Memory := ArenaPush(*FrameArena, T);
    Copy(Memory, Value, size_of(T));
    
    Result: Any;
    Result.value_pointer = Memory;
    Result.type = type_info(T);
    return Result;
}

// C string
CS :: (S: string) -> *u8 {
    String := ArenaAlloc(*WorkingArena, S.count + 1);
    Copy(String, S.data, S.count);
    String[S.count] = 0;
    return String;
}

// Temp C string
TCS :: (S: string) -> *u8 {
    String := ArenaAlloc(*FrameArena, S.count + 1);
    Copy(String, S.data, S.count);
    String[S.count] = 0;
    return String;
}

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
    
    Data := ArenaAlloc(Arena, u8, Count);
    file_read(f, Data.data, Count);
    
    return .{Count, Data.data};
}

FileReadArray :: (f: *File, Arena: *arena, $T: Type, Count: int) -> [] T {
    Out := ArenaAlloc(Arena, T, Count);
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
