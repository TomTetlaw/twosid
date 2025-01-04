
COMMAND_FORMAT :: "%1/SDL_shadercross/shadercross.exe %1/%2 -s HLSL -d %3 -t %5 -e %5_main -o %1/run_tree/shaders/%4.%5.%3 -D%6_SHADER";

compile_shaders_for_format :: (output_format: string) {
    print("Compiling all shaders for format: %\n", output_format);
    
    files := file_list("./");
    shader_files: [..] string;
    for files {
        if !contains(it, ".shader") continue;
        if contains(it, "shared.shader") continue;
        
        array_add(*shader_files, it);
    }
    
    for shader_files {
        path, base_name, ext := path_decomp(it);
        
        file_name := tprint("%.%", base_name, ext);
        
        working_dir := get_working_directory();
        
        vert_string := tprint(COMMAND_FORMAT, working_dir, file_name, output_format, base_name, "vertex", "VERTEX");
        frag_string := tprint(COMMAND_FORMAT, working_dir, file_name, output_format, base_name, "fragment", "FRAGMENT");
        
        vert_args := break_command_into_strings(vert_string);
        frag_args := break_command_into_strings(frag_string);
        
        vert_res, vert_out, vert_err := run_command(..vert_args, "", true, true);
        frag_res, frag_out, frag_err := run_command(..frag_args, "", true, true);
        
        if !vert_err && !frag_err {
            print("\t% -> %, %\n", file_name, tprint("%.%_vert", base_name, output_format), tprint("%.%_frag", base_name, output_format));
        }
    }
}

build_game :: (profiling: bool) {
    workspace := compiler_create_workspace("Game Build");
    options := get_build_options(workspace);
    options.output_path = "run_tree";
    options.intermediate_path = ".build/";
    options.backend = .LLVM;
    options.output_executable_name = "twosid";
    //options.debug_for_expansions = true;
    set_optimization(*options, .VERY_DEBUG);
    
    //set_optimization(*options, .VERY_OPTIMIZED);
    //options.llvm_options.preserve_debug_info = true;
    
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
    } else {
        report_error("Platform not supported.");
    }
    
    array_add(*lib_files, "Shell32.lib");
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
                if is_subclass_of(t, "entity") array_add(*entity_types, t);
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
            print_to_builder(*builder, "___tracy_emit_plot(\"%\".data, cast (float64) %);\n", it, it);
        }
        append(*builder, "__Tracy.FrameMark();\n");
        append(*builder, "}\n");
        add_build_string(builder_to_string(*builder), workspace);
    }
    
    {
        builder: String_Builder;
        
        append(*builder, "entity_types :: struct {\n");
        append(*builder, "\tInfoList: [] entity_type_info;\n");
        for entity_types {
            print_to_builder(*builder, "\t%: arena(%);\n", convert_case(it.name), it.name);
        }
        append(*builder, "}\n\n");
        
        append(*builder, "CreateEntityTypeInfo :: (EntityInfo: *entity_types) {\n");
        append(*builder, "\tEntityTypesList: [..] entity_type_info;\n");
        for entity_types {
            print_to_builder(*builder, "\tarray_add(*EntityTypesList, .{\"%2\", %1, *EntityInfo.%2});\n", it.name, convert_case(it.name));
        }
        append(*builder, "\tEntityInfo.InfoList = EntityTypesList;\n");
        append(*builder, "}\n");
        
        append(*builder, "ResetEntityArenas :: () {\n");
        for entity_types {
            print_to_builder(*builder, "\tArenaReset(*EntityTypes.%);\n", convert_case(it.name));
        }
        append(*builder, "}\n");
        
        append(*builder, "CreateEntityFromInfoIndex :: (Index: int) -> *entity {\n");
        for entity_types {
            print_to_builder(*builder, "\tif Index == % return CreateEntity(%);\n", it_index, it.name);
        }
        append(*builder, "\treturn null;\n");
        append(*builder, "}\n");
        
        append(*builder, "CreateEntityFromName :: (Name: string) -> *entity {\n");
        for entity_types {
            print_to_builder(*builder, "\tif equal(Name, \"%\") return CreateEntity(%);\n", convert_case(it.name), it.name);
        }
        append(*builder, "\treturn null;\n");
        append(*builder, "}\n");
        
        add_build_string(builder_to_string(*builder), workspace);
    }
    
    compiler_end_intercept(workspace);
    
    for plugins if it.finish it.finish(it);
    for plugins if it.shutdown it.shutdown(it);
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
    
    compile_shaders := false;
    generate_sdl_bindings := false;
    profiling := true;
    
    for args {
        if contains(it, "compile_shaders") compile_shaders = true;
        if contains(it, "prof") profiling = true;
    }
    
    if (compile_shaders) {
        compile_shaders_for_format("spirv");
        //compile_shaders_for_format("dxbc");
        //compile_shaders_for_format("dxil");
        compile_shaders_for_format("json");
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