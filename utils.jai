
 Initialize :: (Value: *$T) {
    Zero(Value);
    
    I :: initializer_of(T);
#if I I(Value);
}

GetHash :: (V: float4, Seed: u32) -> u32 {
    Hash := GetHash(<< (cast (*u32) *V.x), Seed);
    Hash = GetHash(<< (cast (*u32) *V.x), Hash);
    Hash = GetHash(<< (cast (*u32) *V.x), Hash);
    Hash = GetHash(<< (cast (*u32) *V.x), Hash);
    return Hash;
}

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
    String := ArenaAlloc(*WorkingArena, xx (S.count + 1));
    Copy(String, S.data, S.count);
    String[S.count] = 0;
    return String;
}

// Temp C string
TCS :: (S: string) -> *u8 {
    String := ArenaAlloc(*FrameArena, xx (S.count + 1));
    Copy(String, S.data, S.count);
    String[S.count] = 0;
    return String;
}

for_expansion :: (List: *linked_list($T), Body: Code, Flags: For_Flags) #expand {
    Value := List.First;
    Index := 0;
    
#if Flags & .REVERSE {
        Value = List.Last;
        Index = List.Last - List.First;
    }
    
    while Value {
#if Flags & .POINTER {
            `it := Value;
        } else {
            `it := <<Value;
        }
        
        `it_index := Index;
        
#insert Body;
        
#if Flags & .REVERSE {
            Value = Value.Prev;
            Index -= 1;
        } else {
            Value = Value.Next;
            Index += 1;
        }
    }
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