
InitRenderer :: () {
    // screen space Pipeline
    {
        ScreenSpaceCreateInfo: SDL_GPUGraphicsPipelineCreateInfo;
        ColourTargetDesc: SDL_GPUColorTargetDescription;
        ColourTargetDesc.format = SDL_GetGPUSwapchainTextureFormat(GDevice, GWindow);
        ScreenSpaceCreateInfo.target_info.color_target_descriptions = *ColourTargetDesc;
        ScreenSpaceCreateInfo.target_info.num_color_targets = 1;
        
        ScreenSpaceCreateInfo.rasterizer_state.cull_mode = .SDL_GPU_CULLMODE_BACK;
        ScreenSpaceCreateInfo.rasterizer_state.fill_mode = .SDL_GPU_FILLMODE_FILL;
        ScreenSpaceCreateInfo.rasterizer_state.front_face = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE;
        
        BufferDescriptions: [2] SDL_GPUVertexBufferDescription;
        BufferDescriptions[0] = .{0, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[1] = .{1, size_of(float2), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        ScreenSpaceCreateInfo.vertex_input_state.vertex_buffer_descriptions = BufferDescriptions.data;
        ScreenSpaceCreateInfo.vertex_input_state.num_vertex_buffers = 2;
        
        VertexAttributes: [2] SDL_GPUVertexAttribute;
        VertexAttributes[0] = .{0, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[1] = .{1, 1, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, 0};
        ScreenSpaceCreateInfo.vertex_input_state.vertex_attributes = VertexAttributes.data;
        ScreenSpaceCreateInfo.vertex_input_state.num_vertex_attributes = 2;
        
        ScreenSpaceCreateInfo.primitive_type = .SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
        ScreenSpaceCreateInfo.vertex_shader = ShaderScreenSpaceMesh.Vert;
        ScreenSpaceCreateInfo.fragment_shader = ShaderScreenSpaceMesh.Frag;
        
        ScreenSpacePipeline = SDL_CreateGPUGraphicsPipeline(GDevice, *ScreenSpaceCreateInfo);
    }
    
    // depth Pass Pipeline
    {
        DepthFormat := SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_D24_UNORM;
        
        ShadowInfo: SDL_GPUTextureCreateInfo;
        ShadowInfo.type = .SDL_GPU_TEXTURETYPE_2D;
        ShadowInfo.width = SHADOW_MAP_SIZE;
        ShadowInfo.height = SHADOW_MAP_SIZE;
        ShadowInfo.layer_count_or_depth = 1;
        ShadowInfo.num_levels = 1;
        ShadowInfo.sample_count = .SDL_GPU_SAMPLECOUNT_1;
        ShadowInfo.format = DepthFormat;
        ShadowInfo.usage = SDL_GPU_TEXTUREUSAGE_SAMPLER | SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET;
        ShadowTexture = SDL_CreateGPUTexture(GDevice, *ShadowInfo);
        SDL_SetGPUTextureName(GDevice, ShadowTexture, "ShadowTexture".data);
        
        DepthCreateInfo: SDL_GPUGraphicsPipelineCreateInfo;
        DepthCreateInfo.target_info.num_color_targets = 0;
        DepthCreateInfo.target_info.has_depth_stencil_target = true;
        DepthCreateInfo.target_info.depth_stencil_format = DepthFormat;
        
        DepthCreateInfo.depth_stencil_state.compare_op = .SDL_GPU_COMPAREOP_LESS;
        DepthCreateInfo.depth_stencil_state.enable_depth_test = true;
        DepthCreateInfo.depth_stencil_state.enable_depth_write = true;
        DepthCreateInfo.depth_stencil_state.enable_stencil_test = false;
        
        DepthCreateInfo.rasterizer_state.cull_mode = .SDL_GPU_CULLMODE_FRONT;
        DepthCreateInfo.rasterizer_state.fill_mode = .SDL_GPU_FILLMODE_FILL;
        DepthCreateInfo.rasterizer_state.front_face = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE;
        
        BufferDescriptions: [3] SDL_GPUVertexBufferDescription;
        BufferDescriptions[0] = .{0, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[1] = .{1, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[2] = .{2, size_of(bone_ids), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        DepthCreateInfo.vertex_input_state.vertex_buffer_descriptions = BufferDescriptions.data;
        DepthCreateInfo.vertex_input_state.num_vertex_buffers = 3;
        
        VertexAttributes: [3] SDL_GPUVertexAttribute;
        VertexAttributes[0] = .{0, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[1] = .{1, 1, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[2] = .{2, 2, .SDL_GPU_VERTEXELEMENTFORMAT_SHORT4, 0};
        DepthCreateInfo.vertex_input_state.vertex_attributes = VertexAttributes.data;
        DepthCreateInfo.vertex_input_state.num_vertex_attributes = 3;
        
        DepthCreateInfo.primitive_type = .SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
        DepthCreateInfo.vertex_shader = ShaderDepthPass.Vert;
        DepthCreateInfo.fragment_shader = ShaderDepthPass.Frag;
        
        DepthPipeline = SDL_CreateGPUGraphicsPipeline(GDevice, *DepthCreateInfo);
    }
    
    // mesh Pipeline
    {
        DepthInfo: SDL_GPUTextureCreateInfo;
        DepthInfo.type = .SDL_GPU_TEXTURETYPE_2D;
        DepthInfo.width = 1366;
        DepthInfo.height = 768;
        DepthInfo.layer_count_or_depth = 1;
        DepthInfo.num_levels = 1;
        DepthInfo.sample_count = .SDL_GPU_SAMPLECOUNT_1;
        DepthInfo.format = .SDL_GPU_TEXTUREFORMAT_D24_UNORM;
        DepthInfo.usage = SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET;
        DepthTexture = SDL_CreateGPUTexture(GDevice, *DepthInfo);
        SDL_SetGPUTextureName(GDevice, DepthTexture, "DepthTexture".data);
        
        MeshCreateInfo: SDL_GPUGraphicsPipelineCreateInfo;
        ColourTargetDesc: SDL_GPUColorTargetDescription;
        ColourTargetDesc.format = SDL_GetGPUSwapchainTextureFormat(GDevice, GWindow);
        MeshCreateInfo.target_info.color_target_descriptions = *ColourTargetDesc;
        MeshCreateInfo.target_info.num_color_targets = 1;
        MeshCreateInfo.target_info.has_depth_stencil_target = true;
        MeshCreateInfo.target_info.depth_stencil_format = DepthInfo.format;
        
        MeshCreateInfo.depth_stencil_state.compare_op = .SDL_GPU_COMPAREOP_LESS;
        MeshCreateInfo.depth_stencil_state.enable_depth_test = true;
        MeshCreateInfo.depth_stencil_state.enable_depth_write = true;
        MeshCreateInfo.depth_stencil_state.enable_stencil_test = false;
        
        MeshCreateInfo.rasterizer_state.cull_mode = .SDL_GPU_CULLMODE_BACK;
        MeshCreateInfo.rasterizer_state.fill_mode = .SDL_GPU_FILLMODE_FILL;
        MeshCreateInfo.rasterizer_state.front_face = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE;
        
        BufferDescriptions: [7] SDL_GPUVertexBufferDescription;
        BufferDescriptions[0] = .{0, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[1] = .{1, size_of(float2), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[2] = .{2, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[3] = .{3, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[4] = .{4, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[5] = .{5, size_of(bone_ids), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        MeshCreateInfo.vertex_input_state.vertex_buffer_descriptions = BufferDescriptions.data;
        MeshCreateInfo.vertex_input_state.num_vertex_buffers = 6;
        
        VertexAttributes: [6] SDL_GPUVertexAttribute;
        VertexAttributes[0] = .{0, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[1] = .{1, 1, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, 0};
        VertexAttributes[2] = .{2, 2, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[3] = .{3, 3, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[4] = .{4, 4, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[5] = .{5, 5, .SDL_GPU_VERTEXELEMENTFORMAT_SHORT4, 0};
        MeshCreateInfo.vertex_input_state.vertex_attributes = VertexAttributes.data;
        MeshCreateInfo.vertex_input_state.num_vertex_attributes = 6;
        
        MeshCreateInfo.primitive_type = .SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
        MeshCreateInfo.vertex_shader = ShaderMesh.Vert;
        MeshCreateInfo.fragment_shader = ShaderMesh.Frag;
        
        MeshPipeline = SDL_CreateGPUGraphicsPipeline(GDevice, *MeshCreateInfo);
    }
    
    {
        ScreenSpacePositionBuffer = CreateVertexBuffer(GDevice, "ScreenSpacePositionBuffer", size_of(float3), 4);
        ScreenSpaceTexCoordBuffer = CreateVertexBuffer(GDevice, "ScreenSpaceTexCoordBuffer", size_of(float2), 4);
        ScreenSpaceIndexBuffer = CreateIndexBuffer(GDevice, "ScreenSpaceIndexBuffer", 6);
        
        CreateInfo: SDL_GPUTransferBufferCreateInfo;
        CreateInfo.usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
        CreateInfo.size = size_of(float) * 5 * 4 + size_of(u32) * 6;
        TransferBuffer := SDL_CreateGPUTransferBuffer(GDevice, *CreateInfo);
        TransferMemory := cast (*u8) SDL_MapGPUTransferBuffer(GDevice, TransferBuffer, false);
        
        {
            Memory := cast(*float3) TransferMemory;
            Memory[0] = .{0, 0, 0};
            Memory[1] = .{1366/4, 0, 0};
            Memory[2] = .{1366/4, 768/4, 0};
            Memory[3] = .{0, 768/4, 0};
        }
        {
            Memory := cast(*float2) (TransferMemory + size_of(float3) * 4);
            Memory[0] = .{0, 0};
            Memory[1] = .{1, 0};
            Memory[2] = .{1, 1};
            Memory[3] = .{0, 1};
        }
        {
            Memory := cast(*u32) (TransferMemory + size_of(float) * 5 * 4);
            Memory[0] = 0;
            Memory[1] = 2;
            Memory[2] = 1;
            Memory[3] = 0;
            Memory[4] = 3;
            Memory[5] = 2;
        }
        
        SDL_UnmapGPUTransferBuffer(GDevice, TransferBuffer);
        
        CommandBuffer := SDL_AcquireGPUCommandBuffer(GDevice);
        CopyPass := SDL_BeginGPUCopyPass(CommandBuffer);
        
        Location: SDL_GPUTransferBufferLocation;
        Location.transfer_buffer = TransferBuffer;
        Location.offset = 0;
        
        Region: SDL_GPUBufferRegion;
        Region.buffer = ScreenSpacePositionBuffer;
        Region.offset = 0;
        Region.size = size_of(float3) * 4;
        
        SDL_UploadToGPUBuffer(CopyPass, *Location, *Region, false);
        
        Location.offset = size_of(float3) * 4;
        Region.buffer = ScreenSpaceTexCoordBuffer;
        Region.size = size_of(float2) * 4;
        
        SDL_UploadToGPUBuffer(CopyPass, *Location, *Region, false);
        
        Location.offset = size_of(float) * 5 * 4;
        Region.buffer = ScreenSpaceIndexBuffer;
        Region.size = size_of(u32) * 6;
        
        SDL_UploadToGPUBuffer(CopyPass, *Location, *Region, false);
        
        SDL_EndGPUCopyPass(CopyPass);
        SDL_SubmitGPUCommandBuffer(CommandBuffer);
        SDL_ReleaseGPUTransferBuffer(GDevice, TransferBuffer);
    }
    
    SkinningCreateInfo: SDL_GPUBufferCreateInfo;
    SkinningCreateInfo.usage = SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ;
    SkinningCreateInfo.size = size_of(float4x4) * MAX_BONES;
    SkinningMatricesBuffer = SDL_CreateGPUBuffer(GDevice, *SkinningCreateInfo);
    SDL_SetGPUBufferName(GDevice, SkinningMatricesBuffer, "skinning_matrices".data);
    
    CreateInfo: SDL_GPUTransferBufferCreateInfo;
    CreateInfo.usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
    CreateInfo.size = size_of(float4x4) * MAX_BONES;
    TransferBuffer := SDL_CreateGPUTransferBuffer(GDevice, *CreateInfo);
    
    TransferMemory := cast (*float4x4) SDL_MapGPUTransferBuffer(GDevice, TransferBuffer, false);
    for 0..MAX_BONES-1 {
        TransferMemory[it] = IdentityMatrix();
    }
    
    SDL_UnmapGPUTransferBuffer(GDevice, TransferBuffer);
    
    CommandBuffer := SDL_AcquireGPUCommandBuffer(GDevice);
    CopyPass := SDL_BeginGPUCopyPass(CommandBuffer);
    
    Location: SDL_GPUTransferBufferLocation;
    Location.transfer_buffer = TransferBuffer;
    Location.offset = 0;
    
    Region: SDL_GPUBufferRegion;
    Region.buffer = SkinningMatricesBuffer;
    Region.offset = 0;
    Region.size = size_of(float4x4) * MAX_BONES;
    
    SDL_UploadToGPUBuffer(CopyPass, *Location, *Region, false);
    
    SDL_EndGPUCopyPass(CopyPass);
    SDL_SubmitGPUCommandBuffer(CommandBuffer);
    SDL_ReleaseGPUTransferBuffer(GDevice, TransferBuffer);
    
    SamplerInfo: SDL_GPUSamplerCreateInfo;
    SamplerInfo.min_lod = 0;
    SamplerInfo.max_lod = 11;
    SamplerInfo.min_filter = .SDL_GPU_FILTER_LINEAR;
    SamplerInfo.mag_filter = .SDL_GPU_FILTER_LINEAR;
    SamplerInfo.mipmap_mode = .SDL_GPU_SAMPLERMIPMAPMODE_LINEAR;
    SamplerInfo.address_mode_u = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
    SamplerInfo.address_mode_v = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
    SamplerInfo.address_mode_w = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
    DefaultSampler = SDL_CreateGPUSampler(GDevice, *SamplerInfo);
    
    SamplerInfo.min_lod = 0;
    SamplerInfo.max_lod = 0;
    SamplerInfo.min_filter = .SDL_GPU_FILTER_NEAREST;
    SamplerInfo.mag_filter = .SDL_GPU_FILTER_NEAREST;
    SamplerInfo.mipmap_mode = .SDL_GPU_SAMPLERMIPMAPMODE_NEAREST;
    SamplerInfo.address_mode_u = .SDL_GPU_SAMPLERADDRESSMODE_MIRRORED_REPEAT;
    SamplerInfo.address_mode_v = .SDL_GPU_SAMPLERADDRESSMODE_MIRRORED_REPEAT;
    SamplerInfo.address_mode_w = .SDL_GPU_SAMPLERADDRESSMODE_MIRRORED_REPEAT;
    ShadowSampler = SDL_CreateGPUSampler(GDevice, *SamplerInfo);
    
    InitPasses();
}

CalcLightSpaceMatrix :: (LightPos: float3, LightDir: float3, Proj: float4x4, View: float4x4) -> float4x4 {
    Inverse := InverseMatrix(Proj * View);
    
    Corners: [8] float4;
    Corners[0] = Inverse * .{-1, -1, -1, 1};
    Corners[1] = Inverse * .{-1, -1,  1, 1};
    Corners[2] = Inverse * .{-1,  1, -1, 1};
    Corners[3] = Inverse * .{-1,  1,  1, 1};
    Corners[4] = Inverse * .{ 1, -1, -1, 1};
    Corners[5] = Inverse * .{ 1, -1,  1, 1};
    Corners[6] = Inverse * .{ 1,  1, -1, 1};
    Corners[7] = Inverse * .{ 1,  1,  1, 1};
    
    for * Corners {
        it.* /= it.w; 
    }
    
    Center: float3;
    for Corners {
        Center += it.xyz;
    }
    Center /= 8;
    
    Dir := float3.{-LightDir.y, LightDir.z, LightDir.x};
    LightView := LookAtMatrix(Center + LightDir, Center);
    
    Right, Top, Far := FLOAT32_MIN;
    Left, Bottom, Near := FLOAT32_MAX;
    
    for Corners {
        corner := (LightView * it).xyz;
        
        Left = min(Left, corner.x);
        Right = max(Right, corner.x);
        Bottom = min(Bottom, corner.y);
        Top = max(Top, corner.y);
        Near = min(Near, corner.z);
        Far = max(Far, corner.z);
    }
    
    ZPad := .5;
    if Near < 0 Near *= ZPad;
    else Near /= ZPad;
    if Far < 0 Far *= ZPad;
    else Far /= ZPad;
    
    LightProj := OrthoProjectionMatrix(Left, Right, Bottom, Top, Near, Far);
    
    return LightProj * LightView;
}

ibuffer_empty :: struct {}

OpaquePass: *draw_pass(ibuffer_mesh);
DepthPass: *draw_pass(ibuffer_mesh);
ScreenSpacePass: *draw_pass(ibuffer_empty);

InitPasses :: () {
    {
        DepthPass = ArenaPush(*RendererArena, draw_pass(ibuffer_mesh));
        DepthPass.Type = .DEPTH;
        DepthPass.Pipeline = DepthPipeline;
        
        DepthPass.VertConstants = ArenaPush(*RendererArena, cbuffer_shadow_vertex);
        DepthPass.VertConstantsSize = size_of(cbuffer_shadow_vertex);
        
        DepthPass.StorageBuffers = ArenaPushN(*RendererArena, *SDL_GPUBuffer, 1);
        DepthPass.StorageBuffers[0] = SkinningMatricesBuffer;
        
        DepthPass.ColourTarget = false;
        DepthPass.DepthTarget = ShadowTexture;
        DepthPass.Viewport = .{SHADOW_MAP_SIZE, SHADOW_MAP_SIZE};
        
        DepthPass.InstanceBuffer = CreateInstanceBufferForPass(DepthPass, "depth_instance");
    }
    
    {
        OpaquePass = ArenaPush(*RendererArena, draw_pass(ibuffer_mesh));
        OpaquePass.Type = .OPAQUE;
        OpaquePass.Pipeline = MeshPipeline;
        
        OpaquePass.VertConstants = ArenaPush(*RendererArena, cbuffer_mesh_vertex);
        OpaquePass.VertConstantsSize = size_of(cbuffer_mesh_vertex);
        OpaquePass.FragConstants = ArenaPush(*RendererArena, cbuffer_mesh_fragment);
        OpaquePass.FragConstantsSize = size_of(cbuffer_mesh_fragment);
        
        OpaquePass.StorageBuffers = ArenaPushN(*RendererArena, *SDL_GPUBuffer, 1);
        OpaquePass.StorageBuffers[0] = SkinningMatricesBuffer;
        
        OpaquePass.Textures = ArenaPushN(*RendererArena, *SDL_GPUTexture, 1);
        OpaquePass.Textures[0] = ShadowTexture;
        OpaquePass.Samplers = ArenaPushN(*RendererArena, *SDL_GPUSampler, 1);
        OpaquePass.Samplers[0] = ShadowSampler;
        
        OpaquePass.ColourTarget = true;
        OpaquePass.ClearColour = true;
        OpaquePass.DepthTarget = DepthTexture;
        OpaquePass.Viewport = .{1366, 768};
        
        OpaquePass.InstanceBuffer = CreateInstanceBufferForPass(OpaquePass, "opaque_instance");
    }
    
    {
        ScreenSpacePass = ArenaPush(*RendererArena, draw_pass(ibuffer_empty));
        ScreenSpacePass.Type = .SCREEN_SPACE;
        ScreenSpacePass.Pipeline = ScreenSpacePipeline;
        
        ScreenSpacePass.VertConstants = ArenaPush(*RendererArena, cbuffer_screenspacemesh_vertex);
        ScreenSpacePass.VertConstantsSize = size_of(cbuffer_screenspacemesh_vertex);
        
        ScreenSpacePass.ColourTarget = true;
        ScreenSpacePass.Viewport = .{1366, 768};
    }
}

DrawFrame :: (Camera: *camera) {
    if KeyPressed(.SDL_SCANCODE_LEFT) {
        FragDebugMode = clamp(FragDebugMode - 1, 0, MAX_FRAG_DEBUG_MODE);
    }
    if KeyPressed(.SDL_SCANCODE_RIGHT) {
        FragDebugMode = clamp(FragDebugMode + 1, 0, MAX_FRAG_DEBUG_MODE);
    }
    
    Projection := ProjectionMatrix(45.0 * Deg2Rad, 1366.0 / 768.0, NEAR_PLANE, FAR_PLANE);
    
    LightPos := float3.{0, 0, 10};
    LightTarget := float3.{1, -1, 1};
    LightDir := Normalize(LightTarget - LightPos);
    
    LightColour := float3.{1.0, 1.0, 0.8};
    LightMatrix := CalcLightSpaceMatrix(LightPos, LightDir, Projection, Camera.View);
    
    {
        VertConstants: cbuffer_shadow_vertex;
        VertConstants.LightMatrix = LightMatrix;
        VertConstants.Time = .{RealTime, 0, 0, 0};
        memcpy(DepthPass.VertConstants, *VertConstants, size_of(cbuffer_shadow_vertex));
    }
    
    {
        VertConstants: cbuffer_mesh_vertex;
        VertConstants.View = Camera.View;
        VertConstants.Projection = Projection;
        VertConstants.ViewPos = Camera.Position;
        VertConstants.LightDir = LightDir;
        VertConstants.Time = .{RealTime, 0, 0, 0};
        
        FragConstants: cbuffer_mesh_fragment;
        FragConstants.LightColour = LightColour;
        FragConstants.LightMatrix = LightMatrix;
        FragConstants.FragDebugMode = FragDebugMode;
        
        memcpy(OpaquePass.VertConstants, *VertConstants, size_of(cbuffer_mesh_vertex));
        memcpy(OpaquePass.FragConstants, *FragConstants, size_of(cbuffer_mesh_fragment));
    }
    
    {
        VertConstants: cbuffer_screenspacemesh_vertex;
        VertConstants.Projection = OrthoProjectionMatrix(0, 1366, 768, 0, -999.0, 999.0);
        memcpy(ScreenSpacePass.VertConstants, *VertConstants, size_of(cbuffer_screenspacemesh_vertex));
    }
    
    CommandBuffer := SDL_AcquireGPUCommandBuffer(GDevice);
    
    SDL_AcquireGPUSwapchainTexture(CommandBuffer, GWindow, *SwapTexture, null, null);
    if !SwapTexture {
        SDL_CancelGPUCommandBuffer(CommandBuffer);
        return;
    }
    
    MapInstanceBuffer(DepthPass.InstanceBuffer);
    MapInstanceBuffer(OpaquePass.InstanceBuffer);
    MapInstanceBuffer(ScreenSpacePass.InstanceBuffer);
    
    DepthCommands := ArenaPushN(*FrameArena, draw_command, 1);
    DrawCubes(DepthPass, *DepthCommands[0]);
    //DrawPlane(*DepthPass, *DepthCommands[1]);
    DepthPass.Commands = DepthCommands;
    
    OpaqueCommands := ArenaPushN(*FrameArena, draw_command, 2);
    DrawCubes(OpaquePass, *OpaqueCommands[0]);
    DrawPlane(OpaquePass, *OpaqueCommands[1]);
    OpaquePass.Commands = OpaqueCommands;
    
    ScreenSpaceCommands := ArenaPushN(*FrameArena, draw_command, 1);
    DrawShadowMap(ScreenSpacePass, *ScreenSpaceCommands[0]);
    ScreenSpacePass.Commands = ScreenSpaceCommands;
    
    SDL_UnmapGPUTransferBuffer(GDevice, DepthPass.InstanceBuffer.TransferBuffer);
    SDL_UnmapGPUTransferBuffer(GDevice, OpaquePass.InstanceBuffer.TransferBuffer);
    
    CopyPass := SDL_BeginGPUCopyPass(CommandBuffer);
    CommitInstanceBuffer(DepthPass.InstanceBuffer, CopyPass);
    CommitInstanceBuffer(OpaquePass.InstanceBuffer, CopyPass);
    CommitInstanceBuffer(ScreenSpacePass.InstanceBuffer, CopyPass);
    SDL_EndGPUCopyPass(CopyPass);
    
    DrawPass(DepthPass, CommandBuffer);
    DrawPass(OpaquePass, CommandBuffer);
    
    if FragDebugMode == 1 {
        DrawPass(ScreenSpacePass, CommandBuffer);
    }
    
    SDL_SubmitGPUCommandBuffer(CommandBuffer);
    
    SwapTexture = null;
}

MAX_BONES :: 1024;

SHADOW_MAP_SIZE :: 8192*2;

NEAR_PLANE :: 0.1;
FAR_PLANE :: 100.0;

MAX_INSTANCES :: 1024;

#scope_file

MAX_FRAG_DEBUG_MODE :: 1;
FragDebugMode: s32;

cbuffer_shadow_vertex :: struct {
    LightMatrix: float4x4;
    Time: float4;
}

cbuffer_mesh_vertex :: struct {
    View: float4x4;
    Projection: float4x4;
    ViewPos: float3;
    Pad1: float;
    LightDir: float3;
    Pad2: float;
    Time: float4;
}

cbuffer_mesh_fragment :: struct {
    LightColour: float3;
    Pad2: float;
    LightMatrix: float4x4;
    FragDebugMode: s32;
    Pad5: float3;
}

ibuffer_mesh :: struct {
    Transform: float4x4;
    DiffuseColour: float3;
    Pad0: float;
    MaterialParams: float4;
}

ScreenSpacePositionBuffer: *SDL_GPUBuffer;
ScreenSpaceTexCoordBuffer: *SDL_GPUBuffer;
ScreenSpaceIndexBuffer: *SDL_GPUBuffer;

cbuffer_screenspacemesh_vertex :: struct {
    Projection: float4x4;
}

MeshPipeline: *SDL_GPUGraphicsPipeline;
DepthPipeline: *SDL_GPUGraphicsPipeline;
ScreenSpacePipeline: *SDL_GPUGraphicsPipeline;

SwapTexture: *SDL_GPUTexture;

ShadowTexture: *SDL_GPUTexture;

SkinningMatricesBuffer: *SDL_GPUBuffer;
DepthTexture: *SDL_GPUTexture;

DefaultSampler: *SDL_GPUSampler;
ShadowSampler: *SDL_GPUSampler;

RendererArena: arena;

draw_pass_type :: enum {
    DEPTH;
    OPAQUE;
    TRANSLUCENT;
    SCREEN_SPACE;
}

draw_pass :: struct ($T: Type) {
    Type: draw_pass_type;
    Pipeline: *SDL_GPUGraphicsPipeline;
    
    VertConstants: *void;
    VertConstantsSize: int;
    FragConstants: *void;
    FragConstantsSize: int;
    
    Commands: [] draw_command;
    
    ColourTarget: bool;
    ClearColour: bool;
    ColourTargetTextureOverride: *SDL_GPUTexture;
    DepthTarget: *SDL_GPUTexture;
    
    Textures: [] *SDL_GPUTexture;
    Samplers: [] *SDL_GPUSampler;
    StorageBuffers: [] *SDL_GPUBuffer;
    
    Viewport: float2;
    
    InstanceBuffer: *instance_buffer(T);
}

draw_command :: struct {
    VertexBuffers: [] *SDL_GPUBuffer;
    IndexBuffer: *SDL_GPUBuffer;
    Textures: [] *SDL_GPUTexture;
    Samplers: [] *SDL_GPUSampler;
    
    IndexCount: int;
    InstanceCount: int;
}

DrawPass :: (Pass: *draw_pass, CommandBuffer: *SDL_GPUCommandBuffer) {
    ColourTargetCount := 0;
    ColourInfo: SDL_GPUColorTargetInfo;
    ColourTarget: *SDL_GPUColorTargetInfo;
    if Pass.ColourTarget {
        TargetTexture: *SDL_GPUTexture;
        if !Pass.ColourTargetTextureOverride {
            TargetTexture = SwapTexture;
        } else {
            TargetTexture = Pass.ColourTargetTextureOverride;
        }
        
        ColourInfo.clear_color = .{0, 0, 0, 1};
        if Pass.ClearColour ColourInfo.load_op = .SDL_GPU_LOADOP_CLEAR;
        else ColourInfo.load_op = .SDL_GPU_LOADOP_LOAD;
        ColourInfo.store_op = .SDL_GPU_STOREOP_STORE;
        ColourInfo.texture = TargetTexture;
        ColourTargetCount = 1;
        
        ColourTarget = *ColourInfo;
        
    }
    
    DepthInfo: SDL_GPUDepthStencilTargetInfo;
    DepthTarget: *SDL_GPUDepthStencilTargetInfo;
    if Pass.DepthTarget {
        DepthInfo.texture = Pass.DepthTarget;
        DepthInfo.cycle = false;
        DepthInfo.clear_depth = 1;
        DepthInfo.clear_stencil = 0;
        DepthInfo.load_op = .SDL_GPU_LOADOP_CLEAR;
        DepthInfo.store_op = .SDL_GPU_STOREOP_STORE;
        DepthInfo.stencil_load_op = .SDL_GPU_LOADOP_DONT_CARE;
        DepthInfo.stencil_store_op = .SDL_GPU_STOREOP_DONT_CARE;
        
        DepthTarget = *DepthInfo;
    }
    
    RenderPass := SDL_BeginGPURenderPass(CommandBuffer, ColourTarget, xx ColourTargetCount, DepthTarget);
    
    Viewport: SDL_GPUViewport;
    Viewport.x = 0;
    Viewport.y = 0;
    Viewport.w = xx Pass.Viewport.x;
    Viewport.h = xx Pass.Viewport.y;
    Viewport.min_depth = 0.0;
    Viewport.max_depth = 1.0;
    SDL_SetGPUViewport(RenderPass, *Viewport);
    
    SDL_BindGPUGraphicsPipeline(RenderPass, Pass.Pipeline);
    
    TextureBindings := ArenaPushN(*FrameArena, SDL_GPUTextureSamplerBinding, xx Pass.Textures.count);
    for Texture, TextureIndex: Pass.Textures {
        TextureBindings[TextureIndex] = .{Texture, Pass.Samplers[TextureIndex]};
    }
    
    SDL_BindGPUFragmentSamplers(RenderPass, 0, TextureBindings.data, xx TextureBindings.count);
    SDL_BindGPUVertexStorageBuffers(RenderPass, 0, Pass.StorageBuffers.data, xx Pass.StorageBuffers.count);
    
    SDL_PushGPUVertexUniformData(CommandBuffer, 0, Pass.VertConstants, xx Pass.VertConstantsSize);
    SDL_PushGPUFragmentUniformData(CommandBuffer, 0, Pass.FragConstants, xx Pass.FragConstantsSize);
    
    if Pass.InstanceBuffer {
        SDL_BindGPUVertexStorageBuffers(RenderPass, xx Pass.StorageBuffers.count, *Pass.InstanceBuffer.Buffer, 1);
    }
    
    BaseInstance := 0;
    for Pass.Commands {
        VertexBindings := ArenaPushN(*FrameArena, SDL_GPUBufferBinding, xx it.VertexBuffers.count);
        for Buffer: it.VertexBuffers {
            VertexBindings[it_index] = .{Buffer, 0};
        }
        
        IndexBinding := SDL_GPUBufferBinding.{it.IndexBuffer, 0};
        
        TextureBindings := ArenaPushN(*FrameArena, SDL_GPUTextureSamplerBinding, xx it.Textures.count);
        for Texture, TextureIndex: it.Textures {
            TextureBindings[TextureIndex] = .{Texture, it.Samplers[TextureIndex]};
        }
        
        SDL_BindGPUVertexBuffers(RenderPass, 0, VertexBindings.data, xx VertexBindings.count);
        SDL_BindGPUIndexBuffer(RenderPass, *IndexBinding, .SDL_GPU_INDEXELEMENTSIZE_32BIT);
        SDL_BindGPUFragmentSamplers(RenderPass, xx Pass.Textures.count, TextureBindings.data, xx TextureBindings.count);
        
        SDL_DrawGPUIndexedPrimitives(RenderPass, xx it.IndexCount, xx it.InstanceCount, 0, 0, xx BaseInstance);
        BaseInstance += it.InstanceCount;
    }
    
    SDL_EndGPURenderPass(RenderPass);
}

DrawMeshInstanced :: (Pass: *draw_pass, Command: *draw_command, Mesh: *mesh, InstanceCount: int, Textures: [] *texture) {
    if Pass.Type == .DEPTH {
        Buffers := ArenaPushN(*FrameArena, *SDL_GPUBuffer, 3);
        Buffers[0] = Mesh.PositionBuffer;
        Buffers[1] = Mesh.WeightBuffer;
        Buffers[2] = Mesh.BoneIdsBuffer;
        Command.VertexBuffers = Buffers;
    } else if Pass.Type == .OPAQUE || Pass.Type == .TRANSLUCENT {
        Buffers := ArenaPushN(*FrameArena, *SDL_GPUBuffer, 6);
        Buffers[0] = Mesh.PositionBuffer;
        Buffers[1] = Mesh.TexCoordBuffer;
        Buffers[2] = Mesh.NormalBuffer;
        Buffers[3] = Mesh.TangentBuffer;
        Buffers[4] = Mesh.WeightBuffer;
        Buffers[5] = Mesh.BoneIdsBuffer;
        Command.VertexBuffers = Buffers;
    }
    
    Command.IndexBuffer = Mesh.IndexBuffer;
    Command.IndexCount = Mesh.NumIndices;
    
    Command.Textures = ArenaPushN(*FrameArena, *SDL_GPUTexture, xx Textures.count);
    Command.Samplers = ArenaPushN(*FrameArena, *SDL_GPUSampler, xx Textures.count);
    for Textures {
        Command.Textures[it_index] = it.GpuTexture;
        Command.Samplers[it_index] = DefaultSampler;
    }
    
    Command.InstanceCount = InstanceCount;
}

DrawPlane :: (Pass: *draw_pass, Command: *draw_command) {
    Mesh := LoadMesh("Meshes/plane.mesh");
    Textures := ArenaPushN(*FrameArena, *texture, 3);
    Textures[0] = LoadTexture("Textures/floor_diffuse.png");
    Textures[1] = LoadTexture("Textures/floor_normal.png");
    Textures[2] = LoadTexture("Textures/floor_rmaoh.png");
    
    Instances := ArenaPushN(*WorkingArena, ibuffer_mesh, 1);
    
    Instances[0].Transform = TranslationMatrix(.{0, 0, -1});
    Instances[0].DiffuseColour = .{1, 1, 1};
    Instances[0].MaterialParams = .{1, 1, 1, 8};
    
    WriteInstanceBuffer(Pass.InstanceBuffer, Instances);
    
    DrawMeshInstanced(Pass, Command, Mesh, 1, Textures);
}

DrawCubes :: (Pass: *draw_pass, Command: *draw_command) {
    Mesh := LoadMesh("Meshes/cube.mesh");
    Textures := ArenaPushN(*FrameArena, *texture, 3);
    Textures[0] = LoadTexture("Textures/unit_diffuse.png");
    Textures[1] = LoadTexture("Textures/unit_normal.png");
    Textures[2] = LoadTexture("Textures/unit_rmaoh.png");
    
    ArenaPushMarkDefer(*WorkingArena);
    Instances := ArenaPushN(*WorkingArena, ibuffer_mesh, 343);
    
    Rotation := RotationMatrix(QuatFromAxisAngle(.{0, 0, 1}, fmod_cycling(GameTime*0.03, 1.0)));
    
    i := 0;
    for x: -3..3 {
        for y: -3..3 {
            for z: -3..3 {
                Instance := *Instances[i];
                Instance.Transform = Rotation * TranslationMatrix(.{xx (x*10), xx (y*10), xx (z*10)});
                Instance.DiffuseColour = .{1, 1, 1};
                Instance.MaterialParams = float4.{1, 1, 1, 1};
                i += 1;
            }
        }
    }
    
    WriteInstanceBuffer(Pass.InstanceBuffer, Instances);
    
    DrawMeshInstanced(Pass, Command, Mesh, 343, Textures);
}

DrawShadowMap :: (Pass: *draw_pass, Command: *draw_command) {
    Buffers := ArenaPushN(*FrameArena, *SDL_GPUBuffer, 2);
    Buffers[0] = ScreenSpacePositionBuffer;
    Buffers[1] = ScreenSpaceTexCoordBuffer;
    Command.VertexBuffers = Buffers;
    
    Command.IndexBuffer = ScreenSpaceIndexBuffer;
    Command.IndexCount = 6;
    
    Command.Textures = ArenaPushN(*FrameArena, *SDL_GPUTexture, 1);
    Command.Textures[0] = ShadowTexture;
    
    Command.Samplers = ArenaPushN(*FrameArena, *SDL_GPUSampler, 1);
    Command.Samplers[0] = ShadowSampler;
    
    Command.InstanceCount = 1;
}

instance_buffer :: struct ($T: Type) {
    Buffer: *SDL_GPUBuffer;
    TransferBuffer: *SDL_GPUTransferBuffer;
    Used: int;
    Capacity: int;
    Mapping: *T;
}

CreateInstanceBufferForPass :: (Pass: *draw_pass($T), Name: string) -> *instance_buffer(T) {
    InstanceBuffer := ArenaPush(*RendererArena, instance_buffer(T));
    InstanceBuffer.Buffer = CreateBuffer(Name, size_of(T) * MAX_INSTANCES, SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ);
    InstanceBuffer.TransferBuffer = CreateTransferBuffer(size_of(T) * MAX_INSTANCES);
    InstanceBuffer.Capacity = MAX_INSTANCES;
    return InstanceBuffer;
}

MapInstanceBuffer :: (InstanceBuffer: *$T/instance_buffer) {
    if !InstanceBuffer return;
    
    InstanceBuffer.Mapping = SDL_MapGPUTransferBuffer(GDevice, InstanceBuffer.TransferBuffer, false);
    InstanceBuffer.Used = 0;
}

WriteInstanceBuffer :: (InstanceBuffer: *$I/instance_buffer, Data: [] $T) {
    if !InstanceBuffer return;
    
    if InstanceBuffer.Used + Data.count >= InstanceBuffer.Capacity return;
    memcpy(InstanceBuffer.Mapping + InstanceBuffer.Used, Data.data, Data.count * size_of(T));
    InstanceBuffer.Used += Data.count;
}

CommitInstanceBuffer :: (InstanceBuffer: *$I/instance_buffer, CopyPass: *SDL_GPUCopyPass) {
    if !InstanceBuffer return;
    
    Location: SDL_GPUTransferBufferLocation;
    Location.transfer_buffer = InstanceBuffer.TransferBuffer;
    Location.offset = 0;
    
    Region: SDL_GPUBufferRegion;
    Region.buffer = InstanceBuffer.Buffer;
    Region.offset = 0;
    Region.size = xx (size_of(I.T) * InstanceBuffer.Used);
    
    SDL_UploadToGPUBuffer(CopyPass, *Location, *Region, false);
}