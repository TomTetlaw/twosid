
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
}

draw_command :: struct {
    Kind: draw_command_kind;
}

draw_command_mesh :: struct {
#as using Base: draw_command;
    
    Flags: mesh_draw_command_flags;
    Mesh: *mesh;
    SkinningTransforms: [] float4x4;
    Textures: [] *texture;
    Instance: ibuffer_mesh;
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

DrawDebugSphere :: (Position: float3, Colour: float4) {
    Command: draw_command_mesh;
    Command.Flags = .DEBUG;
    Command.Mesh = LoadMesh("meshes/sphere.mesh");;
    Command.Instance.Transform = TranslationMatrix(Position);
    Command.Instance.DiffuseColour = Colour;
    AddDrawCommand(*Command);
}

AddDrawCommand :: (Command: *$T/draw_command) {
    if Command.Kind == .MESH {
        MeshCommand := cast (*draw_command_mesh) Command;
        Batch := GetMeshBatch(MeshCommand);
        ArenaPush(*Batch.InstanceData, MeshCommand.Instance);
    }
}

Temp: arena(ibuffer_debug);

ProcessDrawCommands :: () {
    ArenaReset(*Temp);
    
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
            } else {
                DrawMeshInstanced(OpaquePass, it.Mesh, it.SkinningTransforms, it.Textures, ArenaToView(*it.InstanceData));
            }
        }
    }
}

InitRendererFrontend :: () {
    FrontendMeshBatches = ArenaPushN(*RendererArena, draw_batch_mesh, MAX_BATCHES);
}

ResetRendererFrontend :: () {
    for * FrontendMeshBatches {
        ArenaReset(*it.InstanceData);
        it.Initialized = false;
    }
}

#scope_file

MAX_BATCHES :: 2048;

FrontendMeshBatches: [] draw_batch_mesh;

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
    
    if StructuredBuffer.Used + Data.count >= StructuredBuffer.Capacity return;
    
    Copy(StructuredBuffer.Mapping + StructuredBuffer.Used, Data.data, Data.count * size_of(I.T));
    StructuredBuffer.Used += Data.count;
}