#ifndef PRE_INTEGRATED_SKIN_INCLUDED
#define PRE_INTEGRATED_SKIN_INCLUDED

#include "BxDF.hlsl"

#define F0_SKIN 0.028

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
        float curvature,
        Texture2D texDiffuseLUT,
        SamplerState ss,
        float wrapRGB,
        float wrapR,
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
    NoLRGB = (NoLRGB + wrapRGB) / (1.0 + wrapRGB);
    NoLRGB.r = (NoLRGB.r + wrapR) / (1.0 + wrapR);

    NoLRGB *= shadow;
    
    return SkinSSS(curvature, NoLRGB, texDiffuseLUT, ss) * baseColor * lightColor;
}

float3 EvaluateSpecularDirectLight(
        float3 n_high,
        float3 n_geom,
        float3 v,
        float3 l,
        float3 lightColor,
        float3 baseColor,
        float gloss,
        float metallic)
{
    float3 F0 = lerp(F0_SKIN, baseColor, metallic);
    float specPower = exp2(gloss * 13); // remap to be more linear

    float h = normalize(v + l);
    float NoH = saturate(dot(n_high, h));
    float NoL = saturate(dot(n_high, l));
    float NoV = saturate(dot(n_high, v));
    float LoH = dot(l, h);

    // epidermis layer
    float specPower0 = specPower;
    float D0 = NDF_Blinn(specPower0, NoH);
    float V0 = Vis_Schlick(specPower0, NoV, NoL);

    // oil layer
    float specPower1 = specPower * specPower;
    float D1 = NDF_Blinn(specPower1, NoH);
    float V1 = Vis_Schlick(specPower1, NoV, NoL);

    float F = Fresnel_Schlick(F0, LoH);
    
    float3 brdf = lerp(D0*V0, D1*V1, 0.15) * F;
    float3 irradiance = NoL * lightColor;
    
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

#endif 