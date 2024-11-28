
SDL_GPUCommandBuffer :: #type *void;
SDL_PropertiesID :: #type u32;
SDL_GPUDevice :: #type *void;
SDL_GPUShader :: #type *void;
SDL_GPUTexture :: #type *void;
SDL_GPUCopyPass :: #type *void;
SDL_GPUTransferBuffer :: #type *void;
SDL_GPUBuffer :: #type *void;
SDL_Window :: #type *void;
SDL_GPUSampler :: #type *void;
SDL_GPURenderPass :: #type *void;
SDL_GPUGraphicsPipeline :: #type *void;

SDL_GPUShaderFormat :: enum u32 {
    SDL_GPU_SHADERFORMAT_SPIRV :: (1 << 1);
    SDL_GPU_SHADERFORMAT_DXBC :: (1 << 2);
    SDL_GPU_SHADERFORMAT_DXIL :: (1 << 3);
}

SDL_GPUShaderStage :: enum u32 {
    SDL_GPU_SHADERSTAGE_VERTEX :: 0;
    SDL_GPU_SHADERSTAGE_FRAGMENT :: 1;
}

SDL_GPUTransferBufferUsage :: enum u32 {
    SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD :: 1;
    SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD :: 2;
}

SDL_WindowFlags :: enum u64 {
    SDL_WINDOW_FULLSCREEN :: 0x0000000000000001;
    SDL_WINDOW_BORDERLESS :: 0x0000000000000010;
}

SDL_InitFlags :: enum u32 {
    SDL_INIT_VIDEO :: 0x00000020;
}

SDL_MessageBoxFlags :: enum u32 {
    SDL_MESSAGEBOX_ERROR :: 0x00000010;
}

SDL_GPUFilter :: enum u32 {
    SDL_GPU_FILTER_NEAREST :: 0;
    SDL_GPU_FILTER_LINEAR :: 1;
}

SDL_GPUSamplerMipmapMode :: enum u32 {
    SDL_GPU_SAMPLERMIPMAPMODE_NEAREST :: 0;
    SDL_GPU_SAMPLERMIPMAPMODE_LINEAR :: 1;
}

SDL_GPUSamplerAddressMode :: enum u32 {
    SDL_GPU_SAMPLERADDRESSMODE_REPEAT :: 0;
    SDL_GPU_SAMPLERADDRESSMODE_MIRRORED_REPEAT :: 1;
    SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE :: 2;
}

SDL_GPUCompareOp :: enum u32 {
    SDL_GPU_COMPAREOP_INVALID :: 0;
    SDL_GPU_COMPAREOP_NEVER :: 1;
    SDL_GPU_COMPAREOP_LESS :: 2;
    SDL_GPU_COMPAREOP_EQUAL :: 3;
    SDL_GPU_COMPAREOP_LESS_OR_EQUAL :: 4;
    SDL_GPU_COMPAREOP_GREATER :: 5;
    SDL_GPU_COMPAREOP_NOT_EQUAL :: 6;
    SDL_GPU_COMPAREOP_GREATER_OR_EQUAL :: 7;
    SDL_GPU_COMPAREOP_ALWAYS :: 8;
}

SDL_GPULoadOp :: enum u32 {
    SDL_GPU_LOADOP_LOAD :: 0;
    SDL_GPU_LOADOP_CLEAR :: 1;
    SDL_GPU_LOADOP_DONT_CARE :: 2;
}

SDL_GPUStoreOp :: enum u32 {
    SDL_GPU_STOREOP_STORE :: 0;
    SDL_GPU_STOREOP_DONT_CARE :: 1;
    SDL_GPU_STOREOP_RESOLVE :: 2;
    SDL_GPU_STOREOP_RESOLVE_AND_STORE :: 3;
}

SDL_GPUPrimitiveType :: enum u32 {
    SDL_GPU_PRIMITIVETYPE_TRIANGLELIST :: 0;
}

SDL_GPUBlendFactor :: enum u32 {
    SDL_GPU_BLENDFACTOR_INVALID :: 0;
    SDL_GPU_BLENDFACTOR_ZERO :: 1;
    SDL_GPU_BLENDFACTOR_ONE :: 2;
    SDL_GPU_BLENDFACTOR_SRC_COLOR :: 3;
    SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_COLOR :: 4;
    SDL_GPU_BLENDFACTOR_DST_COLOR :: 5;
    SDL_GPU_BLENDFACTOR_ONE_MINUS_DST_COLOR :: 6;
    SDL_GPU_BLENDFACTOR_SRC_ALPHA :: 7;
    SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA :: 8;
    SDL_GPU_BLENDFACTOR_DST_ALPHA :: 9;
    SDL_GPU_BLENDFACTOR_ONE_MINUS_DST_ALPHA :: 10;
    SDL_GPU_BLENDFACTOR_CONSTANT_COLOR :: 11;
    SDL_GPU_BLENDFACTOR_ONE_MINUS_CONSTANT_COLOR :: 12;
    SDL_GPU_BLENDFACTOR_SRC_ALPHA_SATURATE :: 13;
}

SDL_GPUBlendOp :: enum u32 {
    SDL_GPU_BLENDOP_INVALID :: 0;
    SDL_GPU_BLENDOP_ADD :: 1;
    SDL_GPU_BLENDOP_SUBTRACT :: 2;
    SDL_GPU_BLENDOP_REVERSE_SUBTRACT :: 3;
    SDL_GPU_BLENDOP_MIN :: 4;
    SDL_GPU_BLENDOP_MAX :: 5;
}

SDL_GPUColorComponentFlags :: enum u32 {
    SDL_GPU_COLORCOMPONENT_R :: (1 << 0);
    SDL_GPU_COLORCOMPONENT_G :: (1 << 1);
    SDL_GPU_COLORCOMPONENT_B :: (1 << 2);
    SDL_GPU_COLORCOMPONENT_A :: (1 << 3);
}

SDL_GPUCullMode :: enum u32 {
    SDL_GPU_CULLMODE_NONE :: 0;
    SDL_GPU_CULLMODE_FRONT :: 1;
    SDL_GPU_CULLMODE_BACK :: 2;
}

SDL_GPUFillMode :: enum u32 {
    SDL_GPU_FILLMODE_FILL :: 0;
    SDL_GPU_FILLMODE_LINE :: 1;
}

SDL_GPUFrontFace :: enum u32 {
    SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE :: 0;
    SDL_GPU_FRONTFACE_CLOCKWISE :: 1;
}

SDL_GPUSampleCount :: enum u32 {
    SDL_GPU_SAMPLECOUNT_1 :: 0;
    SDL_GPU_SAMPLECOUNT_2 :: 1;
    SDL_GPU_SAMPLECOUNT_4 :: 2;
    SDL_GPU_SAMPLECOUNT_8 :: 3;
}

SDL_GPUStencilOp :: enum u32 {
    SDL_GPU_STENCILOP_INVALID :: 0;
    SDL_GPU_STENCILOP_KEEP :: 1;
    SDL_GPU_STENCILOP_ZERO :: 2;
    SDL_GPU_STENCILOP_REPLACE :: 3;
    SDL_GPU_STENCILOP_INCREMENT_AND_CLAMP :: 4;
    SDL_GPU_STENCILOP_DECREMENT_AND_CLAMP :: 5;
    SDL_GPU_STENCILOP_INVERT :: 6;
    SDL_GPU_STENCILOP_INCREMENT_AND_WRAP :: 7;
    SDL_GPU_STENCILOP_DECREMENT_AND_WRAP :: 8;
}

