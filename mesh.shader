#include "shared.shader"

cbuffer Constant_Buffer : register(b0, space1) {
	float4x4 world;
	float4x4 view;
	float4x4 projection;
	float4 diffuse_colour;
	float4x4 skinning_transforms[MAX_BONES];
};

struct Vertex_Input {
	float3 position: POSITION;
	float2 tex_coord: TEXCOORD0;
    float4 tangent_normal : TEXCOORD1;
    int4 bone_ids : BLENDINDICES0;
    float3 bone_weights : BLENDWEIGHT0;
};

struct Frag_Input {
	float4 ndc_position: SV_Position;
	float3 world_space_position: TEXCOORD0;
	float2 tex_coord: TEXCOORD1;
	float3 normal: TEXCOORD2;
	float3 tangent: TEXCOORD3;
};

struct Frag_Output {
	float4 frag_colour: SV_Target;
};

Frag_Input vertex_main(Vertex_Input input) {
	float3 position = input.position;
    float3 normal = unpack_normal(input.tangent_normal.xy);
    float3 tangent = unpack_tangent(input.tangent_normal.zw);
                                            
    float3 model_position = float3(0, 0, 0);
    float3 model_normal = float3(0, 0, 0);
    float3 model_tangent = float3(0, 0, 0);
                                             
    if (input.bone_ids.x == -1) {
    	model_position = position;
        model_normal = normal;
        model_tangent = tangent;
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
        float3 pose_normal = mul(skinning_matrix, float4(normal, 1)).xyz;
        float3 pose_tangent = mul(skinning_matrix, float4(tangent, 1)).xyz;
                                                 
        model_position += pose_position * weight;
        model_normal += pose_normal * weight;
        model_tangent += pose_tangent * weight;
    }

	float4x4 MVP = projection * view * world;
	float4 ndc_position = mul(MVP, float4(model_position, 1));

	Frag_Input output;
	output.ndc_position = ndc_position;
	output.world_space_position = mul(world, float4(input.position, 1)).xyz;
	output.tex_coord = input.tex_coord;
	output.normal = model_normal;
	output.tangent = model_tangent;
	return output;
}

Texture2D<float4> diffuse_texture: register(t0, space2);
SamplerState diffuse_sampler: register(s0, space2);

Frag_Output fragment_main(Frag_Input input) {
	float4 diffuse_sample = diffuse_texture.Sample(diffuse_sampler, input.tex_coord);
	float4 colour = diffuse_colour * diffuse_sample;

	Frag_Output output;
	output.frag_colour = colour;
	return output;
}