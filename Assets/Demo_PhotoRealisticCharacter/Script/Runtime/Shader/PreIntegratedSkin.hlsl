#ifndef PRE_INTEGRATED_SKIN_INCLUDED
#define PRE_INTEGRATED_SKIN_INCLUDED

#include "K_BxDF.hlsl"

#define F0_SKIN 0.028

// Reoriented Normal Mapping Blending
// input normals' range - [0, 1]
float3 BlendNormal_RNM(float3 n1_map, float3 n2_map)
{
    float3 t = n1_map.xyz*float3( 2,  2, 2) + float3(-1, -1,  0);
    float3 u = n2_map.xyz*float3(-2, -2, 2) + float3( 1,  1, -1);
    float3 r = t*dot(t, u) - u*t.z;
    return normalize(r);
}

float Vis_SchlickSmith_NvFaceWorks(float specPower, float NdotL, float NdotV)
{
	float schlickSmithFactor = rsqrt(specPower * (3.14159265359 * 0.25) + (3.14159265359 * 0.5));
	float visibilityFn = 0.25 / (lerp(schlickSmithFactor, 1, NdotL) * lerp(schlickSmithFactor, 1, NdotV));
	return visibilityFn;
}

float NDF_Blinn_NvFaceWorks(float specPower, float NoH)
{
    return pow(NoH, specPower) * (specPower + 2) * 0.5;
}

float3 SkinSSS(
        float curvature, 
        float3 NoLRGB,
        Texture2D texDiffuseLUT,
        SamplerState ss)
{
    float3 sss;
    sss.r = texDiffuseLUT.Sample(ss, float2(NoLRGB.r, curvature));
    sss.g = texDiffuseLUT.Sample(ss, float2(NoLRGB.g, curvature));
    sss.b = texDiffuseLUT.Sample(ss, float2(NoLRGB.b, curvature));
    
    return sss;
}


float3 EvaluateSSSDirectLight(
        float3 normalHigh,
        float3 normalLow,
        float3 baseColor,
        float3 lightDir,
        float3 lightColor,
        float3 wrap,
        float curvature,
        Texture2D texDiffuseLUT,
        SamplerState ss,
        float shadow)
{
    float NoLBlurredUnclamped = dot(normalLow, lightDir);
    
    float3 normalSmoothFactor = saturate(1.0 - NoLBlurredUnclamped);
    normalSmoothFactor *= normalSmoothFactor;
    float3 normalG = normalize(lerp(normalHigh, normalLow, 0.3+0.7*normalSmoothFactor));
    float3 normalB = normalize(lerp(normalHigh, normalLow, normalSmoothFactor));
    float NoLGUnclamped = dot(normalG, lightDir);
    float NoLBUnclamped = dot(normalB, lightDir);
    float3 NoLRGB = float3(NoLBlurredUnclamped, NoLGUnclamped, NoLBUnclamped);

    NoLRGB.r = (NoLRGB.r + wrap) / (1 + wrap);

    NoLRGB *= shadow;
    
    return SkinSSS(curvature, NoLRGB, texDiffuseLUT, ss) * baseColor * lightColor;
}

float3 EvaluateSSSEnv(
        float3 irradiance, 
        float3 baseColor,
        float curvature,
        Texture2D texDiffuseLUT,
        SamplerState ss,
        float ao)
{
    return SkinSSS(curvature, irradiance * ao, texDiffuseLUT, ss) * baseColor;
}

float3 EvaluateSpecularDirectLight(
        float3 n_high,
        float3 v,
        float3 l,
        float3 lightColor,
        float roughness,
        float specIntensity, 
        float NoLBias, 
        float shadow)
{
    float specPower = exp2((1-roughness) * specIntensity); // remap to be more linear

    float h = normalize(v + l);
    float NoH = saturate(dot(n_high, h));
    // remap irradiance in case that specular shows up in the shadow 
    //float NoL = saturate(dot(n_high, l) - NoLBias);
    float NoL = saturate((dot(n_high, l) - NoLBias) / (1 - NoLBias));
    float NoV = saturate(dot(n_high, v));
    float LoH = dot(l, h);
    float a = roughness * roughness;

    // epidermis layer
    float specPower0 = specPower;
    float D0 = NDF_Blinn_NvFaceWorks(specPower0, NoH);
    float V0 = Vis_SchlickSmith_NvFaceWorks(specPower0, NoV, NoL);

    // oil layer
    float specPower1 = specPower * specPower;
    float D1 = NDF_Blinn_NvFaceWorks(specPower1, NoH);
    float V1 = Vis_SchlickSmith_NvFaceWorks(specPower1, NoV, NoL);

    float F = Fresnel_Schlick(0.028, LoH);
    
    float3 brdf = lerp(D0*V0, D1*V1, 0.15) * F;
    float3 irradiance = NoL * lightColor * shadow;
    
    //return V0 * D0 * F * irradiance;
    return brdf * irradiance;
}

float3 EvaluateTransmittanceDirectLight(
        float3 transColor, 
        float3 normal,
        float3 lightDir,
        float3 lightColor,
        float thickness,
        float2 thicknessScaleBias,
        Texture2D texTransLUT,
        SamplerState ss)
{
    float T = texTransLUT.Sample(ss, float2(thickness * thicknessScaleBias.x + thicknessScaleBias.y, 0));
    float E = max(0.3 + dot(-normal, lightDir), 0.0);
    return T * lightColor * transColor * E;
}

float3 EvaluateTransmittanceEnv(
        float3 transColor, 
        float thickness,
        float2 thicknessScaleBias,
        float3 irradiance_SH,
        Texture2D texTransLUT,
        SamplerState ss)
{
    float T = texTransLUT.Sample(ss, float2(thickness * thicknessScaleBias.x + thicknessScaleBias.y, 0));
    float3 E = irradiance_SH;
    return T * transColor * E;
}

#endif 