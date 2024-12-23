
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