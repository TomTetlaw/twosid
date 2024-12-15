
arena :: struct ($T: Type = u8) {
    Base: *u8;
	TypedBase: *T;
    Used: u64;
	Capacity: u64;
    Initialized: bool;
    NullValue: T;
}

InitArena :: (Arena: *$A/arena, InitialCapacity: u64 = 0) {
    if Arena.Initialized return;
    
    Base := cast (*u8) PlatformReserve(MaxCommittedSize);
    if !Base {
        Value, text := get_error_value_and_string();
        FatalError(tprint("Failed to create arena: error_code=%, error_string=%", Value, text));
    }
    
    if !InitialCapacity InitialCapacity = CommitExpandAmount;
    InitialCapacity = Align(InitialCapacity);
    
    PlatformCommit(Base, 0, InitialCapacity);
	
    Arena.Base = Base;
	Arena.TypedBase = cast (*A.T) Base;
	Arena.Used = 0;
    Arena.Capacity = InitialCapacity;
    Arena.Initialized = true;
	memset(*Arena.NullValue, 0, size_of(A.T));
}

ArenaAlloc :: (Arena: *$A/arena, Size: u64, $Zero := true) -> *u8 {
    AlignedSize := Align(Size);
    
    if !Arena.Initialized InitArena(Arena, max(AlignedSize, CommitExpandAmount));
    
    if Arena.Used + AlignedSize >= Arena.Capacity {
        if Arena.Capacity + CommitExpandAmount >= MaxCommittedSize {
            FatalError("arena exceded max committed Size %! Wow!", MaxCommittedSize);
        }
        
        PlatformCommit(Arena.Base, Arena.Capacity, AlignedSize);
        
        Arena.Capacity += AlignedSize;
    }
    
    Memory := Arena.Base + Arena.Used;
    Arena.Used += Size;
    
#if Zero memset(Memory, 0, xx Size);
    
    return Memory;
}

ArenaPush :: (Arena: *$A/arena, $Initialize := true) -> *A.T {
    Init :: initializer_of(A.T);
    Zero :: !Init || Initialize;
    
    Out := cast(*A.T) ArenaAlloc(Arena, size_of(A.T), Zero);
    
#if !Zero && Initialize Init(Out);
    
    return Out;
}

ArenaPush :: (Arena: *$A/arena, $T: Type, $Initialize := true) -> *T {
#run #if A.T != u8 && T != u8 { compiler_report(tprint("Cannot push a Value of Type % to an arena of non-default Type %.\n", tprint("%", T), tprint("%", A.T)), Location, .ERROR);
    }
    
    Init :: initializer_of(T);
    Zero :: !Init || Initialize;
    
    Out := cast (*T) ArenaAlloc(Arena, size_of(T), Zero);
    
#if !Zero && Initialize Init(Out);
    
    return Out;
}

ArenaPushN :: (Arena: *$A/arena, n: int, $Initialize := true) -> [] A.T {
    Init :: initializer_of(A.T);
    Zero :: !Init || Initialize;
    
    Memory := cast (*A.T) ArenaAlloc(Arena, cast (u64) (size_of(A.T) * n));
    Out := []A.T.{n, Memory};
    
#if !Zero && Initialize for * Out Init(it);
    
    return Out;
}

ArenaPushN :: (Arena: *$A/arena, $T: Type, n: int, $Initialize := true) -> [] T {
#run #if A.T != u8 && T != u8 { compiler_report(tprint("Cannot push a Value of Type % to an arena of non-default Type %.\n", tprint("%", T), tprint("%", A.T)), Location, .ERROR);
    }
    
    Init :: initializer_of(T);
    Zero :: !Init || Initialize;
    
    Memory := cast (*T) ArenaAlloc(Arena, cast (u64) (size_of(T) * n), Zero);
    Out := []T.{n, Memory};
    
#if !Zero && Initialize for * Out Init(it);
    
    return Out;
}

for_expansion :: (Arena: *$A/arena, Body: Code, Flags: For_Flags) #expand {
    num := cast (int) (Arena.Used / size_of(A.T));
    
    for Index: 0..num-1 {
#if Flags & .POINTER `it := *Arena.TypedBase[Index];
        else `it := Arena.TypedBase[Index];
        
        `it_index := Index;
        
#insert Body;
    }
}

ArenaPushMark :: (Arena: *arena) -> u64 {
    return Arena.Used;
}

ArenaPopMark :: (Arena: *arena, Mark: u64) {
    Arena.Used = Mark;
}

ArenaPushMarkDefer :: (Arena: *arena, $Location := #caller_location) #expand {
#insert,scope() -> string {
        Builder: String_Builder;
        print_to_builder(*Builder, "__arena_mark_% := Arena.Used;\n", Location.line_number);
        print_to_builder(*Builder, "defer Arena.Used = __arena_mark_%;\n", Location.line_number);
        return builder_to_string(*Builder);
    }
}

ArenaReset :: (Arena: *arena) { Arena.Used = 0; }

arena_array:: struct($T: Type, $N := 32) {
    Slots: arena(T);
    OccupiedSlots: arena(bool);
    Initialized: bool;
    
    Elements: int; // The actual number of indexable Ts in the array
    Count: int; // The number of added Ts in the array that are occupied
}

ArrayInit :: (Array: *$A/arena_array) {
    InitArena(*Array.Slots, size_of(A.T) * A.N);
    InitArena(*Array.OccupiedSlots, size_of(bool) * A.N);
    
    Array.Slots.Used = size_of(A.T) * A.N;
    Array.OccupiedSlots.Used = size_of(A.T) * A.N;
    
    Array.Elements = A.N;
    
    Array.Count = 0;
    
    Array.Initialized = true;
}

