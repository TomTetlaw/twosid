
Bone_Ids :: struct {
    a, b, c, d: s16;
}

Bone :: struct {
    id: int;
    name: string;
    local_bind_transform: Mat4;
    inverse_bind_transform: Mat4;
    parent: *Bone;
}

Skeleton :: struct {
    bones: [] Bone;
    bone_name_map: [] int;
}

Mesh :: struct {
    path: string;
    positions: [] Vec3;
    tex_coords: [] Vec2;
    normals: [] Vec3;
    tangents: [] Vec3;
    weights: [] Vec3;
    bone_ids: [] Bone_Ids;
    indices: [] u32;
    
    num_indices: int;
    position_buffer: *SDL_GPUBuffer;
    tex_coord_buffer: *SDL_GPUBuffer;
    normal_buffer: *SDL_GPUBuffer;
    tangent_buffer: *SDL_GPUBuffer;
    weight_buffer: *SDL_GPUBuffer;
    bone_ids_buffer: *SDL_GPUBuffer;
    index_buffer: *SDL_GPUBuffer;
    
    skeleton: *Skeleton;
    
    min_bounds: Vec3;
    max_bounds: Vec3;
}

Animation :: struct {
    path: string;
    name: string;
    bone_names: [] string;
    bone_count: int;
    sample_count: int;
    positions: [] Vec3;
    rotations: [] Quaternion;
    scales: [] Vec3;
}

init_mesh_system :: () {
    arena_push_mark_defer(*mesh_arena);
    
    files := file_list("./meshes");
    for files {
        if contains(it, ".mesh_text") continue;
        if contains(it, ".mesh") {
            path, base_name, ext := path_decomp(it);
            load_mesh(tprint("meshes/%.%", base_name, ext));
        }
    }
    
    total_meshes_size := 0;
    
    vertex_create_info: SDL_GPUBufferCreateInfo;
    vertex_create_info.usage = SDL_GPU_BUFFERUSAGE_VERTEX;
    for * meshes {
        it.position_buffer = create_vertex_buffer(g_device, tprint("%_position", it.path), size_of(Vec3), it.positions.count);
        it.tex_coord_buffer = create_vertex_buffer(g_device, tprint("%_tex_coord", it.path), size_of(Vec2), it.positions.count);
        it.normal_buffer = create_vertex_buffer(g_device, tprint("%_normal", it.path), size_of(Vec3), it.positions.count);
        it.tangent_buffer = create_vertex_buffer(g_device, tprint("%_tangent", it.path), size_of(Vec3), it.positions.count);
        it.weight_buffer = create_vertex_buffer(g_device, tprint("%_weight", it.path), size_of(Vec3), it.positions.count);
        it.bone_ids_buffer = create_vertex_buffer(g_device, tprint("%_bone_ids", it.path), size_of(Bone_Ids), it.positions.count);
        
        it.index_buffer = create_index_buffer(g_device, tprint("%_index", it.path), it.indices.count);
        
        vertex_size :: 14 * size_of(float) + size_of(Bone_Ids);
        total_meshes_size += vertex_size * it.positions.count;
        total_meshes_size += size_of(u32) * it.indices.count;
    }
    
    create_info: SDL_GPUTransferBufferCreateInfo;
    create_info.usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
    create_info.size = xx total_meshes_size;
    transfer_buffer := SDL_CreateGPUTransferBuffer(g_device, *create_info);
    
    transfer_memory := cast (*u8) SDL_MapGPUTransferBuffer(g_device, transfer_buffer, false);
    
    cursor := 0;
    for * meshes {
        memcpy(transfer_memory + cursor, it.positions.data, it.positions.count * size_of(Vec3));
        cursor += it.positions.count * size_of(Vec3);
        
        memcpy(transfer_memory + cursor, it.tex_coords.data, it.positions.count * size_of(Vec2));
        cursor += it.positions.count * size_of(Vec2);
        
        memcpy(transfer_memory + cursor, it.normals.data, it.positions.count * size_of(Vec3));
        cursor += it.positions.count * size_of(Vec3);
        
        memcpy(transfer_memory + cursor, it.tangents.data, it.positions.count * size_of(Vec4));
        cursor += it.positions.count * size_of(Vec3);
        
        memcpy(transfer_memory + cursor, it.weights.data, it.positions.count * size_of(Vec3));
        cursor += it.positions.count * size_of(Vec3);
        
        memcpy(transfer_memory + cursor, it.bone_ids.data, it.positions.count * size_of(Bone_Ids));
        cursor += it.positions.count * size_of(Bone_Ids);
        
        memcpy(transfer_memory + cursor, it.indices.data, it.indices.count * size_of(u32));
        cursor += it.indices.count * size_of(u32);
    }
    
    SDL_UnmapGPUTransferBuffer(g_device, transfer_buffer);
    
    command_buffer := SDL_AcquireGPUCommandBuffer(g_device);
    copy_pass := SDL_BeginGPUCopyPass(command_buffer);
    
    location: SDL_GPUTransferBufferLocation;
    location.transfer_buffer = transfer_buffer;
    
    region: SDL_GPUBufferRegion;
    region.offset = 0;
    
    for * meshes {
        region.buffer = it.position_buffer;
        region.size = xx (it.positions.count * size_of(Vec3));
        SDL_UploadToGPUBuffer(copy_pass, *location, *region, false);
        location.offset += xx (it.positions.count * size_of(Vec3));
        
        region.buffer = it.tex_coord_buffer;
        region.size = xx (it.positions.count * size_of(Vec2));
        SDL_UploadToGPUBuffer(copy_pass, *location, *region, false);
        location.offset += xx (it.positions.count * size_of(Vec2));
        
        region.buffer = it.normal_buffer;
        region.size = xx (it.positions.count * size_of(Vec3));
        SDL_UploadToGPUBuffer(copy_pass, *location, *region, false);
        location.offset += xx (it.positions.count * size_of(Vec3));
        
        region.buffer = it.tangent_buffer;
        region.size = xx (it.positions.count * size_of(Vec3));
        SDL_UploadToGPUBuffer(copy_pass, *location, *region, false);
        location.offset += xx (it.positions.count * size_of(Vec3));
        
        region.buffer = it.weight_buffer;
        region.size = xx (it.positions.count * size_of(Vec3));
        SDL_UploadToGPUBuffer(copy_pass, *location, *region, false);
        location.offset += xx (it.positions.count * size_of(Vec3));
        
        region.buffer = it.bone_ids_buffer;
        region.size = xx (it.positions.count * size_of(Bone_Ids));
        SDL_UploadToGPUBuffer(copy_pass, *location, *region, false);
        location.offset += xx (it.positions.count * size_of(Bone_Ids));
        
        region.buffer = it.index_buffer;
        region.size = xx (it.indices.count * size_of(u32));
        SDL_UploadToGPUBuffer(copy_pass, *location, *region, false);
        location.offset += xx (it.indices.count * size_of(u32));
    }
    
    SDL_EndGPUCopyPass(copy_pass);
    SDL_SubmitGPUCommandBuffer(command_buffer);
    SDL_ReleaseGPUTransferBuffer(g_device, transfer_buffer);
}

