// $Id: Floorboards_Bamboo.hlsl,v 1.2 2010-10-28 01:46:51 will Exp $
//version 19

static const float repeat = 1.0;
static const float f0 = 0.05;

static float4 floorboard_diffuse;
static float4 floorboard_normal;

void floorboard_color(const HGlobals globals, inout HColor color)
{
	// Sample textures here since we can re-use results.
	floorboard_diffuse = tex2D(HMaterialSampler1, globals.tex.coords.xy * repeat);
	floorboard_normal = tex2D(HMaterialSampler2, globals.tex.coords.xy * repeat);

	// Diffuse colour from texture	
	color.diffuse.rgb = floorboard_diffuse.rgb;
	
	// Feed roughness into specular light
	color.specular.rgb = float3(f0, f0, f0);
	color.specular.a = floorboard_diffuse.a;
}

void floorboard_bump(const HGlobals globals, inout HSurface surface)
{
	// Bump using normal sampled above.
	h3d_normal_map(floorboard_normal.xyz * 2.0 - 1.0, surface);
}

void floorboard_light(const HGlobals globals, const HSurface surface, inout HLighting lighting)
{
	// Fade lighting by displacement height
	lighting.diffuse *= (0.5 + 0.5 * floorboard_normal.a);
}

#define H3D_COLOR_SHADER floorboard_color
#define H3D_SURFACE_SHADER floorboard_bump
#define H3D_LIGHTING_SHADER floorboard_light
#define H3D_LIGHTING_MODEL H3D_LIGHTING_MODEL_NAME(cook_torrance)

