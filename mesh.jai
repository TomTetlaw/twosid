
bone_ids :: struct {
    a, b, c, d: s16;
}

bone :: struct {
    Id: int;
    Name: string;
    LocalBindTransform: float4x4;
    InverseBindTransform: float4x4;
    Parent: *bone;
}

skeleton :: struct {
    Bones: [] bone;
    BoneNameMap: [] int;
}

mesh :: struct {
    Path: string;
    Positions: [] float3;
    TexCoords: [] float2;
    Normals: [] float3;
    Tangents: [] float3;
    Weights: [] float3;
    BoneIds: [] bone_ids;
    Indices: [] u32;
    
    NumIndices: int;
    PositionBuffer: *SDL_GPUBuffer;
    TexCoordBuffer: *SDL_GPUBuffer;
    NormalBuffer: *SDL_GPUBuffer;
    TangentBuffer: *SDL_GPUBuffer;
    WeightBuffer: *SDL_GPUBuffer;
    BoneIdsBuffer: *SDL_GPUBuffer;
    IndexBuffer: *SDL_GPUBuffer;
    
    Skeleton: *skeleton;
    
    Bounds: bounding_box;
    
    Generated: bool;
}

animation :: struct {
    Path: string;
    Name: string;
    BoneNames: [] string;
    BoneCount: int;
    SampleCount: int;
    Positions: [] float3;
    Rotations: [] quat;
    Scales: [] float3;
}

InitMeshSystem :: () {
    Files := file_list("./meshes");
    for Files {
        if contains(it, ".mesh_text") continue;
        if contains(it, ".mesh") {
            path, base_name, ext := path_decomp(it);
            LoadMesh(Format("meshes/%.%", base_name, ext));
        }
    }
    
    for * Meshes {
        if it.Generated continue;
        
        it.PositionBuffer = CreateVertexBuffer(Format("%_positions", it.Path), it.Positions);
        it.TexCoordBuffer = CreateVertexBuffer(Format("%_tex_coords", it.Path), it.TexCoords);
        it.NormalBuffer = CreateVertexBuffer(Format("%_normals", it.Path), it.Normals);
        it.TangentBuffer = CreateVertexBuffer(Format("%_tangents", it.Path), it.Tangents);
        it.WeightBuffer = CreateVertexBuffer(Format("%_weights", it.Path), it.Weights);
        it.BoneIdsBuffer = CreateVertexBuffer(Format("%_bone_ids", it.Path), it.BoneIds);
        it.IndexBuffer = CreateIndexBuffer(Format("%_indices", it.Path), it.Indices);
    }
}

// @todo: don't load bone ids and Weights if not needed;
//        by which i mean, have two types of Mesh:
//        Static_Mesh and Skeletal_Mesh

