
SDL3_DIR_WINDOWS :: "windows/SDL3-3.1.10";
SDL3_SHADERCROSS_DIR_WINDOWS :: "windows/SDL3_shadercross-3.0.0-windows-VC-x64";

generate_bindings :: () -> bool {
    options: Generate_Bindings_Options;
    options.strip_enum_prefixes = false;
    
#if OS == .WINDOWS {
        output_filename := "windows.jai";
        array_add(*options.include_paths, tprint("%/include", SDL3_DIR_WINDOWS));
        array_add(*options.include_paths, tprint("%/include/SDL3", SDL3_DIR_WINDOWS));
        array_add(*options.libpaths, tprint("%/lib/x64", SDL3_DIR_WINDOWS));
        
        array_add(*options.include_paths, tprint("%/include/SDL3_shadercross", SDL3_SHADERCROSS_DIR_WINDOWS));
        array_add(*options.libpaths, tprint("%/lib", SDL3_SHADERCROSS_DIR_WINDOWS));
        
        array_add(*options.libnames, "SDL3.lib");
        array_add(*options.libnames, "SDL3_shadercross.lib");
    } else {
        assert(false);
    }
    
    array_add(*options.system_types_to_include, "_iobuf");
    
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