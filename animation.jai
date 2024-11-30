
Anim_Player :: struct {
    mesh: *Mesh;
    anim: *Animation;
    
    playing: bool;
    anim_time: float;
    pose: Anim_Pose;
    
    fps := 30;
}

Anim_Pose :: struct {
    bone_names: [] string;
    model_space_transforms: [] Mat4;
    parent_model_space_transforms: [] Mat4;
    skinning_transforms: [] Mat4;
}

init_animation_system :: () {
    anim_arena = create_arena();
}

create_anim_player :: (mesh: *Mesh, anim: *Animation) -> Anim_Player {
    player: Anim_Player;
    player.mesh = mesh;
    player.anim = anim;
    player.pose.bone_names = anim.bone_names;
    
    player.pose.parent_model_space_transforms = arena_push_n(*anim_arena, Mat4, xx anim.bone_count);
    player.pose.model_space_transforms = arena_push_n(*anim_arena, Mat4, xx anim.bone_count);
    player.pose.skinning_transforms = arena_push_n(*anim_arena, Mat4, xx anim.bone_count);
    
    return player;
}

anim_play :: (player: *Anim_Player) {
    player.anim_time = 0;
    player.playing = true;
}

anim_stop :: (player: *Anim_Player) {
    player.playing = false;
}

anim_update :: (player: *Anim_Player) {
    if !player.playing return;
    
    pose := player.pose;
    mesh := player.mesh;
    anim := player.anim;
    
    player.anim_time += delta_time * player.fps;
    player.anim_time = fmod_cycling(player.anim_time, xx anim.sample_count);
    frame_index := cast(int) player.anim_time;
    lerp_t := player.anim_time - frame_index;
    
    for anim.bone_names {
        bone := find_bone(player.mesh.skeleton, it);
        player.pose.model_space_transforms[bone.id] = bone.local_bind_transform;
    }
    
    arena_push_mark_defer(*frame_arena);
    
    positions := arena_push_n(*frame_arena, Vec3, xx anim.bone_names.count);
    rotations := arena_push_n(*frame_arena, Quaternion, xx anim.bone_names.count);
    scales := arena_push_n(*frame_arena, Vec3, xx anim.bone_names.count);
    
    for anim.bone_names {
        bone := find_bone(player.mesh.skeleton, it);
        
        base_index := bone.id * anim.sample_count;
        i0 := base_index + frame_index;
        i1 := base_index + ((frame_index + 1) % anim.sample_count);
        
        /*
        if lerp_t < 0.5 {
            positions[bone.id] = anim.positions[i0];
            rotations[bone.id] = anim.rotations[i0];
            scales[bone.id] = anim.scales[i0];
        } else {
            positions[bone.id] = anim.positions[i1];
            rotations[bone.id] = anim.rotations[i1];
            scales[bone.id] = anim.scales[i1];
        }
*/
        
        positions[bone.id] = lerp(anim.positions[i0], anim.positions[i1], lerp_t);
        rotations[bone.id] = nlerp_shortest(anim.rotations[i0], anim.rotations[i1], lerp_t);
        scales[bone.id] = lerp(anim.scales[i0], anim.scales[i1], lerp_t);
    }
    
    for anim.bone_names {
        bone := find_bone(player.mesh.skeleton, it);
        
        local_transform := mat4_translation(positions[bone.id]) *
            mat4_rotation(rotations[bone.id]) * mat4_scale(scales[bone.id]);
        
        if bone.parent {
            pose.model_space_transforms[bone.id] = pose.model_space_transforms[bone.parent.id] * local_transform;
            pose.parent_model_space_transforms[bone.id] = pose.model_space_transforms[bone.parent.id];
        }
        else {
            pose.model_space_transforms[bone.id] = local_transform;
            pose.parent_model_space_transforms[bone.id] = mat4_identity();
        }
    }
    
    for anim.bone_names {
        bone := find_bone(player.mesh.skeleton, it);
        pose.skinning_transforms[bone.id] = pose.model_space_transforms[bone.id] * bone.inverse_bind_transform;
        pose.skinning_transforms[bone.id] = mat4_transpose(pose.skinning_transforms[bone.id]);
    }
}

#scope_file

anim_arena: Arena;

#import "Basic";