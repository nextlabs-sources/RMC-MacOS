// $Id: brushed_metal.hlsl,v 1.1 2010-10-26 19:16:59 heppe Exp $
//version 19

// Tweakables
static const float detail_repeat = 32.0;
static const float ior = 3.5;
static const float3 base_color = float3(0.4, 0.4, 0.4);
static const float roughness = 0.2;
static const float mirror = 0.7;
static const float anisotropy_power = 16.0;
static const float anisotropy_weight = 0.7;
static const float fresnel_power = 4.0;

// Compute Fresnel factor.
static const float metal_f0 = h3d_compute_f0(ior);

// Globals
static float4 normal;

void bm_color(const HGlobals globals, inout HColor color)
{
	color.diffuse.rgb = base_color;
	color.specular.rgb = float3(metal_f0, metal_f0, metal_f0);
	color.specular.a = roughness;
}

void bm_bump(const HGlobals globals, inout HSurface surface)
{
	normal = tex2D(HMaterialSampler1, globals.tex.coords.xy * detail_repeat);
	
	// Apply normal map
	h3d_normal_map(normal.xyz * 2.0 - 1.0, surface);
}

void bm_lighting(const HGlobals globals, const HSurface surface, inout HLighting lighting)
{
	// Fade lighting by displacement height
	lighting.diffuse *= 0.5 + 0.5 * normal.a;
	lighting.specular *= 0.25 + 0.75 * normal.a;
}

H3D_DECLARE_LIGHTING_MODEL(cook_torrance);
H3D_DECLARE_LIGHTING_MODEL(heidrich_seidel);

H3D_DECLARE_LIGHTING_MODEL(lighting_model)
{
	// Use Cook-Torrance metal for details
	H3D_LIGHTING_MODEL_NAME(cook_torrance)(N, T, B, V, H, L, diffuse, specular, color, out_diffuse, out_specular);
	
	// Use Heidrich-Seidel for anisotropy
	float3 dummy, spec;
	color.specular.a = anisotropy_power;
	H3D_LIGHTING_MODEL_NAME(heidrich_seidel)(N, T, B, V, H, L, diffuse, specular, color, dummy, spec);

	// Blend specular terms
	out_specular = lerp(out_specular, spec, anisotropy_weight);
}

void bm_effects(const HGlobals globals, inout HSurface surface, inout HLighting lighting, inout HEffects effects)
{
	effects.mirror *= normal.a * mirror * h3d_schlick_fresnel(metal_f0, saturate(-dot(surface.normal, globals.cam.direction)), fresnel_power);
}

#define H3D_COLOR_SHADER bm_color
#define H3D_SURFACE_SHADER bm_bump
#define H3D_LIGHTING_SHADER bm_lighting
#define H3D_LIGHTING_MODEL H3D_LIGHTING_MODEL_NAME(lighting_model)
#define H3D_EFFECTS_SHADER bm_effects
