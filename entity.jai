
entity_handle :: struct {
    Index := -1;
    Gen := -1;
    TypeId := -1;
}

entity_flags :: enum_flags {
    BLOCKING;
}

material :: struct {
    TexturePaths: [] string;
    _Textures: [] *texture; @noserialize;
}

entity :: struct {
    Next, Prev: *entity;
    
    TypeName: string; @noserialize;
    
    using Handle: entity_handle; @noserialize;
    
    Active: bool; @noserialize;
    
    Flags: entity_flags;
    
    Position: float3;
    Rotation: quat;
    Scale := float3.{1, 1, 1};
    
    Bounds: bounding_box;
    
    MeshPath: string;
    TexturePaths: [] string;
    
    _Mesh: *mesh;
    Materials: [] material;
    
    AnimPlayer: anim_player;
    
    PositionAboveGround: float3;
    
    Colour := float4.{1, 1, 1, 1};
    DrawTransform: float4x4;
}

EntityLookAtEntity :: (Entity: *entity, Target: *entity) {
    Dir := Normalize(Entity.Position - Target.Position);
    Entity.Rotation = QuatFromForward(Dir, .25); // @entity mesh forward
}

MoveEntityTowards :: (Entity: *entity, Target: float3, Speed: float, StopDistance := -1.0, LookForward := false) -> bool {
    if StopDistance == -1 {
        StopDistance = Length(Entity.Bounds.Max - Entity.Bounds.Min);
    }
    
    Dist := Distance(Entity.Position, Target);
    if Dist <= StopDistance return true;
    
    Dir := Normalize(Target - Entity.Position);
    Entity.Position += Dir * Speed * DeltaTime;
    
    if LookForward {
        Entity.Rotation = QuatFromForward(-Dir, .25); // @entity mesh forward
    }
    
    return false;
}

UpdateEntityDrawTransform :: (Entity: *entity, DrawPosition: float3) {
    Entity.DrawTransform = TranslationMatrix(DrawPosition) * RotationMatrix(Entity.Rotation) * ScaleMatrix(Entity.Scale);
}

UpdateEntityDrawTransform :: (Entity: *entity) {
    if GEditorOpen UpdateEntityDrawTransform(Entity, Entity.Position);
    else UpdateEntityDrawTransform(Entity, Entity.PositionAboveGround);
}

UpdateEntityBounds :: (Entity: *entity) {
    Bounds: bounding_box;
    
    if Entity._Mesh {
        Bounds = Entity._Mesh.Bounds;
    } else {
        Bounds = .{xyz(-1), xyz(1)};
    }
    
    Origin := (Bounds.Min + Bounds.Max) * .5;
    Extents := (Bounds.Max - Bounds.Min) * .5;
    
    Entity.Bounds.Min = Entity.Position + Origin - (Extents * Entity.Scale);
    Entity.Bounds.Max = Entity.Position + Origin + (Extents * Entity.Scale);
}

entity_physics :: struct {
    Velocity: float3;
    GoalVelocity: float3;
    
    AccelTime := 1.0;
}

IntegrateEntityPhysics :: (Entity: *entity, P: *entity_physics) {
    P.Velocity = Approach(P.Velocity, P.GoalVelocity, P.AccelTime);
    Entity.Position = Entity.Position + P.Velocity * DeltaTime;
}

entity_collision :: struct {
    CylinderAxis: float3;
    CylinderRadius, CylinderHeight: float;
}

