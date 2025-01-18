
GTotalCommittedBytes: int; @TracyPlot

alloc_options :: struct {
    Align := 0;
    ShouldZero := true;
}

arena :: struct {
    Base: *u8;
    Used: int;
    Capacity: int;
    MaxCapacity: int;
}

arena_mark :: #type,distinct int;

InitArena :: (Arena: *arena, InitialCapacity: int = 0, $L := #caller_location) {
    if Arena.Base return;
    
    Base := cast (*u8) PlatformReserve(MaxCommittedSize);
    
    if !Base {
        Value, text := get_error_value_and_string();
        FatalError(TFormat("Failed to create arena: error_code=%, error_string=%", Value, text));
    }
    
    if !InitialCapacity InitialCapacity = CommitExpandAmount;
    InitialCapacity = AlignPageSize(InitialCapacity);
    
    PlatformCommit(Base, 0, InitialCapacity);
	
    Arena.Base = Base;
    Arena.Used = 0;
    Arena.Capacity = InitialCapacity;
    Arena.MaxCapacity = MaxCommittedSize;
    
    Zero(Base, InitialCapacity);
}

CreateSubArena :: (Arena: *arena, Capacity: int, Options := alloc_options.{}) -> *arena {
    Sub := ArenaAlloc(Arena, arena);
    Sub.Base = ArenaAlloc(Arena, Capacity, Options);
    Sub.Capacity = Capacity;
    Sub.MaxCapacity = Capacity;
    return Sub;
}

ArenaAlloc :: (Arena: *arena, Size: int, Options := alloc_options.{}, $L := #caller_location) -> *u8 {
    Size += Options.Align;
    
    AlignedSize := AlignPageSize(Size);
    ExpandAmount := max(AlignedSize, CommitExpandAmount);
    
    if !Arena.Base InitArena(Arena, ExpandAmount, L);
    
    if Arena.Used + Size > Arena.Capacity {
        if Arena.Capacity + ExpandAmount >= Arena.MaxCapacity {
            FatalError("arena exceded max capacity %", Arena.MaxCapacity);
        }
        
        PlatformCommit(Arena.Base, Arena.Capacity, ExpandAmount);
        Arena.Capacity += ExpandAmount;
    }
    
    Memory := Arena.Base + Arena.Used;
    
    if Options.Align > 0 {
        Aligned := (Memory + Options.Align - 1) & ~(Options.Align - 1);
    	Zero(Memory, Aligned - Memory); // Zero the bytes before the alignment
    	Memory = Aligned;
    }
    
    if Options.ShouldZero Zero(Memory, Size);
    
    Arena.Used += Size;
    
    return Memory;
}

ArenaAlloc :: (Arena: *arena, $T: Type, Options := alloc_options.{}, $L := #caller_location) -> *T {
    Init :: initializer_of(T);
    
    Opts := Options;
    Opts.ShouldZero = !Init;
    
    Out := cast (*T) ArenaAlloc(Arena, size_of(T), Opts, L);
    
#if Init Init(Out);
    
    return Out;
}

ArenaAllocString :: (Arena: *arena, Count: int) -> string {
    return .{Count, ArenaAlloc(Arena, Count)};
}

ArenaAlloc :: (Arena: *arena, $T: Type, N: int, Options := alloc_options.{}, $L := #caller_location) -> [] T {
    Init :: initializer_of(T);
    
    Opts := Options;
    Opts.ShouldZero = !Init;
    
    Memory := cast (*T) ArenaAlloc(Arena, size_of(T) * N, Opts, L);
    Out := []T.{N, Memory};
    
#if Init for * Out Init(it);
    
    return Out;
}

// @HACK to support reading entities
__ArenaAlloc :: (Arena: *arena, A: [] $T, N: int) -> [] T {
    return ArenaAlloc(Arena, T, N);
}

