
entity_handle :: struct {
    Id: s32;
    Gen: s32;
}

entity :: struct {
    using Handle: entity_handle;
    Active: bool;
    
    Flags: entity_flags;
    
    Position: float3;
    
    Mesh: *mesh;
    AnimPlayer: anim_player;
    Textures: [] *texture;
    
    Colour := float4.{1, 1, 1, 1};
    DrawPosition: float3;
}

entity_physics :: struct {
    Velocity: float3;
    GoalVelocity: float3;
    
    AccelDecay := 16.0;
    AccelSpeed := 1.0;
}

IntegrateEntityPhysics :: (Entity: *entity, P: *entity_physics) {
    P.Velocity = Approach(P.Velocity, P.GoalVelocity, P.AccelDecay, DeltaTime * P.AccelSpeed);
    Entity.Position = Entity.Position + P.Velocity * DeltaTime;
}

entity_collision :: struct {
    CylinderAxis: float3;
    CylinderRadius, CylinderHeight: float;
}

collider_kind :: enum {
    BOX;
    CYLINDER;
}

collider :: struct {
    Kind: collider_kind;
}

collider_box :: struct {
    using #as Base: collider;
    Box: bounding_box;
}

collider_cylinder :: struct {
    using #as Base: collider;
    Cylinder: cylinder;
}

HandleEntityMovementCollision :: (Entity: *entity, C: *entity_collision, Colliders: [] *collider) {
    
    ClosestPointOnSegment :: (P: float3, A: float3, B: float3) -> float3 {
        AB := B - A;
        T := Dot(P - A, AB) / Dot(AB, AB);
        T = Max(0, Min(1.0, T));
        return A + AB * T;
    }
    
    for Colliders {
        if it.Kind == .BOX {
            Collider := cast (*collider_box) it;
            Box := Collider.Box;
            
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
        } else if it.Kind == .CYLINDER {
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
            }
        }
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

entity_flags :: enum_flags {
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

DrawEntity :: (Entity: *entity) {
    Command: draw_command_mesh;
    Command.Flags = 0;
    Command.Mesh = Entity.Mesh;
    Command.SkinningTransforms = Entity.AnimPlayer.Pose.SkinningTransforms;
    Command.Textures = Entity.Textures;
    Command.Instance.Transform = TranslationMatrix(Entity.DrawPosition);
    Command.Instance.DiffuseColour = Entity.Colour;
    Command.Instance.MaterialParams = .{1, 1, 1, 1};
    AddDrawCommand(*Command);
}

entity_type_info :: struct {
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