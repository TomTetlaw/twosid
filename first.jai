
build_game :: (profiling: bool) {
    workspace := compiler_create_workspace("Game Build");
    options := get_build_options(workspace);
    options.output_path = "run_tree";
    options.intermediate_path = ".build/";
    options.backend = .LLVM;
    options.output_executable_name = "twosid";
    
    options.debug_for_expansions = true;
    set_optimization(*options, .VERY_DEBUG);
    
    //options.llvm_options.preserve_debug_info = true;
    //set_optimization(*options, .VERY_OPTIMIZED);
    
    options.text_output_flags = 0;
    
    plugin_names: [..] string;
    
    lib_files: [..] string;
    
#if OS == .WINDOWS {
        options.use_natvis_compatible_types = true;
        if profiling {
            array_add(*lib_files, "Advapi32.lib");
            array_add(*lib_files, "user32.lib");
            array_add(*plugin_names, "jai-tracy");
        }
    } else #if OS == .LINUX {
        array_add(*lib_files, "-lm");
    } else {
        report_error("Platform not supported.");
    }
    
    options.additional_linker_arguments = lib_files;
    
    machine_options := get_machine_options_x86(*options);
    enable_feature(*machine_options.features.leaves, .AVX);
    enable_feature(*machine_options.features.leaves, .AVX2);
    
    set_build_options(*options, workspace);
    
    plugins: [..] *Metaprogram_Plugin;
    init_plugins(plugin_names, *plugins, workspace);
    
    intercept_flags: Intercept_Flags;
    for plugins if it.before_intercept it.before_intercept(it, *intercept_flags);
    
    compiler_begin_intercept(workspace);
    
    for plugins if it.add_source it.add_source(it);
    
    add_build_string(tprint("PROFILE :: %;\n", ifx profiling then 1 else 0), workspace);
    
    files := file_list("./");
    for files {
        if !contains(it, ".jai") continue;
        if contains(it, "first.jai") continue;
        add_build_file(it, workspace);
    }
    
    plots: [..] string;
    entity_types: [..] *Type_Info_Struct;
    
    while true {
        message := compiler_wait_for_message();
        for plugins if it.message it.message(it, message);
        
        if message.kind == .TYPECHECKED {
            tc := cast (*Message_Typechecked) message;
            for tc.declarations {
                exp := it.expression;
                if profiling {
                    for n: exp.notes if equal(n.text, "TracyPlot") {
                        array_add(*plots, exp.name);
                    }
                }
            }
            
            for tc.structs {
                exp := it.expression;
                t := exp.defined_type;
                
                if is_subclass_of(t, "entity") {
                    array_add(*entity_types, t);
                }
            }
        }
        
        if message.kind == .PHASE {
            phase := cast (*Message_Phase) message;
            if phase.phase == .TYPECHECKED_ALL_WE_CAN break;
        }
        
        if message.kind == .COMPLETE break;
    }
    
    if profiling {
        builder: String_Builder;
        append(*builder, "#import \"jai-tracy\" (IMPORT_MODE=.CLIENT);\n");
        append(*builder, "EmitProfilingData :: () {\n");
        for plots {
            print_to_builder(*builder, "___tracy_emit_plot(TCS(\"%\"), cast (float64) %);\n", it, it);
        }
        append(*builder, "__Tracy.FrameMark();\n");
        append(*builder, "}\n");
        add_build_string(builder_to_string(*builder), workspace);
    }
    
    {
        builder: String_Builder;
        
        append(*builder, "entity_types :: struct {\n");
        append(*builder, "\tInfoList: [] *entity_type_info;\n");
        
        for entity_types {
            print_to_builder(*builder, "\t%: entity_type_info;\n", convert_case(it.name));
        }
        
        append(*builder, "}\n\n");
        
        append(*builder, "BuildEntityTypeList :: (Arena: *arena) {\n");
        print_to_builder(*builder, "\tGEntityTypes.InfoList = ArenaAlloc(Arena, *entity_type_info, %);\n", entity_types.count);
        for entity_types {
            print_to_builder(*builder, "\tGEntityTypes.%1 = .{\"%1\", %2, .{}, size_of(%3), .{}};\n", convert_case(it.name), it_index, it.name);
        }
        for entity_types {
            print_to_builder(*builder, "\tGEntityTypes.InfoList[%] = *GEntityTypes.%;\n", it_index, convert_case(it.name));
        }
        append(*builder, "}\n\n");
        
        append(*builder, "EntityTypeId :: ($T: Type) -> int {\n");
        for entity_types {
            print_to_builder(*builder, "\tif T == % return %;\n", it.name, it_index);
        }
        append(*builder, "\tAssert(false);\n");
        append(*builder, "\treturn -1;\n");
        append(*builder, "}\n\n");
        
        append(*builder, "CreateEntityFromName :: (Name: string) -> *entity {\n");
        for entity_types {
            print_to_builder(*builder, "\tif equal(Name, \"%\") return CreateEntity(%);\n", convert_case(it.name), it.name);
        }
        append(*builder, "\treturn null;\n");
        append(*builder, "}\n\n");
        
        T: Table(string, [] entity_member);
        for entity_types {
            BuildMemberList(it, *T);
        }
        
        append(*builder, "WriteEntity :: (F: *File, Entity: *entity) {\n");
        
        Members, Found := table_find(*T, "entity");
        if Found {
            BuildWriteCode(*builder, "Entity", Members, *T, 1);
        }
        
        for entity_types {
            if it_index > 0 {
                append(*builder, " else ");
            } else {
                append(*builder, "\t");
            }
            
            print_to_builder(*builder, "if Entity.TypeId == % {\n", it_index);
            print_to_builder(*builder, "\t\tE := DownCast(Entity, %);\n", it.name);
            
            Members, Found := table_find(*T, it.name);
            if Found {
                BuildWriteCode(*builder, "E", Members, *T, 2);
            }
            
            append(*builder, "\t}");
            
            if it_index == entity_types.count-1 {
                append(*builder, "\n");
            }
        }
        
        append(*builder, "}\n\n");
        
        append(*builder, "ReadEntity :: (F: *File, Entity: *entity) {\n");
        
        Members, Found = table_find(*T, "entity");
        if Found {
            BuildReadCode(*builder, "Entity", Members, *T, 1);
        }
        
        for entity_types {
            if it_index > 0 {
                append(*builder, " else ");
            } else {
                append(*builder, "\t");
            }
            
            print_to_builder(*builder, "if Entity.TypeId == % {\n", it_index);
            print_to_builder(*builder, "\t\tE := DownCast(Entity, %);\n", it.name);
            
            Members, Found := table_find(*T, it.name);
            if Found {
                BuildReadCode(*builder, "E", Members, *T, 2);
            }
            
            append(*builder, "\t}");
            
            if it_index == entity_types.count-1 {
                append(*builder, "\n");
            }
        }
        
        append(*builder, "}\n\n");
        
        add_build_string(builder_to_string(*builder), workspace);
    }
    
    compiler_end_intercept(workspace);
    
    for plugins if it.finish it.finish(it);
    for plugins if it.shutdown it.shutdown(it);
}