PushToArena :: (Arena: *arena, Value: $T, Options := alloc_options.{}, $L := #caller_location) -> *T #modify {
    Info := cast(*Type_Info) T;
    if Info.type == .ARRAY return false;
    else return true;
} {
    Dest := ArenaAlloc(Arena, T, Options, L);
    Copy(Dest, *Value);
    return Dest;
}

PushToArena :: (Arena: *arena, Values: [] $T, Options := alloc_options.{}, $L := #caller_location) -> [] T {
    Dest := ArenaAlloc(Arena, T, Values.count, Options, L);
    Copy(Dest.data, Values.data, Values.count * size_of(T));
    return Dest;
}

GetArenaMark :: (Arena: *arena) -> arena_mark {
    return cast(arena_mark) Arena.Used;
}

PopArenaMark :: (Arena: *arena, Mark: arena_mark) {
    Zero(Arena.Base + cast(int) Mark, Arena.Used - cast(int) Mark);
    Arena.Used = cast(int) Mark;
}

ResetArena :: (Arena: *arena) {
    Zero(Arena.Base, Arena.Capacity);
    Arena.Used = 0;
}

GetArenaElementCount :: (Arena: *arena, $T: Type, Mark: arena_mark = 0) -> int {
    return (Arena.Used - cast(int) Mark) / size_of(T);
}

ArenaToView :: inline (Arena: *arena, $T: Type, Mark: arena_mark = 0) -> [] T {
    Size := Arena.Used - cast(int) Mark;
    Count := Size / size_of(T);
    return .{Count, cast (*T) (Arena.Base + cast(int) Mark)};
}

InitMemorySystem :: () {
    PlatformMemoryInit();
    
    InitArena(*WorkingArena, MB(128));
    InitArena(*FrameArena, MB(128));
}

WorkingArena: arena;
FrameArena: arena;

#scope_file

KB :: ($n: int) -> int #expand { return n * 1024; }
MB :: ($n: int) -> int #expand { return n * KB(1024); }
GB :: ($n: int) -> int #expand { return n * MB(1024); }

AlignPageSize :: n => (n + (PageSize - 1)) & ~(PageSize - 1);

MaxCommittedSize: int;
CommitExpandAmount: int;

#if OS == .WINDOWS {
    
    windows :: #import "Windows";
    
    PageSize: int;
    
    PlatformMemoryInit :: () {
        Info: windows.SYSTEM_INFO;
        windows.GetSystemInfo(*Info);
        
        PageSize = Info.dwPageSize;
        MaxCommittedSize = AlignPageSize(GB(64));
        CommitExpandAmount = PageSize * 16;
        GTotalCommittedBytes = 0;
    }
    
    PlatformReserve :: (Capacity: int) -> *u8 {
        Memory := windows.VirtualAlloc(null, xx Capacity, windows.MEM_RESERVE, windows.PAGE_READWRITE);
        return Memory;
    }
    
    PlatformCommit :: (Memory: *u8, Offset: int, Size: int) {
        windows.VirtualAlloc(Memory + Offset, xx Size, windows.MEM_COMMIT, windows.PAGE_READWRITE);
        GTotalCommittedBytes += Size;
    }
    
} else #if OS == .LINUX {
    
    using,only(getpagesize,mmap,PROT_READ,PROT_WRITE,MAP_PRIVATE,MAP_ANONYMOUS,MAP_NORESERVE) Posix :: #import "POSIX";
    
    PageSize: int;
    
    PlatformMemoryInit :: () {
        PageSize = xx getpagesize();
        MaxCommittedSize = AlignPageSize(GB(64));
        CommitExpandAmount = PageSize * 16;
        GTotalCommittedBytes = 0;
    }
    
    PlatformReserve :: (Capacity: int) -> *u8 {
        Memory := mmap(null, xx Capacity, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE, 0, 0);
        if Memory == (cast(*void)-1) return null; // linux uses a different return Value for failed
        return Memory;
    }
    
    PlatformCommit :: (Memory: *u8, Offset: int, Size: int) {
        GTotalCommittedBytes += Size;
        // linux does this automatically i think?
    }
}

#import "System";
