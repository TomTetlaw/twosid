
generate_sdl3_bindings :: () -> bool {
    options: Generate_Bindings_Options;
    options.strip_enum_prefixes = false;
    
#if OS == .WINDOWS {
        output_filename := "windows.jai";
        array_add(*options.libnames, "sdl3.lib");
    } else {
        output_filename := "linux.jai";
        array_add(*options.libnames, "libSDL3.so");
    }
    
    array_add(*options.include_paths, "sdl3/include/");
    array_add(*options.include_paths, "sdl3/include/SDL3");
    array_add(*options.libpaths, "sdl3/lib/x64");
    
    array_add(*options.source_files, "SDL.h");
    
    if !generate_bindings(options, output_filename) return false;
    
    return true;
}

build :: () {
    if !generate_sdl3_bindings() compiler_set_workspace_status(.FAILED);
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