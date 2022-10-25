// $Id: car_paint.hlsl,v 1.1 2010-10-26 19:17:01 heppe Exp $
//version 19

// Tweakables
static const float f0 = 0.05;
static const float3 base_color = float3(0.92, 0.17, 0.15);
static const float roughness = 0.05;
static const float ambient_weight = 0.5;
static const float fresnel_power = 3.0;

void paint_color(const HGlobals globals, inout HColor color)
{
	// Write paint colour
	color.diffuse.rgb = base_color;
	
	// Write roughness and fresnel tint
	color.specular.rgb = float3(f0, f0, f0);
	color.specular.a = roughness;
}

void paint_light(const HGlobals globals, const HSurface surface, inout HLighting lighting)
{
	lighting.ambient *= ambient_weight + (1.0-ambient_weight) * base_color;
}

void paint_environment(const HGlobals globals, inout HSurface surface, inout HLighting lighting, inout HEffects effects)
{
	// Output Fresnel factor
	effects.mirror *= h3d_schlick_fresnel(f0, saturate(-dot(surface.normal, globals.cam.direction)), fresnel_power);
}

H3D_DECLARE_LIGHTING_MODEL(cook_torrance);

H3D_DECLARE_LIGHTING_MODEL(wide_cook_torrance)
{
	H3D_LIGHTING_MODEL_NAME(cook_torrance)(N, T, B, V, H, L, diffuse, specular, color, out_diffuse, out_specular);

	// Wider diffuse so we don't darken on the back.	
	float NdotL_wide = dot(N, L) * 0.5 + 0.5;
	out_diffuse = NdotL_wide * diffuse.rgb;
}

#define H3D_COLOR_SHADER paint_color
#define H3D_LIGHTING_SHADER paint_light
#define H3D_EFFECTS_SHADER paint_environment
#define H3D_LIGHTING_MODEL H3D_LIGHTING_MODEL_NAME(wide_cook_torrance)
