
anim_player :: struct {
    Mesh: *mesh;
    Anim: *animation;
    
    Playing: bool;
    AnimTime: float;
    Pose: anim_pose;
    
    Fps := 30;
}

anim_pose :: struct {
    BoneNames: [] string;
    ModelSpaceTransforms: [] float4x4;
    ParentModelSpaceTransforms: [] float4x4;
    SkinningTransforms: [] float4x4;
}

CreateAnimPlayer :: (Mesh: *mesh, Anim: *animation) -> anim_player {
    Player: anim_player;
    Player.Mesh = Mesh;
    Player.Anim = Anim;
    Player.Pose.BoneNames = Anim.BoneNames;
    
    Player.Pose.ParentModelSpaceTransforms = ArenaPushN(*AnimArena, float4x4, xx Anim.BoneCount);
    Player.Pose.ModelSpaceTransforms = ArenaPushN(*AnimArena, float4x4, xx Anim.BoneCount);
    Player.Pose.SkinningTransforms = ArenaPushN(*AnimArena, float4x4, xx Anim.BoneCount);
    
    return Player;
}

AnimPlay :: (Player: *anim_player) {
    Player.AnimTime = 0;
    Player.Playing = true;
}

AnimStop :: (Player: *anim_player) {
    Player.Playing = false;
}

AnimUpdate :: (Player: *anim_player) {
    if !Player.Playing return;
    
    Pose := Player.Pose;
    Mesh := Player.Mesh;
    Anim := Player.Anim;
    
    Player.AnimTime += DeltaTime * Player.Fps;
    Player.AnimTime = fmod_cycling(Player.AnimTime, xx Anim.SampleCount);
    FrameIndex := cast(int) Player.AnimTime;
    LerpT := Player.AnimTime - FrameIndex;
    
    for Anim.BoneNames {
        Bone := FindBone(Player.Mesh.Skeleton, it);
        Player.Pose.ModelSpaceTransforms[Bone.Id] = Bone.LocalBindTransform;
    }
    
    ArenaPushMarkDefer(*FrameArena);
    
    Positions := ArenaPushN(*FrameArena, float3, xx Anim.BoneNames.count);
    Rotations := ArenaPushN(*FrameArena, quat, xx Anim.BoneNames.count);
    Scales := ArenaPushN(*FrameArena, float3, xx Anim.BoneNames.count);
    
    for Anim.BoneNames {
        Bone := FindBone(Player.Mesh.Skeleton, it);
        
        BaseIndex := Bone.Id * Anim.SampleCount;
        i0 := BaseIndex + FrameIndex;
        i1 := BaseIndex + ((FrameIndex + 1) % Anim.SampleCount);
        
        /*
        if LerpT < 0.5 {
            Positions[Bone.Id] = Anim.Positions[i0];
            Rotations[Bone.Id] = Anim.Rotations[i0];
            Scales[Bone.Id] = Anim.Scales[i0];
        } else {
            Positions[Bone.Id] = Anim.Positions[i1];
            Rotations[Bone.Id] = Anim.Rotations[i1];
            Scales[Bone.Id] = Anim.Scales[i1];
        }
*/
        
        Positions[Bone.Id] = Lerp(Anim.Positions[i0], Anim.Positions[i1], LerpT);
        Rotations[Bone.Id] = NLerpShortest(Anim.Rotations[i0], Anim.Rotations[i1], LerpT);
        Scales[Bone.Id] = Lerp(Anim.Scales[i0], Anim.Scales[i1], LerpT);
    }
    
    for Anim.BoneNames {
        Bone := FindBone(Player.Mesh.Skeleton, it);
        
        LocalTransform := Mat4Translation(Positions[Bone.Id]) *
            Mat4Rotation(Rotations[Bone.Id]) * Mat4Scale(Scales[Bone.Id]);
        
        if Bone.Parent {
            Pose.ModelSpaceTransforms[Bone.Id] = Pose.ModelSpaceTransforms[Bone.Parent.Id] * LocalTransform;
            Pose.ParentModelSpaceTransforms[Bone.Id] = Pose.ModelSpaceTransforms[Bone.Parent.Id];
        }
        else {
            Pose.ModelSpaceTransforms[Bone.Id] = LocalTransform;
            Pose.ParentModelSpaceTransforms[Bone.Id] = Mat4Identity();
        }
    }
    
    for Anim.BoneNames {
        Bone := FindBone(Player.Mesh.Skeleton, it);
        Pose.SkinningTransforms[Bone.Id] = Pose.ModelSpaceTransforms[Bone.Id] * Bone.InverseBindTransform;
        Pose.SkinningTransforms[Bone.Id] = Mat4Transpose(Pose.SkinningTransforms[Bone.Id]);
    }
}

#scope_file

AnimArena: arena;

#import "Basic";