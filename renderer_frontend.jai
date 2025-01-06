
// The renderer frontend's job is to take arbitrary and random
//    draw commands from the game, batch them, and turn them
//    into renderer commands.

// Mesh draw commands are opaque by default
mesh_draw_command_flags :: enum_flags u32 {
    DEBUG;
    TRANSLUCENT;
    NO_CAST_SHADOWS;
    UNLIT;
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

ss_quad_command_flags :: enum_flags u32 {
    TEXT;
}

draw_command_ss_quad :: struct {
#as using Base: draw_command;
    Base.Kind = .SCREEN_SPACE_QUAD;
    
    Flags: ss_quad_command_flags;
    Texture: *texture;
    Instance: ibuffer_ss_quad;
    Scissor: float4;
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
    Flags: ss_quad_command_flags;
    Texture: *texture;
    Scissor: float4;
    InstanceData: arena(ibuffer_ss_quad);
    Initialized: bool;
}

DebugString :: (Format: string, Args: ..Any) {
    Builder: String_Builder;
    print_to_builder(*Builder, Format, ..Args);
    Message := builder_to_string(*Builder);
    ArenaPush(*DebugStrings, Message);
}

DebugString :: (String: string) {
    ArenaPush(*DebugStrings, String);
}

DebugVars :: ($Args: ..Code) #expand {
    Builder: String_Builder;
    Config: Print_Vars_Config;
    Config.control_flags = .PRINT_NAME | .PRINT_VALUE;
    Config.after_value = "";
    Config.after_type = "";
    print_vars_helper(*Builder, Config, Args);
    
    Strings := split(builder_to_string(*Builder), "\n");
    for Strings DebugString(it);
}

DrawDebugMesh :: (Position: float3, Mesh: *mesh, Colour := float4.{1, 1, 1, 1}) {
    Command: draw_command_mesh;
    Command.Mesh = Mesh;
    Command.Flags = .DEBUG;
    Command.Instance.Transform = TranslationMatrix(Position);
    Command.Instance.DiffuseColour = Colour;
    AddDrawCommand(*Command);
}

