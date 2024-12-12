
Arena :: struct ($N: string, $T: Type = u8) {
    memory: *T;
    used, cap: u64;
    peak: u64;
    initialized: bool;
    name := N;
    _null_value: T;
    null_value: *T;
}

init_arena :: (arena: *$A/Arena, initial_cap: u64 = 0, $location := #caller_location) {
    if arena.initialized return;
    
    memory := cast (*A.T) platform_reserve(max_committed_size);
    if !memory {
        value, text := get_error_value_and_string();
        fatal_error(tprint("Failed to create arena \"%\": error_code=%, error_string=%", A.N, value, text));
    }
    
    if !initial_cap initial_cap = commit_expand_amount;
    initial_cap = align(initial_cap);
    
    platform_commit(cast (*u8) memory, 0, initial_cap);
    
    arena.memory = memory;
    arena.cap = initial_cap;
    arena.initialized = true;
    
    arena.null_value = *arena._null_value;
    memset(arena.null_value, 0, size_of(A.T)); //@todo: make this a one page circular mapping
    
#if RECORD_ALLOCATIONS {
        record: Commit_Record;
        record.location = location;
        record.arena_name = arena.name;
        record.commit_size = initial_cap;
        record.stack_trace = get_stack_trace_string(context.stack_trace);
        add_commit_record(record);
        
        arena_record: Arena_Record;
        arena_record.name = arena.name;
        arena_record.cap = *arena.cap;
        arena_record.peak = *arena.peak;
        array_add(*all_arenas, arena_record);
    }
}

arena_alloc :: (arena: *$A/Arena, size: u64, $zero := true, $type_override: Type = u8, $location := #caller_location) -> *A.T {
    aligned_size := align(size);
    
    if !arena.initialized init_arena(arena, max(aligned_size, commit_expand_amount));
    
    if arena.used + aligned_size >= arena.cap {
        if arena.cap + commit_expand_amount >= max_committed_size {
            fatal_error("Arena exceded max committed size");
        }
        
        platform_commit(cast (*u8) arena.memory, arena.cap, aligned_size);
        arena.cap += aligned_size;
        
#if RECORD_ALLOCATIONS {
            record: Commit_Record;
            record.location = location;
            record.arena_name = arena.name;
            record.commit_size = aligned_size;
            record.stack_trace = get_stack_trace_string(context.stack_trace);
            add_commit_record(record);
        }
    }
    
    memory := arena.memory + (arena.used / size_of(A.T));
    arena.used += size;
    arena.peak = max(arena.peak, arena.used);
    
#if zero memset(memory, 0, xx size);
    
#if RECORD_ALLOCATIONS {
        record: Alloc_Record;
        record.location = location;
        record.type_name = #run -> string { return tprint("%", type_override); }
        record.arena_name = arena.name;
        record.alloc_size = size;
        record.alloc_elements = size / size_of(type_override);
        record.arena_cap = arena.cap;
        record.arena_used = arena.used;
        record.stack_trace = get_stack_trace_string(context.stack_trace);
        add_alloc_record(record);
    }
    
    return memory;
}

arena_push :: (arena: *$A/Arena, $init_value := true, $location := #caller_location) -> *A.T {
    init :: initializer_of(A.T);
    zero :: !init_value || !init;
    
    out := arena_alloc(arena, size_of(A.T), zero, A.T, location);
    
#if !zero init(out);
    
    return out;
}

arena_push :: (arena: *$A/Arena, $T: Type, $init_value := true, $location := #caller_location) -> *T {
#run #if A.T != u8 && T != u8 { compiler_report(tprint("Cannot push a value of type % to an arena of non-default type %.\n", tprint("%", T), tprint("%", A.T)), location, .ERROR);
    }
    
    init :: initializer_of(T);
    zero :: !init_value || !init;
    
    out := cast (*T) arena_alloc(arena, size_of(T), zero, T, location);
    
#if !zero init(out);
    
    return out;
}

arena_push_n :: (arena: *$A/Arena, n: u64, $init_value := true, $location := #caller_location) -> [] A.T {
    init :: initializer_of(A.T);
    zero :: !init_value || !init;
    
    memory := cast (*A.T) arena_alloc(arena, size_of(A.T) * n, !init_value, A.T, location);
    out := []T.{xx n, memory};
    
#if !zero for * out init(it);
    
    return out;
}

arena_push_n :: (arena: *$A/Arena, $T: Type, n: u64, $init_value := true, $location := #caller_location) -> [] T {
#run #if A.T != u8 && T != u8 { compiler_report(tprint("Cannot push a value of type % to an arena of non-default type %.\n", tprint("%", T), tprint("%", A.T)), location, .ERROR);
    }
    
    init :: initializer_of(T);
    zero :: !init_value || !init;
    
    memory := cast (*T) arena_alloc(arena, size_of(T) * n, !init_value, T, location);
    out := []T.{xx n, memory};
    
#if !zero for * out init(it);
    
    return out;
}

operator [] :: (arena: $A/Arena, index: int) -> A.T {
    return arena.memory[index];
}

operator []= :: (arena: *$A/Arena, index: int, value: A.T) {
    arena.memory[index] = A.T;
}

for_expansion :: (arena: *$A/Arena, body: Code, flags: For_Flags) #expand {
    num := cast(int) (arena.used / size_of(A.T));
    
    for index: 0..num-1 {
#if flags & .POINTER `it := *arena.memory[index];
        else {
            print("arena % for by copy\n", arena.name);
            `it := arena.memory[index];
        }
        
        `it_index := index;
        
#insert body;
    }
}

