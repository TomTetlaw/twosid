
add_all_files :: (workspace: Workspace) {
    builder: String_Builder;
    
    print("Code files in build:\n");
    
    files := file_list("./");
    for files {
        if !contains(it, ".jai") continue;
        if contains(it, "first.jai") continue;
        if contains(it, "sdl_bindings.jai") continue;
        
        path, base_name, ext := path_decomp(it);
        print("\t%.%\n", base_name, ext);
        
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
    options.text_output_flags = .OUTPUT_TIMING_INFO;
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
        array_add(*vert_args, ("-DVERTEX_SHADER"));
        
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
        array_add(*frag_args, ("-DFRAGMENT_SHADER"));
        
        run_command(..vert_args);
        run_command(..frag_args);
        
        print("\t% -> %, %\n", file_name, tprint("%.%_vert", base_name, output_format), tprint("%.%_frag", base_name, output_format));
    }
}

build :: () {
    args := get_build_options().compile_time_command_line;
    
    compile_shaders := false;
    for args {
        if contains(it, "compile_shaders") compile_shaders = true;
    }
    
    if (compile_shaders) {
        compile_shaders_for_format("dxil");
        compile_shaders_for_format("dxbc");
        compile_shaders_for_format("spirv");
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