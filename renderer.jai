
MAX_BONES :: 1024;

SHADOW_MAP_SIZE :: 1024;

NEAR_PLANE :: 0.1;
FAR_PLANE :: 100.0;

mesh_pipeline: *SDL_GPUGraphicsPipeline;
depth_pipeline: *SDL_GPUGraphicsPipeline;
shadow_textures: [3] *SDL_GPUTexture;

skinning_matrices_buffer: *SDL_GPUBuffer;
depth_texture: *SDL_GPUTexture;

default_sampler: *SDL_GPUSampler;
shadow_sampler: *SDL_GPUSampler;

init_renderer :: (device: *SDL_GPUDevice, w: *SDL_Window) {
    gpu_device = device;
    window = w;
    
    // depth pass pipeline
    {
        depth_format: SDL_GPUTextureFormat;
        depth_type := SDL_GPUTextureType.SDL_GPU_TEXTURETYPE_2D;
        depth_target := SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET;
        if SDL_GPUTextureSupportsFormat(gpu_device, .SDL_GPU_TEXTUREFORMAT_D24_UNORM, depth_type, xx depth_target) {
            depth_format = .SDL_GPU_TEXTUREFORMAT_D24_UNORM;
        } else if SDL_GPUTextureSupportsFormat(gpu_device, .SDL_GPU_TEXTUREFORMAT_D32_FLOAT, depth_type, xx depth_target) {
            depth_format = .SDL_GPU_TEXTUREFORMAT_D32_FLOAT;
        } else {
            fatal_error("Couldn't find a depth target format");
        }
        
        shadow_info: SDL_GPUTextureCreateInfo;
        shadow_info.type = .SDL_GPU_TEXTURETYPE_2D;
        shadow_info.width = SHADOW_MAP_SIZE;
        shadow_info.height = SHADOW_MAP_SIZE;
        shadow_info.layer_count_or_depth = 1;
        shadow_info.num_levels = 1;
        shadow_info.sample_count = .SDL_GPU_SAMPLECOUNT_1;
        shadow_info.format = depth_format;
        shadow_info.usage = SDL_GPU_TEXTUREUSAGE_SAMPLER | SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET;
        for 0..2 {
            shadow_textures[it] = SDL_CreateGPUTexture(gpu_device, *shadow_info);
            SDL_SetGPUTextureName(gpu_device, shadow_textures[it], tprint("shadow_texture_%", it).data);
        }
        
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
        
        buffer_descriptions: [5] SDL_GPUVertexBufferDescription;
        buffer_descriptions[0] = .{0, size_of(Vec3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        buffer_descriptions[1] = .{1, size_of(Vec2), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        buffer_descriptions[2] = .{2, size_of(Vec3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        buffer_descriptions[3] = .{3, size_of(Vec3), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        buffer_descriptions[4] = .{4, size_of(Bone_Ids), .SDL_GPU_VERTEXINPUTRATE_VERTEX, 0};
        mesh_create_info.vertex_input_state.vertex_buffer_descriptions = buffer_descriptions.data;
        mesh_create_info.vertex_input_state.num_vertex_buffers = 5;
        
        vertex_attributes: [5] SDL_GPUVertexAttribute;
        vertex_attributes[0] = .{0, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        vertex_attributes[1] = .{1, 1, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, 0};
        vertex_attributes[2] = .{2, 2, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        vertex_attributes[3] = .{3, 3, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0};
        vertex_attributes[4] = .{4, 4, .SDL_GPU_VERTEXELEMENTFORMAT_SHORT4, 0};
        mesh_create_info.vertex_input_state.vertex_attributes = vertex_attributes.data;
        mesh_create_info.vertex_input_state.num_vertex_attributes = 5;
        
        mesh_create_info.primitive_type = .SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
        mesh_create_info.vertex_shader = shader_mesh.vert;
        mesh_create_info.fragment_shader = shader_mesh.frag;
        
        mesh_pipeline = SDL_CreateGPUGraphicsPipeline(gpu_device, *mesh_create_info);
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
    sampler_info.max_lod = 9;
    sampler_info.min_filter = .SDL_GPU_FILTER_LINEAR;
    sampler_info.mag_filter = .SDL_GPU_FILTER_LINEAR;
    sampler_info.mipmap_mode = .SDL_GPU_SAMPLERMIPMAPMODE_LINEAR;
    sampler_info.address_mode_u = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
    sampler_info.address_mode_v = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
    sampler_info.address_mode_w = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
    default_sampler = SDL_CreateGPUSampler(gpu_device, *sampler_info);
    
    sampler_info.min_lod = 0;
    sampler_info.max_lod = 0;
    sampler_info.min_filter = .SDL_GPU_FILTER_NEAREST;
    sampler_info.mag_filter = .SDL_GPU_FILTER_NEAREST;
    sampler_info.mipmap_mode = .SDL_GPU_SAMPLERMIPMAPMODE_NEAREST;
    sampler_info.address_mode_u = .SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
    sampler_info.address_mode_v = .SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
    sampler_info.address_mode_w = .SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
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
        vertex_buffers: [5] SDL_GPUBufferBinding;
        vertex_buffers[0] = .{mesh.position_buffer, 0};
        vertex_buffers[1] = .{mesh.tex_coord_buffer, 0};
        vertex_buffers[2] = .{mesh.normal_buffer, 0};
        vertex_buffers[3] = .{mesh.weight_buffer, 0};
        vertex_buffers[4] = .{mesh.bone_ids_buffer, 0};
        SDL_BindGPUVertexBuffers(pass, 0, vertex_buffers.data, 5);
    }
    
    index_buffer := SDL_GPUBufferBinding.{mesh.index_buffer, 0};
    SDL_BindGPUIndexBuffer(pass, *index_buffer, .SDL_GPU_INDEXELEMENTSIZE_32BIT);
    
    SDL_DrawGPUIndexedPrimitives(pass, xx mesh.num_indices, 1, 0, 0, 0);
}

calc_projection_corners :: (proj: Mat4, view: Mat4) -> [] Vec4 {
    inverse := mat4_inverse(proj * view);
    
    points := arena_push_n(*frame_arena, Vec4, 8);
    points[0] = inverse * Vec4.{-1.0,  1.0, -1.0, 1.0};
    points[1] = inverse * Vec4.{-1.0,  1.0,  1.0, 1.0};
    points[2] = inverse * Vec4.{-1.0, -1.0, -1.0, 1.0};
    points[3] = inverse * Vec4.{-1.0, -1.0,  1.0, 1.0};
    points[4] = inverse * Vec4.{ 1.0,  1.0, -1.0, 1.0};
    points[5] = inverse * Vec4.{ 1.0,  1.0,  1.0, 1.0};
    points[6] = inverse * Vec4.{ 1.0, -1.0, -1.0, 1.0};
    points[7] = inverse * Vec4.{ 1.0, -1.0,  1.0, 1.0};
    
    for * points {
        it.* = <<it / it.w;
    }
    
    return points;
}

calc_light_space_matrix :: (light_pos: Vec3, light_dir: Vec3, proj: Mat4, view: Mat4) -> Mat4 {
    corners := calc_projection_corners(proj, view);
    center: Vec3;
    for corners center += it.xyz;
    
    i := 1.0 / corners.count;
    center *= i;
    
    light_view := mat4_look_at(center + light_dir, center);
    
    scene_min_bounds := Vec3.{FLOAT32_MAX, FLOAT32_MAX, FLOAT32_MAX};
    scene_max_bounds := Vec3.{FLOAT32_MIN, FLOAT32_MIN, FLOAT32_MIN};
    
    for corners {
        corner_light_space := (light_view * it).xyz;
        scene_min_bounds = min(scene_min_bounds, corner_light_space);
        scene_max_bounds = max(scene_max_bounds, corner_light_space);
    }
    
    x_pad := 100.0;
    if scene_min_bounds.x < 0 scene_min_bounds.x *= x_pad;
    else scene_min_bounds.x /= x_pad;
    
    if scene_max_bounds.x < 0 scene_max_bounds.x /= x_pad;
    else scene_max_bounds.x *= x_pad;
    
    light_proj := mat4_ortho(scene_max_bounds.y, scene_min_bounds.y, scene_min_bounds.z, scene_max_bounds.z, scene_max_bounds.x, scene_min_bounds.x);
    
    return light_proj * light_view;
}

draw_frame :: (camera: *Camera) {
    command_buffer := SDL_AcquireGPUCommandBuffer(gpu_device);
    
    light_matrices: [3] Mat4;
    
    depth_segment := FAR_PLANE / 3.0;
    depth_planes: [4] float;
    depth_planes[0] = NEAR_PLANE;
    depth_planes[1] = NEAR_PLANE + (FAR_PLANE - NEAR_PLANE) * 0.1;
    depth_planes[2] = NEAR_PLANE + (FAR_PLANE - NEAR_PLANE) * 0.4;
    depth_planes[3] = NEAR_PLANE + (FAR_PLANE - NEAR_PLANE) * 1.0;
    
    light_pos := Vec3.{-14.048857, -21.951605, 21.838087};
    light_dir := normalize(-light_pos);
    
    // depth pass
    {
        for 0..2 {
            near := depth_planes[it];
            far := depth_planes[it + 1];
            
            projection := mat4_projection(59.0 * deg2rad, 1366.0 / 768.0, near, far);
            
            light_matrices[it] = calc_light_space_matrix(light_pos, light_dir, projection, camera.view);
            
            depth_info: SDL_GPUDepthStencilTargetInfo;
            depth_info.texture = shadow_textures[it];
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
            
            for x: -5..5 {
                for y: -5..5 {
                    vert_constant_buffer: CBuffer_Shadow_Vertex;
                    vert_constant_buffer.world = mat4_translation(.{x*10.0, -y*10.0, 7});
                    vert_constant_buffer.light_matrix = light_matrices[it];
                    
                    SDL_PushGPUVertexUniformData(command_buffer, 0, *vert_constant_buffer, size_of(CBuffer_Shadow_Vertex));
                    
                    draw_mesh(render_pass, mesh, true);
                }
            }
            
            {
                vert_constant_buffer: CBuffer_Shadow_Vertex;
                vert_constant_buffer.world = mat4_identity();
                vert_constant_buffer.light_matrix = light_matrices[it];
                
                SDL_PushGPUVertexUniformData(command_buffer, 0, *vert_constant_buffer, size_of(CBuffer_Shadow_Vertex));
                
                draw_mesh(render_pass, mesh2, true);
            }
            
            SDL_EndGPURenderPass(render_pass);
        }
    }
    
    // mesh pass
    {
        projection := mat4_projection(59.0 * deg2rad, 1366.0 / 768.0, NEAR_PLANE, FAR_PLANE);
        
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
        
        samplers: [6] SDL_GPUTextureSamplerBinding;
        samplers[0] = .{shadow_textures[0], shadow_sampler};
        samplers[1] = .{shadow_textures[1], shadow_sampler};
        samplers[2] = .{shadow_textures[2], shadow_sampler};
        
        samplers[3] = .{diffuse_texture, default_sampler};
        samplers[4] = .{normal_texture, default_sampler};
        samplers[5] = .{rmaoh_texture, default_sampler};
        
        SDL_BindGPUFragmentSamplers(render_pass, 0, samplers.data, 6);
        
        for x: -3..3 {
            for y: -3..3 {
                for z: -3..3 {
                    vert_constant_buffer: CBuffer_Mesh_Vertex;
                    vert_constant_buffer.world = mat4_translation(.{xx (x*10), xx (-y*10), xx (z*10)});
                    vert_constant_buffer.view = camera.view;
                    vert_constant_buffer.projection = projection;
                    vert_constant_buffer.light_matrix0 = light_matrices[0];
                    vert_constant_buffer.light_matrix1 = light_matrices[1];
                    vert_constant_buffer.light_matrix2 = light_matrices[2];
                    vert_constant_buffer.diffuse_colour = .{1, 1, 1};
                    
                    frag_constant_buffer: CBuffer_Mesh_Fragment;
                    frag_constant_buffer.camera_position = camera.position;
                    frag_constant_buffer.light_dir = light_dir;
                    frag_constant_buffer.light_colour = .{1.0, 1.0, 0.8};
                    frag_constant_buffer.material_params = .{1, 0, 0};
                    frag_constant_buffer.depth_planes = .{depth_planes[1], depth_planes[2], depth_planes[3]};
                    
                    SDL_PushGPUVertexUniformData(command_buffer, 0, *vert_constant_buffer, size_of(CBuffer_Mesh_Vertex));
                    SDL_PushGPUFragmentUniformData(command_buffer, 0, *frag_constant_buffer, size_of(CBuffer_Mesh_Fragment));
                    
                    draw_mesh(render_pass, mesh, false);
                }
            }
        }
        
        diffuse_texture = load_texture("textures/floor_diffuse.png").gpu_texture;
        normal_texture = load_texture("textures/floor_normal.png").gpu_texture;
        rmaoh_texture = load_texture("textures/floor_rmaoh.png").gpu_texture;
        
        samplers[3] = .{diffuse_texture, default_sampler};
        samplers[4] = .{normal_texture, default_sampler};
        samplers[5] = .{rmaoh_texture, default_sampler};
        
        SDL_BindGPUFragmentSamplers(render_pass, 0, samplers.data, 6);
        
        {
            vert_constant_buffer: CBuffer_Mesh_Vertex;
            vert_constant_buffer.world = mat4_translation(.{0, 0, -1});
            vert_constant_buffer.view = camera.view;
            vert_constant_buffer.projection = projection;
            vert_constant_buffer.light_matrix0 = light_matrices[0];
            vert_constant_buffer.light_matrix1 = light_matrices[1];
            vert_constant_buffer.light_matrix2 = light_matrices[2];
            vert_constant_buffer.diffuse_colour = .{1, 1, 1};
            
            frag_constant_buffer: CBuffer_Mesh_Fragment;
            frag_constant_buffer.camera_position = camera.position;
            frag_constant_buffer.light_dir = light_dir;
            frag_constant_buffer.light_colour = .{1.0, 1.0, 0.8};
            frag_constant_buffer.material_params = .{3, 0, 0};
            frag_constant_buffer.depth_planes = .{depth_planes[1], depth_planes[2], depth_planes[3]};
            
            SDL_PushGPUVertexUniformData(command_buffer, 0, *vert_constant_buffer, size_of(CBuffer_Mesh_Vertex));
            SDL_PushGPUFragmentUniformData(command_buffer, 0, *frag_constant_buffer, size_of(CBuffer_Mesh_Fragment));
            
            draw_mesh(render_pass, mesh2, false);
        }
        
        SDL_EndGPURenderPass(render_pass);
    }
    
    SDL_SubmitGPUCommandBuffer(command_buffer);
}

CBuffer_Shadow_Vertex :: struct {
    world: Mat4;
    light_matrix: Mat4;
}

CBuffer_Mesh_Vertex :: struct {
    world: Mat4;
    view: Mat4;
    projection: Mat4;
    light_matrix0: Mat4;
    light_matrix1: Mat4;
    light_matrix2: Mat4;
    diffuse_colour: Vec3;
    pad0: float;
}

CBuffer_Mesh_Fragment :: struct {
    camera_position: Vec3;
    pad0: float;
    light_dir: Vec3;
    pad1: float;
    light_colour: Vec3;
    pad2: float;
    material_params: Vec3;
    pad3: float;
    depth_planes: Vec3;
    pad4: float;
}

#scope_file

gpu_device: *SDL_GPUDevice;
window: *SDL_Window;