SDL_GPUTextureFormat :: enum u32 {
    SDL_GPU_TEXTUREFORMAT_INVALID;
    SDL_GPU_TEXTUREFORMAT_A8_UNORM;
    SDL_GPU_TEXTUREFORMAT_R8_UNORM;
    SDL_GPU_TEXTUREFORMAT_R8G8_UNORM;
    SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
    SDL_GPU_TEXTUREFORMAT_R16_UNORM;
    SDL_GPU_TEXTUREFORMAT_R16G16_UNORM;
    SDL_GPU_TEXTUREFORMAT_R16G16B16A16_UNORM;
    SDL_GPU_TEXTUREFORMAT_R10G10B10A2_UNORM;
    SDL_GPU_TEXTUREFORMAT_B5G6R5_UNORM;
    SDL_GPU_TEXTUREFORMAT_B5G5R5A1_UNORM;
    SDL_GPU_TEXTUREFORMAT_B4G4R4A4_UNORM;
    SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM;
    SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM;
    SDL_GPU_TEXTUREFORMAT_BC2_RGBA_UNORM;
    SDL_GPU_TEXTUREFORMAT_BC3_RGBA_UNORM;
    SDL_GPU_TEXTUREFORMAT_BC4_R_UNORM;
    SDL_GPU_TEXTUREFORMAT_BC5_RG_UNORM;
    SDL_GPU_TEXTUREFORMAT_BC7_RGBA_UNORM;
    SDL_GPU_TEXTUREFORMAT_BC6H_RGB_FLOAT;
    SDL_GPU_TEXTUREFORMAT_BC6H_RGB_UFLOAT;
    SDL_GPU_TEXTUREFORMAT_R8_SNORM;
    SDL_GPU_TEXTUREFORMAT_R8G8_SNORM;
    SDL_GPU_TEXTUREFORMAT_R8G8B8A8_SNORM;
    SDL_GPU_TEXTUREFORMAT_R16_SNORM;
    SDL_GPU_TEXTUREFORMAT_R16G16_SNORM;
    SDL_GPU_TEXTUREFORMAT_R16G16B16A16_SNORM;
    SDL_GPU_TEXTUREFORMAT_R16_FLOAT;
    SDL_GPU_TEXTUREFORMAT_R16G16_FLOAT;
    SDL_GPU_TEXTUREFORMAT_R16G16B16A16_FLOAT;
    SDL_GPU_TEXTUREFORMAT_R32_FLOAT;
    SDL_GPU_TEXTUREFORMAT_R32G32_FLOAT;
    SDL_GPU_TEXTUREFORMAT_R32G32B32A32_FLOAT;
    SDL_GPU_TEXTUREFORMAT_R11G11B10_UFLOAT;
    SDL_GPU_TEXTUREFORMAT_R8_UINT;
    SDL_GPU_TEXTUREFORMAT_R8G8_UINT;
    SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UINT;
    SDL_GPU_TEXTUREFORMAT_R16_UINT;
    SDL_GPU_TEXTUREFORMAT_R16G16_UINT;
    SDL_GPU_TEXTUREFORMAT_R16G16B16A16_UINT;
    SDL_GPU_TEXTUREFORMAT_R32_UINT;
    SDL_GPU_TEXTUREFORMAT_R32G32_UINT;
    SDL_GPU_TEXTUREFORMAT_R32G32B32A32_UINT;
    SDL_GPU_TEXTUREFORMAT_R8_INT;
    SDL_GPU_TEXTUREFORMAT_R8G8_INT;
    SDL_GPU_TEXTUREFORMAT_R8G8B8A8_INT;
    SDL_GPU_TEXTUREFORMAT_R16_INT;
    SDL_GPU_TEXTUREFORMAT_R16G16_INT;
    SDL_GPU_TEXTUREFORMAT_R16G16B16A16_INT;
    SDL_GPU_TEXTUREFORMAT_R32_INT;
    SDL_GPU_TEXTUREFORMAT_R32G32_INT;
    SDL_GPU_TEXTUREFORMAT_R32G32B32A32_INT;
    SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_BC2_RGBA_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_BC3_RGBA_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_BC7_RGBA_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_D16_UNORM;
    SDL_GPU_TEXTUREFORMAT_D24_UNORM;
    SDL_GPU_TEXTUREFORMAT_D32_FLOAT;
    SDL_GPU_TEXTUREFORMAT_D24_UNORM_S8_UINT;
    SDL_GPU_TEXTUREFORMAT_D32_FLOAT_S8_UINT;
    SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM;
    SDL_GPU_TEXTUREFORMAT_ASTC_5x4_UNORM;
    SDL_GPU_TEXTUREFORMAT_ASTC_5x5_UNORM;
    SDL_GPU_TEXTUREFORMAT_ASTC_6x5_UNORM;
    SDL_GPU_TEXTUREFORMAT_ASTC_6x6_UNORM;
    SDL_GPU_TEXTUREFORMAT_ASTC_8x5_UNORM;
    SDL_GPU_TEXTUREFORMAT_ASTC_8x6_UNORM;
    SDL_GPU_TEXTUREFORMAT_ASTC_8x8_UNORM;
    SDL_GPU_TEXTUREFORMAT_ASTC_10x5_UNORM;
    SDL_GPU_TEXTUREFORMAT_ASTC_10x6_UNORM;
    SDL_GPU_TEXTUREFORMAT_ASTC_10x8_UNORM;
    SDL_GPU_TEXTUREFORMAT_ASTC_10x10_UNORM;
    SDL_GPU_TEXTUREFORMAT_ASTC_12x10_UNORM;
    SDL_GPU_TEXTUREFORMAT_ASTC_12x12_UNORM;
    SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_ASTC_5x4_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_ASTC_5x5_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_ASTC_6x5_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_ASTC_6x6_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_ASTC_8x5_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_ASTC_8x6_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_ASTC_8x8_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_ASTC_10x5_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_ASTC_10x6_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_ASTC_10x8_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_ASTC_10x10_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_ASTC_12x10_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_ASTC_12x12_UNORM_SRGB;
    SDL_GPU_TEXTUREFORMAT_ASTC_4x4_FLOAT;
    SDL_GPU_TEXTUREFORMAT_ASTC_5x4_FLOAT;
    SDL_GPU_TEXTUREFORMAT_ASTC_5x5_FLOAT;
    SDL_GPU_TEXTUREFORMAT_ASTC_6x5_FLOAT;
    SDL_GPU_TEXTUREFORMAT_ASTC_6x6_FLOAT;
    SDL_GPU_TEXTUREFORMAT_ASTC_8x5_FLOAT;
    SDL_GPU_TEXTUREFORMAT_ASTC_8x6_FLOAT;
    SDL_GPU_TEXTUREFORMAT_ASTC_8x8_FLOAT;
    SDL_GPU_TEXTUREFORMAT_ASTC_10x5_FLOAT;
    SDL_GPU_TEXTUREFORMAT_ASTC_10x6_FLOAT;
    SDL_GPU_TEXTUREFORMAT_ASTC_10x8_FLOAT;
    SDL_GPU_TEXTUREFORMAT_ASTC_10x10_FLOAT;
    SDL_GPU_TEXTUREFORMAT_ASTC_12x10_FLOAT;
    SDL_GPU_TEXTUREFORMAT_ASTC_12x12_FLOAT;
}

SDL_GPUVertexElementFormat :: enum u32 {
    SDL_GPU_VERTEXELEMENTFORMAT_INVALID;
    SDL_GPU_VERTEXELEMENTFORMAT_INT;
    SDL_GPU_VERTEXELEMENTFORMAT_INT2;
    SDL_GPU_VERTEXELEMENTFORMAT_INT3;
    SDL_GPU_VERTEXELEMENTFORMAT_INT4;
    SDL_GPU_VERTEXELEMENTFORMAT_UINT;
    SDL_GPU_VERTEXELEMENTFORMAT_UINT2;
    SDL_GPU_VERTEXELEMENTFORMAT_UINT3;
    SDL_GPU_VERTEXELEMENTFORMAT_UINT4;
    SDL_GPU_VERTEXELEMENTFORMAT_FLOAT;
    SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2;
    SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3;
    SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4;
    SDL_GPU_VERTEXELEMENTFORMAT_BYTE2;
    SDL_GPU_VERTEXELEMENTFORMAT_BYTE4;
    SDL_GPU_VERTEXELEMENTFORMAT_UBYTE2;
    SDL_GPU_VERTEXELEMENTFORMAT_UBYTE4;
    SDL_GPU_VERTEXELEMENTFORMAT_BYTE2_NORM;
    SDL_GPU_VERTEXELEMENTFORMAT_BYTE4_NORM;
    SDL_GPU_VERTEXELEMENTFORMAT_UBYTE2_NORM;
    SDL_GPU_VERTEXELEMENTFORMAT_UBYTE4_NORM;
    SDL_GPU_VERTEXELEMENTFORMAT_SHORT2;
    SDL_GPU_VERTEXELEMENTFORMAT_SHORT4;
    SDL_GPU_VERTEXELEMENTFORMAT_USHORT2;
    SDL_GPU_VERTEXELEMENTFORMAT_USHORT4;
    SDL_GPU_VERTEXELEMENTFORMAT_SHORT2_NORM;
    SDL_GPU_VERTEXELEMENTFORMAT_SHORT4_NORM;
    SDL_GPU_VERTEXELEMENTFORMAT_USHORT2_NORM;
    SDL_GPU_VERTEXELEMENTFORMAT_USHORT4_NORM;
    SDL_GPU_VERTEXELEMENTFORMAT_HALF2;
    SDL_GPU_VERTEXELEMENTFORMAT_HALF4;
}

SDL_GPUVertexInputRate :: enum u32 {
    SDL_GPU_VERTEXINPUTRATE_VERTEX;
    SDL_GPU_VERTEXINPUTRATE_INSTANCE;
}

SDL_GPUShaderCreateInfo :: struct {
    code_size: u64;
    code: *u8;
    entrypoint: *u8;
    format: SDL_GPUShaderFormat;
    stage: SDL_GPUShaderStage;
    num_samplers: u32;
    num_storage_textures: u32;
    num_storage_buffers: u32;
    num_uniform_buffers: u32;
    props: SDL_PropertiesID;
}

SDL_GPUTextureTransferInfo :: struct {
    transfer_buffer: *SDL_GPUTransferBuffer;
    offset: u32;
    pixels_per_word: u32;
    rows_per_layer: u32;
}

SDL_GPUTextureRegion :: struct {
    texture: *SDL_GPUTexture;
    mip_levels: u32;
    layer: u32;
    x, y, z, w, h, d: u32;
}

SDL_GPUTransferBufferCreateInfo :: struct {
    usage: SDL_GPUTransferBufferUsage;
    size: u32;
    props: SDL_PropertiesID;
}

SDL_GPUTransferBufferLocation :: struct {
    transfer_buffer: *SDL_GPUTransferBuffer;
    offset: u32;
}

SDL_GPUBufferRegion :: struct {
    buffer: *SDL_GPUBuffer;
    offset: u32;
    size: u32;
}

SDL_GPUSamplerCreateInfo :: struct {
    min_filter, mag_filter: SDL_GPUFilter;
    mipmap_mode: SDL_GPUSamplerMipmapMode;
    address_mode_u, address_mode_v, address_mode_w: SDL_GPUSamplerAddressMode;
    mip_lod_bias: float;
    max_anisotropy: float;
    compare_op: SDL_GPUCompareOp;
    min_lod, max_lod: float;
    enable_anisotropy: bool;
    enable_compare: bool;
    padding1, padding2: u8;
    props: SDL_PropertiesID;
}

SDL_GPUColorTargetInfo :: struct {
    texture: *SDL_GPUTexture;
    mip_level: u32;
    layer_or_depth_plane: u32;
    clear_color: SDL_FColor;
    load_op: SDL_GPULoadOp;
    store_op: SDL_GPUStoreOp;
    resolve_texture: *SDL_GPUTexture;
    resolve_mip_level: u32;
    resolve_layer: u32;
    cycle: bool;
    cycle_resolve_texture: bool;
    padding1, padding2: u8;
}

SDL_GPUDepthStencilTargetInfo :: struct {
    texture: *SDL_GPUTexture;
    clear_depth: float;
    load_op: SDL_GPULoadOp;
    store_op: SDL_GPUStoreOp;
    stencil_load_op: SDL_GPULoadOp;
    stencil_store_op: SDL_GPUStoreOp;
    cycle: bool;
    clear_stencil: u8;
    padding1, padding2: u8;
}

SDL_FColor :: struct {
    r, g, b, a: float;
}

SDL_GPUBufferBinding :: struct {
    buffer: *SDL_GPUBuffer;
    offset: u32;
}

SDL_GPUViewport :: struct {
    x, y, w, h: float;
    min_depth: float;
    max_depth: float;
}

SDL_GPUTextureSamplerBinding :: struct {
    texture: *SDL_GPUTexture;
    sampler: *SDL_GPUSampler;
}

