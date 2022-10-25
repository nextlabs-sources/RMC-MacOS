// $Id: concrete.hlsl,v 1.2 2010-10-28 19:01:27 heppe Exp $
//version 19

// Tweakables:
static const float color_repeat = 1.0;
static const float detail_repeat = 4.0;
static const float3 base_color_tint = float3(1.2, 1.164, 1.128);
static const float3 highlight_color = float3(0.4, 0.4, 0.4);
static const float base_roughness = 0.3;
static const float random_size_scale = 0.5;
static const float random_size_range = 0.1;
static const float random_angle_range = 0.1;
static const float3 random_color_range = float3(0.01, 0.01, 0.01);
static const float random_blend_start = 0.9;

static float4 concrete_diffuse;
static float4 concrete_normal;

void concrete_color(const HGlobals globals, inout HColor color)
{
	// Lookup textures
#define RANDOM_CONCRETE
#ifdef RANDOM_CONCRETE
	float2 oo_size = float2(1.0/1024.0, 1.0/1024.0);
	concrete_diffuse = h3d_random_tile(HMaterialSampler1, HMaterialSampler3, oo_size, globals.tex.coords.xy * color_repeat, random_size_scale, random_size_range, random_angle_range, random_color_range, random_blend_start);
	concrete_normal = tex2D(HMaterialSampler2, globals.tex.coords.xy * detail_repeat);
#else
	concrete_diffuse = tex2D(HMaterialSampler1, globals.tex.coords.xy * color_repeat);
	concrete_normal = tex2D(HMaterialSampler2, globals.tex.coords.xy * detail_repeat);
#endif
	
	// Write color and spec
	color.diffuse.rgb = concrete_diffuse.rgb * base_color_tint;
	color.specular.rgb = highlight_color;
	color.specular.a = base_roughness + 0.7 * concrete_diffuse.a;
}

void concrete_bump(const HGlobals globals, inout HSurface surface)
{
	h3d_normal_map(concrete_normal.xyz * 2.0 - 1.0, surface);
}

void concrete_lighting(const HGlobals globals, const HSurface surface, inout HLighting lighting)
{
	lighting.diffuse *= 0.25 + 0.75 * concrete_normal.a;
	lighting.ambient *= 0.5 + 0.5 * concrete_normal.a;
	lighting.specular *= 0.25 + 0.75 * concrete_normal.a;
}

H3D_DECLARE_LIGHTING_MODEL(cook_torrance);

H3D_DECLARE_LIGHTING_MODEL(wide_cook_torrance)
{
	H3D_LIGHTING_MODEL_NAME(cook_torrance)(N, T, B, V, H, L, diffuse, specular, color, out_diffuse, out_specular);

	// Wider diffuse so we don't darken on the back.	
	float NdotL_wide = dot(N, L) * 0.5 + 0.5;
	out_diffuse = NdotL_wide * diffuse.rgb;
}

#define H3D_LIGHTING_MODEL H3D_LIGHTING_MODEL_NAME(wide_cook_torrance)
#define H3D_COLOR_SHADER concrete_color
#define H3D_SURFACE_SHADER concrete_bump
#define H3D_LIGHTING_SHADER concrete_lighting


