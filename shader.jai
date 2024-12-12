
Shader :: struct {
    vert: *SDL_GPUShader;
    frag: *SDL_GPUShader;
}

shader_mesh: Shader;
shader_screen_space_mesh: Shader;
shader_depth_pass: Shader;

init_shader_system :: () {
    formats := SDL_GetGPUShaderFormats(g_device);
    if formats & SDL_GPU_SHADERFORMAT_DXIL {
        format_to_load = SDL_GPU_SHADERFORMAT_DXIL;
    } else if formats & SDL_GPU_SHADERFORMAT_DXBC {
        format_to_load = SDL_GPU_SHADERFORMAT_DXBC;
    } else if formats & SDL_GPU_SHADERFORMAT_SPIRV {
        format_to_load = SDL_GPU_SHADERFORMAT_SPIRV;
    } else {
        fatal_error("Failed to find suitable shader format");
    }
    
    if format_to_load == SDL_GPU_SHADERFORMAT_DXIL shader_format = "dxil";
    else if format_to_load == SDL_GPU_SHADERFORMAT_DXBC shader_format = "dxbc";
    else if format_to_load == SDL_GPU_SHADERFORMAT_SPIRV shader_format = "spirv";
    else fatal_error("Unsupported shader format %", format_to_load);
    
    mesh_vert := create_shader(g_device, "vert", "mesh", 0, 0, 2, 1);
    mesh_frag := create_shader(g_device, "frag", "mesh", 4, 0, 0, 1);
    shader_mesh = .{mesh_vert, mesh_frag};
    
    screen_space_mesh_vert := create_shader(g_device, "vert", "screen_space_mesh", 0, 0, 0, 1);
    screen_space_mesh_frag := create_shader(g_device, "frag", "screen_space_mesh", 1, 0, 0, 0);
    shader_screen_space_mesh = .{screen_space_mesh_vert, screen_space_mesh_frag};
    
    depth_pass_vert := create_shader(g_device, "vert", "depth_pass", 0, 0, 2, 1);
    depth_pass_frag := create_shader(g_device, "frag", "depth_pass", 0, 0, 0, 0);
    shader_depth_pass = .{depth_pass_vert, depth_pass_frag};
}

#scope_file

#import "Basic";
#import "File";

shader_arena: Arena("shader_working");
shaders: Arena("shaders", Shader);

format_to_load: SDL_GPUShaderFormat;
shader_format: string;

create_shader :: (g_device: *SDL_GPUDevice, stage: string, name: string, num_samplers: u32, num_storage_textures: u32, num_storage_buffers: u32, num_uniform_buffers: u32) -> *SDL_GPUShader {
    
    file_name := tprint("shaders/%.%_%", name, shader_format, stage);
    data, ok := read_entire_file(file_name);
    if !ok return null;
    
    entry_point := "";
    if equal(stage, "vert") entry_point = "vertex_main";
    else if equal(stage, "frag") entry_point = "fragment_main";
    else fatal_error("Unsupported shader stage %", stage);
    
    create_info: SDL_GPUShaderCreateInfo;
    create_info.code_size = xx data.count;
    create_info.code = data.data;
    create_info.entrypoint = entry_point.data;
    create_info.format = format_to_load;
    create_info.num_samplers = num_samplers;
    create_info.num_storage_textures = num_storage_textures;
    create_info.num_storage_buffers = num_storage_buffers;
    create_info.num_uniform_buffers = num_uniform_buffers;
    
    gpu_shader := SDL_CreateGPUShader(g_device, *create_info);
    if !gpu_shader fatal_error("Failed to load shader %: %", file_name, sdl_get_error());
    
    return gpu_shader;
}