DrawMesh :: (Transform: float4x4, Mesh: *mesh, Colour := float4.{1, 1, 1, 1}) {
    Command: draw_command_mesh;
    Command.Flags = .UNLIT;
    Command.Mesh = Mesh;
    Command.Instance.Transform = Transform;
    Grey := LoadTexture("textures/grey.png");
    Command.Textures = ArenaPushN(*RendererFrameArena, *texture, .[Grey, Grey, Grey]);
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

DrawScreenSpaceQuad :: (Position: float2, Size: float2, Colour := float4.{1, 1, 1, 1}, Texture: *texture = null, TexCoord := float4.{0, 0, 1, 1}, IsText := false, TextParams := float4.{0, 0, 0, 0}) {
    Command: draw_command_ss_quad;
    
    if Texture Command.Texture = Texture;
    else Command.Texture = LoadTexture("textures/white.png");
    
    Command.Instance.Position = Position;
    Command.Instance.Size = Size;
    Command.Instance.Colour = Colour;
    Command.Instance.TexCoord = TexCoord;
    if IsText Command.Flags = .TEXT;
    Command.Instance.TextParams = TextParams;
    AddDrawCommand(*Command);
}

DrawText :: (Position: float2, Font: *font, S: string, Colour := float4.{1, 1, 1, 1}) {
    CurrentPos := Position;
    for S {
        
        Quad: Stb_Aligned_Quad;
        stb_get_packed_quad(Font.Chars.data, xx Font.Texture.Width, xx Font.Texture.Height, it - 32, *CurrentPos.x, *CurrentPos.y, *Quad, 1);
        
        W := Quad.x1 - Quad.x0;
        H := Quad.y1 - Quad.y0;
        P := float2.{Quad.x0 + W*.5, Quad.y0 + H*.5};
        S := float2.{W, H};
        
        RangeX := Quad.s1 - Quad.s0;
        RangeY := Quad.t1 - Quad.t0;
        T := float4.{Quad.s0, Quad.t0, RangeX, RangeY};
        
        DrawScreenSpaceQuad(P, S, Colour, Font.Texture, T, true);
    }
}

DrawTextSDF :: (Position: float2, Font: *sdf_font, Size: float, S: string, Colour := float4.{1, 1, 1, 1}) {
    StringSize := GetStringSize(Font, Size, S);
    
    CurrentPos := Position;
    for S {
        Char := GetCharFromDistanceFont(Font, it);
        
        Left := Char.Left*Size;
        Right := Char.Right*Size;
        Bottom := Char.Bottom*Size;
        Top := Char.Top*Size;
        
        Width := Right - Left;
        Height := Top - Bottom;
        
        // Baseline Y should be centered on the position
        P := CurrentPos + float2.{Left, Bottom + Height*.75};
        S := float2.{Width, Height};
        
        T := float4.{
            Char.U0, Char.V0,
            Char.U1 - Char.U0, Char.V1 - Char.V0
        };
        
        DrawScreenSpaceQuad(P, S, Colour, Font.Texture, T, true, .{1, Size/32*4, Width, Height});
        
        CurrentPos.x += Char.Advance*Size;
    }
}

AddDrawCommand :: (Command: *$T/draw_command) {
    if Command.Kind == .MESH {
        MeshCommand := cast (*draw_command_mesh) Command;
        if MeshCommand.Flags & .UNLIT {
            MeshCommand.Instance.FeatureFlags.x = 1.0;
        }
        
        Batch := GetMeshBatch(MeshCommand);
        ArenaPush(*Batch.InstanceData, MeshCommand.Instance);
    } else if Command.Kind == .SCREEN_SPACE_QUAD {
        QuadCommand := cast (*draw_command_ss_quad) Command;
        QuadCommand.Scissor = CurrentScissor;
        Batch := GetQuadBatch(QuadCommand);
        ArenaPush(*Batch.InstanceData, QuadCommand.Instance);
    }
}

Temp: arena(ibuffer_debug);

ProcessDrawCommands :: () {
    DebugStart := float2.{1000, 50};
    for DebugStrings {
        DrawTextSDF(DebugStart, DebugFont, 16.0, it);
        DebugStart.y += 15;
    }
    ArenaReset(*DebugStrings);
    
    for * FrontendMeshBatches {
        if it.InstanceData.Count > 0 {
            DrawInDepthPass := !(it.Flags & .NO_CAST_SHADOWS) && !(it.Flags & .DEBUG) && !(it.Flags & .UNLIT);
            
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
            } else if it.Flags & .UNLIT {
                DrawMeshInstanced(UnlitPass, it.Mesh, it.SkinningTransforms, it.Textures, ArenaToView(*it.InstanceData));
            } else {
                DrawMeshInstanced(OpaquePass, it.Mesh, it.SkinningTransforms, it.Textures, ArenaToView(*it.InstanceData));
            }
        }
    }
    
    for * FrontendQuadBatches {
        if it.InstanceData.Count == 0 continue;
        
        Pass := ScreenSpacePass;
        if it.Flags & .TEXT Pass = TextPass;
        
        Command := ArenaPush(*Pass.Commands);
        Command.Textures = ArenaPushN(*RendererFrameArena, SDL_GPUTextureSamplerBinding, .[.{it.Texture.GpuTexture, DefaultSampler}]);
        
        VertexBuffers := ArenaPushN(*RendererFrameArena, SDL_GPUBufferBinding, 2);
        VertexBuffers[0] = .{ScreenSpacePositionBuffer, 0};
        VertexBuffers[1] = .{ScreenSpaceTexCoordBuffer, 0};
        Command.VertexBuffers = VertexBuffers;
        Command.IndexBuffer = ScreenSpaceIndexBuffer;
        Command.Scissor = it.Scissor;
        Command.IndexCount = 6;
        
        Command.InstanceCount = it.InstanceData.Count;
        WriteStructuredBuffer(Pass.InstanceBuffer, ArenaToView(*it.InstanceData));
    }
    
    CurrentScissor = xyzw(-1);
}

InitRendererFrontend :: () {
    FrontendMeshBatches = ArenaPushN(*RendererArena, draw_batch_mesh, MAX_BATCHES);
    FrontendQuadBatches = ArenaPushN(*RendererArena, draw_batch_quad, MAX_BATCHES);
    DebugFont = LoadDistanceFont("fonts/roboto.png");
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

SetCurrentScissor :: (Rect: float4) {
    CurrentScissor = Rect;
}

#scope_file

MAX_BATCHES :: 2048;

FrontendMeshBatches: [] draw_batch_mesh;
FrontendQuadBatches: [] draw_batch_quad;

DebugStrings: arena(string);
DebugFont: *sdf_font;

CurrentScissor := #run xyzw(-1);

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
    Hash: u32 = 0;
    if QuadCommand.Texture Hash = GetHash(QuadCommand.Texture.Path);
    else Hash = GetHash("no_texture");
    Hash = GetHash(cast (u32) QuadCommand.Flags, Hash);
    Hash = GetHash(QuadCommand.Scissor.x, Hash);
    Hash = GetHash(QuadCommand.Scissor.y, Hash);
    Hash = GetHash(QuadCommand.Scissor.z, Hash);
    Hash = GetHash(QuadCommand.Scissor.w, Hash);
    
    Batch := *FrontendQuadBatches[Hash % MAX_BATCHES];
    
    if !Batch.Initialized {
        Batch.Scissor = QuadCommand.Scissor;
        Batch.Flags = QuadCommand.Flags;
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