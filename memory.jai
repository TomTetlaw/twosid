
Arena :: struct {
    memory: *u8;
    used, cap: u64 = 0;
}

create_arena :: (initial_cap := COMMIT_EXPAND_AMOUNT) -> Arena {
    memory := platform_reserve(MAX_COMMITTED_SIZE);
    if !memory {
        value, text := get_error_value_and_string();
        fatal_error(tprint("Failed to create arena: error_code=%, error_string=%", value, text));
    }
    
    platform_commit(memory, 0, initial_cap);
    
    arena: Arena;
    arena.memory = memory;
    arena.cap = initial_cap;
    return arena;
}

arena_alloc :: (arena: *Arena, size: u64, $zero := true) -> *void {
    if arena.used + size >= arena.cap {
        if arena.cap + COMMIT_EXPAND_AMOUNT >= MAX_COMMITTED_SIZE fatal_error("Arena exceded max committed size");
        
        remainder := size % COMMIT_EXPAND_AMOUNT;
        commit_size := size;
        if remainder != 0 commit_size += COMMIT_EXPAND_AMOUNT - remainder;
        
        platform_commit(arena.memory, arena.cap, commit_size);
        arena.cap += commit_size;
    }
    
    memory := arena.memory + arena.used;
#if zero memset(memory, 0, xx size);
    arena.used += size;
    return memory;
}

arena_push :: (arena: *Arena, $T: Type, $init_value := true) -> *T {
    out := arena_alloc(arena, size_of(T), false);
#if init_value {
        init :: initializer_of(T);
#if init init(out);
    }
    return out;
}

arena_push_n :: (arena: *Arena, $T: Type, n: u64, $init_value := true) -> [] T {
    memory := arena_alloc(arena, size_of(T) * n, false);
    out := []T.{xx n, memory};
#if init_value {
        init :: initializer_of(T);
#if init {
            for * out init(it);
        }
    }
    return out;
}

arena_push_mark :: (arena: *Arena) -> u64 { return arena.used; }
arena_pop_mark :: (arena: *Arena, mark: u64) { arena.used = mark; }

arena_push_mark_defer :: (arena: *Arena) #expand {
    `__arena_mark := arena_push_mark(arena);
    defer arena_pop_mark(arena, __arena_mark);
}

arena_reset :: (arena: *Arena) { arena.used = 0; }

Typed_Arena :: struct ($T: Type) {
    using #as arena: Arena;
}

create_typed_arena :: ($T: Type, initial_cap: u64 = 128) -> Typed_Arena(T) {
    return .{create_arena(size_of(T) * initial_cap)};
}

arena_push :: (arena: *Typed_Arena($T)) -> *T {
    return arena_push(arena, T);
}

for_expansion :: (arena: *Typed_Arena($T), body: Code, flags: For_Flags) #expand {
    num := cast(int) (arena.used / size_of(T));
    for index: 0..num-1 {
        `it := cast (*T) (arena.memory + index * size_of(T));
        `it_index := index;
#insert body;
    }
}

init_memory_system :: () {
    working_arena = create_arena();
    frame_arena = create_arena();
}

working_arena: Arena;
frame_arena: Arena;

#scope_file

#import "System";

#if OS == .WINDOWS {
    
    Windows :: #import "Windows";
    
    PAGE_SIZE :: 4096;
    
    platform_reserve :: (cap: u64) -> *u8 {
        memory := Windows.VirtualAlloc(null, cap, Windows.MEM_RESERVE, Windows.PAGE_READWRITE);
        return memory;
    }
    
    platform_commit :: (memory: *u8, base: u64, size: u64) {
        Windows.VirtualAlloc(memory + base, size, Windows.MEM_COMMIT, Windows.PAGE_READWRITE);
    }
    
} else #if OS == .LINUX {
    
#import "POSIX";
    
    PAGE_SIZE :: 4096;
    
    platform_reserve :: (cap: u64) -> *u8 {
        memory := mmap(null, cap, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, 0, 0);
        if memory == (cast(*void)-1) return null; // linux uses a different return value for failed
        return memory;
    }
    
    platform_commit :: (memory: *u8, base: u64, size: u64) {
    }
    
}

MAX_COMMITTED_SIZE :u64: 1024*1024*1024*4;
COMMIT_EXPAND_AMOUNT :u64: 1024*1024;