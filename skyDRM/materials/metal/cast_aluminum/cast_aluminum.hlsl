// $Id: cast_aluminum.hlsl,v 1.1 2010-10-26 19:16:59 heppe Exp $
//version 19

// Tweakables
static const float color_repeat = 4.0;
static const float detail_repeat = 16.0;
static const float3 highlight_color = float3(0.19, 0.21, 0.23);
static const float base_roughness = 0.1;

static float4 aluminum_diffuse;
static float4 aluminum_normal;

void al_color(const HGlobals globals, inout HColor color)
{
	// Sample textures here since we can re-use results.
	aluminum_diffuse = tex2D(HMaterialSampler1, color_repeat * globals.tex.coords.xy);
	aluminum_normal = tex2D(HMaterialSampler2, detail_repeat * globals.tex.coords.xy);

	// Diffuse colour from texture	
	color.diffuse.rgb = aluminum_diffuse.rgb;
	
	// Feed roughness into specular light
	color.specular.rgb = highlight_color;
	color.specular.a = base_roughness + 0.3 * aluminum_diffuse.a;
}

void al_bump(const HGlobals globals, inout HSurface surface)
{
	// Bump using normal sampled above.
	h3d_normal_map(aluminum_normal.xyz * 2.0 - 1.0, surface);
}

void al_light(const HGlobals globals, const HSurface surface, inout HLighting lighting)
{
	// Fade lighting by displacement height
	lighting.diffuse *= aluminum_normal.a;
	lighting.specular *= aluminum_normal.a;
}

#define H3D_COLOR_SHADER al_color
#define H3D_SURFACE_SHADER al_bump
#define H3D_LIGHTING_SHADER al_light
#define H3D_LIGHTING_MODEL H3D_LIGHTING_MODEL_NAME(cook_torrance)
