
GColliders: [] *collider;

InitEditor :: () {
    PlayerStartMesh = LoadMesh("meshes/text_p.mesh");
    TextFont = LoadDistanceFont("fonts/consolas.png");
    
    Transform.ArrowMesh = LoadMesh("meshes/arrow.mesh");
    Transform.ArrowMeshSquare = LoadMesh("meshes/arrow_square.mesh");
    Transform.PlaneMesh = LoadMesh("meshes/transform_plane.mesh");
    Transform.ArrowCollision = CreateCollisionMesh(*EditorArena, Transform.ArrowMesh);
    Transform.PlaneCollision = CreateCollisionMesh(*EditorArena, Transform.PlaneMesh);
}

TrySelectEntity :: (Ray: ray) {
    Closest := FLOAT32_MAX;
    Index := -1;
    Position: float3;
    
    for GAllEntities {
        if RayIntersectsBox(it.Bounds, Ray) {
            D := Distance(Ray.Origin, it.Position);
            if D < Closest {
                Closest = D;
                Index = it_index;
                Position = it.Position;
            }
        }
    }
    
    if Index != -1 {
        SelectedEntity = GAllEntities[Index];
        Transform.Position = Position;
    } else {
        SelectedEntity = null;
    }
}

UpdateEditor :: () {
    if !GEditorOpen return;
    
    UpdateCameraFlying(*FlyingCamera);
    
    MouseRay = GetRayForMousePosition(FlyingCamera.ViewParameters, Mouse.Position);
    Point, Hit := GetGroundPositionAlongRay(MouseRay);
    GroundPosMouse = Point;
    
    CameraRay = GetRayFromCamera(*FlyingCamera);
    Point, Hit = GetGroundPositionAlongRay(CameraRay);
    GroundPosCamera = Point;
    
    if SelectedEntity != null {
        D := Distance(Transform.Position, FlyingCamera.Position);
        S := Max(1.0, D / 50.0);
        
        Transform.TransformX = TranslationMatrix(Transform.Position) * ScaleMatrix(xyz(S));
        Transform.TransformY = TranslationMatrix(Transform.Position) *
            RotationMatrix(QuatFromAxisAngle(.{0, 0, 1}, .25)) * ScaleMatrix(xyz(S));
        Transform.TransformZ = TranslationMatrix(Transform.Position) *
            RotationMatrix(QuatFromAxisAngle(.{0, 1, 0}, .75)) * ScaleMatrix(xyz(S));
        
        Transform.TransformXY = TranslationMatrix(Transform.Position) * ScaleMatrix(xyz(S*3));
        Transform.TransformXZ = TranslationMatrix(Transform.Position) *
            RotationMatrix(QuatFromAxisAngle(.{1, 0, 0}, .25)) * ScaleMatrix(xyz(S*3));
        Transform.TransformYZ = TranslationMatrix(Transform.Position) *
            RotationMatrix(QuatFromAxisAngle(.{0, 1, 0}, .75)) * ScaleMatrix(xyz(S*3));
        
        Transform.HitX = RayMeshIntersection(MouseRay, Transform.ArrowCollision, Transform.TransformX);
        Transform.HitY = RayMeshIntersection(MouseRay, Transform.ArrowCollision, Transform.TransformY);
        Transform.HitZ = RayMeshIntersection(MouseRay, Transform.ArrowCollision, Transform.TransformZ);
        
        Transform.HitXY = RayMeshIntersection(MouseRay, Transform.PlaneCollision, Transform.TransformXY);
        Transform.HitXZ = RayMeshIntersection(MouseRay, Transform.PlaneCollision, Transform.TransformXZ);
        Transform.HitYZ = RayMeshIntersection(MouseRay, Transform.PlaneCollision, Transform.TransformYZ);
        
        if KeyPressed(.SDL_SCANCODE_T) {
            TransformMode = .TRANSLATE;
        }
        if KeyPressed(.SDL_SCANCODE_Y) {
            TransformMode = .SCALE;
        }
        
        if Mouse.LeftDown && Transform.Dragging {
            PlaneHit := RayPlaneIntersection(MouseRay, Transform.Plane);
            Displacement := PlaneHit.Point - Transform.DragStart;
            
            if TransformMode == {
                case .TRANSLATE;
                SelectedEntity.Position += Displacement;
                Transform.Position = SelectedEntity.Position;
                
                case .SCALE;
                Proj := Dot(Displacement, Transform.Axis);
                ScaleFactor := 1.0 + Proj;
                if (ScaleFactor == 0.0) ScaleFactor = 1.0;
                SelectedEntity.Scale *= ScaleFactor;
            }
            
            Transform.DragStart = PlaneHit.Point;
        }
    }
    
    if KeyPressed(.SDL_SCANCODE_P) {
        if Hit PlayerStart = GroundPosMouse;
    }
}