HandleEntityMovementCollision :: (Entity: *entity, C: *entity_collision) {
    
    ClosestPointOnSegment :: (P: float3, A: float3, B: float3) -> float3 {
        AB := B - A;
        T := Dot(P - A, AB) / Dot(AB, AB);
        T = Max(0, Min(1.0, T));
        return A + AB * T;
    }
    
    for GAllEntities {
        if it == Entity continue;
        if !(it.Flags & .BLOCKING) continue;
        
        Box := it.Bounds;
        Position := xyz(Entity.Position.xy, 0);
        
        Base := Position - (C.CylinderAxis * C.CylinderHeight * .5);
        Top := Position + (C.CylinderAxis * C.CylinderHeight * .5);
        
        ClampedBase := Clamp(Base, Box.Min, Box.Max);
        ClampedTop := Clamp(Top, Box.Min, Box.Max);
        
        ClosestPoint := ClosestPointOnSegment(ClampedBase, Base, Top);
        Delta := ClosestPoint - ClampedBase;
        D := Dot(Delta, Delta);
        
        R := C.CylinderRadius;
        if D <= R*R {
            CollisionNormal := Normalize(Delta);
            Depth := R - SquareRoot(D);
            
            Entity.Position = Entity.Position + (CollisionNormal * Depth);
        }
        
        /*
            Collider := cast (*collider_cylinder) it;
            Cylinder := Collider.Cylinder;
            
            Position := xyz(Entity.Position.xy, 0);
            
            Delta := Position - Cylinder.Center;
            
            DistanceA := Dot(Delta, C.CylinderAxis);
            ClosestPointA := Position - C.CylinderAxis * (DistanceA - C.CylinderHeight * 0.5);
            
            DistanceB := Dot(Delta, Cylinder.Axis);
            ClosestPointB := Cylinder.Center - Cylinder.Axis * DistanceB;
            
            DeltaClosest := ClosestPointA - ClosestPointB;
            
            D := Dot(DeltaClosest, DeltaClosest);
            
            Combined := C.CylinderRadius + Cylinder.Radius;
            if D <= Combined * Combined {
                CollisionNormal := Normalize(DeltaClosest);
                Depth := Combined - SquareRoot(D);
                
                Entity.Position = Entity.Position + (CollisionNormal * Depth);
            }*/
    }
}

patrol_state :: enum {
    TRAVELLING;
    WAITING;
    FOLLOWING;
}

entity_patrol :: struct {
    State: patrol_state;
    AreaExtents: float;
    AreaCenter: float3;
    WaitTime: float;
    WaitStartTime: float;
    Target: float3;
    Started: bool;
    
    SightRadius := 50.0;
    FollowTarget: entity_handle;
    
    StopDistance := -1.0;
    TravelSpeed := 5.0;
    FollowSpeed := 10.0;
}

EntityPatrol :: (Entity: *entity, Patrol: *entity_patrol) {
    if !Patrol.Started {
        Patrol.WaitStartTime = GameTime;
        Patrol.State = .WAITING;
        Patrol.Started = true;
    }
    
    StartTravel :: (Patrol: *entity_patrol) {
        Patrol.State = .TRAVELLING;
        Patrol.Target = RandomFloat3(Patrol.AreaCenter - Patrol.AreaExtents, Patrol.AreaCenter + Patrol.AreaExtents);
    }
    
    StartWait :: (Patrol: *entity_patrol) {
        Patrol.State = .WAITING;
        Patrol.WaitStartTime = GameTime;
    }
    
    StartFollow :: (Patrol: *entity_patrol, Following: *entity) {
        Patrol.FollowTarget = Following.Handle;
        Patrol.State = .FOLLOWING;
    }
    
    if Patrol.State == .WAITING {
        if GameTime - Patrol.WaitStartTime >= Patrol.WaitTime {
            StartTravel(Patrol);
        }
    }
    
    if Patrol.State == .TRAVELLING {
        if MoveEntityTowards(Entity, Patrol.Target, Patrol.TravelSpeed, Patrol.StopDistance, true) {
            StartWait(Patrol);
        }
    }
    
    if Patrol.State == .FOLLOWING {
        Following := GetEntity(Patrol.FollowTarget);
        
        if Following {
            MoveEntityTowards(Entity, Following.Position, Patrol.FollowSpeed, Patrol.StopDistance, true);
        }
        
        if Distance(Entity.Position, Following.Position) > Patrol.SightRadius {
            StartWait(Patrol);
        }
    }
    
    if Patrol.State != .FOLLOWING && GPlayer {
        D := Distance(Entity.Position, GPlayer.Position);
        if D < Patrol.SightRadius {
            StartFollow(Patrol, GPlayer);
        }
    }
}

