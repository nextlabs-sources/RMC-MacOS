// $Id: PineConstructionWood.hlsl,v 1.1 2010-10-26 19:17:03 heppe Exp $
//version 19

// Tweakables
static const float repeat = 1.0;
static const float f0 = 0.1;
static const float roughness = 2.0;

static float4 floorboard_diffuse;
static float4 floorboard_normal;

void floorboard_color(const HGlobals globals, inout HColor color)
{
	// Sample textures here since we can re-use results.
	floorboard_diffuse = tex2D(HMaterialSampler1, repeat * globals.tex.coords.xy);
	floorboard_normal = tex2D(HMaterialSampler2, repeat * globals.tex.coords.xy);

	// Diffuse colour from texture	
	color.diffuse.rgb = floorboard_diffuse.rgb;
	
	// Feed roughness into specular light
	color.specular.rgb = float3(f0, f0, f0);
	color.specular.a = floorboard_diffuse.a * roughness;
}

void floorboard_bump(const HGlobals globals, inout HSurface surface)
{
	// Bump using normal sampled above.
	h3d_normal_map(floorboard_normal.xyz * 2.0 - 1.0, surface);
}

void floorboard_light(const HGlobals globals, const HSurface surface, inout HLighting lighting)
{
	// Fade lighting by displacement height
	lighting.diffuse *= floorboard_normal.a;
	lighting.specular *= floorboard_normal.a * 0.40;
}

#define H3D_COLOR_SHADER floorboard_color
#define H3D_SURFACE_SHADER floorboard_bump
#define H3D_LIGHTING_SHADER floorboard_light
#define H3D_LIGHTING_MODEL H3D_LIGHTING_MODEL_NAME(cook_torrance)

