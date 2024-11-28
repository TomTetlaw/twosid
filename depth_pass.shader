#include "shared.shader"

cbuffer Constant_Buffer : register(b0, space1) {
	float4x4 world;
	float4x4 view;
	float4x4 projection;
	float4x4 skinning_transforms[MAX_BONES];
};

struct Vertex_Input {
	float3 position: POSITION;
    int4 bone_ids : BLENDINDICES0;
    float3 bone_weights : BLENDWEIGHT0;
};

float4 vertex_main(Vertex_Input input): SV_Position {
	float3 position = input.position;
                                            
    float3 model_position = float3(0, 0, 0);
                                             
    if (input.bone_ids.x == -1) {
    	model_position = position;
     }
                                             
     for (int i = 0; i < MAX_WEIGHTS && input.bone_ids[i] != -1; i += 1) {
     	int bone_id = input.bone_ids[i];
         float weight = 0;
         
		if (i == MAX_WEIGHTS - 1) {
            weight = 1.0 - (input.bone_weights.x+input.bone_weights.y+input.bone_weights.z);
        } else {
            weight = input.bone_weights[i];
        }
                                                 
        float4x4 skinning_matrix = skinning_transforms[bone_id];
        float3 pose_position = mul(skinning_matrix, float4(position, 1)).xyz;
        model_position += pose_position * weight;
    }

	float4x4 MVP = projection * view * world;
	return mul(MVP, float4(model_position, 1));
}

float4 fragment_main() : SV_Target {
	return float4(0, 0, 0, 0);
}