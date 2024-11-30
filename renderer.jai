
MAX_BONES :: 1024;

mesh_pipeline: *SDL_GPUGraphicsPipeline;
skinning_matrices_buffer: *SDL_GPUBuffer;
depth_texture: *SDL_GPUTexture;

default_sampler: *SDL_GPUSampler;

init_renderer :: (device: *SDL_GPUDevice, w: *SDL_Window) {
    gpu_device = device;
    window = w;
    
    depth_format: SDL_GPUTextureFormat;
    depth_type := SDL_GPUTextureType.SDL_GPU_TEXTURETYPE_2D;
    depth_target := SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET;
	if SDL_GPUTextureSupportsFormat(gpu_device, .SDL_GPU_TEXTUREFORMAT_D24_UNORM_S8_UINT, depth_type, xx depth_target) {
        depth_format = .SDL_GPU_TEXTUREFORMAT_D24_UNORM_S8_UINT;
	} else if SDL_GPUTextureSupportsFormat(gpu_device, .SDL_GPU_TEXTUREFORMAT_D32_FLOAT_S8_UINT, depth_type, xx depth_target) {
        depth_format = .SDL_GPU_TEXTUREFORMAT_D32_FLOAT_S8_UINT;
    } else {
        fatal_error("Couldn't find a depth target format");
    }
    
    depth_info: SDL_GPUTextureCreateInfo;
    depth_info.type = .SDL_GPU_TEXTURETYPE_2D;
    depth_info.width = 1366;
    depth_info.height = 768;
    depth_info.layer_count_or_depth = 1;
    depth_info.num_levels = 1;
    depth_info.sample_count = .SDL_GPU_SAMPLECOUNT_1;
    depth_info.format = depth_format;
    depth_info.usage = SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET;
    depth_texture = SDL_CreateGPUTexture(gpu_device, *depth_info);
    SDL_SetGPUTextureName(gpu_device, depth_texture, "depth_texture".data);
    
    mesh_create_info: SDL_GPUGraphicsPipelineCreateInfo;
    colour_target_desc: SDL_GPUColorTargetDescription;
    colour_target_desc.format = SDL_GetGPUSwapchainTextureFormat(gpu_device, window);
    mesh_create_info.target_info.color_target_descriptions = *colour_target_desc;
    mesh_create_info.target_info.num_color_targets = 1;
    mesh_create_info.target_info.has_depth_stencil_target = true;
    mesh_create_info.target_info.depth_stencil_format = depth_format;
    
    mesh_create_info.depth_stencil_state.compare_op = .SDL_GPU_COMPAREOP_ALWAYS;
    mesh_create_info.depth_stencil_state.enable_depth_test = true;
    mesh_create_info.depth_stencil_state.enable_depth_write = true;
    
    mesh_create_info.rasterizer_state.cull_mode = .SDL_GPU_CULLMODE_BACK;
    mesh_create_info.rasterizer_state.fill_mode = .SDL_GPU_FILLMODE_FILL;
    mesh_create_info.rasterizer_state.front_face = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE;
    
    buffer_descriptions: [5] SDL_GPUVertexBufferDescription;
    buffer_descriptions[0] = .{0, size_of(Vec3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
    buffer_descriptions[1] = .{1, size_of(Vec2), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
    buffer_descriptions[2] = .{2, size_of(Vec4), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
    buffer_descriptions[3] = .{3, size_of(Vec3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
    buffer_descriptions[4] = .{4, size_of(Bone_Ids), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
    mesh_create_info.vertex_input_state.vertex_buffer_descriptions = buffer_descriptions.data;
    mesh_create_info.vertex_input_state.num_vertex_buffers = 5;
    
    vertex_attributes: [5] SDL_GPUVertexAttribute;
    vertex_attributes[0] = .{0, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
    vertex_attributes[1] = .{1, 1, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, 0};
    vertex_attributes[2] = .{2, 2, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4, 0};
    vertex_attributes[3] = .{3, 3, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
    vertex_attributes[4] = .{4, 4, .SDL_GPU_VERTEXELEMENTFORMAT_SHORT4, 0};
    mesh_create_info.vertex_input_state.vertex_attributes = vertex_attributes.data;
    mesh_create_info.vertex_input_state.num_vertex_attributes = 5;
    
    mesh_create_info.primitive_type = .SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
    mesh_create_info.vertex_shader = shader_mesh.vert;
    mesh_create_info.fragment_shader = shader_mesh.frag;
    
    mesh_pipeline = SDL_CreateGPUGraphicsPipeline(gpu_device, *mesh_create_info);
    
    skinning_create_info: SDL_GPUBufferCreateInfo;
    skinning_create_info.usage = SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ;
    skinning_create_info.size = size_of(Mat4) * MAX_BONES;
    skinning_matrices_buffer = SDL_CreateGPUBuffer(gpu_device, *skinning_create_info);
    SDL_SetGPUBufferName(gpu_device, skinning_matrices_buffer, "skinning_matrices".data);
    
    create_info: SDL_GPUTransferBufferCreateInfo;
    create_info.usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
    create_info.size = size_of(Mat4) * MAX_BONES;
    transfer_buffer := SDL_CreateGPUTransferBuffer(gpu_device, *create_info);
    
    transfer_memory := cast (*Mat4) SDL_MapGPUTransferBuffer(gpu_device, transfer_buffer, false);
    for 0..MAX_BONES-1 {
        transfer_memory[it] = mat4_identity();
    }
    
    SDL_UnmapGPUTransferBuffer(gpu_device, transfer_buffer);
    
    command_buffer := SDL_AcquireGPUCommandBuffer(gpu_device);
    copy_pass := SDL_BeginGPUCopyPass(command_buffer);
    
    location: SDL_GPUTransferBufferLocation;
    location.transfer_buffer = transfer_buffer;
    location.offset = 0;
    
    region: SDL_GPUBufferRegion;
    region.buffer = skinning_matrices_buffer;
    region.offset = 0;
    region.size = size_of(Mat4) * MAX_BONES;
    
    SDL_UploadToGPUBuffer(copy_pass, *location, *region, false);
    
    SDL_EndGPUCopyPass(copy_pass);
    SDL_SubmitGPUCommandBuffer(command_buffer);
    SDL_ReleaseGPUTransferBuffer(gpu_device, transfer_buffer);
    
    sampler_info: SDL_GPUSamplerCreateInfo;
    sampler_info.min_filter = .SDL_GPU_FILTER_LINEAR;
    sampler_info.mag_filter = .SDL_GPU_FILTER_LINEAR;
    sampler_info.mipmap_mode = .SDL_GPU_SAMPLERMIPMAPMODE_LINEAR;
    sampler_info.address_mode_u = .SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
    sampler_info.address_mode_v = .SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
    sampler_info.address_mode_w = .SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
    default_sampler = SDL_CreateGPUSampler(gpu_device, *sampler_info);
}

draw_mesh :: (pass: *SDL_GPURenderPass, mesh: *Mesh) {
    SDL_BindGPUVertexStorageBuffers(pass, 0, *skinning_matrices_buffer, 1);
    
    vertex_buffers: [5] SDL_GPUBufferBinding;
    vertex_buffers[0] = .{mesh.position_buffer, 0};
    vertex_buffers[1] = .{mesh.tex_coord_buffer, 0};
    vertex_buffers[2] = .{mesh.tangent_normal_buffer, 0};
    vertex_buffers[3] = .{mesh.weight_buffer, 0};
    vertex_buffers[4] = .{mesh.bone_ids_buffer, 0};
    SDL_BindGPUVertexBuffers(pass, 0, vertex_buffers.data, 5);
    
    index_buffer := SDL_GPUBufferBinding.{mesh.index_buffer, 0};
    SDL_BindGPUIndexBuffer(pass, *index_buffer, .SDL_GPU_INDEXELEMENTSIZE_32BIT);
    
    SDL_DrawGPUIndexedPrimitives(pass, xx mesh.num_indices, 1, 0, 0, 0);
}

draw_frame :: (camera: *Camera) {
    command_buffer := SDL_AcquireGPUCommandBuffer(gpu_device);
    
    swap_texture: *SDL_GPUTexture;
    SDL_AcquireGPUSwapchainTexture(command_buffer, window, *swap_texture, null, null);
    
    target_info: SDL_GPUColorTargetInfo;
    target_info.texture = swap_texture;
    target_info.clear_color = .{0, 0, 0, 1};
    target_info.load_op = .SDL_GPU_LOADOP_CLEAR;
    target_info.store_op = .SDL_GPU_STOREOP_STORE;
    
    depth_info: SDL_GPUDepthStencilTargetInfo;
    depth_info.texture = depth_texture;
    depth_info.cycle = false;
    depth_info.clear_depth = 0;
    depth_info.clear_stencil = 0;
    depth_info.load_op = .SDL_GPU_LOADOP_CLEAR;
    depth_info.store_op = .SDL_GPU_STOREOP_STORE;
    depth_info.stencil_load_op = .SDL_GPU_LOADOP_DONT_CARE;
    depth_info.stencil_store_op = .SDL_GPU_STOREOP_DONT_CARE;
    
    render_pass := SDL_BeginGPURenderPass(command_buffer, *target_info, 1, *depth_info);
    
    SDL_BindGPUGraphicsPipeline(render_pass, mesh_pipeline);
    
    diffuse_texture := load_texture("textures/cube_diffuse.png").gpu_texture;
    normal_texture := load_texture("textures/cube_normal.png").gpu_texture;
    rmaoh_texture := load_texture("textures/cube_rmaoh.png").gpu_texture;
    
    samplers: [3] SDL_GPUTextureSamplerBinding;
    samplers[0] = .{diffuse_texture, default_sampler};
    samplers[1] = .{normal_texture, default_sampler};
    samplers[2] = .{rmaoh_texture, default_sampler};
    
    SDL_BindGPUFragmentSamplers(render_pass, 0, samplers.data, 3);
    
    mesh := load_mesh("meshes/cube.mesh");
    
    projection := mat4_projection(45.0*PI/180.0, 1366.0/768.0, 0.1, 1000.0);
    
    light_pos := Vec3.{-14.048857, -21.951605, 21.838087};
    look_at_target := Vec3.{0, 0, 0};
    light_dir := normalize(look_at_target - light_pos);
    
    for x: 0..5 {
        for y: 0..5 {
            vert_constant_buffer: CBuffer_Mesh_Vertex;
            vert_constant_buffer.world = mat4_translation(.{x*10.0, -y*10.0, 0});
            vert_constant_buffer.view = camera.view;
            vert_constant_buffer.projection = projection;
            vert_constant_buffer.diffuse_colour = .{1, 1, 1, 1};
            SDL_PushGPUVertexUniformData(command_buffer, 0, *vert_constant_buffer, size_of(CBuffer_Mesh_Vertex));
            
            frag_constant_buffer: CBuffer_Mesh_Fragment;
            frag_constant_buffer.camera_position = camera.position;
            frag_constant_buffer.light_dir = light_dir;
            frag_constant_buffer.light_colour = .{1.0, 1.0, 0.8};
            frag_constant_buffer.material_scale = 1;
            SDL_PushGPUFragmentUniformData(command_buffer, 0, *frag_constant_buffer, size_of(CBuffer_Mesh_Fragment));
            
            draw_mesh(render_pass, mesh);
        }
    }
    
    SDL_EndGPURenderPass(render_pass);
    
    SDL_SubmitGPUCommandBuffer(command_buffer);
}

CBuffer_Mesh_Vertex :: struct {
    world: Mat4;
    view: Mat4;
    projection: Mat4;
    diffuse_colour: Vec4;
}

CBuffer_Mesh_Fragment :: struct {
    camera_position: Vec3;
    light_dir: Vec3;
    light_colour: Vec3;
    material_scale: float;
}

#scope_file

gpu_device: *SDL_GPUDevice;
window: *SDL_Window;