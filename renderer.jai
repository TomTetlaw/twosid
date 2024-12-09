
MAX_BONES :: 1024;

SHADOW_MAP_SIZE :: 4096;

NEAR_PLANE :: 0.1;
FAR_PLANE :: 100.0;

mesh_pipeline: *SDL_GPUGraphicsPipeline;
depth_pipeline: *SDL_GPUGraphicsPipeline;
screen_space_pipeline: *SDL_GPUGraphicsPipeline;
shadow_texture: *SDL_GPUTexture;

skinning_matrices_buffer: *SDL_GPUBuffer;
depth_texture: *SDL_GPUTexture;

default_sampler: *SDL_GPUSampler;
shadow_sampler: *SDL_GPUSampler;

init_renderer :: (device: *SDL_GPUDevice, w: *SDL_Window) {
    gpu_device = device;
    window = w;
    
    // screen space pipeline
    {
        screen_space_create_info: SDL_GPUGraphicsPipelineCreateInfo;
        colour_target_desc: SDL_GPUColorTargetDescription;
        colour_target_desc.format = SDL_GetGPUSwapchainTextureFormat(gpu_device, window);
        screen_space_create_info.target_info.color_target_descriptions = *colour_target_desc;
        screen_space_create_info.target_info.num_color_targets = 1;
        
        screen_space_create_info.rasterizer_state.cull_mode = .SDL_GPU_CULLMODE_BACK;
        screen_space_create_info.rasterizer_state.fill_mode = .SDL_GPU_FILLMODE_FILL;
        screen_space_create_info.rasterizer_state.front_face = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE;
        
        buffer_descriptions: [2] SDL_GPUVertexBufferDescription;
        buffer_descriptions[0] = .{0, size_of(Vec3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        buffer_descriptions[1] = .{1, size_of(Vec2), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        screen_space_create_info.vertex_input_state.vertex_buffer_descriptions = buffer_descriptions.data;
        screen_space_create_info.vertex_input_state.num_vertex_buffers = 2;
        
        vertex_attributes: [2] SDL_GPUVertexAttribute;
        vertex_attributes[0] = .{0, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        vertex_attributes[1] = .{1, 1, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, 0};
        screen_space_create_info.vertex_input_state.vertex_attributes = vertex_attributes.data;
        screen_space_create_info.vertex_input_state.num_vertex_attributes = 2;
        
        screen_space_create_info.primitive_type = .SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
        screen_space_create_info.vertex_shader = shader_screen_space_mesh.vert;
        screen_space_create_info.fragment_shader = shader_screen_space_mesh.frag;
        
        screen_space_pipeline = SDL_CreateGPUGraphicsPipeline(gpu_device, *screen_space_create_info);
    }
    
    // depth pass pipeline
    {
        depth_format := SDL_GPUTextureFormat.SDL_GPU_TEXTUREFORMAT_D24_UNORM;
        
        shadow_info: SDL_GPUTextureCreateInfo;
        shadow_info.type = .SDL_GPU_TEXTURETYPE_2D;
        shadow_info.width = SHADOW_MAP_SIZE;
        shadow_info.height = SHADOW_MAP_SIZE;
        shadow_info.layer_count_or_depth = 1;
        shadow_info.num_levels = 1;
        shadow_info.sample_count = .SDL_GPU_SAMPLECOUNT_1;
        shadow_info.format = depth_format;
        shadow_info.usage = SDL_GPU_TEXTUREUSAGE_SAMPLER | SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET;
        shadow_texture = SDL_CreateGPUTexture(gpu_device, *shadow_info);
        SDL_SetGPUTextureName(gpu_device, shadow_texture, "shadow_texture".data);
        
        depth_create_info: SDL_GPUGraphicsPipelineCreateInfo;
        depth_create_info.target_info.num_color_targets = 0;
        depth_create_info.target_info.has_depth_stencil_target = true;
        depth_create_info.target_info.depth_stencil_format = depth_format;
        
        depth_create_info.depth_stencil_state.compare_op = .SDL_GPU_COMPAREOP_LESS;
        depth_create_info.depth_stencil_state.enable_depth_test = true;
        depth_create_info.depth_stencil_state.enable_depth_write = true;
        depth_create_info.depth_stencil_state.enable_stencil_test = false;
        
        depth_create_info.rasterizer_state.cull_mode = .SDL_GPU_CULLMODE_FRONT;
        depth_create_info.rasterizer_state.fill_mode = .SDL_GPU_FILLMODE_FILL;
        depth_create_info.rasterizer_state.front_face = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE;
        
        buffer_descriptions: [3] SDL_GPUVertexBufferDescription;
        buffer_descriptions[0] = .{0, size_of(Vec3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        buffer_descriptions[1] = .{1, size_of(Vec3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        buffer_descriptions[2] = .{2, size_of(Bone_Ids), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        depth_create_info.vertex_input_state.vertex_buffer_descriptions = buffer_descriptions.data;
        depth_create_info.vertex_input_state.num_vertex_buffers = 3;
        
        vertex_attributes: [3] SDL_GPUVertexAttribute;
        vertex_attributes[0] = .{0, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        vertex_attributes[1] = .{1, 1, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        vertex_attributes[2] = .{2, 2, .SDL_GPU_VERTEXELEMENTFORMAT_SHORT4, 0};
        depth_create_info.vertex_input_state.vertex_attributes = vertex_attributes.data;
        depth_create_info.vertex_input_state.num_vertex_attributes = 3;
        
        depth_create_info.primitive_type = .SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
        depth_create_info.vertex_shader = shader_depth_pass.vert;
        depth_create_info.fragment_shader = shader_depth_pass.frag;
        
        depth_pipeline = SDL_CreateGPUGraphicsPipeline(gpu_device, *depth_create_info);
    }
    
    // mesh pipeline
    {
        depth_info: SDL_GPUTextureCreateInfo;
        depth_info.type = .SDL_GPU_TEXTURETYPE_2D;
        depth_info.width = 1366;
        depth_info.height = 768;
        depth_info.layer_count_or_depth = 1;
        depth_info.num_levels = 1;
        depth_info.sample_count = .SDL_GPU_SAMPLECOUNT_1;
        depth_info.format = .SDL_GPU_TEXTUREFORMAT_D24_UNORM;
        depth_info.usage = SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET;
        depth_texture = SDL_CreateGPUTexture(gpu_device, *depth_info);
        SDL_SetGPUTextureName(gpu_device, depth_texture, "depth_texture".data);
        
        mesh_create_info: SDL_GPUGraphicsPipelineCreateInfo;
        colour_target_desc: SDL_GPUColorTargetDescription;
        colour_target_desc.format = SDL_GetGPUSwapchainTextureFormat(gpu_device, window);
        mesh_create_info.target_info.color_target_descriptions = *colour_target_desc;
        mesh_create_info.target_info.num_color_targets = 1;
        mesh_create_info.target_info.has_depth_stencil_target = true;
        mesh_create_info.target_info.depth_stencil_format = depth_info.format;
        
        mesh_create_info.depth_stencil_state.compare_op = .SDL_GPU_COMPAREOP_LESS;
        mesh_create_info.depth_stencil_state.enable_depth_test = true;
        mesh_create_info.depth_stencil_state.enable_depth_write = true;
        mesh_create_info.depth_stencil_state.enable_stencil_test = false;
        
        mesh_create_info.rasterizer_state.cull_mode = .SDL_GPU_CULLMODE_BACK;
        mesh_create_info.rasterizer_state.fill_mode = .SDL_GPU_FILLMODE_FILL;
        mesh_create_info.rasterizer_state.front_face = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE;
        
        buffer_descriptions: [6] SDL_GPUVertexBufferDescription;
        buffer_descriptions[0] = .{0, size_of(Vec3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        buffer_descriptions[1] = .{1, size_of(Vec2), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        buffer_descriptions[2] = .{2, size_of(Vec3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        buffer_descriptions[3] = .{3, size_of(Vec3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        buffer_descriptions[4] = .{4, size_of(Vec3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        buffer_descriptions[5] = .{5, size_of(Bone_Ids), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        mesh_create_info.vertex_input_state.vertex_buffer_descriptions = buffer_descriptions.data;
        mesh_create_info.vertex_input_state.num_vertex_buffers = 6;
        
        vertex_attributes: [6] SDL_GPUVertexAttribute;
        vertex_attributes[0] = .{0, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        vertex_attributes[1] = .{1, 1, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, 0};
        vertex_attributes[2] = .{2, 2, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        vertex_attributes[3] = .{3, 3, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        vertex_attributes[4] = .{4, 4, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        vertex_attributes[5] = .{5, 5, .SDL_GPU_VERTEXELEMENTFORMAT_SHORT4, 0};
        mesh_create_info.vertex_input_state.vertex_attributes = vertex_attributes.data;
        mesh_create_info.vertex_input_state.num_vertex_attributes = 6;
        
        mesh_create_info.primitive_type = .SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
        mesh_create_info.vertex_shader = shader_mesh.vert;
        mesh_create_info.fragment_shader = shader_mesh.frag;
        
        mesh_pipeline = SDL_CreateGPUGraphicsPipeline(gpu_device, *mesh_create_info);
        
        {
            screen_space_position_buffer = create_vertex_buffer(gpu_device, size_of(Vec3), 4, "screen_space_position_buffer");
            screen_space_tex_coord_buffer = create_vertex_buffer(gpu_device, size_of(Vec2), 4, "screen_space_tex_coord_buffer");
            screen_space_index_buffer = create_index_buffer(gpu_device, 6, "screen_space_index_buffer");
            
            create_info: SDL_GPUTransferBufferCreateInfo;
            create_info.usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
            create_info.size = size_of(float) * 5 * 4 + size_of(u32) * 6;
            transfer_buffer := SDL_CreateGPUTransferBuffer(gpu_device, *create_info);
            transfer_memory := cast (*u8) SDL_MapGPUTransferBuffer(gpu_device, transfer_buffer, false);
            
            {
                memory := cast(*Vec3) transfer_memory;
                memory[0] = .{0, 0, 0};
                memory[1] = .{1366/4, 0, 0};
                memory[2] = .{1366/4, 768/4, 0};
                memory[3] = .{0, 768/4, 0};
            }
            {
                memory := cast(*Vec2) (transfer_memory + size_of(Vec3) * 4);
                memory[0] = .{0, 0};
                memory[1] = .{1, 0};
                memory[2] = .{1, 1};
                memory[3] = .{0, 1};
            }
            {
                memory := cast(*u32) (transfer_memory + size_of(float) * 5 * 4);
                memory[0] = 0;
                memory[1] = 2;
                memory[2] = 1;
                memory[3] = 0;
                memory[4] = 3;
                memory[5] = 2;
            }
            
            SDL_UnmapGPUTransferBuffer(gpu_device, transfer_buffer);
            
            command_buffer := SDL_AcquireGPUCommandBuffer(gpu_device);
            copy_pass := SDL_BeginGPUCopyPass(command_buffer);
            
            location: SDL_GPUTransferBufferLocation;
            location.transfer_buffer = transfer_buffer;
            location.offset = 0;
            
            region: SDL_GPUBufferRegion;
            region.buffer = screen_space_position_buffer;
            region.offset = 0;
            region.size = size_of(Vec3) * 4;
            
            SDL_UploadToGPUBuffer(copy_pass, *location, *region, false);
            
            location.offset = size_of(Vec3) * 4;
            region.buffer = screen_space_tex_coord_buffer;
            region.size = size_of(Vec2) * 4;
            
            SDL_UploadToGPUBuffer(copy_pass, *location, *region, false);
            
            location.offset = size_of(float) * 5 * 4;
            region.buffer = screen_space_index_buffer;
            region.size = size_of(u32) * 6;
            
            SDL_UploadToGPUBuffer(copy_pass, *location, *region, false);
            
            SDL_EndGPUCopyPass(copy_pass);
            SDL_SubmitGPUCommandBuffer(command_buffer);
            SDL_ReleaseGPUTransferBuffer(gpu_device, transfer_buffer);
        }
    }
    
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
    sampler_info.min_lod = 0;
    sampler_info.max_lod = 11;
    sampler_info.min_filter = .SDL_GPU_FILTER_LINEAR;
    sampler_info.mag_filter = .SDL_GPU_FILTER_LINEAR;
    sampler_info.mipmap_mode = .SDL_GPU_SAMPLERMIPMAPMODE_LINEAR;
    sampler_info.address_mode_u = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
    sampler_info.address_mode_v = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
    sampler_info.address_mode_w = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
    default_sampler = SDL_CreateGPUSampler(gpu_device, *sampler_info);
    
    sampler_info.min_lod = 0;
    sampler_info.max_lod = 0;
    sampler_info.min_filter = .SDL_GPU_FILTER_LINEAR;
    sampler_info.mag_filter = .SDL_GPU_FILTER_LINEAR;
    sampler_info.mipmap_mode = .SDL_GPU_SAMPLERMIPMAPMODE_LINEAR;
    sampler_info.address_mode_u = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
    sampler_info.address_mode_v = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
    sampler_info.address_mode_w = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
    shadow_sampler = SDL_CreateGPUSampler(gpu_device, *sampler_info);
}

draw_mesh :: (pass: *SDL_GPURenderPass, mesh: *Mesh, depth_pass: bool) {
    SDL_BindGPUVertexStorageBuffers(pass, 0, *skinning_matrices_buffer, 1);
    
    if depth_pass {
        vertex_buffers: [3] SDL_GPUBufferBinding;
        vertex_buffers[0] = .{mesh.position_buffer, 0};
        vertex_buffers[1] = .{mesh.weight_buffer, 0};
        vertex_buffers[2] = .{mesh.bone_ids_buffer, 0};
        SDL_BindGPUVertexBuffers(pass, 0, vertex_buffers.data, 3);
    } else {
        vertex_buffers: [6] SDL_GPUBufferBinding;
        vertex_buffers[0] = .{mesh.position_buffer, 0};
        vertex_buffers[1] = .{mesh.tex_coord_buffer, 0};
        vertex_buffers[2] = .{mesh.normal_buffer, 0};
        vertex_buffers[3] = .{mesh.tangent_buffer, 0};
        vertex_buffers[4] = .{mesh.weight_buffer, 0};
        vertex_buffers[5] = .{mesh.bone_ids_buffer, 0};
        SDL_BindGPUVertexBuffers(pass, 0, vertex_buffers.data, 6);
    }
    
    index_buffer := SDL_GPUBufferBinding.{mesh.index_buffer, 0};
    SDL_BindGPUIndexBuffer(pass, *index_buffer, .SDL_GPU_INDEXELEMENTSIZE_32BIT);
    
    SDL_DrawGPUIndexedPrimitives(pass, xx mesh.num_indices, 1, 0, 0, 0);
}

calc_light_space_matrix :: (light_pos: Vec3, light_dir: Vec3, proj: Mat4, view: Mat4) -> Mat4 {
    inverse := mat4_inverse(proj * view);
    
    corners: [8] Vec4;
    corners[0] = inverse * .{-1, -1, -1, 1};
    corners[1] = inverse * .{-1, -1,  1, 1};
    corners[2] = inverse * .{-1,  1, -1, 1};
    corners[3] = inverse * .{-1,  1,  1, 1};
    corners[4] = inverse * .{ 1, -1, -1, 1};
    corners[5] = inverse * .{ 1, -1,  1, 1};
    corners[6] = inverse * .{ 1,  1, -1, 1};
    corners[7] = inverse * .{ 1,  1,  1, 1};
    
    for * corners {
        it.* /= it.w; 
    }
    
    center: Vec3;
    for corners {
        center += it.xyz;
    }
    center /= 8;
    
    dir := Vec3.{-light_dir.y, light_dir.z, light_dir.x};
    light_view := mat4_look_at(center + light_dir, center);
    
    right, top, far := FLOAT32_MIN;
    left, bottom, near := FLOAT32_MAX;
    
    for corners {
        corner := (light_view * it).xyz;
        
        left = min(left, corner.x);
        right = max(right, corner.x);
        bottom = min(bottom, corner.y);
        top = max(top, corner.y);
        near = min(near, corner.z);
        far = max(far, corner.z);
    }
    
    half_width := (right - left) / 2;
    half_height := (top - bottom) / 2;
    radius := sqrt(half_width * half_width + half_height * half_height);
    
    center_x := (left + right) / 2;
    center_y := (bottom + top) / 2;
    
    side_length := radius * sqrt(2);
    left = center_x - side_length / 2;
    right = center_x + side_length / 2;
    bottom = center_y - side_length / 2;
    top = center_y + side_length / 2;
    
    z_pad := .5;
    if near < 0 near *= z_pad;
    else near /= z_pad;
    if far < 0 far *= z_pad;
    else far /= z_pad;
    
    light_proj := mat4_ortho(left, right, bottom, top, near, far);
    
    return light_proj * light_view;
}

draw_frame :: (camera: *Camera) {
    command_buffer := SDL_AcquireGPUCommandBuffer(gpu_device);
    
    projection := mat4_projection(45.0 * deg2rad, 1366.0 / 768.0, NEAR_PLANE, FAR_PLANE);
    
    light_pos := Vec3.{0, 0, 10};
    light_target := Vec3.{1, -1, 1};
    light_dir := normalize(light_target - light_pos);
    
    light_colour := Vec3.{1.0, 1.0, 0.8};
    light_matrix := calc_light_space_matrix(light_pos, light_dir, projection, camera.view);
    
    // depth pass
    {
        depth_info: SDL_GPUDepthStencilTargetInfo;
        depth_info.texture = shadow_texture;
        depth_info.cycle = false;
        depth_info.clear_depth = 1;
        depth_info.clear_stencil = 0;
        depth_info.load_op = .SDL_GPU_LOADOP_CLEAR;
        depth_info.store_op = .SDL_GPU_STOREOP_STORE;
        depth_info.stencil_load_op = .SDL_GPU_LOADOP_DONT_CARE;
        depth_info.stencil_store_op = .SDL_GPU_STOREOP_DONT_CARE;
        
        render_pass := SDL_BeginGPURenderPass(command_buffer, null, 0, *depth_info);
        
        viewport: SDL_GPUViewport;
        viewport.x = 0;
        viewport.y = 0;
        viewport.w = SHADOW_MAP_SIZE;
        viewport.h = SHADOW_MAP_SIZE;
        viewport.min_depth = 0.0;
        viewport.max_depth = 1.0;
        SDL_SetGPUViewport(render_pass, *viewport);
        
        SDL_BindGPUGraphicsPipeline(render_pass, depth_pipeline);
        
        mesh := load_mesh("meshes/cube.mesh");
        mesh2 := load_mesh("meshes/plane.mesh");
        
        for x: -3..3 {
            for y: -3..3 {
                for z: -3..3 {
                    vert_constant_buffer: CBuffer_Shadow_Vertex;
                    vert_constant_buffer.world = mat4_translation(.{x*10.0, y*10.0, z*10.0});
                    vert_constant_buffer.light_matrix = light_matrix;
                    
                    SDL_PushGPUVertexUniformData(command_buffer, 0, *vert_constant_buffer, size_of(CBuffer_Shadow_Vertex));
                    
                    draw_mesh(render_pass, mesh, true);
                }
            }
        }
        
        {
            vert_constant_buffer: CBuffer_Shadow_Vertex;
            vert_constant_buffer.world = mat4_translation(.{0, 0, -1});
            vert_constant_buffer.light_matrix = light_matrix;
            
            SDL_PushGPUVertexUniformData(command_buffer, 0, *vert_constant_buffer, size_of(CBuffer_Shadow_Vertex));
            
            //draw_mesh(render_pass, mesh2, true);
        }
        
        SDL_EndGPURenderPass(render_pass);
    }
    
    swap_texture: *SDL_GPUTexture;
    SDL_AcquireGPUSwapchainTexture(command_buffer, window, *swap_texture, null, null);
    
    // mesh pass
    {
        target_info: SDL_GPUColorTargetInfo;
        target_info.texture = swap_texture;
        target_info.clear_color = .{0, 0, 0, 1};
        target_info.load_op = .SDL_GPU_LOADOP_CLEAR;
        target_info.store_op = .SDL_GPU_STOREOP_STORE;
        
        depth_info: SDL_GPUDepthStencilTargetInfo;
        depth_info.texture = depth_texture;
        depth_info.cycle = false;
        depth_info.clear_depth = 1;
        depth_info.clear_stencil = 0;
        depth_info.load_op = .SDL_GPU_LOADOP_CLEAR;
        depth_info.store_op = .SDL_GPU_STOREOP_DONT_CARE;
        depth_info.stencil_load_op = .SDL_GPU_LOADOP_DONT_CARE;
        depth_info.stencil_store_op = .SDL_GPU_STOREOP_DONT_CARE;
        
        render_pass := SDL_BeginGPURenderPass(command_buffer, *target_info, 1, *depth_info);
        
        SDL_BindGPUGraphicsPipeline(render_pass, mesh_pipeline);
        
        mesh := load_mesh("meshes/cube.mesh");
        mesh2 := load_mesh("meshes/plane.mesh");
        
        diffuse_texture := load_texture("textures/unit_diffuse.png").gpu_texture;
        normal_texture := load_texture("textures/unit_normal.png").gpu_texture;
        rmaoh_texture := load_texture("textures/unit_rmaoh.png").gpu_texture;
        
        samplers: [4] SDL_GPUTextureSamplerBinding;
        samplers[0] = .{shadow_texture, shadow_sampler};
        
        samplers[1] = .{diffuse_texture, default_sampler};
        samplers[2] = .{normal_texture, default_sampler};
        samplers[3] = .{rmaoh_texture, default_sampler};
        
        SDL_BindGPUFragmentSamplers(render_pass, 0, samplers.data, 4);
        
        for x: -3..3 {
            for y: -3..3 {
                for z: -3..3 {
                    vert_constant_buffer: CBuffer_Mesh_Vertex;
                    vert_constant_buffer.world = mat4_translation(.{x*10.0, y*10.0, z*10.0});
                    vert_constant_buffer.view = camera.view;
                    vert_constant_buffer.projection = projection;
                    vert_constant_buffer.camera_position = camera.position;
                    vert_constant_buffer.diffuse_colour = .{1, 1, 1};
                    vert_constant_buffer.light_dir = light_dir;
                    
                    frag_constant_buffer: CBuffer_Mesh_Fragment;
                    frag_constant_buffer.light_colour = light_colour;
                    frag_constant_buffer.material_params = .{1, 1, 1, 1};
                    frag_constant_buffer.light_matrix = light_matrix;
                    frag_constant_buffer.frag_debug_mode = frag_debug_mode;
                    
                    SDL_PushGPUVertexUniformData(command_buffer, 0, *vert_constant_buffer, size_of(CBuffer_Mesh_Vertex));
                    SDL_PushGPUFragmentUniformData(command_buffer, 0, *frag_constant_buffer, size_of(CBuffer_Mesh_Fragment));
                    
                    draw_mesh(render_pass, mesh, false);
                }
            }
        }
        
        diffuse_texture = load_texture("textures/floor_diffuse.png").gpu_texture;
        normal_texture = load_texture("textures/floor_normal.png").gpu_texture;
        rmaoh_texture = load_texture("textures/floor_rmaoh.png").gpu_texture;
        
        samplers[1] = .{diffuse_texture, default_sampler};
        samplers[2] = .{normal_texture, default_sampler};
        samplers[3] = .{rmaoh_texture, default_sampler};
        
        SDL_BindGPUFragmentSamplers(render_pass, 0, samplers.data, 4);
        
        if key_pressed(.SDL_SCANCODE_LEFT) {
            frag_debug_mode -= 1;
            frag_debug_mode = clamp(frag_debug_mode, 0, MAX_FRAG_DEBUG_MODE);
        }
        
        if key_pressed(.SDL_SCANCODE_RIGHT) {
            frag_debug_mode += 1;
            frag_debug_mode = clamp(frag_debug_mode, 0, MAX_FRAG_DEBUG_MODE);
        }
        
        {
            vert_constant_buffer: CBuffer_Mesh_Vertex;
            vert_constant_buffer.world = mat4_translation(.{0, 0, -1});
            vert_constant_buffer.view = camera.view;
            vert_constant_buffer.projection = projection;
            vert_constant_buffer.camera_position = camera.position;
            vert_constant_buffer.diffuse_colour = .{1, 1, 1};
            vert_constant_buffer.light_dir = light_dir;
            
            frag_constant_buffer: CBuffer_Mesh_Fragment;
            frag_constant_buffer.light_colour = light_colour;
            frag_constant_buffer.material_params = .{1, 1, 1, 8};
            frag_constant_buffer.light_matrix = light_matrix;
            frag_constant_buffer.frag_debug_mode = frag_debug_mode;
            
            SDL_PushGPUVertexUniformData(command_buffer, 0, *vert_constant_buffer, size_of(CBuffer_Mesh_Vertex));
            SDL_PushGPUFragmentUniformData(command_buffer, 0, *frag_constant_buffer, size_of(CBuffer_Mesh_Fragment));
            
            draw_mesh(render_pass, mesh2, false);
        }
        
        SDL_EndGPURenderPass(render_pass);
    }
    
    if frag_debug_mode == 1 {
        target_info: SDL_GPUColorTargetInfo;
        target_info.texture = swap_texture;
        target_info.clear_color = .{0, 0, 0, 1};
        target_info.load_op = .SDL_GPU_LOADOP_LOAD;
        target_info.store_op = .SDL_GPU_STOREOP_STORE;
        
        render_pass := SDL_BeginGPURenderPass(command_buffer, *target_info, 1, null);
        
        SDL_BindGPUGraphicsPipeline(render_pass, screen_space_pipeline);
        
        {
            vert_constant_buffer: CBuffer_ScreenSpaceMesh_Vertex;
            vert_constant_buffer.projection = mat4_ortho(0, 1366, 768, 0, -999.0, 999.0);
            
            SDL_PushGPUVertexUniformData(command_buffer, 0, *vert_constant_buffer, size_of(CBuffer_ScreenSpaceMesh_Vertex));
            
            vertex_buffers: [2] SDL_GPUBufferBinding;
            vertex_buffers[0] = .{screen_space_position_buffer, 0};
            vertex_buffers[1] = .{screen_space_tex_coord_buffer, 0};
            SDL_BindGPUVertexBuffers(render_pass, 0, vertex_buffers.data, 2);
            
            index_buffer := SDL_GPUBufferBinding.{screen_space_index_buffer, 0};
            SDL_BindGPUIndexBuffer(render_pass, *index_buffer, .SDL_GPU_INDEXELEMENTSIZE_32BIT);
            
            samplers: [1] SDL_GPUTextureSamplerBinding;
            samplers[0] = .{shadow_texture, shadow_sampler};
            SDL_BindGPUFragmentSamplers(render_pass, 0, samplers.data, 1);
            
            SDL_DrawGPUIndexedPrimitives(render_pass, 6, 1, 0, 0, 0);
        }
        
        SDL_EndGPURenderPass(render_pass);
    }
    
    SDL_SubmitGPUCommandBuffer(command_buffer);
}

MAX_FRAG_DEBUG_MODE :: 1;
frag_debug_mode: s32;

CBuffer_Shadow_Vertex :: struct {
    world: Mat4;
    light_matrix: Mat4;
}

CBuffer_Mesh_Vertex :: struct {
    world: Mat4;
    view: Mat4;
    projection: Mat4;
    camera_position: Vec3;
    pad0: float;
    diffuse_colour: Vec3;
    pad1: float;
    light_dir: Vec3;
    pad2: float;
}

CBuffer_Mesh_Fragment :: struct {
    light_colour: Vec3;
    pad2: float;
    material_params: Vec4;
    depth_planes: Vec3;
    pad4: float;
    light_matrix: Mat4;
    frag_debug_mode: s32;
    pad5: Vec3;
}

screen_space_position_buffer: *SDL_GPUBuffer;
screen_space_tex_coord_buffer: *SDL_GPUBuffer;
screen_space_index_buffer: *SDL_GPUBuffer;

CBuffer_ScreenSpaceMesh_Vertex :: struct {
    projection: Mat4;
}

#scope_file

gpu_device: *SDL_GPUDevice;
window: *SDL_Window;