EditorUI :: () {
    ImmBeginWindow(.{50, 200}, "Add to level", .{MaxHeight=500});
    
    if ImmBeginTree("Collider") {
        if ImmButton("Box") {
            CreateCollider(GroundPosCamera);
        }
        
        ImmEndTree();
    }
    
    ImmSeperator();
    
    if ImmBeginTree("Prop") {
        Files := file_list("meshes");
        for Files {
            if contains(it, ".mesh_text") continue;
            
            if contains(it, ".mesh") && ImmButton(it, Id=it_index) {
                print("Creating prop % at %\n", it, GroundPosCamera);
                
                CreateProp(it, GroundPosCamera);
            }
        }
        ImmEndTree();
    }
    
    ImmSeperator();
    
    if ImmBeginTree("Entity") {
        for EntityTypes.InfoList {
            if equal(it.Name, "Player") continue;
            if equal(it.Name, "Prop") continue;
            if equal(it.Name, "Collider") continue;
            
            if ImmButton(it.Name, Id=it_index) {
                Entity := CreateEntityFromName(it.Name);
                if Entity {
                    Entity.Position = GroundPosCamera;
                }
            }
        }
        
        ImmEndTree();
    }
    
    ImmSeperator();
    
    ImmEndWindow();
}

ChoosePlaneForDragAxis :: (Axis: transform_axis) -> plane {
    Normal := MouseRay.Direction;
    
    if Axis == {
        case .X;
        D := Length(Transform.Position * Transform.Axis);
        return .{0, Normal.y, Normal.z, D};
        case .Y;
        D := Length(Transform.Position * Transform.Axis);
        return .{Normal.x, 0, Normal.z, D};
        case .Z;
        D := Length(Transform.Position * Transform.Axis);
        return .{Normal.x, Normal.y, 0, D};
        
        case .XY;
        D := Length(Transform.Position * float3.{0, 0, 1});
        return .{0, 0, 1, D};
        case .XZ;
        D := Length(Transform.Position * float3.{0, 1, 0});
        return .{0, 1, 0, D};
        case .YZ;
        D := Length(Transform.Position * float3.{1, 0, 0});
        return .{1, 0, 0, D};
    }
    
    return .{};
}

transform_axis :: enum {
    X;
    Y;
    Z;
    XY;
    XZ;
    YZ;
}

EditorMouseInput :: (Button: s32, Down: bool) {
    if Button == SDL_BUTTON_LEFT {
        if Down {
            Transform.HitX = RayMeshIntersection(MouseRay, Transform.ArrowCollision, Transform.TransformX);
            Transform.HitY = RayMeshIntersection(MouseRay, Transform.ArrowCollision, Transform.TransformY);
            Transform.HitZ = RayMeshIntersection(MouseRay, Transform.ArrowCollision, Transform.TransformZ);
            
            Transform.HitXY = RayMeshIntersection(MouseRay, Transform.PlaneCollision, Transform.TransformXY);
            Transform.HitXZ = RayMeshIntersection(MouseRay, Transform.PlaneCollision, Transform.TransformXZ);
            Transform.HitYZ = RayMeshIntersection(MouseRay, Transform.PlaneCollision, Transform.TransformYZ);
            
            if Transform.HitX.Intersected {
                Transform.Dragging = true;
                Transform.Axis = .{1, 0, 0};
                
                Transform.Plane = ChoosePlaneForDragAxis(.X);
                Transform.DragStart = RayPlaneIntersection(MouseRay, Transform.Plane).Point;
            }
            if Transform.HitY.Intersected {
                Transform.Dragging = true;
                Transform.Axis = .{0, 1, 0};
                
                Transform.Plane = ChoosePlaneForDragAxis(.Y);
                Transform.DragStart = RayPlaneIntersection(MouseRay, Transform.Plane).Point;
            }
            if Transform.HitZ.Intersected {
                Transform.Dragging = true;
                Transform.Axis = .{0, 0, 1};
                
                Transform.Plane = ChoosePlaneForDragAxis(.Z);
                Transform.DragStart = RayPlaneIntersection(MouseRay, Transform.Plane).Point;
            }
            
            if Transform.HitXY.Intersected {
                Transform.Dragging = true;
                Transform.Axis = .{1, 1, 0};
                
                Transform.Plane = ChoosePlaneForDragAxis(.XY);
                Transform.DragStart = RayPlaneIntersection(MouseRay, Transform.Plane).Point;
            }
            if Transform.HitXZ.Intersected {
                Transform.Dragging = true;
                Transform.Axis = .{1, 0, 1};
                
                Transform.Plane = ChoosePlaneForDragAxis(.XZ);
                Transform.DragStart = RayPlaneIntersection(MouseRay, Transform.Plane).Point;
            }
            if Transform.HitYZ.Intersected {
                Transform.Dragging = true;
                Transform.Axis = .{0, 1, 1};
                
                Transform.Plane = ChoosePlaneForDragAxis(.YZ);
                Transform.DragStart = RayPlaneIntersection(MouseRay, Transform.Plane).Point;
            }
            
            if !Transform.Dragging TrySelectEntity(MouseRay);
        } else {
            Transform.Dragging = false;
        }
    }
}