SDL_GPUGraphicsPipelineCreateInfo :: struct {
    vertex_shader: *SDL_GPUShader;
    fragment_shader: *SDL_GPUShader;
    vertex_input_state: SDL_GPUVertexInputState;
    primitive_type: SDL_GPUPrimitiveType;
    rasterizer_state: SDL_GPURasterizerState;
    multisample_state: SDL_GPUMultisampleState;
    depth_stencil_state: SDL_GPUDepthStencilState;
    target_info: SDL_GPUGraphicsPipelineTargetInfo;
    props: SDL_PropertiesID;
}

SDL_GPUVertexInputState :: struct {
    vertex_buffer_descriptions: *SDL_GPUVertexBufferDescription;
    num_vertex_buffers: u32;
    vertex_attributes: *SDL_GPUVertexAttribute;
    num_vertex_attributes: u32;
}

SDL_GPUDepthStencilState :: struct {
    compare_op: SDL_GPUCompareOp;
    back_stencil_state: SDL_GPUStencilOpState;
    front_stencil_state: SDL_GPUStencilOpState;
    compare_mask: u8;
    write_mask: u8;
    enable_depth_test: bool;
    enable_depth_write: bool;
    enable_stencil_test: bool;
    padding1, padding2, padding3: u8;
}

SDL_GPUGraphicsPipelineTargetInfo :: struct {
    color_target_descriptions: *SDL_GPUColorTargetDescription;
    num_color_targets: u32;
    depth_stencil_format: SDL_GPUTextureFormat;
    has_depth_stencil_target: bool;
    padding1, padding2, padding3: u8;
}

SDL_GPUColorTargetDescription :: struct {
    format: SDL_GPUTextureFormat;
    blend_state: SDL_GPUColorTargetBlendState;
}

SDL_GPUColorTargetBlendState :: struct {
    src_color_blendfactor: SDL_GPUBlendFactor;
    dst_color_blendfactor: SDL_GPUBlendFactor;
    color_blend_op: SDL_GPUBlendOp;
    src_alpha_blendfactor: SDL_GPUBlendFactor;
    dst_alpha_blendfactor: SDL_GPUBlendFactor;
    alpha_blend_op: SDL_GPUBlendOp;
    color_write_mask: SDL_GPUColorComponentFlags;
    enable_blend: bool;
    enable_color_write_mask: bool;
    padding1, padding2: u8;
}

SDL_GPUMultisampleState :: struct {
    sample_count: SDL_GPUSampleCount;
    sample_mask: u32;
    enable_mask: bool;
    padding1, padding2, padding3: u8;
}

SDL_GPURasterizerState :: struct {
    fill_mode: SDL_GPUFillMode;
    cull_mode: SDL_GPUCullMode;
    front_face: SDL_GPUFrontFace;
    depth_bias_constant_factor: float;
    depth_bias_clamp: float;
    depth_bias_slope_factor: float;
    enable_depth_bias: bool;
    enable_depth_clip: bool;
    padding1, padding2: u8;
}

SDL_GPUStencilOpState :: struct {
    fail_op: SDL_GPUStencilOp;
    pass_op: SDL_GPUStencilOp;
    depth_fail_op: SDL_GPUStencilOp;
    compare_op: SDL_GPUCompareOp;
}

SDL_GPUVertexAttribute :: struct {
    location: u32;
    buffer_slot: u32;
    format: SDL_GPUVertexElementFormat;
    offset: u32;
}

SDL_GPUVertexBufferDescription :: struct {
    slot: u32;
    pitch: u32;
    input_rate: SDL_GPUVertexInputRate;
    instance_step_rate: u32;
}

SDL_CreateGPUDevice :: (format_flags: SDL_GPUShaderFormat, debug_mode: bool, name: *u8) -> *SDL_GPUDevice #foreign sdl3;

SDL_GetGPUShaderFormats :: (device: *SDL_GPUDevice) -> SDL_GPUShaderFormat #foreign sdl3;
SDL_GetGPUDeviceDriver :: (device: *SDL_GPUDevice) -> *u8 #foreign sdl3;
sdl_get_gpu_device_driver :: (device: *SDL_GPUDevice) -> string { 
    return to_string(SDL_GetGPUDeviceDriver(device));
}

SDL_ClaimWindowForGPUDevice :: (device: *SDL_GPUDevice, window: *SDL_Window) -> bool #foreign sdl3;

SDL_CreateGPUShader :: (device: *SDL_GPUDevice, create_info: *SDL_GPUShaderCreateInfo) -> *SDL_GPUShader #foreign sdl3;

SDL_AcquireGPUCommandBuffer :: (device: *SDL_GPUDevice) -> *SDL_GPUCommandBuffer #foreign sdl3;

SDL_AcquireGPUSwapchainTexture :: (command_buffer: *SDL_GPUCommandBuffer, window: *SDL_Window, swapchain_texture: **SDL_GPUTexture, swapchain_texture_width: *u32, swapchain_texture_height: *u32) -> bool #foreign sdl3;

SDL_UploadToGPUTexture :: (copy_pass: *SDL_GPUCopyPass, source: *SDL_GPUTextureTransferInfo, destination: *SDL_GPUTextureRegion, cycle: bool) #foreign sdl3;

SDL_CreateGPUTransferBuffer :: (device: *SDL_GPUDevice, createinfo: *SDL_GPUTransferBufferCreateInfo) -> *SDL_GPUTransferBuffer #foreign sdl3;

SDL_UploadToGPUBuffer :: (copy_pass: *SDL_GPUCopyPass, source: *SDL_GPUTransferBufferLocation, destination: *SDL_GPUBufferRegion, cycle: bool) #foreign sdl3;

SDL_CreateGPUSampler :: (device: *SDL_GPUDevice, createinfo: *SDL_GPUSamplerCreateInfo) -> *SDL_GPUSampler #foreign sdl3;

SDL_CreateGPUGraphicsPipeline :: (device: *SDL_GPUDevice, createinfo: *SDL_GPUGraphicsPipelineCreateInfo) -> *SDL_GPUGraphicsPipeline #foreign sdl3;

SDL_BeginGPURenderPass :: (command_buffer: *SDL_GPUCommandBuffer,
                           color_target_infos: *SDL_GPUColorTargetInfo,
                           num_color_targets: u32,
                           depth_stencil_target_info: *SDL_GPUDepthStencilTargetInfo) -> *SDL_GPURenderPass #foreign sdl3;

SDL_BindGPUGraphicsPipeline :: (render_pass: *SDL_GPURenderPass, graphics_pipeline: *SDL_GPUGraphicsPipeline) #foreign sdl3;

SDL_SetGPUViewport :: (render_pass: *SDL_GPURenderPass, viewport: *SDL_GPUViewport) #foreign sdl3;

SDL_BindGPUVertexBuffers :: (render_pass: *SDL_GPURenderPass, first_slot: u32, bindings: *SDL_GPUBufferBinding, num_bindings: u32) #foreign sdl3;

SDL_BindGPUVertexSamplers :: (render_pass: *SDL_GPURenderPass, first_slot: u32, texture_sampler_bindings: *SDL_GPUTextureSamplerBinding, num_bindings: u32) #foreign sdl3;

SDL_DrawGPUPrimitives :: (render_pass: *SDL_GPURenderPass, num_vertices: u32, num_instances: u32, first_vertex: u32, first_instance: u32) #foreign sdl3;

SDL_DrawGPUPrimitivesIndirect :: (render_pass: *SDL_GPURenderPass, buffer: *SDL_GPUBuffer, offset: u32, draw_count: u32) #foreign sdl3;

SDL_DrawGPUIndexedPrimitivesIndirect :: (render_pass: *SDL_GPURenderPass, buffer: *SDL_GPUBuffer, offset: u32, draw_count: u32) #foreign sdl3;

SDL_EndGPURenderPass :: (render_pass: *SDL_GPURenderPass) #foreign sdl3;

SDL_SubmitGPUCommandBuffer :: (command_buffer: *SDL_GPUCommandBuffer) -> bool #foreign sdl3;

SDL_CreateWindow :: (title: *u8, w: s32, h: s32, flags: SDL_WindowFlags) -> *SDL_Window #foreign sdl3;

SDL_Init :: (flags: SDL_InitFlags) -> bool #foreign sdl3;

SDL_GetError :: () -> *u8 #foreign sdl3;
sdl_get_error :: () -> string { return to_string(SDL_GetError()); }

SDL_ShowSimpleMessageBox :: (flags: SDL_MessageBoxFlags, title: *u8, message: *u8, window: *SDL_Window) -> bool #foreign sdl3;

// SDL.h

using SDL_bool :: enum u32 {
    SDL_FALSE :: 0;
    SDL_TRUE :: 1;
}

// SDL_video.jai

using SDL_WindowEventID :: enum u8 {
    SDL_WINDOWEVENT_NONE;
    SDL_WINDOWEVENT_SHOWN;
    SDL_WINDOWEVENT_HIDDEN;
    SDL_WINDOWEVENT_EXPOSED;
    SDL_WINDOWEVENT_MOVED;
    SDL_WINDOWEVENT_RESIZED;
    SDL_WINDOWEVENT_SIZE_CHANGED;
    SDL_WINDOWEVENT_MINIMIZED;
    SDL_WINDOWEVENT_MAXIMIZED;
    SDL_WINDOWEVENT_RESTORED;
    SDL_WINDOWEVENT_ENTER;
    SDL_WINDOWEVENT_LEAVE;
    SDL_WINDOWEVENT_FOCUS_GAINED;
    SDL_WINDOWEVENT_FOCUS_LOST;
    SDL_WINDOWEVENT_CLOSE;
    SDL_WINDOWEVENT_TAKE_FOCUS;
    SDL_WINDOWEVENT_HIT_TEST;
}

// SDL_mouse.jai

SDL_SetWindowRelativeMouseMode :: (enabled: SDL_bool) -> s32 #foreign sdl3;
SDL_GetMouseState :: (x: *s32, y: *s32) -> u32 #foreign sdl3;

// SDL_event.h

SDL_RELEASED :: 0;
SDL_PRESSED :: 1;

