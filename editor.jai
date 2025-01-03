
GColliders: [] *collider;

InitEditor :: () {
    PlayerStartMesh = LoadMesh("meshes/text_p.mesh");
    TextFont = LoadDistanceFont("fonts/consolas.png");
    Root = BuildUI();
    
    Transform.ArrowMesh = LoadMesh("meshes/arrow.mesh");
    Transform.ArrowMeshSquare = LoadMesh("meshes/arrow_square.mesh");
    Transform.PlaneMesh = LoadMesh("meshes/transform_plane.mesh");
    Transform.ArrowCollision = CreateCollisionMesh(*EditorArena, Transform.ArrowMesh);
    Transform.PlaneCollision = CreateCollisionMesh(*EditorArena, Transform.PlaneMesh);
}

SelectBox :: (Ray: ray) {
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
    GroundPos = Point;
    
    if KeyPressed(.SDL_SCANCODE_E) {
        SelectBox(MouseRay);
    }
    
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
        
        if SelectedCollider.Kind == .BOX {
            Collider := cast (*collider_box) SelectedCollider;
            if Mouse.LeftDown && Transform.Dragging {
                
                PlaneHit := RayPlaneIntersection(MouseRay, Transform.Plane);
                Displacement := PlaneHit.Point - Transform.DragStart;
                
                DebugVars(Transform.Plane, Displacement);
                
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
                
                Transform.DragStart = PlaneHit.Point;
            }
        }
    }
    
    if GIsUIOpen return;
    
    if KeyPressed(.SDL_SCANCODE_SPACE) {
        OpenUI(Root);
    }
    
    Selected := GetSelectedUINodeId();
    if Selected > 0 {
        if Selected == BoxId {
            Collider := ArenaPush(*EditorArena, collider_box);
            Collider.Box.Min = GroundPos - xyz(5.0);
            Collider.Box.Max = GroundPos + xyz(5.0);
            Collider.Box.Min += .{0, 0, 5};
            Collider.Box.Max += .{0, 0, 5};
            ArenaPush(*Colliders, Collider);
            GColliders = ArenaToView(*Colliders);
        }
        
        if Selected == CylinderId {
            Collider := ArenaPush(*EditorArena, collider_cylinder);
            Collider.Cylinder.Center = GroundPos;
            Collider.Cylinder.Axis = .{0, 0, 1};
            Collider.Cylinder.Radius = 3.0;
            Collider.Cylinder.Height = 6.0;
            ArenaPush(*Colliders, Collider);
            GColliders = ArenaToView(*Colliders);
        }
        
        if Selected >= EntityBaseId {
            Id := Selected - EntityBaseId;
            Entity := CreateEntityFromInfoIndex(Id);
            if Entity {
                Entity.Position = GroundPos;
            }
        }
    }
    
    if KeyPressed(.SDL_SCANCODE_P) {
        if Hit PlayerStart = GroundPos;
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
        } else {
            Transform.Dragging = false;
        }
    }
}

BuildUI :: () -> *select_node {
    BoxNode := UITextNode("Box", BoxId);
    CylinderNode := UITextNode("Cylinder", CylinderId);
    ColliderNode := UITextNode("Collider", Children=.[BoxNode, CylinderNode]);
    
    EntityNodes := ArenaPushN(*EditorArena, *select_node, EntityTypes.InfoList.count);
    for EntityTypes.InfoList {
        if equal(it.Name, "Player") continue;
        if equal(it.Name, "Prop") continue;
        EntityNodes[it_index] = UITextNode(it.Name, EntityBaseId + it_index);
    }
    
    BaseIndex := 0;
    SetCount := 1 + EntityNodes.count / 3;
    PrevMoreNode: *select_node;
    
    for #v2 < 0..SetCount-1 {
        BaseIndex := it*3;
        
        Children: [4] *select_node;
        if BaseIndex+2 < EntityNodes.count Children[0] = EntityNodes[it*3 + 2];
        if BaseIndex+1 < EntityNodes.count Children[1] = EntityNodes[it*3 + 1];
        if BaseIndex+0 < EntityNodes.count Children[2] = EntityNodes[it*3 + 0];
        if PrevMoreNode Children[3] = PrevMoreNode;
        
        PrevMoreNode = UITextNode("More...", Children=Children);
    }
    
    PrevMoreNode.Text = "Entity";
    
    AddNode := UITextNode("Add to level", Children=.[ColliderNode, PrevMoreNode]);
    
    return AddNode;
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
    
    DrawDebugSphere(GroundPos);
    
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

Root: *select_node;

FlyingCamera: camera_flying;

BoxId :: 1;
CylinderId :: 2;
EntityBaseId :: 1000;
PropId :: 3;

TextFont: *sdf_font;

GroundPos: float3;
MouseRay: ray;

EditorArena: arena;

Colliders: arena(*collider);
SelectedCollider: *collider;

CreatePlayerAtStart :: () {
    Player := CreateEntity(entity_player);
    Player.Position = PlayerStart;
}

PlayerStart: float3;
PlayerStartMesh: *mesh;