DrawTransform :: () {
    ColourX := float4.{1, 0, 0, 1};
    ColourY := float4.{0, 1, 0, 1};
    ColourZ := float4.{0, 0, 1, 1};
    
    if Transform.HitX.Intersected ColourX = float4.{1, 1, 1, 1};
    if Transform.HitY.Intersected ColourY = float4.{1, 1, 1, 1};
    if Transform.HitZ.Intersected ColourZ = float4.{1, 1, 1, 1};
    
    Mesh := Transform.ArrowMesh;
    if TransformMode == .SCALE {
        Mesh = Transform.ArrowMeshSquare;
    }
    
    DrawMesh(Transform.TransformX, Mesh, ColourX);
    DrawMesh(Transform.TransformY, Mesh, ColourY);
    DrawMesh(Transform.TransformZ, Mesh, ColourZ);
    
    ColourXY := float4.{1, 0, 0, 1};
    ColourXZ := float4.{0, 1, 0, 1};
    ColourYZ := float4.{0, 0, 1, 1};
    
    if Transform.HitXY.Intersected ColourXY = float4.{1, 1, 1, 1};
    if Transform.HitXZ.Intersected ColourXZ = float4.{1, 1, 1, 1};
    if Transform.HitYZ.Intersected ColourYZ = float4.{1, 1, 1, 1};
    
    DrawMesh(Transform.TransformXY, Transform.PlaneMesh, ColourXY);
    DrawMesh(Transform.TransformXZ, Transform.PlaneMesh, ColourXZ);
    DrawMesh(Transform.TransformYZ, Transform.PlaneMesh, ColourYZ);
}

DrawEditor :: () {
    if !GEditorOpen return;
    
    DrawTextSDF(.{50, 50 + 0*15}, TextFont, 16.0, "P - set player start, Click - select, F5 - play");
    
    if SelectedEntity != null {
        DrawTextSDF(.{50, 50 + 1*15}, TextFont, 16.0, "Selected - entity");
        
        TransformName := enum_names(transform_mode)[TransformMode];
        DrawTextSDF(.{50, 50 + 2*15}, TextFont, 16.0, TFormat("TransformMode - %", TransformName));
        
        DrawTransform();
    }
    
    for * :OnlyActiveEntities EntityTypes.Collider {
        if SelectedEntity && it.Id == SelectedEntity.Id continue;
        
        DrawBoundingBox(it.Bounds);
    }
    
    if SelectedEntity {
        Colour := Lerp(xyzw(1), float4.{1, 0, 0, 1}, SinTurns(Mod(RealTime, 1.0)) * .5 + .5);
        DrawBoundingBox(SelectedEntity.Bounds, Colour);
    }
    
    DrawDebugMesh(PlayerStart, PlayerStartMesh);
}

ToggleEditor :: () {
    if GEditorOpen {
        GEditorOpen = false;
        CreatePlayerAtStart();
        GamePaused = false;
    } else {
        GEditorOpen = true;
        RemoveAllEntities();
    }
    
    GamePaused = GEditorOpen;
}

GetEditorViewParams :: () -> view_parameters {
    return FlyingCamera.ViewParameters;
}

GEditorOpen := true;

#scope_file

transform_mode :: enum {
    TRANSLATE;
    SCALE;
}

TransformMode := transform_mode.TRANSLATE;

transform_widget :: struct {
    Position: float3;
    
    Plane: plane;
    Axis: float3;
    Dragging: bool;
    DragStart: float3;
    
    ArrowMesh: *mesh;
    ArrowMeshSquare: *mesh;
    ArrowCollision: collision_mesh;
    TransformX: float4x4;
    TransformY: float4x4;
    TransformZ: float4x4;
    HitX, HitY, HitZ: ray_hit;
    
    PlaneMesh: *mesh;
    PlaneCollision: collision_mesh;
    TransformXY: float4x4;
    TransformXZ: float4x4;
    TransformYZ: float4x4;
    HitXY, HitXZ, HitYZ: ray_hit;
}

Transform: transform_widget;

FlyingCamera: camera_flying;

TextFont: *sdf_font;

SelectedEntity: *entity;

GroundPosMouse: float3;
MouseRay: ray;
GroundPosCamera: float3;
CameraRay: ray;

EditorArena: arena;

CreatePlayerAtStart :: () {
    Player := CreateEntity(entity_player);
    Player.Position = PlayerStart;
}

PlayerStart: float3;
PlayerStartMesh: *mesh;