using SDL_EventType :: enum u32 {
    SDL_FIRSTEVENT     :: 0;
    
    /* Application events */
    SDL_QUIT           :: 0x100;
    
    /* iOS events */
    SDL_APP_TERMINATING;
    SDL_APP_LOWMEMORY;
    SDL_APP_WILLENTERBACKGROUND;
    SDL_APP_DIDENTERBACKGROUND;
    SDL_APP_WILLENTERFOREGROUND;
    SDL_APP_DIDENTERFOREGROUND;
    
    SDL_WINDOWEVENT    :: 0x200;
    SDL_SYSWMEVENT;
    
    /* Keyboard events */
    SDL_KEYDOWN        :: 0x300;
    SDL_KEYUP;
    SDL_TEXTEDITING;
    SDL_TEXTINPUT;
    SDL_KEYMAPCHANGED;
    
    /* Mouse events */
    SDL_MOUSEMOTION    :: 0x400;
    SDL_MOUSEBUTTONDOWN;
    SDL_MOUSEBUTTONUP;
    SDL_MOUSEWHEEL;
    
    /* Joystick events */
    SDL_JOYAXISMOTION  :: 0x600;
    SDL_JOYBALLMOTION;
    SDL_JOYHATMOTION;
    SDL_JOYBUTTONDOWN;
    SDL_JOYBUTTONUP;
    SDL_JOYDEVICEADDED;
    SDL_JOYDEVICEREMOVED;
    
    /* Game controller events */
    SDL_CONTROLLERAXISMOTION  :: 0x650;
    SDL_CONTROLLERBUTTONDOWN;
    SDL_CONTROLLERBUTTONUP;
    SDL_CONTROLLERDEVICEADDED;
    SDL_CONTROLLERDEVICEREMOVED;
    SDL_CONTROLLERDEVICEREMAPPED;
    
    /* Touch events */
    SDL_FINGERDOWN      :: 0x700;
    SDL_FINGERUP;
    SDL_FINGERMOTION;
    
    /* Gesture events */
    SDL_DOLLARGESTURE   :: 0x800;
    SDL_DOLLARRECORD;
    SDL_MULTIGESTURE;
    
    /* Clipboard events */
    SDL_CLIPBOARDUPDATE :: 0x900;
    
    /* Drag and drop events */
    SDL_DROPFILE        :: 0x1000;
    SDL_DROPTEXT;
    SDL_DROPBEGIN;
    SDL_DROPCOMPLETE;
    
    /* Audio hotplug events */
    SDL_AUDIODEVICEADDED :: 0x1100;
    SDL_AUDIODEVICEREMOVED;
    
    /* Render events */
    SDL_RENDER_TARGETS_RESET :: 0x2000;
    SDL_RENDER_DEVICE_RESET;
    
    /** Events ::SDL_USEREVENT through ::SDL_LASTEVENT are for your use;
     *  and should be allocated with SDL_RegisterEvents()
     */
    SDL_USEREVENT    :: 0x8000;
    SDL_LASTEVENT    :: 0xFFFF;
}


SDL_CommonEvent :: struct {
    type: SDL_EventType;
    timestamp: u32;   // In milliseconds, populated using SDL_GetTicks() 
}

SDL_WindowEvent :: struct {
    type: SDL_EventType;        // SDL_WINDOWEVENT
    timestamp: u32;
    windowID: u32;              // The associated window 
    event: SDL_WindowEventID;   // SDL_WindowEventID 
    padding1: u8;
    padding2: u8;
    padding3: u8;
    data1: s32;             // event dependent data 
    data2: s32;             // event dependent data 
}

SDL_KeyboardEvent :: struct {
    type: SDL_EventType;    // SDL_KEYDOWN or SDL_KEYUP
    timestamp: u32;         // In milliseconds, populated using SDL_GetTicks()
    windowID: u32;          // The window with keyboard focus, if any
    state: u8;              // SDL_PRESSED or SDL_RELEASED
    repeat: u8;             // Non-zero if this is a key repeat
    padding2: u8;
    padding3: u8;
    keysym: SDL_Keysym;     // The key that was pressed or released
}


SDL_TEXTEDITINGEVENT_TEXT_SIZE :: 32;

SDL_TextEditingEvent :: struct {
    type: SDL_EventType;    // SDL_TEXTEDITING
    timestamp: u32;
    windowID: u32;
    text: [SDL_TEXTEDITINGEVENT_TEXT_SIZE] u8;  // The editing text 
    start: s32;                                 // The start cursor of selected editing text 
    length: s32;                                // The length of selected editing text 
}

SDL_TEXTINPUTEVENT_TEXT_SIZE :: 32;

SDL_TextInputEvent :: struct {
    type: SDL_EventType;    // SDL_TEXTINPUT
    timestamp: u32;
    windowID: u32;
    text: [SDL_TEXTINPUTEVENT_TEXT_SIZE] s8;  // The input text 
}

SDL_MouseMotionEvent :: struct {
    type: SDL_EventType;    // SDL_MOUSEMOTION
    timestamp: u32;
    windowID: u32;
    which: u32;             // The mouse instance id, or SDL_TOUCH_MOUSEID 
    state: u32;             // The current button state 
    x: s32;                 // X coordinate, relative to window 
    y: s32;                 // Y coordinate, relative to window 
    xrel: s32;              // The relative motion in the X direction 
    yrel: s32;              // The relative motion in the Y direction 
}

SDL_MouseButtonEvent :: struct {
    type: SDL_EventType;    // SDL_MOUSEBUTTONDOWN or SDL_MOUSEBUTTONUP
    timestamp: u32;
    windowID: u32;
    which: u32;             // The mouse instance id, or SDL_TOUCH_MOUSEID 
    button: u8;             // The mouse button index 
    state: u8;              // ::SDL_PRESSED or ::SDL_RELEASED 
    clicks: u8;             // 1 for single-click, 2 for double-click, etc. 
    padding1: u8;
    x: s32;                 // X coordinate, relative to window 
    y: s32;                 // Y coordinate, relative to window 
}

SDL_MouseWheelEvent :: struct {
    type: SDL_EventType;    // SDL_MOUSEWHEEL
    timestamp: u32;
    windowID: u32;
    which: u32;             // The mouse instance id, or SDL_TOUCH_MOUSEID 
    x: s32;                 // The amount scrolled horizontally, positive to the right and negative to the left 
    y: s32;                 // The amount scrolled vertically, positive away from the user and negative toward the user 
    direction: u32;         // Set to one of the SDL_MOUSEWHEEL_* defines. When FLIPPED the values in X and Y will be opposite. Multiply by -1 to change them back 
}

SDL_JoyAxisEvent :: struct {
    type: SDL_EventType;    // SDL_JOYAXISMOTION
    timestamp: u32;
    which: SDL_JoystickID;  // The joystick instance id 
    axis: u8;               // The joystick axis index 
    padding1: u8;
    padding2: u8;
    padding3: u8;
    value: s16;             // The axis value (range: -32768 to 32767) 
    padding4: u16;    
}

SDL_JoyBallEvent :: struct {
    type: SDL_EventType;    // SDL_JOYBALLMOTION
    timestamp: u32;
    which: SDL_JoystickID;  // The joystick instance id 
    ball: u8;               // The joystick trackball index 
    padding1: u8;
    padding2: u8;
    padding3: u8;
    xrel: s16;              // The relative motion in the X direction 
    yrel: s16;              // The relative motion in the Y direction 
}

SDL_JoyHatEvent :: struct {
    type: SDL_EventType;    // SDL_JOYHATMOTION
    timestamp: u32;
    which: SDL_JoystickID;  // The joystick instance id 
    hat: u8;                // The joystick hat index 
    value: u8;              // The hat position value.
    padding1: u8;
    padding2: u8;
}

SDL_JoyButtonEvent :: struct {
    type: SDL_EventType;    //SDL_JOYBUTTONDOWN or SDL_JOYBUTTONUP
    timestamp: u32;
    which: SDL_JoystickID;  // The joystick instance id 
    button: u8;             // The joystick button index 
    state: u8;              // SDL_PRESSED or SDL_RELEASED 
    padding1: u8;
    padding2: u8;
}

SDL_JoyDeviceEvent :: struct {
    type: SDL_EventType;    // SDL_JOYDEVICEADDED or SDL_JOYDEVICEREMOVED
    timestamp: u32;
    which: s32;             // The joystick device index for the ADDED event, instance id for the REMOVED event 
}

SDL_ControllerAxisEvent :: struct {
    type: SDL_EventType;    // SDL_CONTROLLERAXISMOTION
    timestamp: u32;
    which: SDL_JoystickID;  // The joystick instance id 
    axis: u8;               // The controller axis (SDL_GameControllerAxis) 
    padding1: u8;
    padding2: u8;
    padding3: u8;
    value: s16;             // The axis value (range: -32768 to 32767) 
    padding4: u16;    
}

SDL_ControllerButtonEvent :: struct {
    type: SDL_EventType;    // SDL_CONTROLLERBUTTONDOWN or SDL_CONTROLLERBUTTONUP
    timestamp: u32;
    which: SDL_JoystickID;  // The joystick instance id 
    button: u8;             // The controller button (SDL_GameControllerButton) 
    state: u8;              // SDL_PRESSED or SDL_RELEASED 
    padding1: u8;
    padding2: u8;
}

SDL_ControllerDeviceEvent :: struct {
    type: SDL_EventType;    // SDL_CONTROLLERDEVICEADDED, SDL_CONTROLLERDEVICEREMOVED, or SDL_CONTROLLERDEVICEREMAPPED
    timestamp: u32;
    which: s32;             // The joystick device index for the ADDED event, instance id for the REMOVED or REMAPPED event 
}

SDL_AudioDeviceEvent :: struct {
    type: SDL_EventType;
    timestamp: u32;
    // @@
}

SDL_QuitEvent :: struct {
    type: SDL_EventType;
    timestamp: u32;
    // @@
}

SDL_UserEvent :: struct {
    type: SDL_EventType;
    timestamp: u32;
    // @@
}

SDL_SysWMEvent :: struct {
    type: SDL_EventType;
    timestamp: u32;
    // @@
}

SDL_TouchFingerEvent :: struct {
    type: SDL_EventType;
    timestamp: u32;
    // @@
}

SDL_MultiGestureEvent :: struct {
    type: SDL_EventType;
    timestamp: u32;
    // @@
}

SDL_DollarGestureEvent :: struct {
    type: SDL_EventType;
    timestamp: u32;
    // @@
}

SDL_DropEvent :: struct {
    type:      SDL_EventType; // SDL_DROPBEGIN or SDL_DROPFILE or SDL_DROPTEXT or SDL_DROPCOMPLETE
    timestamp: u32;           // In milliseconds, populated using SDL_GetTicks()
    file:      *u8;           // The file name, which should be freed with SDL_free(), is NULL on begin/complete
    windowID:  u32;           // The window that was dropped on, if any
}


