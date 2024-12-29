
generate_sdl3_bindings :: () -> bool {
    options: Generate_Bindings_Options;
    options.strip_enum_prefixes = false;
    
    output_filename := "";
    
    output_filename = "sdl_bindings.jai";
    
#if OS == .WINDOWS {
        array_add(*options.libnames, "sdl3.lib");
    } else {
        report_error("Platform not supported.");
    }
    
    array_add(*options.include_paths, "sdl3/include/");
    array_add(*options.include_paths, "sdl3/include/SDL3");
    array_add(*options.libpaths, "sdl3/lib/x64");
    
    array_add(*options.source_files, "SDL.h");
    
    if !generate_bindings(options, output_filename) return false;
    
    return true;
}

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
        
        vert_args: [..] string;
        array_add(*vert_args, tprint("%/SDL_shadercross/shadercross.exe", working_dir));
        array_add(*vert_args, tprint("%/%", working_dir, file_name));
        array_add(*vert_args, "-s");
        array_add(*vert_args, "HLSL");
        array_add(*vert_args, "-d");
        array_add(*vert_args, output_format);
        array_add(*vert_args, "-t");
        array_add(*vert_args, "vertex");
        array_add(*vert_args, "-e");
        array_add(*vert_args, "vertex_main");
        array_add(*vert_args, "-o");
        array_add(*vert_args, tprint("%/run_tree/shaders/%.%_vert", working_dir, base_name, output_format));
        array_add(*vert_args, "-DVERTEX_SHADER");
        
        frag_args: [..] string;
        array_add(*frag_args, tprint("%/SDL_shadercross/shadercross.exe", working_dir));
        array_add(*frag_args, tprint("%/%", working_dir, file_name));
        array_add(*frag_args, "-s");
        array_add(*frag_args, "HLSL");
        array_add(*frag_args, "-d");
        array_add(*frag_args, output_format);
        array_add(*frag_args, "-t");
        array_add(*frag_args, "fragment");
        array_add(*frag_args, "-e");
        array_add(*frag_args, "fragment_main");
        array_add(*frag_args, "-o");
        array_add(*frag_args, tprint("%/run_tree/shaders/%.%_frag", working_dir, base_name, output_format));
        array_add(*frag_args, "-DFRAGMENT_SHADER");
        
        /*for frag_args {
            print("% ", it);
        }
        print("\n");
        */
        
        vert_res, vert_out, vert_err := run_command(..vert_args, "", true, true);
        frag_res, frag_out, frag_err := run_command(..frag_args, "", true, true);
        //print("%, %, %", vert_res, vert_out, vert_err);
        //print("%, %, %", frag_res, frag_out, frag_err);
        
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
    //set_optimization(*options, .VERY_DEBUG);
    
    set_optimization(*options, .VERY_OPTIMIZED);
    //options.llvm_options.preserve_debug_info = true;
    
    options.text_output_flags = 0;
    
    plugin_names: [..] string;
    
#if OS == .WINDOWS {
        options.use_natvis_compatible_types = true;
        if profiling {
            options.additional_linker_arguments = .["Advapi32.lib", "user32.lib"];
            array_add(*plugin_names, "jai-tracy");
        }
    } else #if OS == .LINUX {
    } else {
        report_error("Platform not supported.");
    }
    
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
        for entity_types {
            print_to_builder(*builder, "%1_Arena: arena(%1);\n", it.name);
        }
        append(*builder, "\n");
        
        append(*builder, "entity_types :: struct {\n");
        append(*builder, "\tInfoList: [] entity_type_info;\n");
        for entity_types {
            print_to_builder(*builder, "\t%: *arena(%);\n", convert_case(it.name), it.name);
        }
        append(*builder, "}\n\n");
        
        append(*builder, "CreateEntityTypeInfo :: (EntityInfo: *entity_types) {\n");
        append(*builder, "\tEntityTypesList: [..] entity_type_info;\n");
        for entity_types {
            print_to_builder(*builder, "\tEntityInfo.% = *%_Arena;\n", convert_case(it.name), it.name);
            print_to_builder(*builder, "\tarray_add(*EntityTypesList, .{%1, *%1_Arena});\n", it.name);
        }
        append(*builder, "\tEntityInfo.InfoList = EntityTypesList;\n");
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
        if contains(it, "generate_sdl_bindings") generate_sdl_bindings = true;
        if contains(it, "prof") profiling = true;
    }
    
    if generate_sdl_bindings {
        if !generate_sdl3_bindings() compiler_set_workspace_status(.FAILED);
        
        copy_file("sdl3/lib/x64/sdl3.dll", "run_tree/sdl3.dll");
        copy_file("sdl3/lib/x64/sdl3.pdb", "run_tree/sdl3.pdb");
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