
init_renderer :: () {
    // screen space pipeline
    {
        screen_space_create_info: SDL_GPUGraphicsPipelineCreateInfo;
        colour_target_desc: SDL_GPUColorTargetDescription;
        colour_target_desc.format = SDL_GetGPUSwapchainTextureFormat(g_device, g_window);
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
        
        screen_space_pipeline = SDL_CreateGPUGraphicsPipeline(g_device, *screen_space_create_info);
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
        shadow_texture = SDL_CreateGPUTexture(g_device, *shadow_info);
        SDL_SetGPUTextureName(g_device, shadow_texture, "shadow_texture".data);
        
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
        
        depth_pipeline = SDL_CreateGPUGraphicsPipeline(g_device, *depth_create_info);
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
        depth_texture = SDL_CreateGPUTexture(g_device, *depth_info);
        SDL_SetGPUTextureName(g_device, depth_texture, "depth_texture".data);
        
        mesh_create_info: SDL_GPUGraphicsPipelineCreateInfo;
        colour_target_desc: SDL_GPUColorTargetDescription;
        colour_target_desc.format = SDL_GetGPUSwapchainTextureFormat(g_device, g_window);
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
        
        buffer_descriptions: [7] SDL_GPUVertexBufferDescription;
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
        
        mesh_pipeline = SDL_CreateGPUGraphicsPipeline(g_device, *mesh_create_info);
        
        {
            arena_push_mark_defer(*working_arena);
            instances := arena_push_n(*working_arena, IBuffer_Mesh, 343);
            
            i := 0;
            for x: -3..3 {
                for y: -3..3 {
                    for z: -3..3 {
                        instance := *instances[i];
                        instance.transform = mat4_translation(.{xx (x*10), xx (y*10), xx (z*10)});
                        instance.diffuse_colour = .{1, 1, 1};
                        instance.material_params = Vec4.{1, 1, 1, 1};
                        i += 1;
                    }
                }
            }
            
            cubes_instance_buffer = create_instance_buffer(g_device, "cubes_instance_buffer", instances); 
        }
        
        {
            arena_push_mark_defer(*working_arena);
            instances := arena_push_n(*working_arena, IBuffer_Mesh, 1);
            
            instances[0].transform = mat4_translation(.{0, 0, -1});
            instances[0].diffuse_colour = .{1, 1, 1};
            instances[0].material_params = .{1, 1, 1, 8};
            
            plane_instance_buffer = create_instance_buffer(g_device, "plane_instance_buffer", instances);
        }
    }
    
    {
        screen_space_position_buffer = create_vertex_buffer(g_device, "screen_space_position_buffer", size_of(Vec3), 4);
        screen_space_tex_coord_buffer = create_vertex_buffer(g_device, "screen_space_tex_coord_buffer", size_of(Vec2), 4);
        screen_space_index_buffer = create_index_buffer(g_device, "screen_space_index_buffer", 6);
        
        create_info: SDL_GPUTransferBufferCreateInfo;
        create_info.usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
        create_info.size = size_of(float) * 5 * 4 + size_of(u32) * 6;
        transfer_buffer := SDL_CreateGPUTransferBuffer(g_device, *create_info);
        transfer_memory := cast (*u8) SDL_MapGPUTransferBuffer(g_device, transfer_buffer, false);
        
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
        
        SDL_UnmapGPUTransferBuffer(g_device, transfer_buffer);
        
        command_buffer := SDL_AcquireGPUCommandBuffer(g_device);
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
        SDL_ReleaseGPUTransferBuffer(g_device, transfer_buffer);
    }
    
    skinning_create_info: SDL_GPUBufferCreateInfo;
    skinning_create_info.usage = SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ;
    skinning_create_info.size = size_of(Mat4) * MAX_BONES;
    skinning_matrices_buffer = SDL_CreateGPUBuffer(g_device, *skinning_create_info);
    SDL_SetGPUBufferName(g_device, skinning_matrices_buffer, "skinning_matrices".data);
    
    create_info: SDL_GPUTransferBufferCreateInfo;
    create_info.usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
    create_info.size = size_of(Mat4) * MAX_BONES;
    transfer_buffer := SDL_CreateGPUTransferBuffer(g_device, *create_info);
    
    transfer_memory := cast (*Mat4) SDL_MapGPUTransferBuffer(g_device, transfer_buffer, false);
    for 0..MAX_BONES-1 {
        transfer_memory[it] = mat4_identity();
    }
    
    SDL_UnmapGPUTransferBuffer(g_device, transfer_buffer);
    
    command_buffer := SDL_AcquireGPUCommandBuffer(g_device);
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
    SDL_ReleaseGPUTransferBuffer(g_device, transfer_buffer);
    
    sampler_info: SDL_GPUSamplerCreateInfo;
    sampler_info.min_lod = 0;
    sampler_info.max_lod = 11;
    sampler_info.min_filter = .SDL_GPU_FILTER_LINEAR;
    sampler_info.mag_filter = .SDL_GPU_FILTER_LINEAR;
    sampler_info.mipmap_mode = .SDL_GPU_SAMPLERMIPMAPMODE_LINEAR;
    sampler_info.address_mode_u = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
    sampler_info.address_mode_v = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
    sampler_info.address_mode_w = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
    default_sampler = SDL_CreateGPUSampler(g_device, *sampler_info);
    
    sampler_info.min_lod = 0;
    sampler_info.max_lod = 0;
    sampler_info.min_filter = .SDL_GPU_FILTER_NEAREST;
    sampler_info.mag_filter = .SDL_GPU_FILTER_NEAREST;
    sampler_info.mipmap_mode = .SDL_GPU_SAMPLERMIPMAPMODE_NEAREST;
    sampler_info.address_mode_u = .SDL_GPU_SAMPLERADDRESSMODE_MIRRORED_REPEAT;
    sampler_info.address_mode_v = .SDL_GPU_SAMPLERADDRESSMODE_MIRRORED_REPEAT;
    sampler_info.address_mode_w = .SDL_GPU_SAMPLERADDRESSMODE_MIRRORED_REPEAT;
    shadow_sampler = SDL_CreateGPUSampler(g_device, *sampler_info);
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
    
    z_pad := .5;
    if near < 0 near *= z_pad;
    else near /= z_pad;
    if far < 0 far *= z_pad;
    else far /= z_pad;
    
    light_proj := mat4_ortho(left, right, bottom, top, near, far);
    
    return light_proj * light_view;
}