SDL_Event :: union {
    type: SDL_EventType;
    common : SDL_CommonEvent;         // Common event data 
    window : SDL_WindowEvent;         // Window event data 
    key : SDL_KeyboardEvent;          // Keyboard event data 
    edit : SDL_TextEditingEvent;      // Text editing event data 
    text : SDL_TextInputEvent;        // Text input event data 
    motion : SDL_MouseMotionEvent;    // Mouse motion event data 
    button : SDL_MouseButtonEvent;    // Mouse button event data 
    wheel : SDL_MouseWheelEvent;      // Mouse wheel event data 
    jaxis : SDL_JoyAxisEvent;         // Joystick axis event data 
    jball : SDL_JoyBallEvent;         // Joystick ball event data 
    jhat : SDL_JoyHatEvent;           // Joystick hat event data 
    jbutton : SDL_JoyButtonEvent;     // Joystick button event data 
    jdevice : SDL_JoyDeviceEvent;     // Joystick device change event data 
    caxis : SDL_ControllerAxisEvent;      // Game Controller axis event data 
    cbutton : SDL_ControllerButtonEvent;  // Game Controller button event data 
    cdevice : SDL_ControllerDeviceEvent;  // Game Controller device event data 
    adevice : SDL_AudioDeviceEvent;   // Audio device event data 
    quit : SDL_QuitEvent;             // Quit request event data 
    user : SDL_UserEvent;             // Custom event data 
    syswm : SDL_SysWMEvent;           // System dependent window event data 
    tfinger : SDL_TouchFingerEvent;   // Touch finger event data 
    mgesture : SDL_MultiGestureEvent; // Gesture event data 
    dgesture : SDL_DollarGestureEvent; // Gesture event data 
    drop : SDL_DropEvent;             // Drag and drop event data 
    
    /* This is necessary for ABI compatibility between Visual C++ and GCC
       Visual C++ will respect the push pack pragma and use 52 bytes for
       this structure, and GCC will use the alignment of the largest datatype
       within the union, which is 8 bytes.

       So... we'll add padding to force the size to be 56 bytes for both.
    */
    padding: [56]u8;
}
#assert(size_of(SDL_Event) == 56);


using SDL_eventaction :: enum u32 {
    SDL_ADDEVENT;
    SDL_PEEKEVENT;
    SDL_GETEVENT;
}

SDL_PumpEvents :: () #foreign sdl3;
SDL_PeepEvents :: (events: *SDL_Event, numevents: s32, action: SDL_eventaction, minType: u32, maxType: u32) -> s32 #foreign sdl3;
SDL_HasEvent :: (type: u32) -> SDL_bool #foreign sdl3;
SDL_HasEvents :: (minType: u32, maxType: u32) -> SDL_bool #foreign sdl3;
SDL_FlushEvent :: (type: u32) #foreign sdl3;
SDL_FlushEvents :: (minType: u32, maxType: u32) #foreign sdl3;
SDL_PollEvent :: (event: *SDL_Event) -> s32 #foreign sdl3;
SDL_WaitEvent :: (event: *SDL_Event) -> s32 #foreign sdl3;
SDL_WaitEventTimeout :: (event: *SDL_Event, timeout: s32) -> s32 #foreign sdl3;
SDL_PushEvent :: (event: *SDL_Event) -> s32 #foreign sdl3;

// SDL_keyboard.h

