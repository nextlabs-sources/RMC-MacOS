// $Id: Car_Panel_Walnut.hlsl,v 1.1 2010-10-26 19:17:03 heppe Exp $
//version 19

// Tweakables
static const float color_repeat = 1.0;
static const float gloss_f0 = 0.05;
static const float highlight_tint_weight = 0.05;
static const float roughness = 0.05;
static const float fresnel_power = 3.0;

static float4 wood_diffuse;

void wood_color(const HGlobals globals, inout HColor color)
{
	wood_diffuse = tex2D(HMaterialSampler1, globals.tex.coords.xy * color_repeat * float2(1.0, 4.0));
	
	// Write paint colour
	color.diffuse.rgb = wood_diffuse.rgb;
	
	// Write roughness and fresnel tint
	color.specular.rgb = float3(gloss_f0, gloss_f0, gloss_f0) + highlight_tint_weight * color.diffuse.rgb;
	color.specular.a = roughness;
}

void wood_light(const HGlobals globals, const HSurface surface, inout HLighting lighting)
{
	// Kill most of the ambient
	lighting.ambient *= 0.2 + 0.35 * wood_diffuse.rgb;
}

void wood_environment(const HGlobals globals, inout HSurface surface, inout HLighting lighting, inout HEffects effects)
{
	// Output Fresnel factor
	effects.mirror *= h3d_schlick_fresnel(gloss_f0, saturate(-dot(surface.normal, globals.cam.direction)), fresnel_power);
}

H3D_DECLARE_LIGHTING_MODEL(cook_torrance);

#define H3D_COLOR_SHADER wood_color
#define H3D_LIGHTING_SHADER wood_light
#define H3D_EFFECTS_SHADER wood_environment
#define H3D_LIGHTING_MODEL H3D_LIGHTING_MODEL_NAME(cook_torrance)