LoadMesh :: (Path: string) -> *mesh {
    for * Meshes if equal(it.Path, Path) return it;
    
    File, Success := file_open(Path);
    defer if Success file_close(*File);
    
    if !Success return ArenaPushNull(mesh);
    
    Header := FileReadMeshHeader(*File);
    if !equal(Header.Magic, "MESH") {
        print("Failed to load: % is not a mesh file!", Path);
        return ArenaPushNull(mesh);
    }
    
    Positions := FileReadArray(*File, *MeshArena, float3, Header.NumVertices);
    TexCoords := FileReadArray(*File, *MeshArena, float2, Header.NumVertices);
    Normals := FileReadArray(*File, *MeshArena, float3, Header.NumVertices);
    Tangents := FileReadArray(*File, *MeshArena, float3, Header.NumVertices);
    Weights := FileReadArray(*File, *MeshArena, float3, Header.NumVertices);
    BoneIds := FileReadArray(*File, *MeshArena, bone_ids, Header.NumVertices);
    Indices := FileReadArray(*File, *MeshArena, u32, Header.NumIndices);
    SerializedBones := FileReadBones(*File, *MeshArena, Header.NumBones);
    
    // This should be done at build time!
    IndexRemap := ArenaPushN(*MeshArena, u32, xx Positions.count);
    Streams := ArenaPushN(*WorkingArena, meshopt_Stream, 6);
    Streams[0] = .{Positions.data, size_of(float3), size_of(float3)};
    Streams[1] = .{Weights.data, size_of(float3), size_of(float3)};
    Streams[2] = .{BoneIds.data, size_of(bone_ids), size_of(bone_ids)};
    Streams[3] = .{TexCoords.data, size_of(float2), size_of(float2)};
    Streams[4] = .{Normals.data, size_of(float3), size_of(float3)};
    Streams[5] = .{Tangents.data, size_of(float3), size_of(float3)};
    VertexCount := meshopt_generateVertexRemapMulti(IndexRemap.data, Indices.data, xx Indices.count, xx Positions.count, Streams.data, xx Streams.count);
    
    OptimizedPositions := ArenaPushN(*MeshArena, float3, xx VertexCount);
    OptimizedTexCoords := ArenaPushN(*MeshArena, float2, xx VertexCount);
    OptimizedNormals := ArenaPushN(*MeshArena, float3, xx VertexCount);
    OptimizedTangents := ArenaPushN(*MeshArena, float3, xx VertexCount);
    OptimizedWeights := ArenaPushN(*MeshArena, float3, xx VertexCount);
    OptimizedBoneIds := ArenaPushN(*MeshArena, bone_ids, xx VertexCount);
    OptimizedIndices := ArenaPushN(*MeshArena, u32, Indices.count);
    
    meshopt_remapVertexBuffer(OptimizedPositions.data, Positions.data, xx Positions.count, size_of(float3), IndexRemap.data);
    meshopt_remapVertexBuffer(OptimizedTexCoords.data, TexCoords.data, xx TexCoords.count, size_of(float2), IndexRemap.data);
    meshopt_remapVertexBuffer(OptimizedNormals.data, Normals.data, xx Normals.count, size_of(float3), IndexRemap.data);
    meshopt_remapVertexBuffer(OptimizedTangents.data, Tangents.data, xx Tangents.count, size_of(float3), IndexRemap.data);
    meshopt_remapVertexBuffer(OptimizedWeights.data, Weights.data, xx Weights.count, size_of(float3), IndexRemap.data);
    meshopt_remapVertexBuffer(OptimizedBoneIds.data, BoneIds.data, xx BoneIds.count, size_of(bone_ids), IndexRemap.data);
    meshopt_remapIndexBuffer(OptimizedIndices.data, Indices.data, xx Indices.count, IndexRemap.data);
    
    Positions = OptimizedPositions;
    TexCoords = OptimizedTexCoords;
    Normals = OptimizedNormals;
    Tangents = OptimizedTangents;
    Weights = OptimizedWeights;
    BoneIds = OptimizedBoneIds;
    Indices = OptimizedIndices;
    
    MinBounds := xyz(FLOAT32_MAX);
    MaxBounds := xyz(-FLOAT32_MAX);
    
    for Positions {
        MinBounds.x = min(MinBounds.x, it.x);
        MinBounds.y = min(MinBounds.y, it.y);
        MinBounds.z = min(MinBounds.z, it.z);
        
        MaxBounds.x = max(MaxBounds.x, it.x);
        MaxBounds.y = max(MaxBounds.y, it.y);
        MaxBounds.z = max(MaxBounds.z, it.z);
    }
    
    Bones := ArenaPushN(*MeshArena, bone, xx Header.NumBones);
    BoneNameMap := ArenaPushN(*MeshArena, int, BONE_NAME_MAP_SIZE);
    
    for * BoneNameMap {
        it.* = -1;
    }
    
    for * SerializedBones {
        Bone: bone;
        Bone.Id = it.Id;
        Bone.Name = it.Name;
        
        Bone.LocalBindTransform = it.Transform;
        
        if it.Parent == -1 {
            Bone.Parent = null;
            Bone.InverseBindTransform = Bone.LocalBindTransform;
        } else {
            Bone.Parent = *Bones[it.Parent];
            Bone.InverseBindTransform = Bone.Parent.InverseBindTransform * Bone.LocalBindTransform;
        }
        
        Hash := djb2_hash(it.Name) % BONE_NAME_MAP_SIZE;
        assert(BoneNameMap[Hash] == -1);
        
        BoneNameMap[Hash] = it_index;
        
        Bones[it_index] = Bone;
    }
    
    for * Bones {
        it.InverseBindTransform = InverseMatrix(it.InverseBindTransform);
    }
    
    Skeleton := ArenaPush(*MeshArena, skeleton);
    Skeleton.Bones = Bones;
    Skeleton.BoneNameMap = BoneNameMap;
    
    Mesh := ArenaPush(*Meshes);
    
    Mesh.Positions = Positions;
    Mesh.TexCoords = TexCoords;
    Mesh.Normals = Normals;
    Mesh.Tangents = Tangents;
    Mesh.Indices = Indices;
    Mesh.Weights = Weights;
    Mesh.BoneIds = BoneIds;
    
    Mesh.Path = Path;
    Mesh.Skeleton = Skeleton;
    Mesh.NumIndices = Indices.count;
    Mesh.Bounds = .{MinBounds, MaxBounds};
    
    Mesh.Generated = false;
    
    return Mesh;
}

