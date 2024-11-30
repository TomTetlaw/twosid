#include "shaders/shared.shader"

struct Frag_Input {
	float4 ndc_position: SV_Position;
	float3 world_space_position: TEXCOORD0;
	float4 screen_space_position: TEXCOORD1;
	float2 tex_coord: TEXCOORD2;
	float3 normal: TEXCOORD3;
	float3 tangent: TEXCOORD4;
	float3 colour: TEXCOORD5;
};

#ifdef VERTEX_SHADER

cbuffer Constant_Buffer : register(b0, space1) {
	row_major matrix world;
	row_major matrix view;
	row_major matrix projection;
	float3 diffuse_colour;
};

struct Vertex_Input {
	float3 position: POSITION;
	float2 tex_coord: TEXCOORD0;
    float4 tangent_normal : TEXCOORD1;
	float3 bone_weights : TEXCOORD2;
    short4 bone_ids : TEXCOORD3;
};

StructuredBuffer<matrix> skinning_transforms: register(t0, space0);

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

        matrix skinning_matrix = skinning_transforms[bone_id];
        model_position += mul(skinning_matrix, float4(position, 1)).xyz;
        model_normal += mul(skinning_matrix, float4(normal, 1)).xyz;
        model_tangent += mul(skinning_matrix, float4(tangent, 1)).xyz;
    }

	matrix MVP = mul(projection, mul(view, world)); //mul(mat_ndc_axis_conversion, mul(projection, mul(view, world)));
	float4 ndc_position = mul(MVP, float4(model_position, 1));

	Frag_Input output;
	output.ndc_position = ndc_position;
	output.world_space_position = mul(world, float4(model_position, 1)).xyz;
	output.screen_space_position = ndc_position;
	output.tex_coord = input.tex_coord;
	output.normal = model_normal;
	output.tangent = model_tangent;
	output.colour = diffuse_colour;
	return output;
}

#endif

#ifdef FRAGMENT_SHADER

cbuffer Constant_Buffer : register(b0, space3) {
	float3 camera_position;
	float3 light_dir;
	float3 light_colour;
	float material_scale;
};

struct Frag_Output {
	float4 frag_colour: SV_Target;
	float depth: SV_Depth;
};

Texture2D diffuse_map: register(t0, space2);
Texture2D normal_map: register(t1, space2);
Texture2D rmaoh_map: register(t2, space2);

SamplerState diffuse_sampler: register(s0, space2);
SamplerState normal_sampler: register(s1, space2);
SamplerState rmaoh_sampler: register(s2, space2);

Frag_Output fragment_main(Frag_Input input) {
	float2 tex_coord = input.tex_coord * material_scale;
	
	float3 diffuse = diffuse_map.Sample(diffuse_sampler, tex_coord).rgb;
	diffuse = pow(diffuse, float3(2.2, 2.2, 2.2));
	
	float3 bitangent = cross(input.normal, input.tangent);
	float3x3 TBN = float3x3(input.tangent, bitangent, input.normal);
	float3 normal = normal_map.Sample(normal_sampler, tex_coord).xyz * 2 - 1;
	normal = normalize(mul(TBN, normal));
	normal = normalize(lerp(input.normal, normal, 0.5));
	
	float4 rmaoh = rmaoh_map.Sample(rmaoh_sampler, tex_coord);
	
	Material material;
	material.roughness = 1 * rmaoh.r;
	material.metallic = 1 * rmaoh.g;
	material.ambient_occlusion = 1 * rmaoh.b;
	
	float4 light_space_position;
	
	float3 colour = input.colour * diffuse;
	float shadow = shadow_calculation(diffuse_map, diffuse_sampler, light_space_position, normal, light_dir);
	colour = lighting_directional(0, input.world_space_position, normal, colour, material, camera_position, light_dir, light_colour);

	Frag_Output output;
	output.frag_colour = float4(colour, 1);
	return output;
}

#endif