draw_frame :: (camera: *Camera) {
    projection := mat4_projection(45.0 * deg2rad, 1366.0 / 768.0, NEAR_PLANE, FAR_PLANE);
    
    light_pos := Vec3.{0, 0, 10};
    light_target := Vec3.{1, -1, 1};
    light_dir := normalize(light_target - light_pos);
    
    light_colour := Vec3.{1.0, 1.0, 0.8};
    light_matrix := calc_light_space_matrix(light_pos, light_dir, projection, camera.view);
    
    opaque_pass: Draw_Pass;
    depth_pass: Draw_Pass;
    
    {
        depth_pass.type = .DEPTH;
        depth_pass.pipeline = depth_pipeline;
        
        depth_vert_constants := arena_push(*frame_arena, CBuffer_Shadow_Vertex);
        depth_vert_constants.light_matrix = light_matrix;
        
        depth_pass.vert_constants = depth_vert_constants;
        depth_pass.vert_constants_size = size_of(CBuffer_Shadow_Vertex);
        
        depth_pass.storage_buffers = arena_push_n(*frame_arena, *SDL_GPUBuffer, 1);
        depth_pass.storage_buffers[0] = skinning_matrices_buffer;
        
        depth_pass.colour_target = false;
        depth_pass.depth_target = shadow_texture;
        
        depth_pass.viewport = .{SHADOW_MAP_SIZE, SHADOW_MAP_SIZE};
    }
    
    {
        opaque_pass.type = .OPAQUE;
        opaque_pass.pipeline = mesh_pipeline;
        
        opaque_vert_constants := arena_push(*frame_arena, CBuffer_Mesh_Vertex);
        opaque_vert_constants.view = camera.view;
        opaque_vert_constants.projection = projection;
        opaque_vert_constants.camera_position = camera.position;
        opaque_vert_constants.light_dir = light_dir;
        
        opaque_frag_constants := arena_push(*frame_arena, CBuffer_Mesh_Fragment);
        opaque_frag_constants.light_colour = light_colour;
        opaque_frag_constants.light_matrix = light_matrix;
        opaque_frag_constants.frag_debug_mode = frag_debug_mode;
        
        opaque_pass.vert_constants = opaque_vert_constants;
        opaque_pass.vert_constants_size = size_of(CBuffer_Mesh_Vertex);
        opaque_pass.frag_constants = opaque_frag_constants;
        opaque_pass.frag_constants_size = size_of(CBuffer_Mesh_Fragment);
        
        opaque_pass.storage_buffers = arena_push_n(*frame_arena, *SDL_GPUBuffer, 1);
        opaque_pass.storage_buffers[0] = skinning_matrices_buffer;
        
        opaque_pass.textures = arena_push_n(*frame_arena, *SDL_GPUTexture, 1);
        opaque_pass.textures[0] = shadow_texture;
        opaque_pass.samplers = arena_push_n(*frame_arena, *SDL_GPUSampler, 1);
        opaque_pass.samplers[0] = shadow_sampler;
        
        opaque_pass.colour_target = true;
        opaque_pass.depth_target = depth_texture;
        
        opaque_pass.viewport = .{1366, 768};
    }
    
    {
        /*
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
*/
    }
    
    command_buffer := SDL_AcquireGPUCommandBuffer(g_device);
    
    depth_commands := arena_push_n(*frame_arena, Draw_Command, 1);
    draw_cubes(*depth_pass, *depth_commands[0]);
    //draw_plane(*depth_pass, *depth_commands[1]);
    depth_pass.commands = depth_commands;
    
    opaque_commands := arena_push_n(*frame_arena, Draw_Command, 2);
    draw_cubes(*opaque_pass, *opaque_commands[0]);
    draw_plane(*opaque_pass, *opaque_commands[1]);
    opaque_pass.commands = opaque_commands;
    
    draw_pass(*depth_pass, command_buffer);
    draw_pass(*opaque_pass, command_buffer);
    
    SDL_SubmitGPUCommandBuffer(command_buffer);
}