// @todo: don't load bone ids and weights if not needed;
//        by which i mean, have two types of mesh:
//        Static_Mesh and Skeletal_Mesh

load_mesh :: (path: string) -> *Mesh {
    for * meshes if equal(it.path, path) return it;
    
    file, success := file_open(path);
    defer if success file_close(*file);
    
    if !success return meshes.null_value;
    
    header := file_read_mesh_header(*file);
    if !equal(header.magic, "MESH") {
        print("Failed to load: % is not a mesh file!", path);
        return meshes.null_value;
    }
    
    positions := file_read_array(*file, *mesh_arena, Vec3, header.num_vertices);
    tex_coords := file_read_array(*file, *mesh_arena, Vec2, header.num_vertices);
    normals := file_read_array(*file, *mesh_arena, Vec3, header.num_vertices);
    tangents := file_read_array(*file, *mesh_arena, Vec3, header.num_vertices);
    weights := file_read_array(*file, *mesh_arena, Vec3, header.num_vertices);
    bone_ids := file_read_array(*file, *mesh_arena, Bone_Ids, header.num_vertices);
    indices := file_read_array(*file, *mesh_arena, u32, header.num_indices);
    serialized_bones := file_read_bones(*file, *mesh_arena, header.num_bones);
    
    min_bounds := Vec3.{FLOAT32_MAX, FLOAT32_MAX, FLOAT32_MAX};
    max_bounds := Vec3.{FLOAT32_MIN, FLOAT32_MIN, FLOAT32_MIN};
    
    for positions {
        min_bounds.x = min(min_bounds.x, it.x);
        min_bounds.y = min(min_bounds.y, it.y);
        min_bounds.z = min(min_bounds.z, it.z);
        
        max_bounds.x = max(max_bounds.x, it.x);
        max_bounds.y = max(max_bounds.y, it.y);
        max_bounds.z = max(max_bounds.z, it.z);
    }
    
    bones := arena_push_n(*mesh_arena, Bone, xx header.num_bones);
    bone_name_map := arena_push_n(*mesh_arena, int, BONE_NAME_MAP_SIZE);
    
    for * bone_name_map {
        it.* = -1;
    }
    
    for * serialized_bones {
        bone: Bone;
        bone.id = it.id;
        bone.name = it.name;
        
        bone.local_bind_transform = it.transform;
        
        if it.parent == -1 {
            bone.parent = null;
            bone.inverse_bind_transform = bone.local_bind_transform;
        } else {
            bone.parent = *bones[it.parent];
            bone.inverse_bind_transform = bone.parent.inverse_bind_transform * bone.local_bind_transform;
        }
        
        hash := djb2_hash(it.name) % BONE_NAME_MAP_SIZE;
        assert(bone_name_map[hash] == -1);
        
        bone_name_map[hash] = it_index;
        
        bones[it_index] = bone;
    }
    
    for * bones {
        it.inverse_bind_transform = mat4_inverse(it.inverse_bind_transform);
    }
    
    skeleton := arena_push(*mesh_arena, Skeleton);
    skeleton.bones = bones;
    skeleton.bone_name_map = bone_name_map;
    
    mesh := arena_push(*meshes);
    
    mesh.positions = positions;
    mesh.tex_coords = tex_coords;
    mesh.normals = normals;
    mesh.tangents = tangents;
    mesh.indices = indices;
    mesh.weights = weights;
    mesh.bone_ids = bone_ids;
    
    mesh.path = path;
    mesh.skeleton = skeleton;
    mesh.num_indices = indices.count;
    mesh.min_bounds = min_bounds;
    mesh.max_bounds = max_bounds;
    
    return mesh;
}

