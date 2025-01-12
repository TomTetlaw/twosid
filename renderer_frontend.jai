
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

DrawUnlitMesh :: (Transform: float4x4, Mesh: *mesh, Colour := float4.{1, 1, 1, 1}, Options := batch_state_options.{}) {
    Command: draw_command;
    Command.Kind = .UNLIT;
    Command.Mesh = Mesh;
    Command.Textures = ArenaPushN(*RendererFrameArena, *texture, .[WhiteTexture]);
    Command.Instance.Transform = Transform;
    Command.Instance.Colour = Colour;
    DrawMesh(*Command, Options);
}

DrawOpaqueMesh :: (Transform: float4x4, Mesh: *mesh, Textures: [] *texture, SkinningTransforms: [] float4x4 = .[], MaterialParams := float4.{1, 1, 1, 1}, Colour := float4.{1, 1, 1, 1}, Options := batch_state_options.{}) {
    Command: draw_command;
    Command.Kind = .OPAQUE;
    Command.Mesh = Mesh;
    Command.Textures = Textures;
    Command.SkinningTransforms = SkinningTransforms;
    Command.Instance.Transform = Transform;
    Command.Instance.Colour = Colour;
    Command.Instance.Params = MaterialParams;
    DrawMesh(*Command, Options);
}

DebugDrawMesh :: (Mesh: *mesh, Transform: float4x4, Colour := float3.{1, 1, 1}, Options := batch_state_options.{}) {
    Command: draw_command;
    Command.Kind = .DEBUG;
    Command.Mesh = Mesh;
    Command.Instance.Transform = Transform;
    Command.Instance.Colour = xyzw(Colour, 1.0);
    DrawMesh(*Command, Options);
}

DebugDrawMesh :: (Mesh: *mesh, Position: float3, Scale := float3.{1, 1, 1}, Colour := float3.{1, 1, 1}, Options := batch_state_options.{}) {
    Command: draw_command;
    Command.Kind = .DEBUG;
    Command.Mesh = Mesh;
    Command.Instance.Transform = TranslationMatrix(Position) * ScaleMatrix(Scale);
    Command.Instance.Colour = xyzw(Colour, 1.0);
    DrawMesh(*Command, Options);
}

DebugDrawSphere :: (Position: float3, Size := 1.0, Colour := float3.{1, 1, 1}, Options := batch_state_options.{}) {
    DebugDrawMesh(SphereMesh, Position, xyz(Size), Colour, Options);
}

DebugDrawBoundingBox :: (Box: bounding_box, Colour := float3.{1, 1, 1}, Options := batch_state_options.{}) {
    Origin := (Box.Min + Box.Max) * .5;
    Scale := Box.Max - Box.Min;
    DebugDrawMesh(BoxMesh, Origin, Scale, Colour, Options);
}

DrawCylinder :: (Cylinder: cylinder, Colour := float3.{1, 1, 1}, Options := batch_state_options.{}) {
    DebugDrawMesh(CylinderMesh, Cylinder.Center, float3.{Cylinder.Radius, Cylinder.Radius, Cylinder.Height}, Colour, Options);
}

DrawScreenSpaceQuad :: (Position: float2, Size: float2, Colour := float4.{1, 1, 1, 1}, Texture: *texture = null, TexCoords := float4.{0, 0, 1, 1}, Options := batch_state_options.{}) {
    Command: draw_command;
    Command.Kind = .QUAD_2D;
    Command.Mesh = QuadMesh;
    Command.Textures = ArenaPushN(*RendererFrameArena, *texture, .[Texture]);
    Command.Instance.PositionSize = xyzw(Position, Size);
    Command.Instance.Colour = Colour;
    Command.Instance.TexCoords = TexCoords;
    DrawMesh(*Command, Options);
}

DrawText :: (Position: float2, Font: *font, S: string, Colour := float4.{1, 1, 1, 1}, Options := batch_state_options.{}) {
    CurrentPos := Position;
    for S {
        
        Quad: stbtt_aligned_quad;
        stbtt_GetPackedQuad(Font.Chars.data, xx Font.Texture.Width, xx Font.Texture.Height, it - 32, *CurrentPos.x, *CurrentPos.y, *Quad, 1);
        
        W := Quad.x1 - Quad.x0;
        H := Quad.y1 - Quad.y0;
        P := float2.{Quad.x0 + W*.5, Quad.y0 + H*.5};
        S := float2.{W, H};
        
        RangeX := Quad.s1 - Quad.s0;
        RangeY := Quad.t1 - Quad.t0;
        T := float4.{Quad.s0, Quad.t0, RangeX, RangeY};
        
        DrawScreenSpaceQuad(P, S, Colour, Font.Texture, T, Options);
    }
}

DrawTextSDF :: (Position: float2, Font: *sdf_font, Size: float, S: string, Colour := float4.{1, 1, 1, 1}, Options := batch_state_options.{}) {
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
        
        Command: draw_command;
        Command.Kind = .SDF_TEXT;
        Command.Mesh = QuadMesh;
        Command.Textures = ArenaPushN(*RendererFrameArena, *texture, .[Font.Texture]);
        Command.Instance.PositionSize = xyzw(P, S);
        Command.Instance.Colour = Colour;
        Command.Instance.TexCoords = T;
        Command.Instance.Params = .{1, Size/32*4, Width, Height};
        DrawMesh(*Command, Options);
        
        CurrentPos.x += Char.Advance*Size;
    }
}

