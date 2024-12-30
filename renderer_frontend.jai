
// The renderer frontend's job is to take arbitrary and random
//    draw commands from the game, batch them, and turn them
//    into renderer commands.

// Mesh draw commands are opaque by default
mesh_draw_command_flags :: enum_flags u32 {
    DEBUG;
    TRANSLUCENT;
    NO_CAST_SHADOWS;
}

draw_command_kind :: enum {
    MESH;
    SCREEN_SPACE_QUAD;
}

draw_command :: struct {
    Kind: draw_command_kind;
}

draw_command_mesh :: struct {
#as using Base: draw_command;
    Base.Kind = .MESH;
    
    Flags: mesh_draw_command_flags;
    Mesh: *mesh;
    SkinningTransforms: [] float4x4;
    Textures: [] *texture;
    Instance: ibuffer_mesh;
}

draw_command_ss_quad :: struct {
#as using Base: draw_command;
    Base.Kind = .SCREEN_SPACE_QUAD;
    
    Texture: *texture;
    Instance: ibuffer_ss_quad;
}

// Batch for drawing an instanced mesh.
//    Hashing is based on the mesh name,
//    the draw_command flags, and the 
//    required textures.
draw_batch_mesh :: struct {
    Flags: mesh_draw_command_flags;
    Mesh: *mesh;
    SkinningTransforms: [] float4x4;
    Textures: [] *texture;
    InstanceData: arena(ibuffer_mesh);
    Initialized: bool;
}

draw_batch_quad :: struct {
    Texture: *texture;
    InstanceData: arena(ibuffer_ss_quad);
    Initialized: bool;
}

DrawDebugMesh :: (Position: float3, Mesh: *mesh, Colour := float4.{1, 1, 1, 1}) {
    Command: draw_command_mesh;
    Command.Mesh = Mesh;
    Command.Flags = .DEBUG;
    Command.Instance.Transform = TranslationMatrix(Position);
    Command.Instance.DiffuseColour = Colour;
    AddDrawCommand(*Command);
}

DrawDebugSphere :: (Position: float3, Size := 1.0, Colour := float4.{1, 1, 1, 1}) {
    Command: draw_command_mesh;
    Command.Flags = .DEBUG;
    Command.Mesh = LoadMesh("meshes/sphere.mesh");;
    Command.Instance.Transform = TranslationMatrix(Position) * ScaleMatrix(xyz(Size));
    Command.Instance.DiffuseColour = Colour;
    AddDrawCommand(*Command);
}

DrawBoundingBox :: (Box: bounding_box, Colour := float4.{1, 1, 1, 1}) {
    Origin := (Box.Min + Box.Max) * .5;
    Scale := Box.Max - Box.Min;
    
    Command: draw_command_mesh;
    Command.Flags = .DEBUG;
    Command.Mesh = LoadMesh("meshes/cube.mesh");
    Command.Instance.Transform = TranslationMatrix(Origin) * ScaleMatrix(Scale);
    Command.Instance.DiffuseColour = Colour;
    AddDrawCommand(*Command);
}

DrawCylinder :: (Cylinder: cylinder, Colour := float4.{1, 1, 1, 1}) {
    Command: draw_command_mesh;
    Command.Flags = .DEBUG;
    Command.Mesh = LoadMesh("meshes/cylinder.mesh");
    Command.Instance.Transform = TranslationMatrix(Cylinder.Center) * ScaleMatrix(.{Cylinder.Radius, Cylinder.Radius, Cylinder.Height});
    Command.Instance.DiffuseColour = Colour;
    AddDrawCommand(*Command);
}

DrawScreenSpaceQuad :: (Position: float2, Size: float2, Colour := float4.{1, 1, 1, 1}, Texture: *texture = null) {
    Command: draw_command_ss_quad;
    
    if Texture Command.Texture = Texture;
    else Command.Texture = LoadTexture("textures/white.png");
    
    Command.Instance.Position = Position;
    Command.Instance.Size = Size;
    Command.Instance.Colour = Colour;
    
    AddDrawCommand(*Command);
}

