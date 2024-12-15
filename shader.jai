
shader :: struct {
    Vert: *SDL_GPUShader;
    Frag: *SDL_GPUShader;
}

ShaderMesh: shader;
ShaderScreenSpaceMesh: shader;
ShaderDepthPass: shader;
ShaderDebug: shader;

InitShaderSystem :: () {
    Formats := SDL_GetGPUShaderFormats(GDevice);
    if Formats & SDL_GPU_SHADERFORMAT_DXIL {
        FormatToLoad = SDL_GPU_SHADERFORMAT_DXIL;
    } else if Formats & SDL_GPU_SHADERFORMAT_DXBC {
        FormatToLoad = SDL_GPU_SHADERFORMAT_DXBC;
    } else if Formats & SDL_GPU_SHADERFORMAT_SPIRV {
        FormatToLoad = SDL_GPU_SHADERFORMAT_SPIRV;
    } else {
        FatalError("Failed to find suitable shader Format");
    }
    
    if FormatToLoad == SDL_GPU_SHADERFORMAT_DXIL ShaderFormat = "dxil";
    else if FormatToLoad == SDL_GPU_SHADERFORMAT_DXBC ShaderFormat = "dxbc";
    else if FormatToLoad == SDL_GPU_SHADERFORMAT_SPIRV ShaderFormat = "spirv";
    else FatalError("Unsupported shader Format %", FormatToLoad);
    
    MeshVert := CreateShader("vert", "mesh", 0, 0, 2, 1);
    MeshFrag := CreateShader("frag", "mesh", 4, 0, 0, 1);
    ShaderMesh = .{MeshVert, MeshFrag};
    
    ScreenSpaceMeshVert := CreateShader("vert", "screen_space_mesh", 0, 0, 0, 1);
    ScreenSpaceMeshFrag := CreateShader("frag", "screen_space_mesh", 1, 0, 0, 0);
    ShaderScreenSpaceMesh = .{ScreenSpaceMeshVert, ScreenSpaceMeshFrag};
    
    DepthPassVert := CreateShader("vert", "depth_pass", 0, 0, 2, 1);
    DepthPassFrag := CreateShader("frag", "depth_pass", 0, 0, 0, 0);
    ShaderDepthPass = .{DepthPassVert, DepthPassFrag};
    
    DebugVert := CreateShader("vert", "debug", 0, 0, 1, 1);
    DebugFrag := CreateShader("frag", "debug", 0, 0, 0, 0);
    ShaderDebug = .{DebugVert, DebugFrag};
}

#scope_file

#import "Basic";
#import "File";

ShaderArena: arena;
Shaders: arena(shader);

FormatToLoad: SDL_GPUShaderFormat;
ShaderFormat: string;

CreateShader :: (Stage: string, Name: string, NumSamplers: u32, NumStorageTextures: u32, NumStorageBuffers: u32, NumUniformBuffers: u32) -> *SDL_GPUShader {
    
    FileName := tprint("shaders/%.%_%", Name, ShaderFormat, Stage);
    Data, Ok := read_entire_file(FileName);
    if !Ok return null;
    
    EntryPoint := "";
    if equal(Stage, "vert") EntryPoint = "vertex_main";
    else if equal(Stage, "frag") EntryPoint = "fragment_main";
    else FatalError("Unsupported shader Stage %", Stage);
    
    CreateInfo: SDL_GPUShaderCreateInfo;
    CreateInfo.code_size = xx Data.count;
    CreateInfo.code = Data.data;
    CreateInfo.entrypoint = EntryPoint.data;
    CreateInfo.format = FormatToLoad;
    CreateInfo.num_samplers = NumSamplers;
    CreateInfo.num_storage_textures = NumStorageTextures;
    CreateInfo.num_storage_buffers = NumStorageBuffers;
    CreateInfo.num_uniform_buffers = NumUniformBuffers;
    
    GpuShader := SDL_CreateGPUShader(GDevice, *CreateInfo);
    if !GpuShader FatalError("Failed to load shader %: %", FileName, SdlGetError());
    
    return GpuShader;
}