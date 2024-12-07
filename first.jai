
add_all_files :: (workspace: Workspace) {
    builder: String_Builder;
    
    files := file_list("./");
    for files {
        if !contains(it, ".jai") continue;
        if contains(it, "first.jai") continue;
        add_build_file(it, workspace);
    }
}

set_common_options :: (options: *Build_Options) {
    options.output_path = "run_tree";
    options.intermediate_path = ".build/";
    options.backend = .LLVM;
    options.output_executable_name = "twosid";
    options.debug_for_expansions = true;
    set_optimization(options, .VERY_DEBUG);
    options.text_output_flags = 0;
}

build_linux :: () {
    workspace := compiler_create_workspace("Linux Build");
    options := get_build_options(workspace);
    set_common_options(*options);
    
    options.os_target = .LINUX;
    set_build_options(options, workspace);
    
    add_all_files(workspace);
}

build_windows :: () {
    workspace := compiler_create_workspace("Windows Build");
    options := get_build_options(workspace);
    set_common_options(*options);
    
    options.os_target = .WINDOWS;
    options.use_natvis_compatible_types = true;
    set_build_options(options, workspace);
    
    add_all_files(workspace);
}

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

build :: () {
    set_build_options_dc(.{do_output = false});
    
    args := get_build_options().compile_time_command_line;
    
    compile_shaders := false;
    generate_sdl_bindings := false;
    for args {
        if contains(it, "compile_shaders") compile_shaders = true;
        if contains(it, "generate_sdl_bindings") generate_sdl_bindings = true;
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
    
#if OS == .WINDOWS {
        build_windows();
    }
    else #if OS == .LINUX {
        build_linux();
    }
    else {
        report_error("Platform not supported.");
    }
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