CreateMeshFromTriangles :: (Name: string, Triangles: [] triangle) -> *mesh {
    Mark := ArenaPushMark(*WorkingArena);
    
    Positions := ArenaPushN(*WorkingArena, float3, Triangles.count * 3);
    for Triangles {
        Positions[it_index*3 + 0] = it.P1;
        Positions[it_index*3 + 1] = it.P2;
        Positions[it_index*3 + 2] = it.P3;
    }
    
    IndexCount: u64 = xx (Triangles.count * 3);
    
    Streams := ArenaPushN(*WorkingArena, meshopt_Stream, 1);
    Streams[0] = .{Positions.data, size_of(float3), size_of(float3)};
    
    Remap := ArenaPushN(*WorkingArena, u32, Positions.count);
    VertexCount := meshopt_generateVertexRemapMulti(Remap.data, null, IndexCount, xx Positions.count, Streams.data, xx Streams.count);
    
    OptimizedPositions := ArenaPushN(*MeshArena, float3, xx VertexCount);
    meshopt_remapVertexBuffer(OptimizedPositions.data, Positions.data, xx Positions.count, size_of(float3), Remap.data);
    
    Indices := ArenaPushN(*MeshArena, u32, cast(int) IndexCount);
    meshopt_remapIndexBuffer(Indices.data, null, IndexCount, Remap.data);
    
    MinBounds := xyz(FLOAT32_MAX);
    MaxBounds := xyz(-FLOAT32_MAX);
    
    Positions = OptimizedPositions;
    
    for Positions {
        MinBounds.x = min(MinBounds.x, it.x);
        MinBounds.y = min(MinBounds.y, it.y);
        MinBounds.z = min(MinBounds.z, it.z);
        
        MaxBounds.x = max(MaxBounds.x, it.x);
        MaxBounds.y = max(MaxBounds.y, it.y);
        MaxBounds.z = max(MaxBounds.z, it.z);
    }
    
    Mesh := ArenaPush(*Meshes);
    Mesh.Path = Name;
    Mesh.Positions = OptimizedPositions;
    Mesh.Indices = Indices;
    Mesh.NumIndices = Indices.count;
    Mesh.Bounds = .{MinBounds, MaxBounds};
    
    Mesh.PositionBuffer = CreateVertexBuffer(Format("%_position", Name), OptimizedPositions);
    Mesh.IndexBuffer = CreateIndexBuffer(Format("%_index", Name), Indices);
    
    Mesh.Generated = true;
    
    ArenaPopMark(*WorkingArena, Mark);
    
    return Mesh;
}

CreateMesh :: (Name: string, Positions: [] float3, TexCoords: [] float2, Indices: [] u32) -> *mesh {
    Mark := ArenaPushMark(*WorkingArena);
    
    MinBounds := xyz(FLOAT32_MAX);
    MaxBounds := xyz(-FLOAT32_MAX);
    
    for Positions {
        MinBounds.x = min(MinBounds.x, it.x);
        MinBounds.y = min(MinBounds.y, it.y);
        MinBounds.z = min(MinBounds.z, it.z);
        
        MaxBounds.x = max(MaxBounds.x, it.x);
        MaxBounds.y = max(MaxBounds.y, it.y);
        MaxBounds.z = max(MaxBounds.z, it.z);
    }
    
    Mesh := ArenaPush(*Meshes);
    Mesh.Path = Name;
    Mesh.Positions = Positions;
    Mesh.TexCoords = TexCoords;
    Mesh.Indices = Indices;
    Mesh.NumIndices = Indices.count;
    Mesh.Bounds = .{MinBounds, MaxBounds};
    
    Mesh.PositionBuffer = CreateVertexBuffer(Format("%_position", Name), Positions);
    Mesh.TexCoordBuffer = CreateVertexBuffer(Format("%_tex_coord", Name), TexCoords);
    Mesh.IndexBuffer = CreateIndexBuffer(Format("%_index", Name), Indices);
    
    Mesh.Generated = true;
    
    ArenaPopMark(*WorkingArena, Mark);
    
    return Mesh;
}