BuildWriteCode :: (Builder: *String_Builder, Name: string, Members: [] entity_member, T: *Table, Depth: int) {
    WriteTabs :: (Builder: *String_Builder, N: int) {
        for 0..N-1 {
            append(Builder, "\t");
        }
    }
    
    for M: Members {
        if equal(Name, "E.Base") continue;
        
        if M.Kind == {
            case .FIELD;
            WriteTabs(Builder, Depth);
            print_to_builder(Builder, "Write(F, %.%);\n", Name, M.Name);
            
            case .ARRAY;
            S, F := table_find(T, M.ElementType);
            WriteTabs(Builder, Depth);
            print_to_builder(Builder, "Write(F, %.%.count);\n", Name, M.Name);
            
            if F {
                WriteTabs(Builder, Depth);
                print_to_builder(Builder, "for %.% {\n", Name, M.Name);
                BuildWriteCode(Builder, "it", S, T, Depth + 1);
                WriteTabs(Builder, Depth);
                append(Builder, "}\n");
            } else {
                WriteTabs(Builder, Depth);
                print_to_builder(Builder, "for %.% {\n", Name, M.Name);
                WriteTabs(Builder, Depth + 1);
                append(Builder, "Write(F, it);\n");
                WriteTabs(Builder, Depth);
                append(Builder, "}\n");
            }
            
            case .STRUCT;
            S, F := table_find(T, M.ElementType);
            if F {
                BuildWriteCode(Builder, tprint("%.%", Name, M.Name), S, T, Depth);
            }
        }
    }
}

