#run build();

build :: () {
    set_build_options_dc(.{do_output=false});
    
    if !generate_bindings() {
        compiler_set_workspace_status(.FAILED);
        return;
    }
}

generate_bindings :: () -> bool {
    options: Generate_Bindings_Options;
    options.strip_enum_prefixes = false;
    
    output_filename := "";
    
#if OS == .WINDOWS {
        output_filename = "windows.jai";
		array_add(*options.libnames, "sdl3.lib");
    } else {
        report_error("Platform not supported.");
    }
    
    array_add(*options.include_paths, "./SDL3-3.1.3/include/SDL3");
    array_add(*options.include_paths, "./SDL3-3.1.3/include/");
    array_add(*options.libpaths, ".");
    
    array_add(*options.source_files, "SDL.h");
    
    return generate_bindings(options, output_filename);
}

#scope_file

#import "Basic";
#import "Compiler";
#import "BuildCpp";
#import "Check";
#import "Bindings_Generator";
#import "File";
#import "String";
