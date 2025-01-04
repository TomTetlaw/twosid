
GFrameNum := 0;

InitRenderer :: () {
    // screen space Pipeline
    {
        ColourTargetDesc: SDL_GPUColorTargetDescription;
        ColourTargetDesc.format = SDL_GetGPUSwapchainTextureFormat(GDevice, GWindow);
        ColourTargetDesc.blend_state.src_color_blendfactor = .SDL_GPU_BLENDFACTOR_SRC_ALPHA;
        ColourTargetDesc.blend_state.dst_color_blendfactor = .SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
        ColourTargetDesc.blend_state.color_blend_op = .SDL_GPU_BLENDOP_ADD;
        ColourTargetDesc.blend_state.src_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ONE;
        ColourTargetDesc.blend_state.dst_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ZERO;
        ColourTargetDesc.blend_state.alpha_blend_op = .SDL_GPU_BLENDOP_ADD;
        ColourTargetDesc.blend_state.enable_blend = true;
        
        ScreenSpaceCreateInfo: SDL_GPUGraphicsPipelineCreateInfo;
        
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
        
        ScreenSpaceCreateInfo.vertex_shader = ShaderScreenSpace.Vert;
        ScreenSpaceCreateInfo.fragment_shader = ShaderScreenSpace.Frag;
        
        ScreenSpacePipeline = SDL_CreateGPUGraphicsPipeline(GDevice, *ScreenSpaceCreateInfo);
        
        ScreenSpaceCreateInfo.vertex_shader = ShaderText.Vert;
        ScreenSpaceCreateInfo.fragment_shader = ShaderText.Frag;
        
        TextPipeline = SDL_CreateGPUGraphicsPipeline(GDevice, *ScreenSpaceCreateInfo);
    }
    
    DepthFormat := SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_D32_FLOAT;
    
    // depth Pass Pipeline
    {
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
        
        DepthCreateInfo.rasterizer_state.cull_mode = .SDL_GPU_CULLMODE_NONE;
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
        DepthInfo.format = DepthFormat;
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
        
        MeshCreateInfo.rasterizer_state.cull_mode = .SDL_GPU_CULLMODE_FRONT;
        MeshCreateInfo.rasterizer_state.fill_mode = .SDL_GPU_FILLMODE_FILL;
        MeshCreateInfo.rasterizer_state.front_face = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE;
        
        BufferDescriptions: [6] SDL_GPUVertexBufferDescription;
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
        
        MeshCreateInfo.rasterizer_state.cull_mode = .SDL_GPU_CULLMODE_NONE;
        UnlitPipeline = SDL_CreateGPUGraphicsPipeline(GDevice, *MeshCreateInfo);
        
        MeshCreateInfo.vertex_input_state.num_vertex_buffers = 1;
        MeshCreateInfo.vertex_input_state.num_vertex_attributes = 1;
        MeshCreateInfo.rasterizer_state.cull_mode = .SDL_GPU_CULLMODE_NONE;
        MeshCreateInfo.rasterizer_state.fill_mode = .SDL_GPU_FILLMODE_LINE;
        MeshCreateInfo.vertex_shader = ShaderDebug.Vert;
        MeshCreateInfo.fragment_shader = ShaderDebug.Frag;
        WireframeMeshPipeline = SDL_CreateGPUGraphicsPipeline(GDevice, *MeshCreateInfo);
    }
    
    // translucent Pipeline
    {
        TranslucentCreateInfo: SDL_GPUGraphicsPipelineCreateInfo;
        ColourTargetDesc: SDL_GPUColorTargetDescription;
        ColourTargetDesc.format = SDL_GetGPUSwapchainTextureFormat(GDevice, GWindow);
        
        ColourTargetDesc.blend_state.src_color_blendfactor = .SDL_GPU_BLENDFACTOR_SRC_ALPHA;
        ColourTargetDesc.blend_state.dst_color_blendfactor = .SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
        ColourTargetDesc.blend_state.color_blend_op = .SDL_GPU_BLENDOP_ADD;
        
        ColourTargetDesc.blend_state.src_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ONE;
        ColourTargetDesc.blend_state.dst_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ZERO;
        ColourTargetDesc.blend_state.alpha_blend_op = .SDL_GPU_BLENDOP_ADD;
        
        ColourTargetDesc.blend_state.enable_blend = true;
        
        TranslucentCreateInfo.target_info.has_depth_stencil_target = true;
        TranslucentCreateInfo.target_info.depth_stencil_format = DepthFormat;
        TranslucentCreateInfo.target_info.color_target_descriptions = *ColourTargetDesc;
        TranslucentCreateInfo.target_info.num_color_targets = 1;
        
        TranslucentCreateInfo.depth_stencil_state.compare_op = .SDL_GPU_COMPAREOP_LESS;
        TranslucentCreateInfo.depth_stencil_state.enable_depth_test = true;
        TranslucentCreateInfo.depth_stencil_state.enable_depth_write = false;
        TranslucentCreateInfo.depth_stencil_state.enable_stencil_test = false;
        
        TranslucentCreateInfo.rasterizer_state.cull_mode = .SDL_GPU_CULLMODE_BACK;
        TranslucentCreateInfo.rasterizer_state.fill_mode = .SDL_GPU_FILLMODE_FILL;
        TranslucentCreateInfo.rasterizer_state.front_face = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE;
        
        BufferDescriptions: [6] SDL_GPUVertexBufferDescription;
        BufferDescriptions[0] = .{0, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[1] = .{1, size_of(float2), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[2] = .{2, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[3] = .{3, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[4] = .{4, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[5] = .{5, size_of(bone_ids), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        TranslucentCreateInfo.vertex_input_state.vertex_buffer_descriptions = BufferDescriptions.data;
        TranslucentCreateInfo.vertex_input_state.num_vertex_buffers = 6;
        
        VertexAttributes: [6] SDL_GPUVertexAttribute;
        VertexAttributes[0] = .{0, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[1] = .{1, 1, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, 0};
        VertexAttributes[2] = .{2, 2, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[3] = .{3, 3, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[4] = .{4, 4, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[5] = .{5, 5, .SDL_GPU_VERTEXELEMENTFORMAT_SHORT4, 0};
        TranslucentCreateInfo.vertex_input_state.vertex_attributes = VertexAttributes.data;
        TranslucentCreateInfo.vertex_input_state.num_vertex_attributes = 6;
        
        TranslucentCreateInfo.primitive_type = .SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
        TranslucentCreateInfo.vertex_shader = ShaderMesh.Vert;
        TranslucentCreateInfo.fragment_shader = ShaderMesh.Frag;
        
        TranslucentPipeline = SDL_CreateGPUGraphicsPipeline(GDevice, *TranslucentCreateInfo);
    }
    
    {
        ScreenSpacePositionBuffer = CreateVertexBuffer("ScreenSpacePositionBuffer", size_of(float3), 4);
        ScreenSpaceTexCoordBuffer = CreateVertexBuffer("ScreenSpaceTexCoordBuffer", size_of(float2), 4);
        ScreenSpaceIndexBuffer = CreateIndexBuffer("ScreenSpaceIndexBuffer", 6);
        
        CreateInfo: SDL_GPUTransferBufferCreateInfo;
        CreateInfo.usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
        CreateInfo.size = size_of(float) * 5 * 4 + size_of(u32) * 6;
        TransferBuffer := SDL_CreateGPUTransferBuffer(GDevice, *CreateInfo);
        TransferMemory := cast (*u8) SDL_MapGPUTransferBuffer(GDevice, TransferBuffer, false);
        
        {
            Memory := cast(*float3) TransferMemory;
            Memory[0] = .{0, 0, 0};
            Memory[1] = .{1, 0, 0};
            Memory[2] = .{1, 1, 0};
            Memory[3] = .{0, 1, 0};
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
    
    SamplerInfo.max_lod = 0;
    NoMipMapSampler = SDL_CreateGPUSampler(GDevice, *SamplerInfo);
    
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
    InitRendererFrontend();
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
    
    Right, Top, Far := -FLOAT32_MAX;
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

InitPasses :: () {
    {
        DepthPass = ArenaPush(*RendererArena, draw_pass(ibuffer_mesh));
        DepthPass.Name = "DepthPass";
        DepthPass.Type = .DEPTH;
        DepthPass.BuffersNeeded = .DEPTH_ONLY;
        DepthPass.TexturesNeeded = .NONE;
        DepthPass.Pipeline = DepthPipeline;
        
        DepthPass.VertConstants = ArenaPush(*RendererArena, cbuffer_shadow_vertex);
        DepthPass.VertConstantsSize = size_of(cbuffer_shadow_vertex);
        
        DepthPass.ColourTarget = false;
        DepthPass.ClearDepth = true;
        DepthPass.DepthTarget = ShadowTexture;
        DepthPass.Viewport = .{SHADOW_MAP_SIZE, SHADOW_MAP_SIZE};
        
        DepthPass.InstanceBuffer = CreateStructuredBuffer(ibuffer_mesh, "depth_instance", MAX_INSTANCES);
        DepthPass.SkinningBuffer = CreateStructuredBuffer(float4x4, "depth_skinning", MAX_BONES);
    }
    
    {
        OpaquePass = ArenaPush(*RendererArena, draw_pass(ibuffer_mesh));
        OpaquePass.Name = "OpaquePass";
        OpaquePass.Type = .OPAQUE;
        OpaquePass.BuffersNeeded = .MESH;
        OpaquePass.TexturesNeeded = .DIFFUSE_NORMAL_RMAOH;
        OpaquePass.Pipeline = MeshPipeline;
        
        OpaquePass.VertConstants = ArenaPush(*RendererArena, cbuffer_mesh_vertex);
        OpaquePass.VertConstantsSize = size_of(cbuffer_mesh_vertex);
        OpaquePass.FragConstants = ArenaPush(*RendererArena, cbuffer_mesh_fragment);
        OpaquePass.FragConstantsSize = size_of(cbuffer_mesh_fragment);
        
        OpaquePass.Textures = ArenaPushN(*RendererArena, SDL_GPUTextureSamplerBinding, .[.{ShadowTexture, ShadowSampler}]);
        
        OpaquePass.ColourTarget = true;
        OpaquePass.ClearColour = true;
        OpaquePass.ClearDepth = true;
        OpaquePass.DepthTarget = DepthTexture;
        OpaquePass.Viewport = .{1366, 768};
        
        OpaquePass.InstanceBuffer = CreateStructuredBuffer(ibuffer_mesh, "opaque_instance", MAX_INSTANCES);
        OpaquePass.SkinningBuffer = CreateStructuredBuffer(float4x4, "opaque_skinning", MAX_BONES);
    }
    
    {
        UnlitPass = ArenaPush(*RendererArena, draw_pass(ibuffer_mesh));
        UnlitPass.Name = "UnlitPass";
        UnlitPass.Type = .OPAQUE;
        UnlitPass.BuffersNeeded = .MESH;
        UnlitPass.TexturesNeeded = .DIFFUSE_NORMAL_RMAOH;
        UnlitPass.Pipeline = UnlitPipeline;
        
        UnlitPass.VertConstants = ArenaPush(*RendererArena, cbuffer_mesh_vertex);
        UnlitPass.VertConstantsSize = size_of(cbuffer_mesh_vertex);
        UnlitPass.FragConstants = ArenaPush(*RendererArena, cbuffer_mesh_fragment);
        UnlitPass.FragConstantsSize = size_of(cbuffer_mesh_fragment);
        
        UnlitPass.Textures = ArenaPushN(*RendererArena, SDL_GPUTextureSamplerBinding, .[.{ShadowTexture, ShadowSampler}]);
        
        UnlitPass.ColourTarget = true;
        UnlitPass.ClearColour = false;
        UnlitPass.ClearDepth = false;
        UnlitPass.DepthTarget = DepthTexture;
        UnlitPass.Viewport = .{1366, 768};
        
        UnlitPass.InstanceBuffer = CreateStructuredBuffer(ibuffer_mesh, "opaque_instance", MAX_INSTANCES);
        UnlitPass.SkinningBuffer = CreateStructuredBuffer(float4x4, "opaque_skinning", MAX_BONES);
    }
    
    {
        DebugPass = ArenaPush(*RendererArena, draw_pass(ibuffer_debug));
        DebugPass.Name = "DebugPass";
        DebugPass.Type = .OPAQUE;
        DebugPass.BuffersNeeded = .POSITION_ONLY;
        DebugPass.TexturesNeeded = .NONE;
        DebugPass.Pipeline = WireframeMeshPipeline;
        
        DebugPass.VertConstants = ArenaPush(*RendererArena, cbuffer_mesh_vertex);
        DebugPass.VertConstantsSize = size_of(cbuffer_mesh_vertex);
        DebugPass.FragConstants = ArenaPush(*RendererArena, cbuffer_mesh_fragment);
        DebugPass.FragConstantsSize = size_of(cbuffer_mesh_fragment);
        
        DebugPass.ColourTarget = true;
        DebugPass.ClearColour = false;
        DebugPass.ClearDepth = false;
        DebugPass.DepthTarget = DepthTexture;
        DebugPass.Viewport = .{1366, 768};
        
        DebugPass.InstanceBuffer = CreateStructuredBuffer(ibuffer_debug, "debug_instance", MAX_INSTANCES);
    }
    
    {
        TranslucentPass = ArenaPush(*RendererArena, draw_pass(ibuffer_mesh));
        TranslucentPass.Name = "TranslucentPass";
        TranslucentPass.Type = .TRANSLUCENT;
        TranslucentPass.BuffersNeeded = .MESH;
        TranslucentPass.TexturesNeeded = .DIFFUSE_NORMAL_RMAOH;
        TranslucentPass.Pipeline = TranslucentPipeline;
        
        TranslucentPass.VertConstants = ArenaPush(*RendererArena, cbuffer_mesh_vertex);
        TranslucentPass.VertConstantsSize = size_of(cbuffer_mesh_vertex);
        TranslucentPass.FragConstants = ArenaPush(*RendererArena, cbuffer_mesh_fragment);
        TranslucentPass.FragConstantsSize = size_of(cbuffer_mesh_fragment);
        
        TranslucentPass.Textures = ArenaPushN(*RendererArena, SDL_GPUTextureSamplerBinding, .[.{ShadowTexture, ShadowSampler}]);
        
        TranslucentPass.ColourTarget = true;
        TranslucentPass.ClearColour = false;
        TranslucentPass.ClearDepth = false;
        TranslucentPass.DepthTarget = DepthTexture;
        TranslucentPass.Viewport = .{1366, 768};
        
        TranslucentPass.InstanceBuffer = CreateStructuredBuffer(ibuffer_mesh, "translucent_instance", MAX_INSTANCES);
        TranslucentPass.SkinningBuffer = CreateStructuredBuffer(float4x4, "translucent_skinning", MAX_BONES);
    }
    
    {
        ScreenSpacePass = ArenaPush(*RendererArena, draw_pass(ibuffer_ss_quad));
        ScreenSpacePass.Name = "ScreenSpacePass";
        ScreenSpacePass.Type = .SCREEN_SPACE;
        ScreenSpacePass.BuffersNeeded = .NONE;
        ScreenSpacePass.TexturesNeeded = .DIFFUSE;
        ScreenSpacePass.Pipeline = ScreenSpacePipeline;
        
        ScreenSpacePass.VertConstants = ArenaPush(*RendererArena, cbuffer_screenspacemesh_vertex);
        ScreenSpacePass.VertConstantsSize = size_of(cbuffer_screenspacemesh_vertex);
        
        ScreenSpacePass.ColourTarget = true;
        ScreenSpacePass.ClearColour = false;
        ScreenSpacePass.Viewport = .{1366, 768};
        
        ScreenSpacePass.InstanceBuffer = CreateStructuredBuffer(ibuffer_ss_quad, "screen_space_instance", MAX_INSTANCES);
    }
    
    {
        TextPass = ArenaPush(*RendererArena, draw_pass(ibuffer_ss_quad));
        TextPass.Name = "TextPass";
        TextPass.Type = .SCREEN_SPACE;
        TextPass.BuffersNeeded = .NONE;
        TextPass.TexturesNeeded = .DIFFUSE;
        TextPass.Pipeline = TextPipeline;
        
        TextPass.VertConstants = ArenaPush(*RendererArena, cbuffer_screenspacemesh_vertex);
        TextPass.VertConstantsSize = size_of(cbuffer_screenspacemesh_vertex);
        
        TextPass.ColourTarget = true;
        TextPass.ClearColour = false;
        TextPass.Viewport = .{1366, 768};
        
        TextPass.InstanceBuffer = CreateStructuredBuffer(ibuffer_ss_quad, "text_instance", MAX_INSTANCES);
    }
}

ResetPass :: (Pass: *draw_pass($T)) {
    ArenaReset(*Pass.Commands);
}

ResetPasses :: () {
    ResetPass(DepthPass);
    ResetPass(OpaquePass);
    ResetPass(TranslucentPass);
    ResetPass(DebugPass);
    ResetPass(ScreenSpacePass);
    ResetPass(TextPass);
    ResetPass(UnlitPass);
}

DrawFrame :: (Camera: *$T/interface view_parameters) {
    if KeyPressed(.SDL_SCANCODE_UP) {
        FragDebugMode = clamp(FragDebugMode - 1, 0, MAX_FRAG_DEBUG_MODE);
    }
    if KeyPressed(.SDL_SCANCODE_DOWN) {
        FragDebugMode = clamp(FragDebugMode + 1, 0, MAX_FRAG_DEBUG_MODE);
    }
    
    LightPos := float3.{0, 0, 10};
    LightTarget := float3.{1, -1, 1};
    LightDir := Normalize(LightTarget - LightPos);
    
    LightColour := float3.{1.0, 1.0, 0.8};
    LightMatrix := CalcLightSpaceMatrix(LightPos, LightDir, Camera.Proj, Camera.View);
    
    {
        VertConstants: cbuffer_shadow_vertex;
        VertConstants.LightMatrix = LightMatrix;
        VertConstants.Time = .{RealTime, 0, 0, 0};
        memcpy(DepthPass.VertConstants, *VertConstants, size_of(cbuffer_shadow_vertex));
    }
    
    {
        VertConstants: cbuffer_mesh_vertex;
        VertConstants.View = Camera.View;
        VertConstants.Projection = Camera.Proj;
        VertConstants.ViewPos = Camera.Position;
        VertConstants.LightDir = LightDir;
        VertConstants.Time = .{RealTime, 0, 0, 0};
        
        FragConstants: cbuffer_mesh_fragment;
        FragConstants.LightColour = LightColour;
        FragConstants.LightMatrix = LightMatrix;
        FragConstants.FragDebugMode = FragDebugMode;
        
        memcpy(OpaquePass.VertConstants, *VertConstants, size_of(cbuffer_mesh_vertex));
        memcpy(OpaquePass.FragConstants, *FragConstants, size_of(cbuffer_mesh_fragment));
        memcpy(TranslucentPass.VertConstants, *VertConstants, size_of(cbuffer_mesh_vertex));
        memcpy(TranslucentPass.FragConstants, *FragConstants, size_of(cbuffer_mesh_fragment));
        memcpy(DebugPass.VertConstants, *VertConstants, size_of(cbuffer_mesh_vertex));
        memcpy(DebugPass.FragConstants, *FragConstants, size_of(cbuffer_mesh_fragment));
        memcpy(UnlitPass.VertConstants, *VertConstants, size_of(cbuffer_mesh_vertex));
        memcpy(UnlitPass.FragConstants, *FragConstants, size_of(cbuffer_mesh_fragment));
    }
    
    {
        VertConstants: cbuffer_screenspacemesh_vertex;
        VertConstants.Projection = OrthoProjectionMatrix(0, 1366, 768, 0, -999.0, 999.0);
        memcpy(ScreenSpacePass.VertConstants, *VertConstants, size_of(cbuffer_screenspacemesh_vertex));
    }
    
    {
        VertConstants: cbuffer_screenspacemesh_vertex;
        VertConstants.Projection = OrthoProjectionMatrix(0, 1366, 768, 0, -999.0, 999.0);
        memcpy(TextPass.VertConstants, *VertConstants, size_of(cbuffer_screenspacemesh_vertex));
    }
    
    CommandBuffer := SDL_AcquireGPUCommandBuffer(GDevice);
    
    SDL_AcquireGPUSwapchainTexture(CommandBuffer, GWindow, *SwapTexture, null, null);
    if !SwapTexture {
        SDL_CancelGPUCommandBuffer(CommandBuffer);
        return;
    }
    
    MapStructuredBuffer(DepthPass.InstanceBuffer);
    MapStructuredBuffer(OpaquePass.InstanceBuffer);
    MapStructuredBuffer(TranslucentPass.InstanceBuffer);
    MapStructuredBuffer(DebugPass.InstanceBuffer);
    MapStructuredBuffer(ScreenSpacePass.InstanceBuffer);
    MapStructuredBuffer(TextPass.InstanceBuffer);
    MapStructuredBuffer(UnlitPass.InstanceBuffer);
    
    MapStructuredBuffer(DepthPass.SkinningBuffer);
    MapStructuredBuffer(OpaquePass.SkinningBuffer);
    MapStructuredBuffer(UnlitPass.SkinningBuffer);
    MapStructuredBuffer(TranslucentPass.SkinningBuffer);
    
    ProcessDrawCommands();
    
    SDL_UnmapGPUTransferBuffer(GDevice, DepthPass.SkinningBuffer.TransferBuffer);
    SDL_UnmapGPUTransferBuffer(GDevice, OpaquePass.SkinningBuffer.TransferBuffer);
    SDL_UnmapGPUTransferBuffer(GDevice, TranslucentPass.SkinningBuffer.TransferBuffer);
    SDL_UnmapGPUTransferBuffer(GDevice, UnlitPass.SkinningBuffer.TransferBuffer);
    
    SDL_UnmapGPUTransferBuffer(GDevice, DepthPass.InstanceBuffer.TransferBuffer);
    SDL_UnmapGPUTransferBuffer(GDevice, OpaquePass.InstanceBuffer.TransferBuffer);
    SDL_UnmapGPUTransferBuffer(GDevice, TranslucentPass.InstanceBuffer.TransferBuffer);
    SDL_UnmapGPUTransferBuffer(GDevice, DebugPass.InstanceBuffer.TransferBuffer);
    SDL_UnmapGPUTransferBuffer(GDevice, ScreenSpacePass.InstanceBuffer.TransferBuffer);
    SDL_UnmapGPUTransferBuffer(GDevice, TextPass.InstanceBuffer.TransferBuffer);
    SDL_UnmapGPUTransferBuffer(GDevice, UnlitPass.SkinningBuffer.TransferBuffer);
    
    CopyPass := SDL_BeginGPUCopyPass(CommandBuffer);
    
    CommitStructuredBuffer(DepthPass.SkinningBuffer, CopyPass);
    CommitStructuredBuffer(OpaquePass.SkinningBuffer, CopyPass);
    CommitStructuredBuffer(TranslucentPass.SkinningBuffer, CopyPass);
    CommitStructuredBuffer(UnlitPass.SkinningBuffer, CopyPass);
    
    CommitStructuredBuffer(DepthPass.InstanceBuffer, CopyPass);
    CommitStructuredBuffer(OpaquePass.InstanceBuffer, CopyPass);
    CommitStructuredBuffer(TranslucentPass.InstanceBuffer, CopyPass);
    CommitStructuredBuffer(DebugPass.InstanceBuffer, CopyPass);
    CommitStructuredBuffer(ScreenSpacePass.InstanceBuffer, CopyPass);
    CommitStructuredBuffer(TextPass.InstanceBuffer, CopyPass);
    CommitStructuredBuffer(UnlitPass.InstanceBuffer, CopyPass);
    
    SDL_EndGPUCopyPass(CopyPass);
    
    DrawPass(DepthPass, CommandBuffer);
    DrawPass(OpaquePass, CommandBuffer);
    DrawPass(TranslucentPass, CommandBuffer);
    DrawPass(DebugPass, CommandBuffer);
    DrawPass(UnlitPass, CommandBuffer);
    DrawPass(ScreenSpacePass, CommandBuffer);
    DrawPass(TextPass, CommandBuffer);
    
    SDL_SubmitGPUCommandBuffer(CommandBuffer);
    
    SwapTexture = null;
    
    ResetPasses();
    ResetRendererFrontend();
    
    ArenaReset(*RendererFrameArena);
}

MAX_BONES :: 1024;

SHADOW_MAP_SIZE :: 4096;

NEAR_PLANE :: 0.1;
FAR_PLANE :: 500.0;

MAX_INSTANCES :: 10000;

RendererArena: arena;

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
    DiffuseColour: float4;
    MaterialParams: float4;
    FeatureFlags: float4;
}

ibuffer_debug :: struct {
    Transform: float4x4;
    DiffuseColour: float3;
    Pad: float;
}

ibuffer_ss_quad :: struct {
    Position: float2;
    Pad0: float2;
    Size: float2;
    Pad1: float2;
    Colour: float4;
    TexCoord: float4;
    TextParams: float4;
}

cbuffer_screenspacemesh_vertex :: struct {
    Projection: float4x4;
}

ibuffer_empty :: struct {}

draw_pass_type :: enum {
    DEPTH;
    OPAQUE;
    TRANSLUCENT;
    SCREEN_SPACE;
}

draw_pass_buffers :: enum {
    NONE;
    POSITION_ONLY;
    DEPTH_ONLY;
    MESH;
}

draw_pass_textures :: enum {
    NONE;
    DIFFUSE;
    DIFFUSE_NORMAL_RMAOH;
}

draw_pass :: struct ($T: Type) {
    Name: string;
    Type: draw_pass_type;
    BuffersNeeded: draw_pass_buffers;
    TexturesNeeded: draw_pass_textures;
    Pipeline: *SDL_GPUGraphicsPipeline;
    
    VertConstants: *void;
    VertConstantsSize: int;
    FragConstants: *void;
    FragConstantsSize: int;
    
    Commands: arena(render_command);
    
    ColourTarget: bool;
    ClearColour: bool;
    ClearDepth: bool;
    ColourTargetTextureOverride: *SDL_GPUTexture;
    DepthTarget: *SDL_GPUTexture;
    
    Textures: [] SDL_GPUTextureSamplerBinding;
    
    Viewport: float2;
    
    InstanceBuffer: *structured_buffer(T);
    SkinningBuffer: *structured_buffer(float4x4);
}

render_command_flags :: enum_flags {
    WIREFRAME;
}

render_command :: struct {
    VertexBuffers: [] SDL_GPUBufferBinding;
    IndexBuffer: *SDL_GPUBuffer;
    Textures: [] SDL_GPUTextureSamplerBinding;
    
    IndexCount: int;
    InstanceCount: int;
    
    Flags: render_command_flags;
}

structured_buffer :: struct ($T: Type) {
    Buffer: *SDL_GPUBuffer;
    TransferBuffer: *SDL_GPUTransferBuffer;
    Used: int;
    Capacity: int;
    Mapping: *T;
}

OpaquePass: *draw_pass(ibuffer_mesh);
DebugPass: *draw_pass(ibuffer_debug);
DepthPass: *draw_pass(ibuffer_mesh);
TranslucentPass: *draw_pass(ibuffer_mesh);
ScreenSpacePass: *draw_pass(ibuffer_ss_quad);
TextPass: *draw_pass(ibuffer_ss_quad);
UnlitPass: *draw_pass(ibuffer_mesh);

DefaultSampler: *SDL_GPUSampler;
NoMipMapSampler: *SDL_GPUSampler;
ShadowSampler: *SDL_GPUSampler;

RendererFrameArena: arena;

ScreenSpacePositionBuffer: *SDL_GPUBuffer;
ScreenSpaceTexCoordBuffer: *SDL_GPUBuffer;
ScreenSpaceIndexBuffer: *SDL_GPUBuffer;

#scope_file

MAX_FRAG_DEBUG_MODE :: 1;
FragDebugMode: s32;

MeshPipeline: *SDL_GPUGraphicsPipeline;
WireframeMeshPipeline: *SDL_GPUGraphicsPipeline;
DepthPipeline: *SDL_GPUGraphicsPipeline;
ScreenSpacePipeline: *SDL_GPUGraphicsPipeline;
TextPipeline: *SDL_GPUGraphicsPipeline;
TranslucentPipeline: *SDL_GPUGraphicsPipeline;
UnlitPipeline: *SDL_GPUGraphicsPipeline;

SwapTexture: *SDL_GPUTexture;

ShadowTexture: *SDL_GPUTexture;

DepthTexture: *SDL_GPUTexture;

DrawPass :: (Pass: *draw_pass, CommandBuffer: *SDL_GPUCommandBuffer) {
    SDL_PushGPUDebugGroup(CommandBuffer, Pass.Name.data);
    
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
        if Pass.ClearDepth DepthInfo.load_op = .SDL_GPU_LOADOP_CLEAR;
        else DepthInfo.load_op = .SDL_GPU_LOADOP_LOAD;
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
    
    Scissor: SDL_Rect;
    Scissor.x = 0;
    Scissor.y = 0;
    Scissor.w = xx Pass.Viewport.x;
    Scissor.h = xx Pass.Viewport.y;
    SDL_SetGPUScissor(RenderPass, *Scissor);
    
    SDL_BindGPUGraphicsPipeline(RenderPass, Pass.Pipeline);
    
    SDL_BindGPUFragmentSamplers(RenderPass, 0, Pass.Textures.data, xx Pass.Textures.count);
    
    SDL_PushGPUVertexUniformData(CommandBuffer, 0, Pass.VertConstants, xx Pass.VertConstantsSize);
    SDL_PushGPUFragmentUniformData(CommandBuffer, 0, Pass.FragConstants, xx Pass.FragConstantsSize);
    
    BufferIndex := 0;
    if Pass.SkinningBuffer {
        SDL_BindGPUVertexStorageBuffers(RenderPass, xx BufferIndex, *Pass.SkinningBuffer.Buffer, 1);
        BufferIndex += 1;
    }
    if Pass.InstanceBuffer {
        SDL_BindGPUVertexStorageBuffers(RenderPass, xx BufferIndex, *Pass.InstanceBuffer.Buffer, 1);
        BufferIndex += 1;
    }
    
    BaseInstance := 0;
    for Pass.Commands {
        SDL_BindGPUFragmentSamplers(RenderPass, xx Pass.Textures.count, it.Textures.data, xx it.Textures.count);
        
        SDL_BindGPUVertexBuffers(RenderPass, 0, it.VertexBuffers.data, xx it.VertexBuffers.count);
        
        if it.IndexBuffer {
            IndexBinding := SDL_GPUBufferBinding.{it.IndexBuffer, 0};
            SDL_BindGPUIndexBuffer(RenderPass, *IndexBinding, .SDL_GPU_INDEXELEMENTSIZE_32BIT);
        }
        
        SDL_DrawGPUIndexedPrimitives(RenderPass, xx it.IndexCount, xx it.InstanceCount, 0, 0, xx BaseInstance);
        BaseInstance += it.InstanceCount;
    }
    
    SDL_EndGPURenderPass(RenderPass);
    
    SDL_PopGPUDebugGroup(CommandBuffer);
}

CreateStructuredBuffer :: ($T: Type, Name: string, Capacity: int) -> *structured_buffer(T) {
    StructuredBuffer := ArenaPush(*RendererArena, structured_buffer(T));
    StructuredBuffer.Buffer = CreateBuffer(Name, size_of(T) * MAX_INSTANCES, SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ);
    StructuredBuffer.TransferBuffer = CreateTransferBuffer(size_of(T) * Capacity);
    StructuredBuffer.Capacity = MAX_INSTANCES;
    return StructuredBuffer;
}

MapStructuredBuffer :: (StructuredBuffer: *$T/structured_buffer) {
    if !StructuredBuffer return;
    
    StructuredBuffer.Mapping = SDL_MapGPUTransferBuffer(GDevice, StructuredBuffer.TransferBuffer, false);
    StructuredBuffer.Used = 0;
}

CommitStructuredBuffer :: (StructuredBuffer: *$I/structured_buffer, CopyPass: *SDL_GPUCopyPass) {
    if !StructuredBuffer return;
    if StructuredBuffer.Used == 0 return;
    
    Location: SDL_GPUTransferBufferLocation;
    Location.transfer_buffer = StructuredBuffer.TransferBuffer;
    Location.offset = 0;
    
    Region: SDL_GPUBufferRegion;
    Region.buffer = StructuredBuffer.Buffer;
    Region.offset = 0;
    Region.size = xx (size_of(I.T) * StructuredBuffer.Used);
    
    SDL_UploadToGPUBuffer(CopyPass, *Location, *Region, false);
}