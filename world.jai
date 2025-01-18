
WriteWorld :: () {
    F := file_open("terrain_settings.data", true);
    WriteTerrain(*F);
    file_close(*F);
    
    for GAllEntities {
        F := file_open(TFormat("world/%-%-%.entity", it.TypeName, it.Index, it.Gen), true);
        Write(*F, it.TypeName);
        WriteEntity(*F, it);
        file_close(*F);
    }
}

ReadWorld :: () {
    /*F := file_open("terrain_settings.data");
    ReadTerrain(*F);
    file_close(*F);*/
    
    RemoveAllEntities();
    
    EntityFiles := file_list("world", true);
    for EntityFiles {
        if !contains(it, ".entity") continue;
        
        F := file_open(it);
        
        TypeName: string;
        Read(*F, *TypeName);
        
        Entity := CreateEntityFromName(TypeName);
        ReadEntity(*F, Entity);
        
        if Entity.MeshPath.count > 0 {
            Entity._Mesh = LoadMesh(Entity.MeshPath);
        }
        
        for * Entity.Materials {
            it._Textures = ArenaAlloc(*WorldArena, *texture, it.TexturePaths.count);
            for T: it.TexturePaths {
                it._Textures[it_index] = LoadTexture(T);
            }
        }
        
        file_close(*F);
    }
}

WorldArena: arena;

#scope_file

#import "Basic";
#import "File";