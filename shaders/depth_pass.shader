#include "shaders/shared.shader"

#ifdef VERTEX_SHADER

struct Vertex_Input {
	float3 position: POSITION;
	short4 bone_ids : TEXCOORD0;
    float3 bone_weights : TEXCOORD1;
};

cbuffer Constant_Buffer : register(b0, space1) {
	matrix world;
	matrix view;
	matrix projection;
};

StructuredBuffer<matrix> skinning_transforms: register(t0, space0);

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
                                                 
        matrix skinning_matrix = skinning_transforms[bone_id];
        model_position += mul(skinning_matrix, float4(position, 1)).xyz;
    }

	matrix MVP = mul(projection, mul(view, world));
	return mul(MVP, float4(model_position, 1));
}

#endif

#ifdef FRAGMENT_SHADER

float4 fragment_main() : SV_Target {
	return float4(0, 0, 0, 0);
}

#endif