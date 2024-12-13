
arena :: struct ($T: Type = u8) {
    Base: *u8;
	TypedBase: *T;
    Used: u64;
	Capacity: u64;
    Initialized: bool;
    NullValue: T;
}

InitArena :: (Arena: *$A/arena, InitialCapacity: u64 = 0, $Location := #caller_location) {
    if Arena.Initialized return;
    
    Base := cast (*u8) PlatformReserve(MaxCommittedSize);
    if !Base {
        Value, text := get_error_value_and_string();
        FatalError(tprint("Failed to create arena: error_code=%, error_string=%", Value, text));
    }
    
    if !InitialCapacity InitialCapacity = CommitExpandAmount;
	InitialCapacity += size_of(A.T);
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

ArenaPush :: (Arena: *$A/arena, $InitValue := true) -> *A.T {
    Init :: initializer_of(A.T);
    Zero :: !InitValue || !Init;
    
    Out := cast(*A.T) ArenaAlloc(Arena, size_of(A.T), Zero);
    
#if !Zero Init(Out);
    
    return Out;
}

ArenaPush :: (Arena: *$A/arena, $T: Type, $InitValue := true) -> *T {
#run #if A.T != u8 && T != u8 { compiler_report(tprint("Cannot push a Value of Type % to an arena of non-default Type %.\n", tprint("%", T), tprint("%", A.T)), Location, .ERROR);
    }
    
    Init :: initializer_of(T);
    Zero :: !InitValue || !Init;
    
    Out := cast (*T) ArenaAlloc(Arena, size_of(T), Zero);
    
#if !Zero Init(Out);
    
    return Out;
}

ArenaPushN :: (Arena: *$A/arena, n: u64, $InitValue := true) -> [] A.T {
    Init :: initializer_of(A.T);
    Zero :: !InitValue || !Init;
    
    Memory := cast (*A.T) ArenaAlloc(Arena, size_of(A.T) * n, !InitValue);
    Out := []T.{xx n, Memory};
    
#if !Zero for * Out Init(it);
    
    return Out;
}

ArenaPushN :: (Arena: *$A/arena, $T: Type, n: u64, $InitValue := true) -> [] T {
#run #if A.T != u8 && T != u8 { compiler_report(tprint("Cannot push a Value of Type % to an arena of non-default Type %.\n", tprint("%", T), tprint("%", A.T)), Location, .ERROR);
    }
    
    Init :: initializer_of(T);
    Zero :: !InitValue || !Init;
    
    Memory := cast (*T) ArenaAlloc(Arena, size_of(T) * n, !InitValue);
    Out := []T.{xx n, Memory};
    
#if !Zero for * Out Init(it);
    
    return Out;
}

operator [] :: (Arena: $A/arena, Index: int) -> A.T {
    return Arena.Memory[Index];
}

operator []= :: (Arena: *$A/arena, Index: int, Value: A.T) {
    Arena.Memory[Index] = A.T;
}

for_expansion :: (Arena: *$A/arena, Body: Code, Flags: For_Flags) #expand {
    num := cast(int) (Arena.Used / size_of(A.T));
    
    for Index: 0..num-1 {
#if Flags & .POINTER `it := *Arena.TypedBase[Index];
        else {
            print("arena % for by copy\n", Arena.Name);
            `it := Arena.TypedBase[Index];
        }
        
        `it_index := Index;
        
#insert Body;
    }
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