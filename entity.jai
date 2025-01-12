
entity_handle :: struct {
    Id: s32;
    Gen: s32;
}

entity_flags :: enum_flags {
    BLOCKING;
}

entity :: struct {
    using Handle: entity_handle;
    Active: bool;
    
    Flags: entity_flags; @v1;
    
    Position: float3; @v1;
    Rotation: quat; @v1;
    Scale := float3.{1, 1, 1}; @v1;
    
    Bounds: bounding_box; @v1;
    
    Mesh: *mesh;
    AnimPlayer: anim_player; @v1;
    Textures: [] *texture;
    
    Colour := float4.{1, 1, 1, 1}; @v1;
    DrawPosition: float3; @v1;
    DrawTransform: float4x4; @v1;
}

UpdateEntityDrawTransform :: (Entity: *entity) {
    UpdateEntityDrawTransform(Entity, Entity.DrawPosition, Entity.Rotation, Entity.Scale);
}

UpdateEntityDrawTransform :: (Entity: *entity, Position: float3, Rotation: quat, Scale: float3) {
    Entity.DrawTransform = TranslationMatrix(Position) * RotationMatrix(Rotation) * ScaleMatrix(Scale);
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
        if it.Id == Entity.Id continue;
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

PositionEntityAboveGround :: (Entity: *entity, HeightAboveGround: float) {
    GroundHeight := GetGroundHeight(Entity.Position);
    Height := GroundHeight + HeightAboveGround;
    Entity.DrawPosition = xyz(Entity.Position.xy, Height);
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
    
    if !Entity Entity = ArenaPush(Entities);
    
    Entity.Id = NextId;
    Entity.Gen += 1;
    Entity.Active = true;
    
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
    if !Entity.Active return;
    
    DrawOpaqueMesh(Entity.DrawTransform, Entity.Mesh, Entity.Textures, Entity.AnimPlayer.Pose.SkinningTransforms, .{1, 1, 1, 1}, Entity.Colour);
}

OnlyActiveEntities :: (Arena: *$A/arena, Body: Code, Flags: For_Flags) #expand {
    num := cast (int) (Arena.Used / size_of(A.T));
    
    for Index: 0..num-1 {
        ActualIndex := Index;
#if Flags & .REVERSE {
            ActualIndex = Num - 1 - Index;
        }
        
        Entity := *Arena.TypedBase[ActualIndex];
        if !Entity.Active continue;
        
#if Flags & .POINTER {
            `it := *Arena.TypedBase[ActualIndex];
        } else {
            `it := Arena.TypedBase[ActualIndex];
        }
        
        `it_index := ActualIndex;
        
#insert Body;
    }
}

entity_type_info :: struct {
    Name: string;
    T: Type;
    Arena: *void; // *void so we can cast it to the actual type (arena(T)) later
}

InitEntitySystem :: () {
    CreateEntityTypeInfo(*EntityTypes);
}

EntityTypes: entity_types;

#scope_file 

NextId: s32 = 0;

FindEntityTypeArena :: ($T: Type) -> *arena(T) {
    for EntityTypes.InfoList {
        if it.T == T return cast(*arena(T)) it.Arena;
    }
    
    return null;
}