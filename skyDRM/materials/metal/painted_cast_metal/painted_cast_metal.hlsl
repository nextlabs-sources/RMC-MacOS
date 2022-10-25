// $Id: painted_cast_metal.hlsl,v 1.2 2011-05-24 13:50:46 will Exp $
//version 19

// Tweakables
static const float detail_repeat = 8.0;
static const float3 base_color = float3(0.1, 0.8, 1.5);
static const float paint_f0 = 0.01;
static const float roughness = 0.035;
static const float mirror = 0.75;
static const float fresnel_power = 4.0;
static const float parallax = 0.01;

static float4 metal_normal;

void metal_parallax(const HGlobals globals, const HSurface surface, inout float2 tex_coords)
{
	h3d_parallax_map(globals, surface, tex_coords, HMaterialSampler1, float2(1024, 1024), parallax/detail_repeat, detail_repeat);
} 

void metal_color(const HGlobals globals, inout HColor color)
{
	// Sample texture here since we can re-use results.
	metal_normal = tex2D(HMaterialSampler1, detail_repeat * globals.tex.coords.xy);

	// Diffuse colour
	color.diffuse.rgb = base_color;
	
	// Feed roughness into specular light
	color.specular.rgb = float3(paint_f0, paint_f0, paint_f0);
	color.specular.a = roughness;
}

void metal_bump(const HGlobals globals, inout HSurface surface)
{
	// Bump using normal sampled above.
	h3d_normal_map(metal_normal.xyz * 2.0 - 1.0, surface);
}

void metal_light(const HGlobals globals, const HSurface surface, inout HLighting lighting)
{
	// Fade lighting by displacement height
	lighting.diffuse *= metal_normal.a;
	lighting.specular *= 0.5 + 0.5 * metal_normal.a;
	lighting.ambient *= 0.5 + 0.5 * metal_normal.a;
}

void metal_effects(const HGlobals globals, const HSurface surface, const HLighting lighting, inout HEffects effects)
{
	// Output Fresnel factor
	effects.mirror *= mirror * metal_normal.a * h3d_schlick_fresnel(paint_f0, saturate(-dot(surface.normal, globals.cam.direction)), fresnel_power);
}

#ifdef H3D_HINT_BEST_IMAGE_QUALITY
#define H3D_PETURB_SHADER metal_parallax
#endif
#define H3D_COLOR_SHADER metal_color
#define H3D_SURFACE_SHADER metal_bump
#define H3D_LIGHTING_SHADER metal_light
#define H3D_EFFECTS_SHADER metal_effects
#define H3D_LIGHTING_MODEL H3D_LIGHTING_MODEL_NAME(cook_torrance)
