
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
    
    if SelectedEntity && KeyPressed(.SDL_SCANCODE_DELETE) {
        RemoveEntity(SelectedEntity);
        SelectedEntity = null;
    }
    
    if SelectedEntity != null {
        D := Distance(Transform.Position, FlyingCamera.Position);
        S := Max(1.0, D / 50.0) * .5;
        
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
                SelectedEntity.Position += Displacement*Transform.Axis;
                Transform.Position = SelectedEntity.Position;
                
                case .SCALE;
                Proj := Dot(Displacement, Transform.Axis);
                ScaleFactor := 1.0 + Proj;
                if (ScaleFactor == 0.0) ScaleFactor = 1.0;
                Scale := Max(ScaleFactor * Transform.Axis, .{1, 1, 1});
                SelectedEntity.Scale *= Scale;
            }
            
            Transform.DragStart = PlaneHit.Point;
        }
    }
    
    if KeyPressed(.SDL_SCANCODE_P) {
        if Hit PlayerStart = GroundPosMouse;
    }
}

EditorUI :: () {
    if !GEditorOpen return;
    
    ImmBeginWindow(.{10, 200}, "Add to level", .{MaxHeight=200});
    
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
    Normal: float3;
    
    R := MouseRay.Direction;
    if Axis == {
        case .X;
        Normal = .{0, R.y, R.z};
        case .Y;
        Normal = .{R.x, 0, R.z};
        case .Z;
        Normal = .{R.x, R.y, 0};
        
        case .XY;
        Normal = .{0, 0, 1};
        case .XZ;
        Normal = .{0, 1, 0};
        case .YZ;
        Normal = .{1, 0, 0};
    }
    
    return PlaneFromNormalAndPoint(Normal, Transform.Position);
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
    TransformAlpha := 1.0;
    
    ColourX := float4.{1, 0, 0, TransformAlpha};
    ColourY := float4.{0, 1, 0, TransformAlpha};
    ColourZ := float4.{0, 0, 1, TransformAlpha};
    
    if Transform.HitX.Intersected ColourX = float4.{1, 1, 1, TransformAlpha};
    if Transform.HitY.Intersected ColourY = float4.{1, 1, 1, TransformAlpha};
    if Transform.HitZ.Intersected ColourZ = float4.{1, 1, 1, TransformAlpha};
    
    Mesh := Transform.ArrowMesh;
    if TransformMode == .SCALE {
        Mesh = Transform.ArrowMeshSquare;
    }
    
    DrawUnlitMesh(Transform.TransformX, Mesh, ColourX);
    DrawUnlitMesh(Transform.TransformY, Mesh, ColourY);
    DrawUnlitMesh(Transform.TransformZ, Mesh, ColourZ);
    
    ColourXY := float4.{1, 0, 0, TransformAlpha};
    ColourXZ := float4.{0, 1, 0, TransformAlpha};
    ColourYZ := float4.{0, 0, 1, TransformAlpha};
    
    if Transform.HitXY.Intersected ColourXY = float4.{1, 1, 1, TransformAlpha};
    if Transform.HitXZ.Intersected ColourXZ = float4.{1, 1, 1, TransformAlpha};
    if Transform.HitYZ.Intersected ColourYZ = float4.{1, 1, 1, TransformAlpha};
    
    DrawUnlitMesh(Transform.TransformXY, Transform.PlaneMesh, ColourXY);
    DrawUnlitMesh(Transform.TransformXZ, Transform.PlaneMesh, ColourXZ);
    DrawUnlitMesh(Transform.TransformYZ, Transform.PlaneMesh, ColourYZ);
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
    
    if SelectedEntity {
        Colour := Lerp(xyzw(xyz(1), 0.125), float4.{1, 0, 0, 0.125}, Mod(RealTime, 1.0));
        DebugDrawMesh(SelectedEntity.Mesh, SelectedEntity.DrawTransform, Colour);
        
        DrawTextSDF(.{50, 50 + 3*15}, TextFont, 16.0, TFormat("Transform Axis - %", Transform.Axis));
        DrawTextSDF(.{50, 50 + 4*15}, TextFont, 16.0, TFormat("Position - %", SelectedEntity.Position));
        DrawTextSDF(.{50, 50 + 5*15}, TextFont, 16.0, TFormat("Rotation - %", SelectedEntity.Rotation));
        DrawTextSDF(.{50, 50 + 6*15}, TextFont, 16.0, TFormat("Scale - %", SelectedEntity.Scale));
    }
    
    DebugDrawMesh(PlayerStartMesh, PlayerStart);
}

ToggleEditor :: () {
    if GEditorOpen {
        SelectedEntity = null;
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