AddDrawCommand :: (Command: *$T/draw_command) {
    if Command.Kind == .MESH {
        MeshCommand := cast (*draw_command_mesh) Command;
        Batch := GetMeshBatch(MeshCommand);
        ArenaPush(*Batch.InstanceData, MeshCommand.Instance);
    } else if Command.Kind == .SCREEN_SPACE_QUAD {
        QuadCommand := cast (*draw_command_ss_quad) Command;
        Batch := GetQuadBatch(QuadCommand);
        ArenaPush(*Batch.InstanceData, QuadCommand.Instance);
    }
}

Temp: arena(ibuffer_debug);

ProcessDrawCommands :: () {
    for * FrontendMeshBatches {
        if it.InstanceData.Count > 0 {
            DrawInDepthPass := !(it.Flags & .NO_CAST_SHADOWS) && !(it.Flags & .DEBUG);
            
            if DrawInDepthPass {
                DrawMeshInstanced(DepthPass, it.Mesh, it.SkinningTransforms, it.Textures, ArenaToView(*it.InstanceData));
            }
            
            if it.Flags & .TRANSLUCENT {
                DrawMeshInstanced(TranslucentPass, it.Mesh, it.SkinningTransforms, it.Textures, ArenaToView(*it.InstanceData));
            } else if it.Flags & .DEBUG {
                for it.InstanceData {
                    DebugInstance: ibuffer_debug;
                    DebugInstance.Transform = it.Transform;
                    DebugInstance.DiffuseColour = it.DiffuseColour.xyz;
                    ArenaPush(*Temp, DebugInstance);
                }
                
                DrawMeshInstanced(DebugPass, it.Mesh, it.SkinningTransforms, it.Textures, ArenaToView(*Temp));
                
                ArenaReset(*Temp);
            } else {
                DrawMeshInstanced(OpaquePass, it.Mesh, it.SkinningTransforms, it.Textures, ArenaToView(*it.InstanceData));
            }
        }
    }
    
    for * FrontendQuadBatches {
        if it.InstanceData.Count == 0 continue;
        
        Command := ArenaPush(*ScreenSpacePass.Commands);
        Command.Textures = ArenaPushN(*RendererFrameArena, SDL_GPUTextureSamplerBinding, .[.{it.Texture.GpuTexture, DefaultSampler}]);
        
        VertexBuffers := ArenaPushN(*RendererFrameArena, SDL_GPUBufferBinding, 2);
        VertexBuffers[0] = .{ScreenSpacePositionBuffer, 0};
        VertexBuffers[1] = .{ScreenSpaceTexCoordBuffer, 0};
        Command.VertexBuffers = VertexBuffers;
        Command.IndexBuffer = ScreenSpaceIndexBuffer;
        
        Command.IndexCount = 6;
        
        Command.InstanceCount = it.InstanceData.Count;
        WriteStructuredBuffer(ScreenSpacePass.InstanceBuffer, ArenaToView(*it.InstanceData));
    }
}

InitRendererFrontend :: () {
    FrontendMeshBatches = ArenaPushN(*RendererArena, draw_batch_mesh, MAX_BATCHES);
    FrontendQuadBatches = ArenaPushN(*RendererArena, draw_batch_quad, MAX_BATCHES);
}

ResetRendererFrontend :: () {
    for * FrontendMeshBatches {
        ArenaReset(*it.InstanceData);
        it.Initialized = false;
    }
    
    for * FrontendQuadBatches {
        ArenaReset(*it.InstanceData);
        it.Initialized = false;
    }
}

#scope_file

MAX_BATCHES :: 2048;

FrontendMeshBatches: [] draw_batch_mesh;
FrontendQuadBatches: [] draw_batch_quad;

