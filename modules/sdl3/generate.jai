
generate_bindings :: () -> bool {
    options: Generate_Bindings_Options;
    options.strip_enum_prefixes = false;
    
#if OS == .WINDOWS {
        output_filename := "windows.jai";
        array_add(*options.libnames, "SDL3.lib");
        array_add(*options.libnames, "SDL3_shadercross.lib");
    } else {
        return false;
    }
    
    array_add(*options.include_paths, "source/include/");
    array_add(*options.include_paths, "source/include/SDL3");
    array_add(*options.libpaths, "build");
    
    array_add(*options.source_files, "SDL.h");
    array_add(*options.source_files, "SDL_shadercross.h");
    
    if !generate_bindings(options, output_filename) return false;
    
    return true;
}

build :: () {
    if !generate_bindings() compiler_set_workspace_status(.FAILED);
    set_build_options_dc(.{do_output = false});
}

#run build();

#scope_file

#import "Basic";
#import "File_Utilities";
#import "File";
#import "Compiler";
#import "String";
#import "Bindings_Generator";