
GFrameNum := 0;

BeginPass :: (Pass: *render_pass, CommandBuffer: *SDL_GPUCommandBuffer) {
    ColourTargetCount := 0;
    ColourInfo: SDL_GPUColorTargetInfo;
    ColourTarget: *SDL_GPUColorTargetInfo;
    if Pass.ColourTarget {
        TargetTexture: *SDL_GPUTexture;
        if !Pass.ColourTexture {
            TargetTexture = SwapTexture;
        } else {
            TargetTexture = Pass.ColourTexture;
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
        DepthInfo.texture = Pass.DepthTexture;
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
    
    Assert(Pass.RenderPass == null);
    Pass.RenderPass = SDL_BeginGPURenderPass(CommandBuffer, ColourTarget, xx ColourTargetCount, DepthTarget);
}

EndPass :: (Pass: *render_pass) {
    Assert(Pass.RenderPass != null);
    SDL_EndGPURenderPass(Pass.RenderPass);
    Pass.RenderPass = null;
}

CreatePipeline :: (Name: string, Options: *pipeline_options, Textures: [] SDL_GPUTextureSamplerBinding, $Cv: Type, $Cf: Type, $I: Type, TextureCount: int) -> *pipeline {
    Info: SDL_GPUGraphicsPipelineCreateInfo;
    
    ColourTargetDesc: SDL_GPUColorTargetDescription;
    ColourTargetDesc.format = SDL_GetGPUSwapchainTextureFormat(GDevice, GWindow);
    if Options.AlphaBlending {
        ColourTargetDesc.blend_state.src_color_blendfactor = .SDL_GPU_BLENDFACTOR_SRC_ALPHA;
        ColourTargetDesc.blend_state.dst_color_blendfactor = .SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
        ColourTargetDesc.blend_state.color_blend_op = .SDL_GPU_BLENDOP_ADD;
        ColourTargetDesc.blend_state.src_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ONE;
        ColourTargetDesc.blend_state.dst_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ZERO;
        ColourTargetDesc.blend_state.alpha_blend_op = .SDL_GPU_BLENDOP_ADD;
        ColourTargetDesc.blend_state.enable_blend = true;
    }
    
    if Options.ColourTarget {
        Info.target_info.color_target_descriptions = *ColourTargetDesc;
        Info.target_info.num_color_targets = 1;
    }
    
    if Options.DepthTarget {
        DepthFormat := SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_D32_FLOAT;
        
        Info.target_info.has_depth_stencil_target = true;
        Info.target_info.depth_stencil_format = DepthFormat;
        
        Info.depth_stencil_state.compare_op = .SDL_GPU_COMPAREOP_LESS;
        Info.depth_stencil_state.enable_depth_test = Options.DepthTest;
        Info.depth_stencil_state.enable_depth_write = Options.DepthWrite;
        Info.depth_stencil_state.enable_stencil_test = false;
    }
    
    Info.rasterizer_state.cull_mode = Options.CullMode;
    Info.rasterizer_state.fill_mode = Options.FillMode;
    Info.rasterizer_state.front_face = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE;
    
    Mark := ArenaPushMark(*WorkingArena);
    
    NeedsSkinningBuffer := false;
    AttributeCount := 0;
    
    if Options.Buffers == .POSITION_ONLY {
        AttributeCount = 1;
        
        BufferDescriptions := ArenaPushN(*WorkingArena, SDL_GPUVertexBufferDescription, AttributeCount);
        BufferDescriptions[0] = .{0, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        Info.vertex_input_state.vertex_buffer_descriptions = BufferDescriptions.data;
        Info.vertex_input_state.num_vertex_buffers = xx AttributeCount;
        
        VertexAttributes := ArenaPushN(*WorkingArena, SDL_GPUVertexAttribute, AttributeCount);
        VertexAttributes[0] = .{0, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        Info.vertex_input_state.vertex_attributes = VertexAttributes.data;
        Info.vertex_input_state.num_vertex_attributes = xx AttributeCount;
    }
    
    if Options.Buffers == .POSITION_TEXCOORD {
        AttributeCount = 2;
        
        BufferDescriptions := ArenaPushN(*WorkingArena, SDL_GPUVertexBufferDescription, AttributeCount);
        BufferDescriptions[0] = .{0, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[1] = .{1, size_of(float2), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        Info.vertex_input_state.vertex_buffer_descriptions = BufferDescriptions.data;
        Info.vertex_input_state.num_vertex_buffers = xx AttributeCount;
        
        VertexAttributes := ArenaPushN(*WorkingArena, SDL_GPUVertexAttribute, AttributeCount);
        VertexAttributes[0] = .{0, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[1] = .{1, 1, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, 0};
        Info.vertex_input_state.vertex_attributes = VertexAttributes.data;
        Info.vertex_input_state.num_vertex_attributes = xx AttributeCount;
    }
    
    if Options.Buffers == .POSITION_SKINNING {
        AttributeCount = 3;
        NeedsSkinningBuffer = true;
        
        BufferDescriptions := ArenaPushN(*WorkingArena, SDL_GPUVertexBufferDescription, AttributeCount);
        BufferDescriptions[0] = .{0, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[1] = .{1, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[2] = .{2, size_of(bone_ids), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        Info.vertex_input_state.vertex_buffer_descriptions = BufferDescriptions.data;
        Info.vertex_input_state.num_vertex_buffers = xx AttributeCount;
        
        VertexAttributes := ArenaPushN(*WorkingArena, SDL_GPUVertexAttribute, AttributeCount);
        VertexAttributes[0] = .{0, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[1] = .{1, 1, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[2] = .{2, 2, .SDL_GPU_VERTEXELEMENTFORMAT_SHORT4, 0};
        Info.vertex_input_state.vertex_attributes = VertexAttributes.data;
        Info.vertex_input_state.num_vertex_attributes = xx AttributeCount;
    }
    
    if Options.Buffers == .POSITION_TEXCOORD_NORMAL_TANGENT_SKINNING {
        AttributeCount = 6;
        NeedsSkinningBuffer = true;
        
        BufferDescriptions := ArenaPushN(*WorkingArena, SDL_GPUVertexBufferDescription, AttributeCount);
        BufferDescriptions[0] = .{0, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[1] = .{1, size_of(float2), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[2] = .{2, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[3] = .{3, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[4] = .{4, size_of(float3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        BufferDescriptions[5] = .{5, size_of(bone_ids), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        Info.vertex_input_state.vertex_buffer_descriptions = BufferDescriptions.data;
        Info.vertex_input_state.num_vertex_buffers = xx AttributeCount;
        
        VertexAttributes := ArenaPushN(*WorkingArena, SDL_GPUVertexAttribute, AttributeCount); 
        VertexAttributes[0] = .{0, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[1] = .{1, 1, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, 0};
        VertexAttributes[2] = .{2, 2, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[3] = .{3, 3, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[4] = .{4, 4, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        VertexAttributes[5] = .{5, 5, .SDL_GPU_VERTEXELEMENTFORMAT_SHORT4, 0};
        Info.vertex_input_state.vertex_attributes = VertexAttributes.data;
        Info.vertex_input_state.num_vertex_attributes = xx AttributeCount;
    }
    
    Info.vertex_shader = Options.Shader.Vert;
    Info.fragment_shader = Options.Shader.Frag;
    
    PipelineObject := SDL_CreateGPUGraphicsPipeline(GDevice, *Info);
    
    ArenaPopMark(*WorkingArena, Mark);
    
    Pipeline := ArenaPush(*RendererArena, pipeline);
    
    AddToLinkedList(*PipelineList, Pipeline);
    
    Pipeline.Options = <<Options;
    
    Pipeline.PipelineObject = PipelineObject;
    Pipeline.InstanceBuffer = CreateStructuredBuffer(Format("%_instance_buffer", Name), size_of(I) * MAX_INSTANCES);
    if NeedsSkinningBuffer {
        Pipeline.SkinningBuffer = CreateStructuredBuffer(Format("%_skinning_buffer", Name), size_of(float4x4) * MAX_BONES);
    }
    
    Pipeline.AttributeCount = AttributeCount;
    Pipeline.TextureCount = Textures.count + TextureCount;
    
    Pipeline.Textures = ArenaPushN(*RendererArena, SDL_GPUTextureSamplerBinding, Textures);
    
    Pipeline.VertConstants = ArenaAlloc(*RendererArena, size_of(Cv));
    Pipeline.VertConstantsSize = size_of(Cv);
    
    Pipeline.FragConstants = ArenaAlloc(*RendererArena, size_of(Cf));
    Pipeline.FragConstantsSize = size_of(Cf);
    
    Pipeline.Name = Name;
    
    return Pipeline;
}

ResetPipelines :: () {
    for * PipelineList {
        ResetLinkedList(*it.BatchList);
    }
}

CreatePipelineBatchForMesh :: (Pipeline: *pipeline, Textures: [] *texture, Samplers: [] *SDL_GPUSampler, Mesh: *mesh, InstanceData: [] $T) -> *pipeline_render_batch {
    Batch := ArenaPush(*RendererFrameArena, pipeline_render_batch);
    
    AddToLinkedList(*Pipeline.BatchList, Batch);
    
    Batch.TextureBindings = ArenaPushN(*RendererFrameArena, SDL_GPUTextureSamplerBinding, Pipeline.TextureCount);
    
    Grey := LoadTexture("textures/grey.png");
    for * Batch.TextureBindings {
        it.texture = Grey.GpuTexture;
        it.sampler = DefaultSampler;
    }
    
    for Pipeline.Textures {
        Batch.TextureBindings[it_index] = it;
    }
    
    for Textures {
        if it_index >= Pipeline.TextureCount break;
        if !it continue;
        
        Sampler: *SDL_GPUSampler;
        if it_index >= Samplers.count || !Samplers[it_index] Sampler = DefaultSampler;
        else Sampler = Samplers[it_index];
        
        Batch.TextureBindings[Pipeline.Textures.count + it_index] = .{it.GpuTexture, Sampler};
    }
    
    Batch.VertexBuffers = ArenaPushN(*RendererFrameArena, SDL_GPUBufferBinding, Pipeline.AttributeCount);
    if Pipeline.Buffers == .POSITION_ONLY {
        Batch.VertexBuffers[0] = SDL_GPUBufferBinding.{Mesh.PositionBuffer, 0};
    }
    
    if Pipeline.Buffers == .POSITION_TEXCOORD {
        Batch.VertexBuffers[0] = SDL_GPUBufferBinding.{Mesh.PositionBuffer, 0};
        Batch.VertexBuffers[1] = SDL_GPUBufferBinding.{Mesh.TexCoordBuffer, 0};
    }
    
    if Pipeline.Buffers == .POSITION_SKINNING {
        Batch.VertexBuffers[0] = SDL_GPUBufferBinding.{Mesh.PositionBuffer, 0};
        Batch.VertexBuffers[1] = SDL_GPUBufferBinding.{Mesh.WeightBuffer, 0};
        Batch.VertexBuffers[2] = SDL_GPUBufferBinding.{Mesh.BoneIdsBuffer, 0};
    }
    
    if Pipeline.Buffers == .POSITION_TEXCOORD_NORMAL_TANGENT_SKINNING {
        Batch.VertexBuffers[0] = SDL_GPUBufferBinding.{Mesh.PositionBuffer, 0};
        Batch.VertexBuffers[1] = SDL_GPUBufferBinding.{Mesh.TexCoordBuffer, 0};
        Batch.VertexBuffers[2] = SDL_GPUBufferBinding.{Mesh.NormalBuffer, 0};
        Batch.VertexBuffers[3] = SDL_GPUBufferBinding.{Mesh.TangentBuffer, 0};
        Batch.VertexBuffers[4] = SDL_GPUBufferBinding.{Mesh.WeightBuffer, 0};
        Batch.VertexBuffers[5] = SDL_GPUBufferBinding.{Mesh.BoneIdsBuffer, 0};
    }
    
    Batch.IndexBuffer = SDL_GPUBufferBinding.{Mesh.IndexBuffer, 0};
    
    for Batch.VertexBuffers {
        Assert(it.buffer != null);
    }
    
    Batch.IndexCount = Mesh.NumIndices;
    Batch.InstanceData = InstanceData.data;
    Batch.InstanceDataSize = size_of(T) * InstanceData.count;
    Batch.InstanceCount = InstanceData.count;
    
    return Batch;
}

RenderPipelineBatches :: (Pipeline: *pipeline, CommandBuffer: *SDL_GPUCommandBuffer, RenderPass: *SDL_GPURenderPass) {
    SDL_PushGPUDebugGroup(CommandBuffer, TCS(Pipeline.Name));
    
    BaseInstance := 0;
    
    for * Pipeline.BatchList {
        SDL_BindGPUGraphicsPipeline(RenderPass, Pipeline.PipelineObject);
        
        SDL_PushGPUVertexUniformData(CommandBuffer, 0, Pipeline.VertConstants, xx Pipeline.VertConstantsSize);
        SDL_PushGPUFragmentUniformData(CommandBuffer, 0, Pipeline.FragConstants, xx Pipeline.FragConstantsSize);
        
        SDL_BindGPUVertexStorageBuffers(RenderPass, 0, *Pipeline.InstanceBuffer.Buffer, 1);
        if Pipeline.SkinningBuffer SDL_BindGPUVertexStorageBuffers(RenderPass, 1, *Pipeline.SkinningBuffer.Buffer, 1);
        
        Viewport: SDL_GPUViewport;
        Viewport.x = xx it.Viewport.x;
        Viewport.y = xx it.Viewport.y;
        Viewport.w = xx it.Viewport.z;
        Viewport.h = xx it.Viewport.w;
        Viewport.min_depth = 0.0;
        Viewport.max_depth = 1.0;
        SDL_SetGPUViewport(RenderPass, *Viewport);
        
        Scissor: SDL_Rect;
        Scissor.x = xx it.Scissor.x;
        Scissor.y = xx it.Scissor.y;
        Scissor.w = xx it.Scissor.z;
        Scissor.h = xx it.Scissor.w;
        SDL_SetGPUScissor(RenderPass, *Scissor);
        
        SDL_BindGPUFragmentSamplers(RenderPass, 0, it.TextureBindings.data, xx it.TextureBindings.count);
        
        SDL_BindGPUVertexBuffers(RenderPass, 0, it.VertexBuffers.data, xx it.VertexBuffers.count);
        
        SDL_BindGPUIndexBuffer(RenderPass, *it.IndexBuffer, .SDL_GPU_INDEXELEMENTSIZE_32BIT);
        
        SDL_DrawGPUIndexedPrimitives(RenderPass, xx it.IndexCount, xx it.InstanceCount, 0, 0, xx BaseInstance);
        BaseInstance += it.InstanceCount;
    }
    
    SDL_PopGPUDebugGroup(CommandBuffer);
}

InitRenderer :: () {
    if SDL_WindowSupportsGPUPresentMode(GDevice, GWindow, .SDL_GPU_PRESENTMODE_MAILBOX) {
        SDL_SetGPUSwapchainParameters(GDevice, GWindow, .SDL_GPU_SWAPCHAINCOMPOSITION_SDR, .SDL_GPU_PRESENTMODE_MAILBOX);
    } else {
        SDL_SetGPUSwapchainParameters(GDevice, GWindow, .SDL_GPU_SWAPCHAINCOMPOSITION_SDR, .SDL_GPU_PRESENTMODE_VSYNC);
    }
    
    ShadowTexture = CreateDepthTexture("shadow", SHADOW_MAP_SIZE, SHADOW_MAP_SIZE);
    DepthTexture = CreateDepthTexture("depth", 1366, 768);
    
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
    
    ShadowPass = ArenaPush(*RendererArena, render_pass);
    ShadowPass.DepthTarget = true;
    ShadowPass.ClearDepth = true;
    ShadowPass.DepthTexture = ShadowTexture;
    
    OpaquePass = ArenaPush(*RendererArena, render_pass);
    OpaquePass.ColourTarget = true;
    OpaquePass.ClearColour = true;
    OpaquePass.DepthTarget = true;
    OpaquePass.ClearDepth = true;
    OpaquePass.DepthTexture = DepthTexture;
    
    TranslucentPass = ArenaPush(*RendererArena, render_pass);
    TranslucentPass.ColourTarget = true;
    TranslucentPass.DepthTarget = true;
    TranslucentPass.DepthTexture = DepthTexture;
    
    UIPass = ArenaPush(*RendererArena, render_pass);
    UIPass.ColourTarget = true;
    
    QuadOptions := pipeline_options.{
        ColourTarget = true,
        AlphaBlending = true,
        Buffers = .POSITION_TEXCOORD,
        CullMode = .SDL_GPU_CULLMODE_NONE,
        Shader = ShaderQuad
    };
    
    QuadPipeline = CreatePipeline("Quad", *QuadOptions, .[], cbuffer_quad, cbuffer_empty, ibuffer_quad, 1);
    
    TextOptions := pipeline_options.{
        ColourTarget = true,
        AlphaBlending = true,
        Buffers = .POSITION_TEXCOORD,
        CullMode = .SDL_GPU_CULLMODE_NONE,
        Shader = ShaderText
    };
    
    TextPipeline = CreatePipeline("Text", *TextOptions, .[], cbuffer_quad, cbuffer_empty, ibuffer_quad, 1);
    
    SDFTextOptions := pipeline_options.{
        ColourTarget = true,
        AlphaBlending = true,
        Buffers = .POSITION_TEXCOORD,
        CullMode = .SDL_GPU_CULLMODE_NONE,
        Shader = ShaderTextSDF
    };
    
    TextSDFPipeline = CreatePipeline("TextSDF", *SDFTextOptions, .[], cbuffer_quad, cbuffer_empty, ibuffer_text_sdf, 1);
    
    ShadowOptions := pipeline_options.{
        ColourTarget = false,
        DepthTarget = true,
        DepthTest = true,
        DepthWrite = true,
        CullMode = .SDL_GPU_CULLMODE_NONE,
        Buffers = .POSITION_SKINNING,
        Shader = ShaderShadowPass
    };
    
    ShadowPipeline = CreatePipeline("Shadow", *ShadowOptions, .[], cbuffer_shadow_vertex, cbuffer_empty, ibuffer_shadow, 0);
    
    OpaqueOptions := pipeline_options.{
        ColourTarget = true,
        DepthTarget = true,
        DepthTest = true,
        DepthWrite = true,
        CullMode = .SDL_GPU_CULLMODE_BACK,
        Buffers = .POSITION_TEXCOORD_NORMAL_TANGENT_SKINNING,
        Shader = ShaderMesh
    };
    
    OpaquePipeline = CreatePipeline("Opaque", *OpaqueOptions, .[.{ShadowTexture, ShadowSampler}], cbuffer_mesh_vertex, cbuffer_mesh_fragment, ibuffer_mesh, 4);
    
    UnlitOptions := pipeline_options.{
        ColourTarget = true,
        DepthTarget = true,
        CullMode = .SDL_GPU_CULLMODE_NONE,
        Buffers = .POSITION_TEXCOORD,
        Shader = ShaderUnlit
    };
    
    UnlitPipeline = CreatePipeline("Unlit", *UnlitOptions, .[], cbuffer_unlit_vertex, cbuffer_empty, ibuffer_unlit, 1);
    
    DebugOptions := pipeline_options.{
        ColourTarget = true,
        DepthTarget = true,
        CullMode = .SDL_GPU_CULLMODE_NONE,
        FillMode = .SDL_GPU_FILLMODE_LINE,
        Buffers = .POSITION_ONLY,
        Shader = ShaderDebug
    };
    
    DebugPipeline = CreatePipeline("Debug", *DebugOptions, .[], cbuffer_unlit_vertex, cbuffer_empty, ibuffer_debug, 0);
    
    TranslucentOptions := pipeline_options.{
        ColourTarget = true,
        DepthTarget = true,
        DepthTest = true,
        CullMode = .SDL_GPU_CULLMODE_BACK,
        Buffers = .POSITION_TEXCOORD_NORMAL_TANGENT_SKINNING,
        Shader = ShaderMesh
    };
    
    TranslucentPipeline = CreatePipeline("Translucent", *TranslucentOptions, .[.{ShadowTexture, ShadowSampler}], cbuffer_mesh_vertex, cbuffer_mesh_fragment, ibuffer_mesh, 4);
    
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
        Corner := (LightView * it).xyz;
        
        Left = Min(Left, Corner.x);
        Right = Max(Right, Corner.x);
        Bottom = Min(Bottom, Corner.y);
        Top = Max(Top, Corner.y);
        Near = Min(Near, Corner.z);
        Far = Max(Far, Corner.z);
    }
    
    ZPad := .5;
    if Near < 0 Near *= ZPad;
    else Near /= ZPad;
    if Far < 0 Far *= ZPad;
    else Far /= ZPad;
    
    LightProj := OrthoProjectionMatrix(Left, Right, Bottom, Top, Near, Far);
    
    return LightProj * LightView;
}

RenderFrame :: (Camera: *$T/interface view_parameters) {
    LightPos := float3.{0, 0, 10};
    LightTarget := float3.{1, -1, 1};
    LightDir := Normalize(LightTarget - LightPos);
    
    LightColour := float3.{1.0, 1.0, 0.8};
    LightMatrix := CalcLightSpaceMatrix(LightPos, LightDir, Camera.Proj, Camera.View);
    
    {
        VertConstants: cbuffer_shadow_vertex;
        VertConstants.LightMatrix = LightMatrix;
        Copy(ShadowPipeline.VertConstants, *VertConstants, ShadowPipeline.VertConstantsSize);
    }
    
    {
        VertConstants: cbuffer_mesh_vertex;
        VertConstants.View = Camera.View;
        VertConstants.Projection = Camera.Proj;
        VertConstants.ViewPos = Camera.Position;
        VertConstants.LightDir = LightDir;
        
        FragConstants: cbuffer_mesh_fragment;
        FragConstants.LightColour = LightColour;
        FragConstants.LightMatrix = LightMatrix;
        
        Copy(OpaquePipeline.VertConstants, *VertConstants, OpaquePipeline.VertConstantsSize);
        Copy(TranslucentPipeline.VertConstants, *VertConstants, TranslucentPipeline.VertConstantsSize);
        
        Copy(OpaquePipeline.FragConstants, *FragConstants, OpaquePipeline.FragConstantsSize);
        Copy(TranslucentPipeline.FragConstants, *FragConstants, TranslucentPipeline.FragConstantsSize);
    }
    
    {
        VertConstants: cbuffer_unlit_vertex;
        VertConstants.View = Camera.View;
        VertConstants.Projection = Camera.Proj;
        
        Copy(DebugPipeline.VertConstants, *VertConstants, DebugPipeline.VertConstantsSize);
        Copy(UnlitPipeline.VertConstants, *VertConstants, UnlitPipeline.VertConstantsSize);
    }
    
    {
        VertConstants: cbuffer_quad;
        VertConstants.Projection = OrthoProjectionMatrix(0, 1366, 768, 0, -999.0, 999.0);
        Copy(QuadPipeline.VertConstants, *VertConstants, QuadPipeline.VertConstantsSize);
        Copy(TextPipeline.VertConstants, *VertConstants, TextPipeline.VertConstantsSize);
        Copy(TextSDFPipeline.VertConstants, *VertConstants, TextSDFPipeline.VertConstantsSize);
    }
    
    for * PipelineList {
        ResetLinkedList(*it.BatchList);
    }
    
    CreateRendererBatches();
    
    for Pipeline: * PipelineList {
        MapStructuredBuffer(Pipeline.InstanceBuffer);
        
        for * Pipeline.BatchList {
            WriteStructuredBuffer(Pipeline.InstanceBuffer, it.InstanceData, it.InstanceDataSize);
        }
        
        UnmapStructuredBuffer(Pipeline.InstanceBuffer);
    }
    
    CommandBuffer := SDL_AcquireGPUCommandBuffer(GDevice);
    CopyPass := SDL_BeginGPUCopyPass(CommandBuffer);
    
    for * PipelineList {
        CommitStructuredBuffer(it.InstanceBuffer, CopyPass);
        if it.SkinningBuffer CommitStructuredBuffer(it.SkinningBuffer, CopyPass);
    }
    
    SDL_EndGPUCopyPass(CopyPass);
    
    SDL_AcquireGPUSwapchainTexture(CommandBuffer, GWindow, *SwapTexture, null, null);
    if !SwapTexture {
        SDL_CancelGPUCommandBuffer(CommandBuffer);
        return;
    }
    
    BeginPass(ShadowPass, CommandBuffer);
    RenderPipelineBatches(ShadowPipeline, CommandBuffer, ShadowPass.RenderPass);
    EndPass(ShadowPass);
    
    BeginPass(OpaquePass, CommandBuffer);
    RenderPipelineBatches(OpaquePipeline, CommandBuffer, OpaquePass.RenderPass);
    RenderPipelineBatches(UnlitPipeline, CommandBuffer, OpaquePass.RenderPass);
    RenderPipelineBatches(DebugPipeline, CommandBuffer, OpaquePass.RenderPass);
    EndPass(OpaquePass);
    
    BeginPass(TranslucentPass, CommandBuffer);
    RenderPipelineBatches(TranslucentPipeline, CommandBuffer, TranslucentPass.RenderPass);
    EndPass(TranslucentPass);
    
    BeginPass(UIPass, CommandBuffer);
    RenderPipelineBatches(QuadPipeline, CommandBuffer, UIPass.RenderPass);
    RenderPipelineBatches(TextPipeline, CommandBuffer, UIPass.RenderPass);
    RenderPipelineBatches(TextSDFPipeline, CommandBuffer, UIPass.RenderPass);
    EndPass(UIPass);
    
    SDL_SubmitGPUCommandBuffer(CommandBuffer);
    
    ResetPipelines();
    ResetRendererFrontend();
    
    ArenaReset(*RendererFrameArena);
    
    SwapTexture = null;
}

render_pass :: struct {
    ColourTarget: bool;
    ColourTexture: *SDL_GPUTexture;
    ClearColour: bool;
    
    DepthTarget: bool;
    DepthTexture: *SDL_GPUTexture;
    ClearDepth: bool;
    
    RenderPass: *SDL_GPURenderPass;
}

pipeline_buffers_mode :: enum {
    POSITION_ONLY;
    POSITION_TEXCOORD;
    POSITION_SKINNING;
    POSITION_TEXCOORD_NORMAL_TANGENT_SKINNING;
}

pipeline_options :: struct {
    ColourTarget: bool;
    DepthTarget: bool;
    DepthTest: bool;
    DepthWrite: bool;
    AlphaBlending: bool;
    CullMode := SDL_GPUCullMode.SDL_GPU_CULLMODE_BACK;
    FillMode := SDL_GPUFillMode.SDL_GPU_FILLMODE_FILL;
    Buffers: pipeline_buffers_mode;
    Shader: *shader;
}

pipeline :: struct {
    Prev, Next: *pipeline;
    
    Name: string;
    
    PipelineObject: *SDL_GPUGraphicsPipeline;
    
    using Options: pipeline_options;
    
    AttributeCount: int;
    TextureCount: int;
    
    Textures: [] SDL_GPUTextureSamplerBinding;
    
    VertConstants: *void;
    VertConstantsSize: int;
    
    FragConstants: *void;
    FragConstantsSize: int;
    
    InstanceBuffer: *structured_buffer;
    SkinningBuffer: *structured_buffer;
    
    BatchList: linked_list(pipeline_render_batch);
}

pipeline_render_batch :: struct {
    Prev, Next: *pipeline_render_batch;
    
    Pipeline: *pipeline;
    Options: pipeline_options;
    
    Initialized: bool;
    
    TextureBindings: [] SDL_GPUTextureSamplerBinding;
    VertexBuffers: [] SDL_GPUBufferBinding;
    IndexBuffer: SDL_GPUBufferBinding;
    
    InstanceCount: int;
    IndexCount: int;
    
    InstanceData: *void;
    InstanceDataSize: int;
    
    Viewport: float4;
    Scissor: float4;
}

PipelineList: linked_list(pipeline);

MAX_BONES :: 1024;

SHADOW_MAP_SIZE :: 4096;

NEAR_PLANE :: 0.1;
FAR_PLANE :: 500.0;

MAX_INSTANCES :: 10000;

cbuffer_shadow_vertex :: struct {
    LightMatrix: float4x4;
}

cbuffer_unlit_vertex :: struct {
    View: float4x4;
    Projection: float4x4;
}

cbuffer_mesh_vertex :: struct {
    View: float4x4;
    Projection: float4x4;
    ViewPos: float3;
    Pad1: float;
    LightDir: float3;
    Pad2: float;
}

cbuffer_mesh_fragment :: struct {
    LightColour: float3;
    Pad2: float;
    LightMatrix: float4x4;
}

cbuffer_quad :: struct {
    Projection: float4x4;
}

cbuffer_text_vertex :: struct {
    Projection: float4x4;
}

cbuffer_sdf_text_vertex :: struct {
    Projection: float4x4;
}

ibuffer_shadow :: struct {
    Transform: float4x4;
}

ibuffer_text_sdf :: struct {
    PositionSize: float4;
    Colour: float4;
    TexCoords: float4;
    Params: float4;
}

ibuffer_mesh :: struct {
    Transform: float4x4;
    Colour: float4;
    MaterialParams: float4;
}

ibuffer_unlit :: struct {
    Transform: float4x4;
    Colour: float4;
}

ibuffer_debug :: struct {
    Transform: float4x4;
    Colour: float4;
}

ibuffer_quad :: struct {
    PositionSize: float4;
    Colour: float4;
    TexCoords: float4;
}

cbuffer_empty :: struct {}
ibuffer_empty :: struct {}

DefaultSampler: *SDL_GPUSampler;
NoMipMapSampler: *SDL_GPUSampler;
ShadowSampler: *SDL_GPUSampler;

RendererArena: arena;
RendererFrameArena: arena;

ShadowPass: *render_pass;
OpaquePass: *render_pass;
TranslucentPass: *render_pass;
UIPass: *render_pass;

QuadPipeline: *pipeline;
TextPipeline: *pipeline;
TextSDFPipeline: *pipeline;
ShadowPipeline: *pipeline;
OpaquePipeline: *pipeline;
UnlitPipeline: *pipeline;
TranslucentPipeline: *pipeline;
DebugPipeline: *pipeline;

#scope_file

SwapTexture: *SDL_GPUTexture;
ShadowTexture: *SDL_GPUTexture;
DepthTexture: *SDL_GPUTexture;