BuildReadCode :: (Builder: *String_Builder, Name: string, Members: [] entity_member, T: *Table, Depth: int) {
    WriteTabs :: (Builder: *String_Builder, N: int) {
        for 0..N-1 {
            append(Builder, "\t");
        }
    }
    
    for M: Members {
        if equal(Name, "E.Base") continue;
        
        if M.Kind == {
            case .FIELD;
            if M.Read {
                WriteTabs(Builder, Depth);
                print_to_builder(Builder, "Read(F, *%.%);\n", Name, M.Name);
            }
            
            case .ARRAY;
            S, F := table_find(T, M.ElementType);
            WriteTabs(Builder, Depth);
            print_to_builder(Builder, "%Count := 0;\n", M.Name);
            WriteTabs(Builder, Depth);
            print_to_builder(Builder, "Read(F, *%Count);\n", M.Name);
            WriteTabs(Builder, Depth);
            print_to_builder(Builder, "%1.%2 = __ArenaAlloc(*WorldArena, %1.%2, %2Count);\n", Name, M.Name);
            if F {
                WriteTabs(Builder, Depth);
                print_to_builder(Builder, "for 0..%Count-1 {\n", M.Name);
                BuildReadCode(Builder, tprint("%.%[it]", Name, M.Name), S, T, Depth + 1);
                WriteTabs(Builder, Depth);
                append(Builder, "}\n");
            } else {
                WriteTabs(Builder, Depth);
                print_to_builder(Builder, "for 0..%Count-1 {\n", M.Name);
                WriteTabs(Builder, Depth + 1);
                print_to_builder(Builder, "Read(F, *%.%[it]);\n", Name, M.Name);
                WriteTabs(Builder, Depth);
                append(Builder, "}\n");
            }
            
            case .STRUCT;
            S, F := table_find(T, M.ElementType);
            if F {
                BuildReadCode(Builder, tprint("%.%", Name, M.Name), S, T, Depth);
            }
        }
    }
}

entity_member_kind :: enum {
    FIELD;
    STRUCT;
    ARRAY;
}

entity_member :: struct {
    Name: string;
    Kind := entity_member_kind.FIELD;
    ElementType: string;
    Read: bool;
}

BuildMemberList :: (Info: *Type_Info_Struct, T: *Table) {
    List: [..] entity_member;
    
    for Info.members {
        if it.flags & .CONSTANT continue;
        
        if it.type.type == .POINTER continue;
        
        Filter := false;
        NamesToFilter := string.["Rows", "Coef", "Floats", "xy", "yz", "zw", "xyz", "yzw", "Components"];
        
        for N: NamesToFilter {
            if ends_with(it.name, N) {
                Filter = true;
                break;
            }
        }
        
        if Filter continue;
        
        if array_find(it.notes, "noserialize") continue;
        
        Read := true;
        if array_find(it.notes, "noread") Read = false;
        
        SimpleTypes := string.["float2", "float3", "float4", "quat", "float4x4"];
        
        S := cast (*Type_Info_Struct) it.type;
        
        if it.type.type == .STRUCT && !array_find(SimpleTypes, S.name) {
            
            if !table_contains(T, S.name) {
                BuildMemberList(S, T);
            }
            
            array_add(*List, .{Name=it.name, Kind=.STRUCT, ElementType=S.name, Read=Read});
        } else {
            Kind := entity_member_kind.FIELD;
            ElementType := "";
            
            if it.type.type == .ARRAY {
                Kind = .ARRAY;
                
                Info := cast (*Type_Info_Array) it.type;
                S := cast (*Type_Info_Struct) Info.element_type;
                if Info.element_type.type == .STRUCT && !array_find(SimpleTypes, S.name) {
                    ElementType = S.name;
                    if !table_contains(T, S.name) {
                        BuildMemberList(S, T);
                    }
                }
            }
            
            array_add(*List, .{Name=it.name, Kind=Kind, ElementType=ElementType, Read=Read});
        }
    }
    
    table_add(T, Info.name, List);
}

convert_case :: (name: string) -> string {
    capitalise_next := false;
    
    builder: String_Builder;
    
    initial := replace(name, "entity", "");
    for initial {
        if it == #char "_" {
            capitalise_next = true;
        } else {
            if capitalise_next {
                append(*builder, to_upper(it));
                capitalise_next = false;
            } else {
                append(*builder, it);
            }
        }
    }
    
    return builder_to_string(*builder);
}

build :: () {
    args := get_build_options().compile_time_command_line;
    
    generate_sdl_bindings := false;
    profiling := false;
    
    for args {
        if contains(it, "prof") profiling = true;
    }
    
    build_game(profiling);
    
    set_build_options_dc(.{do_output = false});
}

#run build();

#scope_file

#import "Basic";
#import "Compiler";
#import "String";
#import "File";
#import "File_Utilities";
#import "Process";
#import "Command_Line";
#import "Bindings_Generator";
#import "Hash_Table";
#import "Metaprogram_Plugins";
#import "Machine_X64";