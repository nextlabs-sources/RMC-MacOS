// $Id: brass.hlsl,v 1.1 2010-10-26 19:16:59 heppe Exp $
//version 19

// Tweakables
static const float ior = 3.5;
static const float3 base_color = float3(0.5,0.4,0.1);
static const float3 highlight_color = float3(1.425, 1.5, 1.275);
static const float roughness = 0.35;
static const float mirror = 0.7;
static const float fresnel_power = 4.0;

// Derived constants
static const float f0 = h3d_compute_f0(ior);
static const float3 f0_rgb = f0 * highlight_color;

// Globals
static float4 normal;

void brass_color(const HGlobals globals, inout HColor color)
{
	color.diffuse.rgb = base_color;
	color.specular.rgb = f0_rgb;
	color.specular.a = roughness;
}

void brass_effects(const HGlobals globals, inout HSurface surface, inout HLighting lighting, inout HEffects effects)
{
	effects.mirror *= base_color * mirror * h3d_schlick_fresnel_rgb(f0_rgb, saturate(-dot(surface.normal, globals.cam.direction)), fresnel_power);
}

void brass_lighting(const HGlobals globals, const HSurface surface, inout HLighting lighting)
{
	lighting.ambient *= base_color * 0.9 + 0.1;
}

#define H3D_COLOR_SHADER brass_color
#define H3D_LIGHTING_SHADER brass_lighting
#define H3D_EFFECTS_SHADER brass_effects
#define H3D_LIGHTING_MODEL H3D_LIGHTING_MODEL_NAME(cook_torrance)
