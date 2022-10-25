// $Id: metal.hlsl,v 1.1 2010-10-26 19:17:01 heppe Exp $
//version 19

// Tweakables
static const float ior = 3.5;
static const float3 base_color = float3(0.12, 0.18, 0.2);
static const float3 highlight_color = float3(0.92, 0.95, 1.0);
static const float roughness = 0.32;
static const float mirror = 0.35;
static const float fresnel_power = 4.0;

// Derived constants
static const float metal_f0 = h3d_compute_f0(ior);

// Globals
static float4 normal;

void metal_color(const HGlobals globals, inout HColor color)
{
	color.diffuse.rgb = base_color;

	color.specular.rgb = metal_f0 * highlight_color;
	color.specular.a = roughness;
}

void metal_effects(const HGlobals globals, inout HSurface surface, inout HLighting lighting, inout HEffects effects)
{
	// Very subtle environment reflection
	effects.mirror *= mirror * h3d_schlick_fresnel(metal_f0, saturate(-dot(surface.normal, globals.cam.direction)), fresnel_power);
}


#define H3D_COLOR_SHADER metal_color
#define H3D_EFFECTS_SHADER metal_effects
#define H3D_LIGHTING_MODEL H3D_LIGHTING_MODEL_NAME(cook_torrance)