ArrayFindFreeSlot :: (Array: *$A/arena_array) -> int {
    for 0..Array.Elements-1 {
        if !Array.OccupiedSlots.TypedBase[it] return it;
    }
    
    return -1;
}

ArrayAdd :: (Array: *$A/arena_array, Value: A.T) {
    Slot := ArrayPush(Array);
    memcpy(Slot, *Value, size_of(A.T));
}

ArrayPush :: (Array: *$A/arena_array, $Initialize := true) -> *A.T {
    if !Array.Initialized ArrayInit(Array);
    
    SlotIndex := ArrayFindFreeSlot(Array);
    Slot: *A.T;
    if SlotIndex == -1 {
        Slot = ArenaPush(*Array.Slots, Initialize);
        Occupied := ArenaPush(*Array.OccupiedSlots);
        Occupied.* = true;
        Array.Elements += 1;
    } else {
        Slot = *Array.Slots.TypedBase[SlotIndex];
        Array.OccupiedSlots.TypedBase[SlotIndex] = true;
    }
    
    Array.Count += 1;
    return Slot;
}

ArrayAdd :: (Array: *$A/arena_array, Other: *arena_array(A.T)) {
    for Other {
        ArrayAdd(Array, it);
    }
}

ArrayRemove :: (Array: *$A/arena_array, SlotIndex: int) {
    if SlotIndex < 0 || SlotIndex >= Array.Elements return;
    Arena.OccupiedSlots[SlotIndex] = false;
    Array.Count -= 1;
}

ArrayReset :: (Array: *$A/arena_array) {
    ArenaReset(*Array.Slots);
    ArenaReset(*Array.OccupiedSlots);
    
    for 0..Array.Elements-1 {
        Array.OccupiedSlots.TypedBase[it] = false;
    }
    
    Array.Count = 0;
}

// This will return an array view.
//     If the arena_array has free slots, then
//     we need to collapse it into a flat array
//     with no gaps. This is a slower path but 
//     it probably won't happen that often?
//
//     The flat array view will be allocated
//     by the provided arena, or by the frame
//     arena if none is provided. Don't expect
//     to hold onto this array view forever!

ArrayToView :: (Array: *$A/arena_array, Arena: *arena(u8) = null) -> [] A.T {
    if !Arena Arena = *FrameArena;
    
    Flat := ArenaPushN(Arena, A.T, Array.Count);
    
    Index := 0;
    for Array {
        Flat[Index] = it;
        Index += 1;
    }
    
    return Flat;
}

operator [] :: (Array: *$A/arena_array, Index: int) -> A.T {
    return Array.Slots.TypedBase[Index];
}

// When indexing an arena_array, `it_index` == the slot index, occupied or not.
//     If you're building a flat array from this arena_array in a for loop,
//     you'll have to track the destination index yourself.

for_expansion :: (Array: *$A/arena_array, Body: Code, Flags: For_Flags) #expand {
    for Index: 0..Array.Elements-1 {
        if !Array.OccupiedSlots.TypedBase[Index] continue;
        
#if Flags & .POINTER `it := *Array.Slots.TypedBase[Index];
        else `it := Array.Slots.TypedBase[Index];
        
        `it_index := Index;
        
#insert Body;
    }
}

InitMemorySystem :: () {
    PlatformMemoryInit();
    
    InitArena(*WorkingArena, MB(128));
    InitArena(*FrameArena, MB(128));
}

WorkingArena: arena;
FrameArena: arena;

#scope_file

KB :: ($n: u64) -> u64 #expand { return n * 1024; }
MB :: ($n: u64) -> u64 #expand { return n * KB(1024); }
GB :: ($n: u64) -> u64 #expand { return n * MB(1024); }

Align :: n => (n + (PageSize - 1)) & ~(PageSize - 1);

#if OS == .WINDOWS {
    
    windows :: #import "Windows";
    
    PageSize: u64;
    MaxCommittedSize: u64;
    CommitExpandAmount: u64;
    
    PlatformMemoryInit :: () {
        Info: windows.SYSTEM_INFO;
        windows.GetSystemInfo(*Info);
        
        PageSize = Info.dwPageSize;
        MaxCommittedSize = Align(GB(64));
        CommitExpandAmount = PageSize * 16;
    }
    
    PlatformReserve :: (Capacity: u64) -> *u8 {
        Memory := windows.VirtualAlloc(null, Capacity, windows.MEM_RESERVE, windows.PAGE_READWRITE);
        return Memory;
    }
    
    PlatformCommit :: (Memory: *u8, Offset: u64, Size: u64) {
        windows.VirtualAlloc(Memory + Offset, Size, windows.MEM_COMMIT, windows.PAGE_READWRITE);
    }
    
} else #if OS == .LINUX {
    
#import "POSIX";
    
    PageSize: s32;
    
    PlatformMemoryInit :: () {
        PageSize = getpagesize();
        MaxCommittedSize = Align(GB(64));
        CommitExpandAmount = PageSize * 16;
    }
    
    PlatformReserve :: (Capacity: u64) -> *u8 {
        Memory := mmap(null, Capacity, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, 0, 0);
        if Memory == (cast(*void)-1) return null; // linux uses a different return Value for failed
        return Memory;
    }
    
    PlatformCommit :: (Memory: *u8, Offset: u64, Size: u64) {
        // linux does this automatically i think?
    }
    
}

#import "System";
#import "Compiler";