CreateRendererBatches :: () {
    DebugStart := float2.{1000, 50};
    for DebugStrings {
        DrawTextSDF(DebugStart, DebugFont, 16.0, it);
        DebugStart.y += 15;
    }
    ArenaReset(*DebugStrings);
    
    for * BatchList {
        if it.Kind == {
            case .QUAD_2D;
            Quad := CreatePipelineBatchForMesh(QuadPipeline, it.Textures, .[], QuadMesh, ArenaToView(it.InstanceDataQuad));
            Quad.Viewport = it.Viewport;
            Quad.Scissor = it.Scissor;
            
            case .TEXT;
            Text := CreatePipelineBatchForMesh(TextPipeline, it.Textures, .[], it.Mesh, ArenaToView(it.InstanceDataQuad));
            Text.Viewport = it.Viewport;
            Text.Scissor = it.Scissor;
            
            case .SDF_TEXT;
            Text := CreatePipelineBatchForMesh(TextSDFPipeline, it.Textures, .[], it.Mesh, ArenaToView(it.InstanceDataTextSDF));
            Text.Viewport = it.Viewport;
            Text.Scissor = it.Scissor;
            
            case .OPAQUE;
            Shadow := CreatePipelineBatchForMesh(ShadowPipeline, it.Textures, .[], it.Mesh, ArenaToView(it.InstanceDataShadow));
            Shadow.Viewport = .{0, 0, SHADOW_MAP_SIZE, SHADOW_MAP_SIZE};
            Shadow.Scissor = .{0, 0, SHADOW_MAP_SIZE, SHADOW_MAP_SIZE};
            
            Mesh := CreatePipelineBatchForMesh(OpaquePipeline, it.Textures, .[], it.Mesh, ArenaToView(it.InstanceDataMesh));
            Mesh.Viewport = it.Viewport;
            Mesh.Scissor = it.Scissor;
            
            case .UNLIT;
            Mesh := CreatePipelineBatchForMesh(UnlitPipeline, it.Textures, .[], it.Mesh, ArenaToView(it.InstanceDataUnlit));
            Mesh.Viewport = it.Viewport;
            Mesh.Scissor = it.Scissor;
            
            case .DEBUG;
            Mesh := CreatePipelineBatchForMesh(DebugPipeline, it.Textures, .[], it.Mesh, ArenaToView(it.InstanceDataDebug));
            Mesh.Viewport = it.Viewport;
            Mesh.Scissor = it.Scissor;
            
            case .TRANSLUCENT;
            Shadow := CreatePipelineBatchForMesh(ShadowPipeline, it.Textures, .[], it.Mesh, ArenaToView(it.InstanceDataShadow));
            Shadow.Viewport = .{0, 0, SHADOW_MAP_SIZE, SHADOW_MAP_SIZE};
            Shadow.Scissor = .{0, 0, SHADOW_MAP_SIZE, SHADOW_MAP_SIZE};
            
            Mesh := CreatePipelineBatchForMesh(TranslucentPipeline, it.Textures, .[], it.Mesh, ArenaToView(it.InstanceDataMesh));
            Mesh.Viewport = it.Viewport;
            Mesh.Scissor = it.Scissor;
        }
    }
}

ResetRendererFrontend :: () {
    for 0..MAX_BATCHES-1 {
        IndexHash[it] = -1;
    }
    
    ResetLinkedList(*BatchList);
    ArenaReset(*Batches);
}

InitRendererFrontend :: () {
    DebugFont = LoadDistanceFont("fonts/roboto.png");
    
    Positions: [4] float3;
    Positions[0] = .{0, 0, 0};
    Positions[1] = .{1, 0, 0};
    Positions[2] = .{1, 1, 0};
    Positions[3] = .{0, 1, 0};
    
    TexCoords: [4] float2;
    TexCoords[0] = .{0, 0};
    TexCoords[1] = .{1, 0};
    TexCoords[2] = .{1, 1};
    TexCoords[3] = .{0, 1};
    
    QuadMesh = CreateMesh("quad", Positions, TexCoords, .[0, 1, 2, 0, 3, 2]);
    
    WhiteTexture = LoadTexture("textures/white.png");
    SphereMesh = LoadMesh("meshes/sphere.mesh");
    BoxMesh = LoadMesh("meshes/cube.mesh");
    CylinderMesh = LoadMesh("meshes/cylinder.mesh");
    
    IndexHash = ArenaPushN(*RendererArena, int, MAX_BATCHES * 2);
    for 0..MAX_BATCHES-1 {
        IndexHash[it] = -1;
    }
}

batch_state_options :: struct {
    Viewport := #run xyzw(-1);
    Scissor := #run xyzw(-1);
}

#scope_file

MAX_BATCHES :: 2048;

