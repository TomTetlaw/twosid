
GTotalCommittedBytes: u64; @TracyPlot

arena :: struct ($T: Type = u8) {
    Base: *u8;
	TypedBase: *T;
    Used: u64;
    Count: int;
	Capacity: u64;
    Initialized: bool;
    
    IsFixed := false;
    ParentMark: u64;
    Parent: *void; // ugh...
}

operator [] :: (Arena: *$A/arena, Index: int) -> A.T {
    return Arena.TypedBase[Index];
}

operator *[] :: (Arena: *$A/arena, Index: int) -> *A.T {
    return *Arena.TypedBase[Index];
}

InitArena :: (Arena: *$A/arena, InitialCapacity: u64 = 0, $L := #caller_location) {
    if Arena.Initialized return;
    
    Base := cast (*u8) PlatformReserve(MaxCommittedSize);
    if !Base {
        Value, text := get_error_value_and_string();
        FatalError(TFormat("Failed to create arena: error_code=%, error_string=%", Value, text));
    }
    
    if !InitialCapacity InitialCapacity = CommitExpandAmount;
    InitialCapacity = AlignPageSize(InitialCapacity);
    
    PlatformCommit(Base, 0, InitialCapacity);
	
    Arena.Base = Base;
	Arena.TypedBase = cast (*A.T) Base;
	Arena.Used = 0;
    Arena.Count = 0;
    Arena.Capacity = InitialCapacity;
    Arena.Initialized = true;
    
    Zero(Base, InitialCapacity);
}

ArenaAlloc :: (Arena: *$A/arena, Size: u64, $Align := 0, $L := #caller_location) -> *u8 {
    AlignedSize := AlignPageSize(Size + Align);
    
    if !Arena.Initialized InitArena(Arena, max(AlignedSize, CommitExpandAmount), L);
    
    if Arena.Used + Size > Arena.Capacity {
        if Arena.IsFixed {
            return null;
        }
        
        if Arena.Capacity + CommitExpandAmount >= MaxCommittedSize {
            FatalError("arena exceded max committed Size %! Wow!", MaxCommittedSize);
        }
        
        PlatformCommit(Arena.Base, Arena.Capacity, AlignedSize);
        Arena.Capacity += AlignedSize;
    }
    
    Memory := Arena.Base + Arena.Used;
    if Align > 0 Memory = (Memory + Align - 1) & ~(Align - 1);
    
    Arena.Used += Size;
    Arena.Count = xx (Arena.Used / size_of(A.T));
    
    Zero(Memory, Size);
    
    return Memory;
}

ArenaPushNull :: ($T: Type, $L := #caller_location) -> *T {
    return ArenaPush(*NullValuesArena, T, L);
}

ArenaPush :: (Arena: *$A/arena, $L := #caller_location) -> *A.T {
    Init :: initializer_of(A.T);
    
    Out := cast (*A.T) ArenaAlloc(Arena, size_of(A.T), L=L);
    
#if Init Init(Out);
    
    return Out;
}

ArenaPushN :: (Arena: *$A/arena, n: int, $L := #caller_location) -> [] A.T {
    Init :: initializer_of(A.T);
    
    Memory := cast (*A.T) ArenaAlloc(Arena, cast (u64) (size_of(A.T) * n), L=L);
    Out := []A.T.{n, Memory};
    
#if Init for * Out Init(it);
    
    return Out;
}

ArenaPush :: (Arena: *arena(u8), $T: Type, $L := #caller_location) -> *T {
    Init :: initializer_of(T);
    
    Out := cast (*T) ArenaAlloc(Arena, size_of(T), L=L);
    
#if Init Init(Out);
    
    return Out;
}

ArenaPushN :: (Arena: *arena(u8), $T: Type, n: int, $Align := 0, $L := #caller_location) -> [] T {
    Init :: initializer_of(T);
    
    Memory := cast (*T) ArenaAlloc(Arena, cast (u64) (size_of(T) * n), Align, L);
    Out := []T.{n, Memory};
    
#if Init for * Out Init(it);
    
    return Out;
}

ArenaPush :: (Arena: *arena($T), Value: T) -> *T {
    Dest := cast (*T) ArenaPush(Arena);
    Copy(Dest, *Value);
    return Dest;
}

ArenaPushN :: (Arena: *arena($T), Values: [] T) -> [] T {
    Dest := ArenaPushN(Arena, Values.count);
    Copy(Dest.data, Values.data, Values.count * size_of(T));
    return Dest;
}

ArenaPush :: (Arena: *$A/arena, $T: Type, Value: T) -> *T {
    Dest := ArenaPush(Arena, T);
    Copy(Dest, *Value);
    return Dest;
}

ArenaPushN :: (Arena: *$A/arena, $T: Type, Values: [] T) -> [] T{
    Dest := ArenaPushN(Arena, T, Values.count);
    Copy(Dest.data, Values.data, Values.count * size_of(T));
    return Dest;
}

ArenaPushView :: (Arena: *$A/arena, Values: [] $T) {
    Dest := ArenaAlloc(Arena, xx (Values.count * size_of(T)));
    Copy(Dest, Values.data, Values.count * size_of(T));
}

