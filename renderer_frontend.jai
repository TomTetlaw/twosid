
// The renderer frontend's job is to take arbitrary and random
//    draw commands from the game, batch them, and turn them
//    into renderer commands.

// Mesh draw commands are opaque by default
mesh_draw_command_flags :: enum_flags u32 {
    DEBUG;
    TRANSLUCENT;
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
    Textures: arena_array(*texture);
    Instance: ibuffer_mesh;
}

// Batch for drawing an instanced mesh.
//    Hashing is based on the mesh name,
//    the draw_command flags, and the 
//    required textures.
draw_batch_mesh :: struct {
    Flags: mesh_draw_command_flags;
    Mesh: *mesh;
    Textures: arena_array(*texture);
    InstanceData: arena_array(ibuffer_mesh);
    Initialized: bool;
}

AddDrawCommand :: (Command: *$T/draw_command) {
    if Command.Kind == .MESH {
        MeshCommand := cast (*draw_command_mesh) Command;
        Batch := GetMeshBatch(MeshCommand);
        ArrayAdd(*Batch.InstanceData, *MeshCommand.Instance);
    }
}

Temp: arena_array(ibuffer_debug);
Temp2: arena_array(ibuffer_debug);

ProcessDrawCommands :: () {
    ArrayReset(*Temp);
    ArrayReset(*Temp2);
    
    for * FrontendMeshBatches {
        if it.InstanceData.Count > 0 {
            if it.Flags & .TRANSLUCENT {
                DrawMeshInstanced(DepthPass, it.Mesh, *it.Textures, *it.InstanceData);
                DrawMeshInstanced(TranslucentPass, it.Mesh, *it.Textures, *it.InstanceData);
            } else if it.Flags & .DEBUG {
                for it.InstanceData {
                    DebugInstance: ibuffer_debug;
                    DebugInstance.Transform = it.Transform;
                    DebugInstance.DiffuseColour = it.DiffuseColour.xyz;
                    ArrayAdd(*Temp, *DebugInstance);
                }
                
                DrawMeshInstanced(DebugPass, it.Mesh, *it.Textures, *Temp);
            } else {
                for it.InstanceData {
                    DebugInstance: ibuffer_debug;
                    DebugInstance.Transform = it.Transform;
                    DebugInstance.DiffuseColour = it.DiffuseColour.xyz;
                    ArrayAdd(*Temp2, *DebugInstance);
                }
                
                DrawMeshInstanced(DepthPass, it.Mesh, *it.Textures, *it.InstanceData);
                DrawMeshInstanced(OpaquePass, it.Mesh, *it.Textures, *it.InstanceData);
                DrawMeshInstanced(DebugPass, it.Mesh, *it.Textures, *Temp2);
            }
        }
    }
}

InitRendererFrontend :: () {
    FrontendMeshBatches = ArenaPushN(*RendererArena, draw_batch_mesh, MAX_BATCHES);
}

ResetRendererFrontend :: () {
    for * FrontendMeshBatches {
        ArrayReset(*it.InstanceData);
        ArrayReset(*it.Textures);
        it.Initialized = false;
    }
    
    for * RenderCommandArray {
        ArrayReset(*it.VertexBuffers);
        ArrayReset(*it.Textures);
        it.IndexBuffer = null;
        it.IndexCount = 0;
        it.InstanceCount = 0;
        it.Flags = 0;
    }
    
    ArrayReset(*RenderCommandArray);
}

#scope_file

MAX_BATCHES :: 1024;

FrontendMeshBatches: [] draw_batch_mesh;

RenderCommandArray: arena_array(render_command);

GetMeshBatch :: (MeshCommand: *draw_command_mesh) -> *draw_batch_mesh {
    Hash := GetHash(MeshCommand.Mesh.Path, cast (u32) MeshCommand.Flags);
    Hash = GetHash(cast (u32) MeshCommand.Flags, Hash);
    for MeshCommand.Textures {
        Hash = GetHash(it.Path, Hash);
    }
    
    Batch := *FrontendMeshBatches[Hash % MAX_BATCHES];
    if !Batch.Initialized {
        Batch.Mesh = MeshCommand.Mesh;
        Batch.Flags = MeshCommand.Flags;
        ArrayAdd(*Batch.Textures, *MeshCommand.Textures);
        Batch.Initialized = true;
    }
    
    return Batch;
}

DrawMeshInstanced :: (Pass: *draw_pass($T), Mesh: *mesh, Textures: arena_array(*texture), InstanceData: *arena_array(T)) {
    Command := ArrayPush(*RenderCommandArray, false);
    
    if Pass.BuffersNeeded == .POSITION_ONLY {
        ArrayAdd(*Command.VertexBuffers, Mesh.PositionBuffer);
    } else if Pass.BuffersNeeded == .DEPTH_ONLY {
        ArrayAdd(*Command.VertexBuffers, Mesh.PositionBuffer);
        ArrayAdd(*Command.VertexBuffers, Mesh.WeightBuffer);
        ArrayAdd(*Command.VertexBuffers, Mesh.BoneIdsBuffer);
    } else if Pass.BuffersNeeded == .MESH {
        ArrayAdd(*Command.VertexBuffers, Mesh.PositionBuffer);
        ArrayAdd(*Command.VertexBuffers, Mesh.TexCoordBuffer);
        ArrayAdd(*Command.VertexBuffers, Mesh.NormalBuffer);
        ArrayAdd(*Command.VertexBuffers, Mesh.TangentBuffer);
        ArrayAdd(*Command.VertexBuffers, Mesh.WeightBuffer);
        ArrayAdd(*Command.VertexBuffers, Mesh.BoneIdsBuffer);
    }
    
    Command.IndexBuffer = Mesh.IndexBuffer;
    Command.IndexCount = Mesh.NumIndices;
    
    if Pass.BuffersNeeded == .MESH {
        for Textures {
            ArrayAdd(*Command.Textures, .{it.GpuTexture, DefaultSampler});
        }
    }
    
    Command.InstanceCount = InstanceData.Count;
    
    WriteInstanceBuffer(Pass.InstanceBuffer, InstanceData);
    
    ArrayAdd(*Pass.Commands, Command);
}

WriteInstanceBuffer :: (InstanceBuffer: *$I/instance_buffer, Data: *arena_array(I.T)) {
    if !InstanceBuffer return;
    
    if InstanceBuffer.Used + Data.Count >= InstanceBuffer.Capacity return;
    
    InstanceData := ArrayToView(Data);
    memcpy(InstanceBuffer.Mapping + InstanceBuffer.Used, InstanceData.data, InstanceData.count * size_of(I.T));
    InstanceBuffer.Used += Data.Count;
}