GetMeshBatch :: (MeshCommand: *draw_command_mesh) -> *draw_batch_mesh {
    Hash := GetHash(MeshCommand.Mesh.Path, cast (u32) MeshCommand.Flags);
    Hash = GetHash(cast (u32) MeshCommand.Flags, Hash);
    for MeshCommand.Textures {
        Hash = GetHash(it.Path, Hash);
    }
    
    Batch := *FrontendMeshBatches[Hash % MAX_BATCHES];
    
    if !Batch.Initialized {
        Batch.Flags = MeshCommand.Flags;
        Batch.SkinningTransforms = MeshCommand.SkinningTransforms;
        Batch.Mesh = MeshCommand.Mesh;
        Batch.Textures = MeshCommand.Textures;
        Batch.Initialized = true;
    }
    
    return Batch;
}

GetQuadBatch :: (QuadCommand: *draw_command_ss_quad) -> *draw_batch_quad {
    Hash := 0;
    if QuadCommand.Texture Hash = GetHash(QuadCommand.Texture.Path);
    else Hash = GetHash("no_texture");
    
    Batch := *FrontendQuadBatches[Hash % MAX_BATCHES];
    
    if !Batch.Initialized {
        Batch.Texture = QuadCommand.Texture;
        Batch.Initialized = true;
    }
    
    return Batch;
}

DrawMeshInstanced :: (Pass: *draw_pass($T), Mesh: *mesh, SkinningTransforms: [] float4x4, Textures: [] *texture, InstanceData: [] T) {
    Command := ArenaPush(*Pass.Commands);
    
    VertexBuffers: [] SDL_GPUBufferBinding;
    if Pass.BuffersNeeded == .POSITION_ONLY {
        VertexBuffers = ArenaPushN(*RendererFrameArena, SDL_GPUBufferBinding, 1);
        VertexBuffers[0] = .{Mesh.PositionBuffer, 0};
    } else if Pass.BuffersNeeded == .DEPTH_ONLY {
        VertexBuffers = ArenaPushN(*RendererFrameArena, SDL_GPUBufferBinding, 3);
        VertexBuffers[0] = .{Mesh.PositionBuffer, 0};
        VertexBuffers[1] = .{Mesh.WeightBuffer, 0};
        VertexBuffers[2] = .{Mesh.BoneIdsBuffer, 0};
    } else if Pass.BuffersNeeded == .MESH {
        VertexBuffers = ArenaPushN(*RendererFrameArena, SDL_GPUBufferBinding, 6);
        VertexBuffers[0] = .{Mesh.PositionBuffer, 0};
        VertexBuffers[1] = .{Mesh.TexCoordBuffer, 0};
        VertexBuffers[2] = .{Mesh.NormalBuffer, 0};
        VertexBuffers[3] = .{Mesh.TangentBuffer, 0};
        VertexBuffers[4] = .{Mesh.WeightBuffer, 0};
        VertexBuffers[5] = .{Mesh.BoneIdsBuffer, 0};
    }
    
    Command.VertexBuffers = VertexBuffers;
    Command.IndexBuffer = Mesh.IndexBuffer;
    Command.IndexCount = Mesh.NumIndices;
    
    if Pass.TexturesNeeded == .DIFFUSE_NORMAL_RMAOH {
        Command.Textures = ArenaPushN(*RendererFrameArena, SDL_GPUTextureSamplerBinding, Textures.count);
        for Textures {
            Command.Textures[it_index] = .{it.GpuTexture, DefaultSampler};
        }
    }
    
    Command.InstanceCount = InstanceData.count;
    WriteStructuredBuffer(Pass.InstanceBuffer, InstanceData);
    
    if SkinningTransforms.count > 0 {
        WriteStructuredBuffer(Pass.SkinningBuffer, SkinningTransforms);
    }
}

WriteStructuredBuffer :: (StructuredBuffer: *$I/structured_buffer, Data: [] I.T) {
    if !StructuredBuffer return;
    
    Count := Min(Data.count, StructuredBuffer.Capacity - StructuredBuffer.Used);
    
    Copy(StructuredBuffer.Mapping + StructuredBuffer.Used, Data.data, Data.count * size_of(I.T));
    StructuredBuffer.Used += Count;
}