ArenaPushMark :: (Arena: *arena) -> u64 {
    return Arena.Used;
}

ArenaPopMark :: (Arena: *$A/arena, Mark: u64) {
    Zero(Arena.Base + Mark, Arena.Used - Mark);
    Arena.Used = Mark;
    Arena.Count = xx (Arena.Used / size_of(A.T));
}

ArenaReset :: (Arena: *arena) {
    Zero(Arena.Base, Arena.Capacity);
    Arena.Used = 0;
    Arena.Count = 0;
}

PushFixedArena :: (Arena: *$A/arena, $T: Type, N: int) -> *arena(T) {
    Mark := ArenaPushMark(Arena);
    
    Fixed := ArenaPush(Arena, arena(T));
    
    Fixed.Base = ArenaAlloc(Arena, xx (size_of(T) * N));
	Fixed.TypedBase = cast (*T) Fixed.Base;
	Fixed.Used = 0;
    Fixed.Count = 0;
    Fixed.Capacity = xx (size_of(T) * N);
    Fixed.IsFixed = true;
    Fixed.ParentMark = Mark;
    Fixed.Parent = Arena;
    Fixed.Initialized = true;
    
    return Fixed;
}

PushFixedArena :: (Arena: *$A/arena, Cap: int) -> *arena {
    Mark := ArenaPushMark(Arena);
    
    Fixed := ArenaPush(Arena, arena);
    
    Fixed.Base = ArenaAlloc(Arena, xx Cap);
	Fixed.TypedBase = Fixed.Base;
	Fixed.Used = 0;
    Fixed.Count = 0;
    Fixed.Capacity = xx Cap;
    Fixed.IsFixed = true;
    Fixed.ParentMark = Mark;
    Fixed.Parent = Arena;
    Fixed.Initialized = true;
    
    return Fixed;
}

PopFixedArena :: (Fixed: *$A/arena) {
    Arena := cast(*arena(u8)) Fixed.Parent;
    ArenaPopMark(Arena, Fixed.ParentMark);
}

ArenaToView :: (Arena: *$A/arena) -> [] A.T {
    return .{xx (Arena.Used / size_of(A.T)), Arena.TypedBase};
}

ArenaToView :: (Arena: *arena, $T: Type, Offset: u64, Size: u64) -> [] T {
    Count := cast(s64) (Size / size_of(T));
    return .{Count, cast (*T) (Arena.Base + Offset)};
}

for_expansion :: (Arena: *$A/arena, Body: Code, Flags: For_Flags) #expand {
    num := cast (int) (Arena.Used / size_of(A.T));
    
    for Index: 0..num-1 {
        ActualIndex := Index;
#if Flags & .REVERSE {
            ActualIndex = Num - 1 - Index;
        }
        
#if Flags & .POINTER {
            `it := *Arena.TypedBase[ActualIndex];
        } else {
            `it := Arena.TypedBase[ActualIndex];
        }
        
        `it_index := ActualIndex;
        
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

NullValuesArena: arena;

KB :: ($n: u64) -> u64 #expand { return n * 1024; }
MB :: ($n: u64) -> u64 #expand { return n * KB(1024); }
GB :: ($n: u64) -> u64 #expand { return n * MB(1024); }

AlignPageSize :: n => (n + (PageSize - 1)) & ~(PageSize - 1);

MaxCommittedSize: u64;
CommitExpandAmount: u64;

#if OS == .WINDOWS {
    
    windows :: #import "Windows";
    
    PageSize: u64;
    
    PlatformMemoryInit :: () {
        Info: windows.SYSTEM_INFO;
        windows.GetSystemInfo(*Info);
        
        PageSize = Info.dwPageSize;
        MaxCommittedSize = AlignPageSize(GB(64));
        CommitExpandAmount = PageSize * 16;
        GTotalCommittedBytes = 0;
    }
    
    PlatformReserve :: (Capacity: u64) -> *u8 {
        Memory := windows.VirtualAlloc(null, Capacity, windows.MEM_RESERVE, windows.PAGE_READWRITE);
        return Memory;
    }
    
    PlatformCommit :: (Memory: *u8, Offset: u64, Size: u64) {
        windows.VirtualAlloc(Memory + Offset, Size, windows.MEM_COMMIT, windows.PAGE_READWRITE);
        GTotalCommittedBytes += Size;
    }
    
} else #if OS == .LINUX {
    
#import "POSIX";
    
    PageSize: u64;
    
    PlatformMemoryInit :: () {
        PageSize = xx getpagesize();
        MaxCommittedSize = AlignPageSize(GB(64));
        CommitExpandAmount = PageSize * 16;
        GTotalCommittedBytes = 0;
    }
    
    PlatformReserve :: (Capacity: u64) -> *u8 {
        Memory := mmap(null, Capacity, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, 0, 0);
        if Memory == (cast(*void)-1) return null; // linux uses a different return Value for failed
        return Memory;
    }
    
    PlatformCommit :: (Memory: *u8, Offset: u64, Size: u64) {
        GTotalCommittedBytes += Size;
        // linux does this automatically i think?
    }
}

#import "System";