arena_push_mark :: (arena: *Arena, $location := #caller_location) -> u64 { return arena.used; }
arena_pop_mark :: (arena: *Arena, mark: u64, $location := #caller_location) { arena.used = mark; }

arena_push_mark_defer :: (arena: *Arena, $location := #caller_location) #expand {
#insert,scope() -> string {
        builder: String_Builder;
        print_to_builder(*builder, "__arena_mark_% := arena_push_mark(arena);\n", location.line_number);
        print_to_builder(*builder, "defer arena_pop_mark(arena, __arena_mark_%);\n", location.line_number);
        return builder_to_string(*builder);
    }
}

arena_reset :: (arena: *Arena) { arena.used = 0; }

init_memory_system :: () {
    platform_memory_init();
    
#if RECORD_ALLOCATIONS {
        file_delete("memory_records.txt");
    }
    
    init_arena(*working_arena, MB(128));
    init_arena(*frame_arena, MB(128));
}

shutdown_memory_system :: () {
#if RECORD_ALLOCATIONS {
        flush_records();
        
        builder: String_Builder;
        for all_arenas {
            format :: "name: %, peak usage: %, peak capacity: %\n";
            print_to_builder(*builder, format, it.name, <<(it.peak), <<(it.cap));
        }
        
        write_entire_file("arena_records.txt", builder_to_string(*builder));
    }
}

working_arena: Arena("working");
frame_arena: Arena("frame");

#scope_file

Alloc_Record :: struct {
    location: Source_Code_Location;
    stack_trace: string;
    
    type_name: string;
    
    arena_name: string;
    
    alloc_size: u64;
    alloc_elements: u64;
    
    arena_cap: u64;
    arena_used: u64;
}

Commit_Record :: struct {
    location: Source_Code_Location;
    stack_trace: string;
    
    arena_name: string;
    commit_size: u64;
}

lines_buffer: String_Builder;

Arena_Record :: struct {
    name: string;
    peak: *u64;
    cap: *u64;
}

all_arenas: [..] Arena_Record;

#if RECORD_ALLOCATIONS {
    flush_records :: (force := false) {
        if !force {
            total_size := STRING_BUILDER_BUFFER_SIZE;
            buffer := get_base_buffer(*lines_buffer);
            while (buffer) {
                total_size += buffer.count;
                buffer = buffer.next;
            }
            
            if total_size < STRING_BUILDER_BUFFER_SIZE * 128 {
                return;
            }
        }
        
        file, ok := file_open("memory_records.txt", true, true);
        if !ok return;
        
        length := file_length(file);
        file_set_position(file, length);
        
        file_write(*file, builder_to_string(*lines_buffer));
        
        file_close(*file);
    }
    
    add_alloc_record :: (record: Alloc_Record) {
        path, base, ext := path_decomp(record.location.fully_pathed_filename);
        if equal(base, "memory") return;
        
        format :: "Allocation at t=%s, %.jai line %: arena name: %, type_name: %, alloc size: %, alloc n elements: %, arena used: %, arena capacity: %\n";
        
        print_to_builder(*lines_buffer, format, real_time, base, record.location.line_number, record.arena_name, record.type_name, record.alloc_size, record.alloc_elements, record.arena_used, record.arena_cap);
        print_to_builder(*lines_buffer, "Stack trace:\n%\n", record.stack_trace);
        
        flush_records();
    }
    
    add_commit_record :: (record: Commit_Record) {
        path, base, ext := path_decomp(record.location.fully_pathed_filename);
        
        format :: "Commit at t=%s, %.jai line %: arena name: %, commit size: %\n";
        print_to_builder(*lines_buffer, format, real_time, base, record.location.line_number, record.arena_name, record.commit_size);
        print_to_builder(*lines_buffer, "Stack trace:\n%\n", record.stack_trace);
        
        flush_records();
    }
} else {
    flush_records :: (force := false) {}
    add_alloc_record :: (record: Alloc_Record) {}
    add_commit_record :: (record: Commit_Record) {}
}

KB :: ($n: u64) -> u64 #expand { return n * 1024; }
MB :: ($n: u64) -> u64 #expand { return n * KB(1024); }
GB :: ($n: u64) -> u64 #expand { return n * MB(1024); }

align :: n => (n + (page_size - 1)) & ~(page_size - 1);

#if OS == .WINDOWS {
    
    Windows :: #import "Windows";
    
    page_size: u64;
    max_committed_size: u64;
    commit_expand_amount: u64;
    
    platform_memory_init :: () {
        info: Windows.SYSTEM_INFO;
        Windows.GetSystemInfo(*info);
        
        page_size = info.dwPageSize;
        max_committed_size = align(GB(64));
        commit_expand_amount = page_size * 16;
    }
    
    platform_reserve :: (cap: u64) -> *u8 {
        memory := Windows.VirtualAlloc(null, cap, Windows.MEM_RESERVE, Windows.PAGE_READWRITE);
        return memory;
    }
    
    platform_commit :: (memory: *u8, base: u64, size: u64) {
        
        Windows.VirtualAlloc(memory + base, size, Windows.MEM_COMMIT, Windows.PAGE_READWRITE);
    }
    
} else #if OS == .LINUX {
    
#import "POSIX";
    
    page_size: s32;
    
    platform_memory_init :: () {
        page_size = getpagesize();
        max_committed_size = align(GB(64));
        commit_expand_amount = page_size * 16;
    }
    
    platform_reserve :: (cap: u64) -> *u8 {
        memory := mmap(null, cap, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, 0, 0);
        if memory == (cast(*void)-1) return null; // linux uses a different return value for failed
        return memory;
    }
    
    platform_commit :: (memory: *u8, base: u64, size: u64) {
        // linux does this automatically i think?
    }
    
}

#import "System";
#import "Compiler";