#include "shaders/shared.shader"

struct Frag_Input {
	float4 ndc_position: SV_Position;
	float3 world_space_position: TEXCOORD0;
	float2 tex_coord: TEXCOORD1;
	float3 normal: TEXCOORD2;
	float3 tangent: TEXCOORD3;
	float4 colour: TEXCOORD4;
};

#ifdef VERTEX_SHADER

struct Vertex_Input {
	float3 position: POSITION;
	float2 tex_coord: TEXCOORD0;
    float4 tangent_normal : TEXCOORD1;
};

cbuffer Constant_Buffer : register(b0, space1) {
	float4x4 world;
	float4x4 view;
	float4x4 projection;
	float4 diffuse_colour;
};

Frag_Input vertex_main(Vertex_Input input) {
    float3 normal = unpack_normal(input.tangent_normal.xy);
    float3 tangent = unpack_tangent(input.tangent_normal.zw);
                                            
	float4x4 MVP = projection * view * world;
	float4 ndc_position = mul(MVP, float4(input.position, 1));

	Frag_Input output;
	output.ndc_position = ndc_position;
	output.world_space_position = mul(world, float4(input.position, 1)).xyz;
	output.tex_coord = input.tex_coord;
	output.normal = normal;
	output.tangent = tangent;
	output.colour = diffuse_colour;
	return output;
}

#endif

#ifdef FRAGMENT_SHADER

struct Frag_Output {
	float4 frag_colour: SV_Target;
};

Texture2D<float4> diffuse_texture: register(t0, space2);
SamplerState diffuse_sampler: register(s0, space2);

Frag_Output fragment_main(Frag_Input input) {
	float4 diffuse_sample = diffuse_texture.Sample(diffuse_sampler, input.tex_coord);
	float4 colour = input.colour * diffuse_sample;

	Frag_Output output;
	output.frag_colour = colour;
	return output;
}

#endif