IndexHash: [] int;
BatchList: linked_list(draw_batch);
Batches: arena(draw_batch);

WhiteTexture: *texture;
QuadMesh, SphereMesh, BoxMesh, CylinderMesh: *mesh;

DebugStrings: arena(string);
DebugFont: *sdf_font;

draw_command_kind :: enum {
    QUAD_2D;
    TEXT;
    SDF_TEXT;
    OPAQUE;
    UNLIT;
    TRANSLUCENT;
    DEBUG;
}

combined_instance_data :: struct {
    // shared
    Colour: float4;
    Params: float4;
    
    // for meshes
    Transform: float4x4;
    
    // for quads
    PositionSize: float4;
    TexCoords: float4;
}

draw_command :: struct {
    Kind: draw_command_kind;
    Mesh: *mesh;
    SkinningTransforms: [] float4x4;
    Textures: [] *texture;
    Instance: combined_instance_data;
}

batch_state_options :: struct {
    Viewport := #run xyzw(-1);
    Scissor := #run xyzw(-1);
}

draw_batch :: struct {
    Next, Prev: *draw_batch;
    
    Kind: draw_command_kind;
    Mesh: *mesh;
    SkinningTransforms: [] float4x4;
    Textures: [] *texture;
    InstanceDataShadow: *arena(ibuffer_shadow);
    InstanceDataMesh: *arena(ibuffer_mesh);
    InstanceDataUnlit: *arena(ibuffer_unlit);
    InstanceDataDebug: *arena(ibuffer_debug);
    InstanceDataQuad: *arena(ibuffer_quad);
    InstanceDataTextSDF: *arena(ibuffer_text_sdf);
    using Options: batch_state_options;
    Initialized: bool;
}

DrawMesh :: (Command: *draw_command, Options: batch_state_options = .{}) {
    Hash := GetHash(Command.Kind);
    Hash = GetHash(Command.Mesh.Path, Hash);
    for Command.Textures {
        if !it continue;
        Hash = GetHash(it.Path, Hash);
    }
    
    Hash = GetHash(Options.Viewport, Hash);
    Hash = GetHash(Options.Scissor, Hash);
    
    Batch: *draw_batch;
    HashIndex := Hash % MAX_BATCHES;
    if IndexHash[HashIndex] == -1 {
        IndexHash[HashIndex] = BatchList.Count;
        Batch = ArenaPush(*Batches);
        AddToLinkedList(*BatchList, Batch);
    } else {
        Batch = *Batches[IndexHash[HashIndex]];
    }
    
    if !Batch.Initialized {
        Batch.Kind = Command.Kind;
        Batch.Mesh = Command.Mesh;
        Batch.SkinningTransforms = Command.SkinningTransforms;
        Batch.Textures = Command.Textures;
        Batch.Options = Options;
        
        if Options.Viewport.x == -1.0 {
            Batch.Viewport = float4.{0, 0, 1366, 768};
        } else {
            Batch.Viewport = Options.Viewport;
        }
        
        if Options.Scissor.x == -1.0 {
            Batch.Scissor = float4.{0, 0, 1366, 768};
        } else {
            Batch.Scissor = Options.Scissor;
        }
        
        Batch.InstanceDataShadow = PushFixedArena(*RendererFrameArena, ibuffer_shadow, MAX_INSTANCES);
        Batch.InstanceDataMesh = PushFixedArena(*RendererFrameArena, ibuffer_mesh, MAX_INSTANCES);
        Batch.InstanceDataUnlit = PushFixedArena(*RendererFrameArena, ibuffer_unlit, MAX_INSTANCES);
        Batch.InstanceDataDebug = PushFixedArena(*RendererFrameArena, ibuffer_debug, MAX_INSTANCES);
        Batch.InstanceDataQuad = PushFixedArena(*RendererFrameArena, ibuffer_quad, MAX_INSTANCES);
        Batch.InstanceDataTextSDF = PushFixedArena(*RendererFrameArena, ibuffer_text_sdf, MAX_INSTANCES);
        Batch.Initialized = true;
    }
    
    Instance := Command.Instance;
    Shadow := ibuffer_shadow.{Instance.Transform};
    Mesh := ibuffer_mesh.{Instance.Transform, Instance.Colour, Instance.Params};
    Unlit := ibuffer_unlit.{Instance.Transform, Instance.Colour};
    Debug := ibuffer_debug.{Instance.Transform, Instance.Colour};
    Quad := ibuffer_quad.{Instance.PositionSize, Instance.Colour, Instance.TexCoords};
    TextSDF := ibuffer_text_sdf.{Instance.PositionSize, Instance.Colour, Instance.TexCoords, Instance.Params};
    
    ArenaPush(Batch.InstanceDataShadow, Shadow);
    ArenaPush(Batch.InstanceDataMesh, Mesh);
    ArenaPush(Batch.InstanceDataUnlit, Unlit);
    ArenaPush(Batch.InstanceDataDebug, Debug);
    ArenaPush(Batch.InstanceDataQuad, Quad);
    ArenaPush(Batch.InstanceDataTextSDF, TextSDF);
}