using SDL_Scancode :: enum s32 {
    SDL_SCANCODE_UNKNOWN :: 0;
    
    SDL_SCANCODE_A :: 4;
    SDL_SCANCODE_B :: 5;
    SDL_SCANCODE_C :: 6;
    SDL_SCANCODE_D :: 7;
    SDL_SCANCODE_E :: 8;
    SDL_SCANCODE_F :: 9;
    SDL_SCANCODE_G :: 10;
    SDL_SCANCODE_H :: 11;
    SDL_SCANCODE_I :: 12;
    SDL_SCANCODE_J :: 13;
    SDL_SCANCODE_K :: 14;
    SDL_SCANCODE_L :: 15;
    SDL_SCANCODE_M :: 16;
    SDL_SCANCODE_N :: 17;
    SDL_SCANCODE_O :: 18;
    SDL_SCANCODE_P :: 19;
    SDL_SCANCODE_Q :: 20;
    SDL_SCANCODE_R :: 21;
    SDL_SCANCODE_S :: 22;
    SDL_SCANCODE_T :: 23;
    SDL_SCANCODE_U :: 24;
    SDL_SCANCODE_V :: 25;
    SDL_SCANCODE_W :: 26;
    SDL_SCANCODE_X :: 27;
    SDL_SCANCODE_Y :: 28;
    SDL_SCANCODE_Z :: 29;
    
    SDL_SCANCODE_1 :: 30;
    SDL_SCANCODE_2 :: 31;
    SDL_SCANCODE_3 :: 32;
    SDL_SCANCODE_4 :: 33;
    SDL_SCANCODE_5 :: 34;
    SDL_SCANCODE_6 :: 35;
    SDL_SCANCODE_7 :: 36;
    SDL_SCANCODE_8 :: 37;
    SDL_SCANCODE_9 :: 38;
    SDL_SCANCODE_0 :: 39;
    
    SDL_SCANCODE_RETURN :: 40;
    SDL_SCANCODE_ESCAPE :: 41;
    SDL_SCANCODE_BACKSPACE :: 42;
    SDL_SCANCODE_TAB :: 43;
    SDL_SCANCODE_SPACE :: 44;
    
    SDL_SCANCODE_MINUS :: 45;
    SDL_SCANCODE_EQUALS :: 46;
    SDL_SCANCODE_LEFTBRACKET :: 47;
    SDL_SCANCODE_RIGHTBRACKET :: 48;
    SDL_SCANCODE_BACKSLASH :: 49;
    SDL_SCANCODE_NONUSHASH :: 50;
    SDL_SCANCODE_SEMICOLON :: 51;
    SDL_SCANCODE_APOSTROPHE :: 52;
    SDL_SCANCODE_GRAVE :: 53;
    SDL_SCANCODE_COMMA :: 54;
    SDL_SCANCODE_PERIOD :: 55;
    SDL_SCANCODE_SLASH :: 56;
    
    SDL_SCANCODE_CAPSLOCK :: 57;
    
    SDL_SCANCODE_F1 :: 58;
    SDL_SCANCODE_F2 :: 59;
    SDL_SCANCODE_F3 :: 60;
    SDL_SCANCODE_F4 :: 61;
    SDL_SCANCODE_F5 :: 62;
    SDL_SCANCODE_F6 :: 63;
    SDL_SCANCODE_F7 :: 64;
    SDL_SCANCODE_F8 :: 65;
    SDL_SCANCODE_F9 :: 66;
    SDL_SCANCODE_F10 :: 67;
    SDL_SCANCODE_F11 :: 68;
    SDL_SCANCODE_F12 :: 69;
    
    SDL_SCANCODE_PRINTSCREEN :: 70;
    SDL_SCANCODE_SCROLLLOCK :: 71;
    SDL_SCANCODE_PAUSE :: 72;
    SDL_SCANCODE_INSERT :: 73;
    SDL_SCANCODE_HOME :: 74;
    SDL_SCANCODE_PAGEUP :: 75;
    SDL_SCANCODE_DELETE :: 76;
    SDL_SCANCODE_END :: 77;
    SDL_SCANCODE_PAGEDOWN :: 78;
    SDL_SCANCODE_RIGHT :: 79;
    SDL_SCANCODE_LEFT :: 80;
    SDL_SCANCODE_DOWN :: 81;
    SDL_SCANCODE_UP :: 82;
    
    SDL_SCANCODE_NUMLOCKCLEAR :: 83;
    SDL_SCANCODE_KP_DIVIDE :: 84;
    SDL_SCANCODE_KP_MULTIPLY :: 85;
    SDL_SCANCODE_KP_MINUS :: 86;
    SDL_SCANCODE_KP_PLUS :: 87;
    SDL_SCANCODE_KP_ENTER :: 88;
    SDL_SCANCODE_KP_1 :: 89;
    SDL_SCANCODE_KP_2 :: 90;
    SDL_SCANCODE_KP_3 :: 91;
    SDL_SCANCODE_KP_4 :: 92;
    SDL_SCANCODE_KP_5 :: 93;
    SDL_SCANCODE_KP_6 :: 94;
    SDL_SCANCODE_KP_7 :: 95;
    SDL_SCANCODE_KP_8 :: 96;
    SDL_SCANCODE_KP_9 :: 97;
    SDL_SCANCODE_KP_0 :: 98;
    SDL_SCANCODE_KP_PERIOD :: 99;
    
    SDL_SCANCODE_NONUSBACKSLASH :: 100;
    SDL_SCANCODE_APPLICATION :: 101;
    SDL_SCANCODE_POWER :: 102;
    SDL_SCANCODE_KP_EQUALS :: 103;
    SDL_SCANCODE_F13 :: 104;
    SDL_SCANCODE_F14 :: 105;
    SDL_SCANCODE_F15 :: 106;
    SDL_SCANCODE_F16 :: 107;
    SDL_SCANCODE_F17 :: 108;
    SDL_SCANCODE_F18 :: 109;
    SDL_SCANCODE_F19 :: 110;
    SDL_SCANCODE_F20 :: 111;
    SDL_SCANCODE_F21 :: 112;
    SDL_SCANCODE_F22 :: 113;
    SDL_SCANCODE_F23 :: 114;
    SDL_SCANCODE_F24 :: 115;
    SDL_SCANCODE_EXECUTE :: 116;
    SDL_SCANCODE_HELP :: 117;
    SDL_SCANCODE_MENU :: 118;
    SDL_SCANCODE_SELECT :: 119;
    SDL_SCANCODE_STOP :: 120;
    SDL_SCANCODE_AGAIN :: 121;
    SDL_SCANCODE_UNDO :: 122;
    SDL_SCANCODE_CUT :: 123;
    SDL_SCANCODE_COPY :: 124;
    SDL_SCANCODE_PASTE :: 125;
    SDL_SCANCODE_FIND :: 126;
    SDL_SCANCODE_MUTE :: 127;
    SDL_SCANCODE_VOLUMEUP :: 128;
    SDL_SCANCODE_VOLUMEDOWN :: 129;
    SDL_SCANCODE_KP_COMMA :: 133;
    SDL_SCANCODE_KP_EQUALSAS400 :: 134;
    
    SDL_SCANCODE_INTERNATIONAL1 :: 135;
    SDL_SCANCODE_INTERNATIONAL2 :: 136;
    SDL_SCANCODE_INTERNATIONAL3 :: 137;
    SDL_SCANCODE_INTERNATIONAL4 :: 138;
    SDL_SCANCODE_INTERNATIONAL5 :: 139;
    SDL_SCANCODE_INTERNATIONAL6 :: 140;
    SDL_SCANCODE_INTERNATIONAL7 :: 141;
    SDL_SCANCODE_INTERNATIONAL8 :: 142;
    SDL_SCANCODE_INTERNATIONAL9 :: 143;
    SDL_SCANCODE_LANG1 :: 144;
    SDL_SCANCODE_LANG2 :: 145;
    SDL_SCANCODE_LANG3 :: 146;
    SDL_SCANCODE_LANG4 :: 147;
    SDL_SCANCODE_LANG5 :: 148;
    SDL_SCANCODE_LANG6 :: 149;
    SDL_SCANCODE_LANG7 :: 150;
    SDL_SCANCODE_LANG8 :: 151;
    SDL_SCANCODE_LANG9 :: 152;
    
    SDL_SCANCODE_ALTERASE :: 153;
    SDL_SCANCODE_SYSREQ :: 154;
    SDL_SCANCODE_CANCEL :: 155;
    SDL_SCANCODE_CLEAR :: 156;
    SDL_SCANCODE_PRIOR :: 157;
    SDL_SCANCODE_RETURN2 :: 158;
    SDL_SCANCODE_SEPARATOR :: 159;
    SDL_SCANCODE_OUT :: 160;
    SDL_SCANCODE_OPER :: 161;
    SDL_SCANCODE_CLEARAGAIN :: 162;
    SDL_SCANCODE_CRSEL :: 163;
    SDL_SCANCODE_EXSEL :: 164;
    
    SDL_SCANCODE_KP_00 :: 176;
    SDL_SCANCODE_KP_000 :: 177;
    SDL_SCANCODE_THOUSANDSSEPARATOR :: 178;
    SDL_SCANCODE_DECIMALSEPARATOR :: 179;
    SDL_SCANCODE_CURRENCYUNIT :: 180;
    SDL_SCANCODE_CURRENCYSUBUNIT :: 181;
    SDL_SCANCODE_KP_LEFTPAREN :: 182;
    SDL_SCANCODE_KP_RIGHTPAREN :: 183;
    SDL_SCANCODE_KP_LEFTBRACE :: 184;
    SDL_SCANCODE_KP_RIGHTBRACE :: 185;
    SDL_SCANCODE_KP_TAB :: 186;
    SDL_SCANCODE_KP_BACKSPACE :: 187;
    SDL_SCANCODE_KP_A :: 188;
    SDL_SCANCODE_KP_B :: 189;
    SDL_SCANCODE_KP_C :: 190;
    SDL_SCANCODE_KP_D :: 191;
    SDL_SCANCODE_KP_E :: 192;
    SDL_SCANCODE_KP_F :: 193;
    SDL_SCANCODE_KP_XOR :: 194;
    SDL_SCANCODE_KP_POWER :: 195;
    SDL_SCANCODE_KP_PERCENT :: 196;
    SDL_SCANCODE_KP_LESS :: 197;
    SDL_SCANCODE_KP_GREATER :: 198;
    SDL_SCANCODE_KP_AMPERSAND :: 199;
    SDL_SCANCODE_KP_DBLAMPERSAND :: 200;
    SDL_SCANCODE_KP_VERTICALBAR :: 201;
    SDL_SCANCODE_KP_DBLVERTICALBAR :: 202;
    SDL_SCANCODE_KP_COLON :: 203;
    SDL_SCANCODE_KP_HASH :: 204;
    SDL_SCANCODE_KP_SPACE :: 205;
    SDL_SCANCODE_KP_AT :: 206;
    SDL_SCANCODE_KP_EXCLAM :: 207;
    SDL_SCANCODE_KP_MEMSTORE :: 208;
    SDL_SCANCODE_KP_MEMRECALL :: 209;
    SDL_SCANCODE_KP_MEMCLEAR :: 210;
    SDL_SCANCODE_KP_MEMADD :: 211;
    SDL_SCANCODE_KP_MEMSUBTRACT :: 212;
    SDL_SCANCODE_KP_MEMMULTIPLY :: 213;
    SDL_SCANCODE_KP_MEMDIVIDE :: 214;
    SDL_SCANCODE_KP_PLUSMINUS :: 215;
    SDL_SCANCODE_KP_CLEAR :: 216;
    SDL_SCANCODE_KP_CLEARENTRY :: 217;
    SDL_SCANCODE_KP_BINARY :: 218;
    SDL_SCANCODE_KP_OCTAL :: 219;
    SDL_SCANCODE_KP_DECIMAL :: 220;
    SDL_SCANCODE_KP_HEXADECIMAL :: 221;
    
    SDL_SCANCODE_LCTRL :: 224;
    SDL_SCANCODE_LSHIFT :: 225;
    SDL_SCANCODE_LALT :: 226;
    SDL_SCANCODE_LGUI :: 227;
    SDL_SCANCODE_RCTRL :: 228;
    SDL_SCANCODE_RSHIFT :: 229;
    SDL_SCANCODE_RALT :: 230;
    SDL_SCANCODE_RGUI :: 231;
    
    SDL_SCANCODE_MODE :: 257;
    
    SDL_SCANCODE_AUDIONEXT :: 258;
    SDL_SCANCODE_AUDIOPREV :: 259;
    SDL_SCANCODE_AUDIOSTOP :: 260;
    SDL_SCANCODE_AUDIOPLAY :: 261;
    SDL_SCANCODE_AUDIOMUTE :: 262;
    SDL_SCANCODE_MEDIASELECT :: 263;
    SDL_SCANCODE_WWW :: 264;
    SDL_SCANCODE_MAIL :: 265;
    SDL_SCANCODE_CALCULATOR :: 266;
    SDL_SCANCODE_COMPUTER :: 267;
    SDL_SCANCODE_AC_SEARCH :: 268;
    SDL_SCANCODE_AC_HOME :: 269;
    SDL_SCANCODE_AC_BACK :: 270;
    SDL_SCANCODE_AC_FORWARD :: 271;
    SDL_SCANCODE_AC_STOP :: 272;
    SDL_SCANCODE_AC_REFRESH :: 273;
    SDL_SCANCODE_AC_BOOKMARKS :: 274;
    
    SDL_SCANCODE_BRIGHTNESSDOWN :: 275;
    SDL_SCANCODE_BRIGHTNESSUP :: 276;
    SDL_SCANCODE_DISPLAYSWITCH :: 277;
    SDL_SCANCODE_KBDILLUMTOGGLE :: 278;
    SDL_SCANCODE_KBDILLUMDOWN :: 279;
    SDL_SCANCODE_KBDILLUMUP :: 280;
    SDL_SCANCODE_EJECT :: 281;
    SDL_SCANCODE_SLEEP :: 282;
    
    SDL_SCANCODE_APP1 :: 283;
    SDL_SCANCODE_APP2 :: 284;
    
    SDL_NUM_SCANCODES :: 512;
};

//SDLK_SCANCODE_MASK :: 1 << 30;
SDL_SCANCODE_TO_KEYCODE :: inline (scancode: SDL_Scancode) -> s32 {
    //return scancode | SDLK_SCANCODE_MASK;
    return (cast(s32)scancode) | (1 << 30);
} 

Hack :: struct {
    // This is a @Temporary hack to get around the circular dependency thing that
    // is happening with #run and overloads if you just call SDL_SCANCODE_TO_KEYCODE.
    // I need to do something to resolve this. My only idea so far is to have name-inclusion
    // be a separate phase from typechecking. (Right now we wait on something being inferred
    // to kick off a 'using', but this is not necessary if we know all the names and can
    // just insert import_links to them, and then we wait for those import links to typecheck.)
    
    K :: inline (scancode: SDL_Scancode) -> s32 {
        //return scancode | SDLK_SCANCODE_MASK;
        return (cast(s32)scancode) | (1 << 30);
    } 
}