find_bone :: (skeleton: *Skeleton, name: string) -> *Bone {
    hash := djb2_hash(name) % BONE_NAME_MAP_SIZE;
    return *skeleton.bones[skeleton.bone_name_map[hash]];
}

load_animation :: (path: string) -> *Animation {
    for * animations if equal(it.path, path) return it;
    
    file, success := file_open(path);
    defer if success file_close(*file);
    
    if !success return animations.null_value;
    
    header := file_read_anim_header(*file);
    if !equal(header.magic, "ANIM") {
        print("Failed to load: % is not an anim file!", path);
        return animations.null_value;
    }
    
    name := file_read_string(*file, *animation_arena);
    
    bone_names := arena_push_n(*animation_arena, string, xx header.bone_count);
    for 0..header.bone_count-1 {
        bone_names[it] = file_read_string(*file, *animation_arena);
    }
    
    positions := file_read_array(*file, *animation_arena, Vec3, header.bone_count * header.sample_count);
    rotations := file_read_array(*file, *animation_arena, Quaternion, header.bone_count * header.sample_count);
    scales := file_read_array(*file, *animation_arena, Vec3, header.bone_count * header.sample_count);
    
    anim := arena_push(*animations);
    anim.name = name;
    anim.path = path;
    anim.sample_count = header.sample_count;
    anim.bone_count = header.bone_count;
    anim.bone_names = bone_names;
    anim.positions = positions;
    anim.rotations = rotations;
    anim.scales = scales;
    
    return anim;
}

#scope_file

#import "Basic";
#import "Sort";
#import "File";
#import "Hash";

BONE_NAME_MAP_SIZE :: 2048;

Mesh_Header :: struct {
    magic: string;
    num_vertices: int;
    num_indices: int;
    num_bones: int;
}

Anim_Header :: struct {
    magic: string;
    sample_count: int;
    bone_count: int;
}

Serialized_Bone :: struct {
    id: s16;
    parent: s16;
    name: string;
    transform: Mat4;
}

Serialized_Animation :: struct {
    name: string;
    sample_count: int;
    bone_names: [..] string;
    positions: [..] Vec3;
    rotations: [..] Quaternion;
    scales: [..] Vec3;
}

file_read_bones :: (file: *File, arena: *Arena, count: int) -> [] Serialized_Bone {
    bones := arena_push_n(arena, Serialized_Bone, xx count);
    
    for 0..count-1 {
        name := file_read_string(file, arena);
        
        id: s16;
        file_read(file, *id, size_of(s16));
        
        parent: s16;
        file_read(file, *parent, size_of(s16));
        
        transform: Mat4;
        file_read(file, transform.floats.data, size_of(float) * 16);
        
        bones[it] = Serialized_Bone.{id, parent, name, transform};
    }
    
    return bones;
}

file_read_mesh_header :: (file: *File) -> Mesh_Header {
    header: Mesh_Header;
    header.magic = file_read_string(file, *mesh_arena);
    file_read(file, *header.num_vertices, size_of(int));
    file_read(file, *header.num_indices, size_of(int));
    file_read(file, *header.num_bones, size_of(int));
    return header;
}

file_read_anim_header :: (file: *File) -> Anim_Header {
    header: Anim_Header;
    header.magic = file_read_string(file, *animation_arena);
    file_read(file, *header.sample_count, size_of(int));
    file_read(file, *header.bone_count, size_of(int));
    return header;
}

meshes: Arena("meshes", Mesh);
mesh_arena: Arena("mesh_working");

animations: Arena("animations", Animation);
animation_arena: Arena("animation_working");