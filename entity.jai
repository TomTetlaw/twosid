
entity_handle :: struct {
    Index: int;
    Gen: int;
    TypeId: int;
}

entity_flags :: enum_flags {
    BLOCKING;
}

entity :: struct {
    using Handle: entity_handle;
    
    Active: bool;
    
    Flags: entity_flags;
    
    Position: float3;
    Rotation: quat;
    Scale := float3.{1, 1, 1};
    
    Bounds: bounding_box;
    
    MeshPath: string;
    Mesh: *mesh;
    AnimPlayer: anim_player;
    Textures: [] *texture;
    
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
    UpdateEntityDrawTransform(Entity, Entity.PositionAboveGround);
}

UpdateEntityBounds :: (Entity: *entity) {
    Bounds: bounding_box;
    
    if Entity.Mesh {
        Bounds = Entity.Mesh.Bounds;
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
    AreaExtents: random_value;
    AreaCenter: float3;
    WaitTime: random_value;
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
        UpdateRandomValue(*Patrol.AreaExtents);
        UpdateRandomValue(*Patrol.WaitTime);
        Patrol.WaitStartTime = GameTime;
        Patrol.State = .WAITING;
        Patrol.Started = true;
    }
    
    if Patrol.State == .WAITING {
        if GameTime - Patrol.WaitStartTime >= Patrol.WaitTime.Value {
            Patrol.State = .TRAVELLING;
            Patrol.Target = RandomFloat3(Patrol.AreaCenter - Patrol.AreaExtents.Value, Patrol.AreaCenter + Patrol.AreaExtents.Value);
        }
    }
    
    if Patrol.State == .TRAVELLING {
        if MoveEntityTowards(Entity, Patrol.Target, Patrol.TravelSpeed, Patrol.StopDistance, true) {
            Patrol.State = .WAITING;
            Patrol.WaitStartTime = GameTime;
            UpdateRandomValue(*Patrol.WaitTime);
        }
    }
    
    if Patrol.State == .FOLLOWING {
        F := GetEntity(Patrol.FollowTarget);
        
        if F {
            Target := F.Position;
            MoveEntityTowards(Entity, Target, Patrol.TravelSpeed, Patrol.StopDistance, true);
            
            if Distance(Entity.Position, Target) > Patrol.SightRadius {
                Patrol.State = .WAITING;
                Patrol.WaitStartTime = GameTime;
                UpdateRandomValue(*Patrol.WaitTime);
            }
        } else {
            Patrol.State = .WAITING;
            Patrol.WaitStartTime = GameTime;
            UpdateRandomValue(*Patrol.WaitTime);
        }
    }
    
    if Patrol.State != .FOLLOWING {
        for * :OnlyActiveEntities GEntities {
            if Distance(Entity, it.Position) < Patrol.SightRadius {
                Patrol.FollowTarget = it.Handle;
                Patrol.State = .FOLLOWING;
            }
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
    Entities := FindEntityTypeArena(T);
    if !Entities return null;
    
    Entity: *T;
    
    for * Entities {
        if it.Active continue;
        Entity = it;
    }
    
    if !Entity {
        Entity = ArenaPush(Entities);
        Entity.Index = Entities.Count - 1;
    }
    
    Entity.Gen += 1;
    Entity.Active = true;
    
    if Entity.MeshPath.count > 0 {
        Entity.Mesh = LoadMesh(Entity.MeshPath);
    }
    
    NextId += 1;
    
    return Entity;
}

RemoveEntity :: (Entity: *entity) {
    Entity.Active = false;
}

RemoveAllEntities :: () {
    ResetEntityArenas();
}

DrawEntity :: (Entity: *entity) {
    DrawOpaqueMesh(Entity.DrawTransform, Entity.Mesh, Entity.Textures, Entity.AnimPlayer.Pose.SkinningTransforms, .{1, 1, 1, 1}, Entity.Colour);
}

GetEntityList :: (TypeId: int) -> *entity_list {
    for EntityTypes.InfoList {
        if it.TypeId == TypeId return *it.List;
    }
    
    return null;
}

GetEntity :: (Handle: entity_handle) -> *entity {
    Entities := GetEntityList(Handle.TypeId);
    Entity := (<<Entities)[Handle.Index];
    if Entity.Gen != Handle.Gen return null;
    return Entity;
}

InitEntitySystem :: () {
    CreateEntityTypeInfo(*EntityArena, *EntityTypes);
}

AllocateEntity :: (List: *entity_list, $T: Type) -> *entity {
    Entity: *T;
    
    for * List {
        if !it.Active {
            Entity = it;
            Initialize(Entity);
        }
    }
    
    if !Entity Entity = ArenaPush(*List.Arena, T);
    
    AddToLinkedList(*List.List, Entity);
    
    return Entity;
}

operator [] :: (List: entity_list, Index: int) -> *entity {
    Entity := cast(*entity) (List.Arena.Base + (Num * List.TypeSize));
    if Entity.Active return Entity;
    return null;
}

for_expansion :: (List: *entity_list, Body: Code, Flags: For_Flags) #expand {
    for Entity, Index: List.List {
        if !Entity.Active continue;
        
        `it = Entity;
        `it_index := Index;
        
#insert Body;
    }
}

EntityTypes: entity_types;

entity_type_info :: struct {
    Name: string;
    TypeId: int;
    List: entity_list;
}

entity_list :: struct {
    Arena: arena;
    TypeSize: int;
    using List: linked_list(*entity);
}

#scope_file 

EntityArena: arena;

NextId: s32 = 0;