FindBone :: (Skeleton: *skeleton, Name: string) -> *bone {
    Hash := djb2_hash(Name) % BONE_NAME_MAP_SIZE;
    return *Skeleton.Bones[Skeleton.BoneNameMap[Hash]];
}

LoadAnimation :: (Path: string) -> *animation {
    for * Animations if equal(it.Path, Path) return it;
    
    File, Success := file_open(Path);
    defer if Success file_close(*File);
    
    if !Success return ArenaPushNull(animation);
    
    Header := FileReadAnimHeader(*File);
    if !equal(Header.Magic, "ANIM") {
        print("Failed to load: % is not an Anim File!", Path);
        return ArenaPushNull(animation);
    }
    
    Name := FileReadString(*File, *AnimationArena);
    
    BoneNames := ArenaPushN(*AnimationArena, string, xx Header.BoneCount);
    for 0..Header.BoneCount-1 {
        BoneNames[it] = FileReadString(*File, *AnimationArena);
    }
    
    Positions := FileReadArray(*File, *AnimationArena, float3, Header.BoneCount * Header.SampleCount);
    Rotations := FileReadArray(*File, *AnimationArena, quat, Header.BoneCount * Header.SampleCount);
    Scales := FileReadArray(*File, *AnimationArena, float3, Header.BoneCount * Header.SampleCount);
    
    Anim := ArenaPush(*Animations);
    Anim.Name = Name;
    Anim.Path = Path;
    Anim.SampleCount = Header.SampleCount;
    Anim.BoneCount = Header.BoneCount;
    Anim.BoneNames = BoneNames;
    Anim.Positions = Positions;
    Anim.Rotations = Rotations;
    Anim.Scales = Scales;
    
    return Anim;
}

#scope_file

BONE_NAME_MAP_SIZE :: 2048;

mesh_header :: struct {
    Magic: string;
    NumVertices: int;
    NumIndices: int;
    NumBones: int;
}

anim_header :: struct {
    Magic: string;
    SampleCount: int;
    BoneCount: int;
}

serialized_bone :: struct {
    Id: s16;
    Parent: s16;
    Name: string;
    Transform: float4x4;
}

serialized_animation :: struct {
    Name: string;
    SampleCount: int;
    BoneNames: [..] string;
    Positions: [..] float3;
    Rotations: [..] quat;
    Scales: [..] float3;
}

FileReadBones :: (f: *File, Arena: *arena, Count: int) -> [] serialized_bone {
    Bones := ArenaPushN(Arena, serialized_bone, xx Count);
    
    for 0..Count-1 {
        Name := FileReadString(f, Arena);
        
        Id: s16;
        file_read(f, *Id, size_of(s16));
        
        Parent: s16;
        file_read(f, *Parent, size_of(s16));
        
        Transform: float4x4;
        file_read(f, Transform.Floats.data, size_of(float) * 16);
        
        Bones[it] = serialized_bone.{Id, Parent, Name, Transform};
    }
    
    return Bones;
}

FileReadMeshHeader :: (f: *File) -> mesh_header {
    Header: mesh_header;
    Header.Magic = FileReadString(f, *MeshArena);
    file_read(f, *Header.NumVertices, size_of(int));
    file_read(f, *Header.NumIndices, size_of(int));
    file_read(f, *Header.NumBones, size_of(int));
    return Header;
}

FileReadAnimHeader :: (f: *File) -> anim_header {
    Header: anim_header;
    Header.Magic = FileReadString(f, *AnimationArena);
    file_read(f, *Header.SampleCount, size_of(int));
    file_read(f, *Header.BoneCount, size_of(int));
    return Header;
}

Meshes: arena(mesh);
MeshArena: arena;

Animations: arena(animation);
AnimationArena: arena;

#import "Basic";
#import "Sort";
#import "File";
#import "Hash";
#import "meshoptimizer";