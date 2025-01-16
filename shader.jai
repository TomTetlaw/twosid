
shader :: struct {
    Vert: *SDL_GPUShader;
    VertMeta: SDL_ShaderCross_GraphicsShaderMetadata;
    
    Frag: *SDL_GPUShader;
    FragMeta: SDL_ShaderCross_GraphicsShaderMetadata;
}

ShaderMesh: *shader;
ShaderUnlit: *shader;
ShaderQuad: *shader;
ShaderShadowPass: *shader;
ShaderDebug: *shader;
ShaderText: *shader;
ShaderTextSDF: *shader;

InitShaderSystem :: () {
    SDL_ShaderCross_Init();
    
    ShaderMesh = CreateShader("shaders/mesh.hlsl");
    ShaderUnlit = CreateShader("shaders/unlit.hlsl");
    ShaderQuad = CreateShader("shaders/quad.hlsl");
    ShaderShadowPass = CreateShader("shaders/shadow_pass.hlsl");
    ShaderDebug = CreateShader("shaders/debug.hlsl");
    ShaderText = CreateShader("shaders/text.hlsl");
    ShaderTextSDF = CreateShader("shaders/text_sdf.hlsl");
}

#scope_file

#import "Basic";
#import "File";

ShaderArena: arena;
Shaders: arena;

FormatToLoad: SDL_GPUShaderFormat;
ShaderFormat: string;

CreateShader :: (Path: string) -> *shader {
    Data, Ok := read_entire_file(Path, true);
    if !Ok return null;
    
    Formats := SDL_ShaderCross_GetSPIRVShaderFormats();
    
    Dir, Name, Ext := path_decomp(Path);
    
    Info: SDL_ShaderCross_HLSL_Info;
    Info.source = Data.data;
    Info.include_dir = "shaders/";
    Info.entrypoint = "vertex_main";
    Info.shader_stage = .VERTEX;
    //Info.enable_debug = true;
    //Info.defines = Defines.data;
    Info.name = TCS(tprint("%_vert", Name));
    
    VertMeta: SDL_ShaderCross_GraphicsShaderMetadata;
    VertShader := SDL_ShaderCross_CompileGraphicsShaderFromHLSL(GDevice, *Info, *VertMeta);
    
    Info.entrypoint = "fragment_main";
    Info.shader_stage = .FRAGMENT;
    Info.name = TCS(tprint("%_frag", Name));
    
    FragMeta: SDL_ShaderCross_GraphicsShaderMetadata;
    FragShader := SDL_ShaderCross_CompileGraphicsShaderFromHLSL(GDevice, *Info, *FragMeta);
    
    Shader := ArenaAlloc(*Shaders, shader);
    Shader.Vert = VertShader;
    Shader.VertMeta = VertMeta;
    Shader.Frag = FragShader;
    Shader.FragMeta = FragMeta;
    
    return Shader;
}