using SDL_Keycode :: enum s32 {
    SDLK_UNKNOWN :: 0;
    
    SDLK_RETURN :: #char "\r";
    SDLK_ESCAPE :: 27; // 0o33
    SDLK_BACKSPACE :: 8; // '\b';
    SDLK_TAB :: #char "\t";
    SDLK_SPACE :: #char " ";
    SDLK_EXCLAIM :: #char "!";
    SDLK_QUOTEDBL ::  #char "\"";
    SDLK_HASH :: #char "#";
    SDLK_PERCENT :: #char "%";
    SDLK_DOLLAR :: #char "$";
    SDLK_AMPERSAND :: #char "&";
    SDLK_QUOTE :: #char "'";
    SDLK_LEFTPAREN :: #char "(";
    SDLK_RIGHTPAREN :: #char ")";
    SDLK_ASTERISK :: #char "*";
    SDLK_PLUS :: #char "+";
    SDLK_COMMA :: #char ",";
    SDLK_MINUS :: #char "-";
    SDLK_PERIOD :: #char ".";
    SDLK_SLASH :: #char "/";
    SDLK_0 :: #char "0";
    SDLK_1 :: #char "1";
    SDLK_2 :: #char "2";
    SDLK_3 :: #char "3";
    SDLK_4 :: #char "4";
    SDLK_5 :: #char "5";
    SDLK_6 :: #char "6";
    SDLK_7 :: #char "7";
    SDLK_8 :: #char "8";
    SDLK_9 :: #char "9";
    SDLK_COLON :: #char ":";
    SDLK_SEMICOLON :: #char ";";
    SDLK_LESS :: #char "<";
    SDLK_EQUALS :: #char "=";
    SDLK_GREATER :: #char ">";
    SDLK_QUESTION :: #char "?";
    SDLK_AT :: #char "@";
    /*
       Skip uppercase letters
     */
    SDLK_LEFTBRACKET :: #char "[";
    SDLK_BACKSLASH :: #char "\\";
    SDLK_RIGHTBRACKET :: #char "]";
    SDLK_CARET :: #char "^";
    SDLK_UNDERSCORE :: #char "_";
    SDLK_BACKQUOTE :: #char "`";
    SDLK_a :: #char "a";
    SDLK_b :: #char "b";
    SDLK_c :: #char "c";
    SDLK_d :: #char "d";
    SDLK_e :: #char "e";
    SDLK_f :: #char "f";
    SDLK_g :: #char "g";
    SDLK_h :: #char "h";
    SDLK_i :: #char "i";
    SDLK_j :: #char "j";
    SDLK_k :: #char "k";
    SDLK_l :: #char "l";
    SDLK_m :: #char "m";
    SDLK_n :: #char "n";
    SDLK_o :: #char "o";
    SDLK_p :: #char "p";
    SDLK_q :: #char "q";
    SDLK_r :: #char "r";
    SDLK_s :: #char "s";
    SDLK_t :: #char "t";
    SDLK_u :: #char "u";
    SDLK_v :: #char "v";
    SDLK_w :: #char "w";
    SDLK_x :: #char "x";
    SDLK_y :: #char "y";
    SDLK_z :: #char "z";
    
    SDLK_SCANCODE_MASK :: 1 << 30;
    
    //
    // Note: All this #run SDL_SCANCODE_TO_KEYCODE is crazy in terms of
    // expense required to do simple things. Eventually we will probably be
    // able to substitute a macro here (when we have macros) but that will
    // still be perhaps a bit more expensive than I'd like.
    //
    
    SDLK_CAPSLOCK :: #run Hack.K(SDL_SCANCODE_CAPSLOCK);
    
    SDLK_F1 :: #run Hack.K(SDL_SCANCODE_F1);
    SDLK_F2 :: #run Hack.K(SDL_SCANCODE_F2);
    SDLK_F3 :: #run Hack.K(SDL_SCANCODE_F3);
    SDLK_F4 :: #run Hack.K(SDL_SCANCODE_F4);
    SDLK_F5 :: #run Hack.K(SDL_SCANCODE_F5);
    SDLK_F6 :: #run Hack.K(SDL_SCANCODE_F6);
    SDLK_F7 :: #run Hack.K(SDL_SCANCODE_F7);
    SDLK_F8 :: #run Hack.K(SDL_SCANCODE_F8);
    SDLK_F9 :: #run Hack.K(SDL_SCANCODE_F9);
    SDLK_F10 :: #run Hack.K(SDL_SCANCODE_F10);
    SDLK_F11 :: #run Hack.K(SDL_SCANCODE_F11);
    SDLK_F12 :: #run Hack.K(SDL_SCANCODE_F12);
    
    SDLK_PRINTSCREEN :: #run Hack.K(SDL_SCANCODE_PRINTSCREEN);
    SDLK_SCROLLLOCK :: #run Hack.K(SDL_SCANCODE_SCROLLLOCK);
    SDLK_PAUSE :: #run Hack.K(SDL_SCANCODE_PAUSE);
    SDLK_INSERT :: #run Hack.K(SDL_SCANCODE_INSERT);
    SDLK_HOME :: #run Hack.K(SDL_SCANCODE_HOME);
    SDLK_PAGEUP :: #run Hack.K(SDL_SCANCODE_PAGEUP);
    SDLK_DELETE :: 127;// #run Hack.K(SDL_SCANCODE_DELETE); // 177? @@ Why is this one different ???
    SDLK_END :: #run Hack.K(SDL_SCANCODE_END);
    SDLK_PAGEDOWN :: #run Hack.K(SDL_SCANCODE_PAGEDOWN);
    SDLK_RIGHT :: #run Hack.K(SDL_SCANCODE_RIGHT);
    SDLK_LEFT :: #run Hack.K(SDL_SCANCODE_LEFT);
    SDLK_DOWN :: #run Hack.K(SDL_SCANCODE_DOWN);
    SDLK_UP :: #run Hack.K(SDL_SCANCODE_UP);
    
    
    SDLK_NUMLOCKCLEAR :: #run Hack.K(SDL_SCANCODE_NUMLOCKCLEAR);
    SDLK_KP_DIVIDE :: #run Hack.K(SDL_SCANCODE_KP_DIVIDE);
    SDLK_KP_MULTIPLY :: #run Hack.K(SDL_SCANCODE_KP_MULTIPLY);
    SDLK_KP_MINUS :: #run Hack.K(SDL_SCANCODE_KP_MINUS);
    SDLK_KP_PLUS :: #run Hack.K(SDL_SCANCODE_KP_PLUS);
    SDLK_KP_ENTER :: #run Hack.K(SDL_SCANCODE_KP_ENTER);
    SDLK_KP_1 :: #run Hack.K(SDL_SCANCODE_KP_1);
    SDLK_KP_2 :: #run Hack.K(SDL_SCANCODE_KP_2);
    SDLK_KP_3 :: #run Hack.K(SDL_SCANCODE_KP_3);
    SDLK_KP_4 :: #run Hack.K(SDL_SCANCODE_KP_4);
    SDLK_KP_5 :: #run Hack.K(SDL_SCANCODE_KP_5);
    SDLK_KP_6 :: #run Hack.K(SDL_SCANCODE_KP_6);
    SDLK_KP_7 :: #run Hack.K(SDL_SCANCODE_KP_7);
    SDLK_KP_8 :: #run Hack.K(SDL_SCANCODE_KP_8);
    SDLK_KP_9 :: #run Hack.K(SDL_SCANCODE_KP_9);
    SDLK_KP_0 :: #run Hack.K(SDL_SCANCODE_KP_0);
    SDLK_KP_PERIOD :: #run Hack.K(SDL_SCANCODE_KP_PERIOD);
    
    SDLK_APPLICATION :: #run Hack.K(SDL_SCANCODE_APPLICATION);
    SDLK_POWER :: #run Hack.K(SDL_SCANCODE_POWER);
    SDLK_KP_EQUALS :: #run Hack.K(SDL_SCANCODE_KP_EQUALS);
    SDLK_F13 :: #run Hack.K(SDL_SCANCODE_F13);
    SDLK_F14 :: #run Hack.K(SDL_SCANCODE_F14);
    SDLK_F15 :: #run Hack.K(SDL_SCANCODE_F15);
    SDLK_F16 :: #run Hack.K(SDL_SCANCODE_F16);
    SDLK_F17 :: #run Hack.K(SDL_SCANCODE_F17);
    SDLK_F18 :: #run Hack.K(SDL_SCANCODE_F18);
    SDLK_F19 :: #run Hack.K(SDL_SCANCODE_F19);
    SDLK_F20 :: #run Hack.K(SDL_SCANCODE_F20);
    SDLK_F21 :: #run Hack.K(SDL_SCANCODE_F21);
    SDLK_F22 :: #run Hack.K(SDL_SCANCODE_F22);
    SDLK_F23 :: #run Hack.K(SDL_SCANCODE_F23);
    SDLK_F24 :: #run Hack.K(SDL_SCANCODE_F24);
    SDLK_EXECUTE :: #run Hack.K(SDL_SCANCODE_EXECUTE);
    SDLK_HELP :: #run Hack.K(SDL_SCANCODE_HELP);
    SDLK_MENU :: #run Hack.K(SDL_SCANCODE_MENU);
    SDLK_SELECT :: #run Hack.K(SDL_SCANCODE_SELECT);
    SDLK_STOP :: #run Hack.K(SDL_SCANCODE_STOP);
    SDLK_AGAIN :: #run Hack.K(SDL_SCANCODE_AGAIN);
    SDLK_UNDO :: #run Hack.K(SDL_SCANCODE_UNDO);
    SDLK_CUT :: #run Hack.K(SDL_SCANCODE_CUT);
    SDLK_COPY :: #run Hack.K(SDL_SCANCODE_COPY);
    SDLK_PASTE :: #run Hack.K(SDL_SCANCODE_PASTE);
    SDLK_FIND :: #run Hack.K(SDL_SCANCODE_FIND);
    SDLK_MUTE :: #run Hack.K(SDL_SCANCODE_MUTE);
    SDLK_VOLUMEUP :: #run Hack.K(SDL_SCANCODE_VOLUMEUP);
    SDLK_VOLUMEDOWN :: #run Hack.K(SDL_SCANCODE_VOLUMEDOWN);
    SDLK_KP_COMMA :: #run Hack.K(SDL_SCANCODE_KP_COMMA);
    SDLK_KP_EQUALSAS400 :: #run Hack.K(SDL_SCANCODE_KP_EQUALSAS400);
    
    SDLK_ALTERASE :: #run Hack.K(SDL_SCANCODE_ALTERASE);
    SDLK_SYSREQ :: #run Hack.K(SDL_SCANCODE_SYSREQ);
    SDLK_CANCEL :: #run Hack.K(SDL_SCANCODE_CANCEL);
    SDLK_CLEAR :: #run Hack.K(SDL_SCANCODE_CLEAR);
    SDLK_PRIOR :: #run Hack.K(SDL_SCANCODE_PRIOR);
    SDLK_RETURN2 :: #run Hack.K(SDL_SCANCODE_RETURN2);
    SDLK_SEPARATOR :: #run Hack.K(SDL_SCANCODE_SEPARATOR);
    SDLK_OUT :: #run Hack.K(SDL_SCANCODE_OUT);
    SDLK_OPER :: #run Hack.K(SDL_SCANCODE_OPER);
    SDLK_CLEARAGAIN :: #run Hack.K(SDL_SCANCODE_CLEARAGAIN);
    SDLK_CRSEL :: #run Hack.K(SDL_SCANCODE_CRSEL);
    SDLK_EXSEL :: #run Hack.K(SDL_SCANCODE_EXSEL);
    
    SDLK_KP_00 :: #run Hack.K(SDL_SCANCODE_KP_00);
    SDLK_KP_000 :: #run Hack.K(SDL_SCANCODE_KP_000);
    SDLK_THOUSANDSSEPARATOR :: #run Hack.K(SDL_SCANCODE_THOUSANDSSEPARATOR);
    SDLK_DECIMALSEPARATOR :: #run Hack.K(SDL_SCANCODE_DECIMALSEPARATOR);
    SDLK_CURRENCYUNIT :: #run Hack.K(SDL_SCANCODE_CURRENCYUNIT);
    SDLK_CURRENCYSUBUNIT :: #run Hack.K(SDL_SCANCODE_CURRENCYSUBUNIT);
    SDLK_KP_LEFTPAREN :: #run Hack.K(SDL_SCANCODE_KP_LEFTPAREN);
    SDLK_KP_RIGHTPAREN :: #run Hack.K(SDL_SCANCODE_KP_RIGHTPAREN);
    SDLK_KP_LEFTBRACE :: #run Hack.K(SDL_SCANCODE_KP_LEFTBRACE);
    SDLK_KP_RIGHTBRACE :: #run Hack.K(SDL_SCANCODE_KP_RIGHTBRACE);
    SDLK_KP_TAB :: #run Hack.K(SDL_SCANCODE_KP_TAB);
    SDLK_KP_BACKSPACE :: #run Hack.K(SDL_SCANCODE_KP_BACKSPACE);
    SDLK_KP_A :: #run Hack.K(SDL_SCANCODE_KP_A);
    SDLK_KP_B :: #run Hack.K(SDL_SCANCODE_KP_B);
    SDLK_KP_C :: #run Hack.K(SDL_SCANCODE_KP_C);
    SDLK_KP_D :: #run Hack.K(SDL_SCANCODE_KP_D);
    SDLK_KP_E :: #run Hack.K(SDL_SCANCODE_KP_E);
    SDLK_KP_F :: #run Hack.K(SDL_SCANCODE_KP_F);
    SDLK_KP_XOR :: #run Hack.K(SDL_SCANCODE_KP_XOR);
    SDLK_KP_POWER :: #run Hack.K(SDL_SCANCODE_KP_POWER);
    SDLK_KP_PERCENT :: #run Hack.K(SDL_SCANCODE_KP_PERCENT);
    SDLK_KP_LESS :: #run Hack.K(SDL_SCANCODE_KP_LESS);
    SDLK_KP_GREATER :: #run Hack.K(SDL_SCANCODE_KP_GREATER);
    SDLK_KP_AMPERSAND :: #run Hack.K(SDL_SCANCODE_KP_AMPERSAND);
    SDLK_KP_DBLAMPERSAND :: #run Hack.K(SDL_SCANCODE_KP_DBLAMPERSAND);
    SDLK_KP_VERTICALBAR :: #run Hack.K(SDL_SCANCODE_KP_VERTICALBAR);
    SDLK_KP_DBLVERTICALBAR :: #run Hack.K(SDL_SCANCODE_KP_DBLVERTICALBAR);
    SDLK_KP_COLON :: #run Hack.K(SDL_SCANCODE_KP_COLON);
    SDLK_KP_HASH :: #run Hack.K(SDL_SCANCODE_KP_HASH);
    SDLK_KP_SPACE :: #run Hack.K(SDL_SCANCODE_KP_SPACE);
    SDLK_KP_AT :: #run Hack.K(SDL_SCANCODE_KP_AT);
    SDLK_KP_EXCLAM :: #run Hack.K(SDL_SCANCODE_KP_EXCLAM);
    SDLK_KP_MEMSTORE :: #run Hack.K(SDL_SCANCODE_KP_MEMSTORE);
    SDLK_KP_MEMRECALL :: #run Hack.K(SDL_SCANCODE_KP_MEMRECALL);
    SDLK_KP_MEMCLEAR :: #run Hack.K(SDL_SCANCODE_KP_MEMCLEAR);
    SDLK_KP_MEMADD :: #run Hack.K(SDL_SCANCODE_KP_MEMADD);
    SDLK_KP_MEMSUBTRACT :: #run Hack.K(SDL_SCANCODE_KP_MEMSUBTRACT);
    SDLK_KP_MEMMULTIPLY :: #run Hack.K(SDL_SCANCODE_KP_MEMMULTIPLY);
    SDLK_KP_MEMDIVIDE :: #run Hack.K(SDL_SCANCODE_KP_MEMDIVIDE);
    SDLK_KP_PLUSMINUS :: #run Hack.K(SDL_SCANCODE_KP_PLUSMINUS);
    SDLK_KP_CLEAR :: #run Hack.K(SDL_SCANCODE_KP_CLEAR);
    SDLK_KP_CLEARENTRY :: #run Hack.K(SDL_SCANCODE_KP_CLEARENTRY);
    SDLK_KP_BINARY :: #run Hack.K(SDL_SCANCODE_KP_BINARY);
    SDLK_KP_OCTAL :: #run Hack.K(SDL_SCANCODE_KP_OCTAL);
    SDLK_KP_DECIMAL :: #run Hack.K(SDL_SCANCODE_KP_DECIMAL);
    SDLK_KP_HEXADECIMAL :: #run Hack.K(SDL_SCANCODE_KP_HEXADECIMAL);
    
    SDLK_LCTRL :: #run Hack.K(SDL_SCANCODE_LCTRL);
    SDLK_LSHIFT :: #run Hack.K(SDL_SCANCODE_LSHIFT);
    SDLK_LALT :: #run Hack.K(SDL_SCANCODE_LALT);
    SDLK_LGUI :: #run Hack.K(SDL_SCANCODE_LGUI);
    SDLK_RCTRL :: #run Hack.K(SDL_SCANCODE_RCTRL);
    SDLK_RSHIFT :: #run Hack.K(SDL_SCANCODE_RSHIFT);
    SDLK_RALT :: #run Hack.K(SDL_SCANCODE_RALT);
    SDLK_RGUI :: #run Hack.K(SDL_SCANCODE_RGUI);
    
    SDLK_MODE :: #run Hack.K(SDL_SCANCODE_MODE);
    
    SDLK_AUDIONEXT :: #run Hack.K(SDL_SCANCODE_AUDIONEXT);
    SDLK_AUDIOPREV :: #run Hack.K(SDL_SCANCODE_AUDIOPREV);
    SDLK_AUDIOSTOP :: #run Hack.K(SDL_SCANCODE_AUDIOSTOP);
    SDLK_AUDIOPLAY :: #run Hack.K(SDL_SCANCODE_AUDIOPLAY);
    SDLK_AUDIOMUTE :: #run Hack.K(SDL_SCANCODE_AUDIOMUTE);
    SDLK_MEDIASELECT :: #run Hack.K(SDL_SCANCODE_MEDIASELECT);
    SDLK_WWW :: #run Hack.K(SDL_SCANCODE_WWW);
    SDLK_MAIL :: #run Hack.K(SDL_SCANCODE_MAIL);
    SDLK_CALCULATOR :: #run Hack.K(SDL_SCANCODE_CALCULATOR);
    SDLK_COMPUTER :: #run Hack.K(SDL_SCANCODE_COMPUTER);
    SDLK_AC_SEARCH :: #run Hack.K(SDL_SCANCODE_AC_SEARCH);
    SDLK_AC_HOME :: #run Hack.K(SDL_SCANCODE_AC_HOME);
    SDLK_AC_BACK :: #run Hack.K(SDL_SCANCODE_AC_BACK);
    SDLK_AC_FORWARD :: #run Hack.K(SDL_SCANCODE_AC_FORWARD);
    SDLK_AC_STOP :: #run Hack.K(SDL_SCANCODE_AC_STOP);
    SDLK_AC_REFRESH :: #run Hack.K(SDL_SCANCODE_AC_REFRESH);
    SDLK_AC_BOOKMARKS :: #run Hack.K(SDL_SCANCODE_AC_BOOKMARKS);
    
    SDLK_BRIGHTNESSDOWN :: #run Hack.K(SDL_SCANCODE_BRIGHTNESSDOWN);
    SDLK_BRIGHTNESSUP :: #run Hack.K(SDL_SCANCODE_BRIGHTNESSUP);
    SDLK_DISPLAYSWITCH :: #run Hack.K(SDL_SCANCODE_DISPLAYSWITCH);
    SDLK_KBDILLUMTOGGLE :: #run Hack.K(SDL_SCANCODE_KBDILLUMTOGGLE);
    SDLK_KBDILLUMDOWN :: #run Hack.K(SDL_SCANCODE_KBDILLUMDOWN);
    SDLK_KBDILLUMUP :: #run Hack.K(SDL_SCANCODE_KBDILLUMUP);
    SDLK_EJECT :: #run Hack.K(SDL_SCANCODE_EJECT);
    SDLK_SLEEP :: #run Hack.K(SDL_SCANCODE_SLEEP);
    SDLK_APP1 :: #run Hack.K(SDL_SCANCODE_APP1);
    SDLK_APP2 :: #run Hack.K(SDL_SCANCODE_APP2);
    
    //SDLK_AUDIOREWIND :: #run Hack.K(SDL_SCANCODE_AUDIOREWIND);
    //SDLK_AUDIOFASTFORWARD :: #run Hack.K(SDL_SCANCODE_AUDIOFASTFORWARD);
}