PositionEntityAboveGround :: (Entity: *entity, HeightAboveGround := 0.0) {
    GroundHeight := GetGroundHeight(Entity.Position);
    Height := GroundHeight + HeightAboveGround;
    Entity.PositionAboveGround = xyz(Entity.Position.xy, Height);
}

UpdateEntityAnimation :: (Entity: *entity) {
    AnimUpdate(*Entity.AnimPlayer);
}

CreateEntity :: ($T: Type) -> *T {
    TypeId := EntityTypeId(T);
    
    Info := GetEntityTypeInfo(TypeId);
    if !Info return null;
    
    Entity := AllocateEntity(Info, T);
    Entity.TypeName = Info.Name;
    Entity.TypeId = TypeId;
    Entity.Gen += 1;
    Entity.Active = true;
    
    if Entity.MeshPath.count > 0 {
        Entity._Mesh = LoadMesh(Entity.MeshPath);
    }
    
    return cast (*T) Entity;
}

DownCast :: (Entity: *entity, $T: Type) -> *T {
    if Entity.TypeId != EntityTypeId(T) return null;
    return cast (*T) Entity;
}

RemoveEntity :: (Entity: *entity) {
    Entity.Active = false;
}

RemoveAllEntities :: () {
    for GEntityTypes.InfoList {
        ResetArena(*it.Arena);
    }
}

DrawEntity :: (Entity: *entity) {
    DrawOpaqueMesh(Entity.DrawTransform, Entity._Mesh, .[], Entity.AnimPlayer.Pose.SkinningTransforms, .{1, 1, 1, 1}, Entity.Colour);
}

GetEntityTypeInfo :: (TypeId: int) -> *entity_type_info {
    for GEntityTypes.InfoList {
        if it.TypeId == TypeId return it;
    }
    
    return null;
}

GetEntityTypeInfo :: (Name: string) -> *entity_type_info {
    for GEntityTypes.InfoList {
        if equal(it.Name, Name) return it;
    }
    
    return null;
}

GetEntity :: (Handle: entity_handle) -> *entity {
    if Handle.Index == -1 return null;
    
    TypeInfo := GetEntityTypeInfo(Handle.TypeId);
    Entity := GetEntityFromList(TypeInfo, Handle.Index);
    
    if !Entity return null;
    if Entity.Gen != Handle.Gen return null;
    
    return Entity;
}

InitEntitySystem :: () {
    BuildEntityTypeList(*EntityArena);
}

UpdateEntitySystem :: () {
    Mark := GetArenaMark(*FrameArena);
    
    for Info: GEntityTypes.InfoList {
        for Info {
            PushToArena(*FrameArena, it);
        }
    }
    
    GAllEntities = ArenaToView(*FrameArena, *entity, Mark);
}

AllocateEntity :: (Info: *entity_type_info, $T: Type) -> *entity {
    Entity: *T;
    
    for Info {
        if !it.Active {
            Entity = cast(*T) it;
            Initialize(Entity);
        }
    }
    
    if !Entity {
        Index := xx GetArenaMark(*Info.Arena) / Info.TypeSize;
        Entity = ArenaAlloc(*Info.Arena, T);
        Entity.Index = Index;
    }
    
    AddToLinkedList(*Info.List, Entity);
    
    return Entity;
}

GetEntityFromList :: (Info: *entity_type_info, Index: int) -> *entity {
    Entity := cast(*entity) (Info.Arena.Base + (Index * Info.TypeSize));
    return Entity;
}

for_expansion :: (Info: *entity_type_info, Body: Code, Flags: For_Flags) #expand {
    for *`it, `it_index: Info.List {
        if !it.Active continue;
        
#insert Body;
    }
}

GAllEntities: [] *entity;

GEntityTypes: entity_types;

entity_type_info :: struct {
    Name: string;
    TypeId: int;
    Arena: arena;
    TypeSize: int;
    using List: linked_list(entity);
    
}

#scope_file 

EntityArena: arena;