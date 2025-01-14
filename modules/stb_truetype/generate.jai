
generate :: () -> bool {
    success := true;
    
    source_files: [..] string;
    array_add(*source_files, "source/stb_truetype.c");
    
    success &&= build_cpp_static_lib("build/stb_truetype", ..source_files);
    success &&= build_cpp_dynamic_lib("build/stb_truetype", ..source_files);
    
    if !success {
        print("CPP build failed!\n");
        return false;
    }
    
    options: Generate_Bindings_Options;
    options.strip_enum_prefixes = false;
    options.generate_library_declarations = false;
    options.footer = "stb_truetype :: #library,no_dll \"build/stb_truetype\";";
    
#if OS == .WINDOWS {
        output_filename := "windows.jai";
        array_add(*options.libnames, "stb_truetype.lib");
    } else {
        output_filename := "linux.jai";
        array_add(*options.libnames, "stb_truetype.so");
    }
    
    array_add(*options.include_paths, "source");
    array_add(*options.libpaths, "build");
    
    array_add(*options.source_files, "stb_truetype.h");
    
    if !generate_bindings(options, output_filename) return false;
    
    return true;
}

build :: () {
    if !generate() compiler_set_workspace_status(.FAILED);
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
#import "BuildCpp";