using SDL_Keymod :: enum u16 {
    KMOD_NONE :: 0x0000;
    KMOD_LSHIFT :: 0x0001;
    KMOD_RSHIFT :: 0x0002;
    KMOD_SHIFT :: KMOD_LSHIFT|KMOD_RSHIFT;
    KMOD_LCTRL :: 0x0040;
    KMOD_RCTRL :: 0x0080;
    KMOD_CTRL :: KMOD_LCTRL|KMOD_RCTRL;
    KMOD_LALT :: 0x0100;
    KMOD_RALT :: 0x0200;
    KMOD_ALT :: KMOD_LALT|KMOD_RALT;
    KMOD_LGUI :: 0x0400;
    KMOD_RGUI :: 0x0800;
    KMOD_GUI :: KMOD_LGUI|KMOD_RGUI;
    KMOD_NUM :: 0x1000;
    KMOD_CAPS :: 0x2000;
    KMOD_MODE :: 0x4000;
    KMOD_RESERVED :: 0x8000;
}

SDL_Keysym :: struct {
    scancode: SDL_Scancode;     // SDL physical key code - see ::SDL_Scancode for details 
    sym: SDL_Keycode;           // SDL virtual key code - see ::SDL_Keycode for details 
    mod: SDL_Keymod;            // current key modifiers 
    unused: u16;
}


SDL_GetKeyboardState :: (numkeys: *s32) -> *u8 #foreign sdl3;

// SDL_joystick.h

SDL_Joystick :: *void;
SDL_JoystickID :: #type u32;

// SDL_rect.h

SDL_Rect :: struct {
    x, y, w, h: s32;
}

#scope_file

#if OS == .WINDOWS sdl3 :: #library "lib/sdl3";