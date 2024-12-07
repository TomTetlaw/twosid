#include "shared.shader"

struct Frag_Input {
	float4 ndc_position: SV_Position;
	float2 tex_coord: TEXCOORD0;
	float4 colour: TEXCOORD1;
};

#ifdef VERTEX_SHADER

struct Vertex_Input {
	float3 position: POSITION;
	float2 tex_coord: TEXCOORD0;
    float3 normal: TEXCOORD1;
};

cbuffer Constant_Buffer : register(b0, space1) {
	float4x4 world;
	float4x4 view;
	float4x4 projection;
	float4 diffuse_colour;
};

Frag_Input vertex_main(Vertex_Input input) {
	float4x4 MVP = projection * view * world;
	float4 ndc_position = mul(MVP, float4(input.position, 1));

	Frag_Input output;
	output.tex_coord = input.tex_coord;
	output.colour = diffuse_colour;
	output.ndc_position = ndc_position;
	return output;
}

#endif

#ifdef FRAGMENT_SHADER

struct Frag_Output {
	float4 frag_colour: SV_Target;
};

Texture2D<float4> diffuse_texture: register(t0, space2);
SamplerState diffuse_sampler: register(s0, space2);

float4 fragment_main(Frag_Input input): SV_Target {
	float4 diffuse_sample = diffuse_texture.Sample(diffuse_sampler, input.tex_coord);
	float4 colour = input.colour * diffuse_sample;

	return colour;
}

#endif