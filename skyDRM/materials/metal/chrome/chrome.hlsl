// $Id: chrome.hlsl,v 1.1 2010-10-26 19:16:59 heppe Exp $
//version 19

// Tweakables
static const float detail_repeat = 8.0;
static const float ior = 5.0;
static const float3 base_color = float3(0.2, 0.2, 0.2);
static const float roughness = 0.025;

static float4 normal;

// Compute Fresnel factor.
static const float metal_f0 = h3d_compute_f0(ior);

void cm_color(const HGlobals globals, inout HColor color)
{
	// Sample textures here since we can re-use results.
	normal = tex2D(HMaterialSampler1, detail_repeat * globals.tex.coords.xy);
	
	color.diffuse.rgb = base_color;
	color.specular.rgb = float3(metal_f0, metal_f0, metal_f0);
	color.specular.a = roughness;
}

void cm_bump(const HGlobals globals, inout HSurface surface)
{
	h3d_normal_map(normal.xyz * 2.0 - 1.0, surface);
}

void cm_lighting(const HGlobals globals, const HSurface surface, inout HLighting lighting)
{
	// Fade lighting by displacement height
	lighting.diffuse *= normal.a;
	lighting.specular *= normal.a;
}

void cm_effects(const HGlobals globals, inout HSurface surface, inout HLighting lighting, inout HEffects effects)
{
	effects.mirror *= normal.a;
}

#define H3D_COLOR_SHADER cm_color
#define H3D_SURFACE_SHADER cm_bump
#define H3D_LIGHTING_SHADER cm_lighting
#define H3D_LIGHTING_MODEL H3D_LIGHTING_MODEL_NAME(cook_torrance)
#define H3D_EFFECTS_SHADER cm_effects
