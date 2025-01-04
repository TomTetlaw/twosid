
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

SelectObject :: (Ray: ray) {
    Closest := FLOAT32_MAX;
    Index := -1;
    Position: float3;
    
    for Colliders {
        if it.Kind == .BOX {
            Collider := cast (*collider_box) it;
            Origin := (Collider.Box.Min + Collider.Box.Max) * .5;
            
            if RayIntersectsBox(Collider.Box, Ray) {
                D := Distance(Ray.Origin, Origin);
                if D < Closest {
                    Closest = D;
                    Index = it_index;
                    Position = Origin;
                }
            }
        }
        
        if it.Kind == .CYLINDER {
            Collider := cast (*collider_cylinder) it;
            
            if RayIntersectsCylinder(Collider.Cylinder, Ray) {
                D := Distance(Ray.Origin, Collider.Cylinder.Center);
                if D < Closest {
                    Closest = D;
                    Index = it_index;
                    Position = Collider.Cylinder.Center;
                }
            }
        }
    }
    
    if Index != -1 {
        SelectedCollider = Colliders[Index];
        Transform.Position = Position;
    } else {
        SelectedCollider = null;
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
    
    if SelectedCollider != null {
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
            
            if SelectedCollider.Kind == .BOX {
                Collider := cast (*collider_box) SelectedCollider;
                
                if TransformMode == {
                    case .TRANSLATE;
                    Collider.Box.Min += Displacement * Transform.Axis;
                    Collider.Box.Max += Displacement * Transform.Axis;
                    Origin := (Collider.Box.Min + Collider.Box.Max) * .5;
                    Transform.Position = Origin;
                    
                    case .SCALE;
                    Proj := Dot(Displacement, Transform.Axis);
                    ScaleFactor := 1.0 + Proj;
                    if (ScaleFactor == 0.0) ScaleFactor = 1.0;
                    Center := (Collider.Box.Min + Collider.Box.Max) * 0.5;
                    Extents := (Collider.Box.Max - Collider.Box.Min) * 0.5;
                    ScaledExtents := Extents * ScaleFactor * Transform.Axis;
                    ScaledExtents += (Extents * (xyz(1.0) - Transform.Axis));
                    Collider.Box.Min = Center - ScaledExtents;
                    Collider.Box.Max = Center + ScaledExtents;
                }
            } else if SelectedCollider.Kind == .CYLINDER {
                Collider := cast (*collider_cylinder) SelectedCollider;
                
                if TransformMode == {
                    case .TRANSLATE;
                    Collider.Cylinder.Center += Displacement * Transform.Axis;
                    Transform.Position = Collider.Cylinder.Center;
                    
                    case .SCALE;
                    Proj := Dot(Displacement, Transform.Axis);
                    ScaleFactor := 1.0 + Proj;
                    if (ScaleFactor == 0.0) ScaleFactor = 1.0;
                    
                    if Transform.Axis.x > 0 Collider.Cylinder.Radius *= ScaleFactor;
                    if Transform.Axis.y > 0 Collider.Cylinder.Radius *= ScaleFactor;
                    if Transform.Axis.z > 0 Collider.Cylinder.Height *= ScaleFactor;
                }
                
                Transform.DragStart = PlaneHit.Point;
            }
        }
    }
    
    ImmBeginWindow(.{50, 200}, "ADD TO LEVEL");
    
    if ImmBeginTree("Collider") {
        if ImmButton("Box") {
            Collider := ArenaPush(*EditorArena, collider_box);
            Collider.Box.Min = GroundPosCamera - xyz(5.0);
            Collider.Box.Max = GroundPosCamera + xyz(5.0);
            Collider.Box.Min += .{0, 0, 5};
            Collider.Box.Max += .{0, 0, 5};
            ArenaPush(*Colliders, Collider);
        }
        
        if ImmButton("Cylinder") {
            Collider := ArenaPush(*EditorArena, collider_cylinder);
            Collider.Cylinder.Center = GroundPosCamera;
            Collider.Cylinder.Axis = .{0, 0, 1};
            Collider.Cylinder.Radius = 3.0;
            Collider.Cylinder.Height = 6.0;
            ArenaPush(*Colliders, Collider);
            GColliders = ArenaToView(*Colliders);
        }
        
        ImmEndTree();
    }
    
    ImmSeperator();
    
    if ImmBeginTree("Entity") {
        for EntityTypes.InfoList {
            if ImmButton(it.Name) {
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
    
    if KeyPressed(.SDL_SCANCODE_P) {
        if Hit PlayerStart = GroundPosMouse;
    }
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
            
            if !Transform.Dragging SelectObject(MouseRay);
        } else {
            Transform.Dragging = false;
        }
    }
}

DrawTransform :: (Position: float3) {
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
    
    DrawTextSDF(.{50, 50 + 0*15}, TextFont, 16.0, "Space - add object, P - set player start, E - select, F5 - play");
    
    if SelectedCollider != null {
        DrawTextSDF(.{50, 50 + 1*15}, TextFont, 16.0, "Selected - box");
        
        TransformName := enum_names(transform_mode)[TransformMode];
        DrawTextSDF(.{50, 50 + 2*15}, TextFont, 16.0, tprint("TransformMode - %", TransformName));
        
        Collider := cast (*collider_box) SelectedCollider;
        Origin := (Collider.Box.Min + Collider.Box.Max) * .5;
        DrawTransform(Origin);
    }
    
    DrawDebugMesh(PlayerStart, PlayerStartMesh);
    
    for Colliders {
        Colour := float4.{1, 1, 1, 1};
        if it == SelectedCollider Colour = .{1, 0, 0, 1};
        
        if it.Kind == .BOX {
            Collider := cast (*collider_box) it;
            DrawBoundingBox(Collider.Box, Colour);
        }
        
        if it.Kind == .CYLINDER {
            Collider := cast (*collider_cylinder) it;
            DrawCylinder(Collider.Cylinder, Colour);
        }
    }
}

ToggleEditor :: () {
    if GEditorOpen {
        GColliders = ArenaToView(*Colliders);
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

BoxId :: 1;
CylinderId :: 2;
EntityBaseId :: 1000;
PropId :: 3;

TextFont: *sdf_font;

GroundPosMouse: float3;
MouseRay: ray;
GroundPosCamera: float3;
CameraRay: ray;

EditorArena: arena;

Colliders: arena(*collider);
SelectedCollider: *collider;

CreatePlayerAtStart :: () {
    Player := CreateEntity(entity_player);
    Player.Position = PlayerStart;
}

PlayerStart: float3;
PlayerStartMesh: *mesh;