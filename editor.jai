
GColliders: [] *collider;

InitEditor :: () {
    PlayerStartMesh = LoadMesh("meshes/text_p.mesh");
}

UpdateEditor :: (Camera: *camera_flying) {
    if !GEditorOpen return;
    
    if KeyPressed(.SDL_SCANCODE_P) {
        Ray := GetRayFromCamera(Camera);
        Point, Hit := GetGroundPositionAlongRay(Ray);
        if Hit PlayerStart = Point;
    }
    
    if KeyPressed(.SDL_SCANCODE_C) {
        Ray := GetRayFromCamera(Camera);
        Point, Hit := GetGroundPositionAlongRay(Ray);
        if Hit {
            Collider := ArenaPush(*EditorArena, collider_box);
            Collider.Box.Min = Point - xyz(5.0);
            Collider.Box.Max = Point + xyz(5.0);
            ArenaPush(*Colliders, Collider);
        }
    }
}

DrawEditor :: () {
    if !GEditorOpen return;
    
    DrawDebugMesh(PlayerStart, PlayerStartMesh);
    
    for Colliders {
        if it.Kind == .BOX {
            Collider := cast (*collider_box) it;
            DrawBoundingBox(Collider.Box);
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

GEditorOpen := true;

#scope_file

EditorArena: arena;

Colliders: arena(*collider);

CreatePlayerAtStart :: () {
    Player := CreateEntity(entity_player);
    Player.CylinderAxis = .{0, 0, 1};
    Player.CylinderRadius = 3.0;
    Player.CylinderHeight = 6.0;
    
    Player.Position = PlayerStart;
}

PlayerStart: float3;
PlayerStartMesh: *mesh;