MAX_BONES :: 1024;

SHADOW_MAP_SIZE :: 4096;

NEAR_PLANE :: 0.1;
FAR_PLANE :: 100.0;

MAX_INSTANCES :: 1024;

#scope_file

MAX_FRAG_DEBUG_MODE :: 1;
frag_debug_mode: s32;

CBuffer_Shadow_Vertex :: struct {
    light_matrix: Mat4;
}

CBuffer_Mesh_Vertex :: struct {
    view: Mat4;
    projection: Mat4;
    camera_position: Vec3;
    pad1: float;
    light_dir: Vec3;
    pad2: float;
}

CBuffer_Mesh_Fragment :: struct {
    light_colour: Vec3;
    pad2: float;
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

mesh_pipeline: *SDL_GPUGraphicsPipeline;

depth_pipeline: *SDL_GPUGraphicsPipeline;
screen_space_pipeline: *SDL_GPUGraphicsPipeline;
shadow_texture: *SDL_GPUTexture;

skinning_matrices_buffer: *SDL_GPUBuffer;
depth_texture: *SDL_GPUTexture;

default_sampler: *SDL_GPUSampler;
shadow_sampler: *SDL_GPUSampler;

IBuffer_Mesh :: struct {
    transform: Mat4;
    diffuse_colour: Vec3;
    pad0: float;
    material_params: Vec4;
}

Draw_Pass_Type :: enum {
    DEPTH;
    OPAQUE;
    TRANSLUCENT;
}

Draw_Pass :: struct {
    type: Draw_Pass_Type;
    pipeline: *SDL_GPUGraphicsPipeline;
    
    vert_constants: *void;
    vert_constants_size: int;
    frag_constants: *void;
    frag_constants_size: int;
    
    commands: [] Draw_Command;
    
    colour_target: bool;
    colour_target_texture_override: *SDL_GPUTexture;
    depth_target: *SDL_GPUTexture;
    
    textures: [] *SDL_GPUTexture;
    samplers: [] *SDL_GPUSampler;
    storage_buffers: [] *SDL_GPUBuffer;
    
    viewport: Vec2;
}

Draw_Command :: struct {
    vertex_buffers: [] *SDL_GPUBuffer;
    index_buffer: *SDL_GPUBuffer;
    textures: [] *SDL_GPUTexture;
    samplers: [] *SDL_GPUSampler;
    
    index_count: int;
    
    instance_buffer: *SDL_GPUBuffer;
    instance_count: int;
}

draw_pass :: (pass: *Draw_Pass, command_buffer: *SDL_GPUCommandBuffer) {
    colour_target_count := 0;
    colour_info: SDL_GPUColorTargetInfo;
    colour_target: *SDL_GPUColorTargetInfo;
    if pass.colour_target {
        target_texture: *SDL_GPUTexture;
        if !pass.colour_target_texture_override {
            SDL_AcquireGPUSwapchainTexture(command_buffer, g_window, *target_texture, null, null);
        } else {
            target_texture = pass.colour_target_texture_override;
        }
        
        colour_info.clear_color = .{0, 0, 0, 1};
        colour_info.load_op = .SDL_GPU_LOADOP_CLEAR;
        colour_info.store_op = .SDL_GPU_STOREOP_STORE;
        colour_info.texture = target_texture;
        colour_target_count = 1;
        
        colour_target = *colour_info;
        
    }
    
    depth_info: SDL_GPUDepthStencilTargetInfo;
    depth_target: *SDL_GPUDepthStencilTargetInfo;
    if pass.depth_target {
        depth_info.texture = pass.depth_target;
        depth_info.cycle = false;
        depth_info.clear_depth = 1;
        depth_info.clear_stencil = 0;
        depth_info.load_op = .SDL_GPU_LOADOP_CLEAR;
        depth_info.store_op = .SDL_GPU_STOREOP_STORE;
        depth_info.stencil_load_op = .SDL_GPU_LOADOP_DONT_CARE;
        depth_info.stencil_store_op = .SDL_GPU_STOREOP_DONT_CARE;
        
        depth_target = *depth_info;
    }
    
    render_pass := SDL_BeginGPURenderPass(command_buffer, colour_target, xx colour_target_count, depth_target);
    
    viewport: SDL_GPUViewport;
    viewport.x = 0;
    viewport.y = 0;
    viewport.w = xx pass.viewport.x;
    viewport.h = xx pass.viewport.y;
    viewport.min_depth = 0.0;
    viewport.max_depth = 1.0;
    SDL_SetGPUViewport(render_pass, *viewport);
    
    SDL_BindGPUGraphicsPipeline(render_pass, pass.pipeline);
    
    texture_bindings := arena_push_n(*frame_arena, SDL_GPUTextureSamplerBinding, xx pass.textures.count);
    for texture, texture_index: pass.textures {
        texture_bindings[texture_index] = .{texture, pass.samplers[texture_index]};
    }
    
    SDL_BindGPUFragmentSamplers(render_pass, 0, texture_bindings.data, xx texture_bindings.count);
    SDL_BindGPUVertexStorageBuffers(render_pass, 0, pass.storage_buffers.data, xx pass.storage_buffers.count);
    
    SDL_PushGPUVertexUniformData(command_buffer, 0, pass.vert_constants, xx pass.vert_constants_size);
    SDL_PushGPUFragmentUniformData(command_buffer, 0, pass.frag_constants, xx pass.frag_constants_size);
    
    for pass.commands {
        vertex_bindings := arena_push_n(*frame_arena, SDL_GPUBufferBinding, xx it.vertex_buffers.count);
        for buffer: it.vertex_buffers {
            vertex_bindings[it_index] = .{buffer, 0};
        }
        
        index_binding := SDL_GPUBufferBinding.{it.index_buffer, 0};
        
        texture_bindings := arena_push_n(*frame_arena, SDL_GPUTextureSamplerBinding, xx it.textures.count);
        for texture, texture_index: it.textures {
            texture_bindings[texture_index] = .{texture, it.samplers[texture_index]};
        }
        
        SDL_BindGPUVertexBuffers(render_pass, 0, vertex_bindings.data, xx vertex_bindings.count);
        SDL_BindGPUIndexBuffer(render_pass, *index_binding, .SDL_GPU_INDEXELEMENTSIZE_32BIT);
        SDL_BindGPUFragmentSamplers(render_pass, xx pass.textures.count, texture_bindings.data, xx texture_bindings.count);
        SDL_BindGPUVertexStorageBuffers(render_pass, xx pass.storage_buffers.count, *it.instance_buffer, 1);
        
        SDL_DrawGPUIndexedPrimitives(render_pass, xx it.index_count, xx it.instance_count, 0, 0, 0);
    }
    
    SDL_EndGPURenderPass(render_pass);
}

cubes_instance_buffer: *SDL_GPUBuffer;
plane_instance_buffer: *SDL_GPUBuffer;

draw_mesh_instanced :: (pass: *Draw_Pass, command: *Draw_Command, mesh: *Mesh, instance_count: int, instance_buffer: *SDL_GPUBuffer, textures: [] *Texture) {
    command.index_buffer = mesh.index_buffer;
    if pass.type == .DEPTH {
        buffers := arena_push_n(*frame_arena, *SDL_GPUBuffer, 3);
        buffers[0] = mesh.position_buffer;
        buffers[1] = mesh.weight_buffer;
        buffers[2] = mesh.bone_ids_buffer;
        command.vertex_buffers = buffers;
    } else if pass.type == .OPAQUE || pass.type == .TRANSLUCENT {
        buffers := arena_push_n(*frame_arena, *SDL_GPUBuffer, 6);
        buffers[0] = mesh.position_buffer;
        buffers[1] = mesh.tex_coord_buffer;
        buffers[2] = mesh.normal_buffer;
        buffers[3] = mesh.tangent_buffer;
        buffers[4] = mesh.weight_buffer;
        buffers[5] = mesh.bone_ids_buffer;
        command.vertex_buffers = buffers;
    }
    
    command.textures = arena_push_n(*frame_arena, *SDL_GPUTexture, xx textures.count);
    command.samplers = arena_push_n(*frame_arena, *SDL_GPUSampler, xx textures.count);
    for textures {
        command.textures[it_index] = it.gpu_texture;
        command.samplers[it_index] = default_sampler;
    }
    
    command.index_count = mesh.num_indices;
    
    command.instance_buffer = instance_buffer;
    command.instance_count = instance_count;
}

draw_plane :: (pass: *Draw_Pass, command: *Draw_Command) {
    mesh := load_mesh("meshes/plane.mesh");
    textures := arena_push_n(*frame_arena, *Texture, 3);
    textures[0] = load_texture("textures/floor_diffuse.png");
    textures[1] = load_texture("textures/floor_normal.png");
    textures[2] = load_texture("textures/floor_rmaoh.png");
    
    draw_mesh_instanced(pass, command, mesh, 1, plane_instance_buffer, textures);
}

draw_cubes :: (pass: *Draw_Pass, command: *Draw_Command) {
    mesh := load_mesh("meshes/cube.mesh");
    textures := arena_push_n(*frame_arena, *Texture, 3);
    textures[0] = load_texture("textures/unit_diffuse.png");
    textures[1] = load_texture("textures/unit_normal.png");
    textures[2] = load_texture("textures/unit_rmaoh.png");
    
    draw_mesh_instanced(pass, command, mesh, 343, cubes_instance_buffer, textures);
}