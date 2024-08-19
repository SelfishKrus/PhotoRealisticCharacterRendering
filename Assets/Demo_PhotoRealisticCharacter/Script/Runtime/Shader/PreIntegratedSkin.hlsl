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
        float curvature,
        Texture2D texDiffuseLUT,
        SamplerState ss,
        float wrapRGB,
        float wrapR)
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
    
    return SkinSSS(curvature, NoLRGB, texDiffuseLUT, ss) * baseColor;
}

float3 EvaluateSpecularDirectLight(
        float3 n_high,
        float3 n_geom,
        float3 v,
        float3 l,
        float3 lightColor,
        float3 baseColor,
        float roughness,
        float gloss,
        float metallic,
        float specReflectance)
{
    float a = roughness * roughness;
    float a2 = a * a;
    float3 F0 = lerp(F0_SKIN, baseColor, metallic);
    float specPower = exp2(gloss * 13.0);

    float h = normalize(v + l);
    float NoH = saturate(dot(n_high, h));
    float NoL = saturate(dot(n_high, l));
    float NoV = saturate(dot(n_high, v));
    float LoH = dot(l, h);
    
    float specLobeBlend = _Test.x;
    float specPower0 = specPower;
    float specPower1 = specPower * specPower;
    float ndf0 = pow(NoH, specPower0) * (specPower0 + 2.0) * 0.5;
    float schlickSmithFactor0 = rsqrt(specPower0 * (3.14159 * 0.25) + (3.14159 * 0.5));
    float visibilityFn0 = 0.25 / (lerp(schlickSmithFactor0, 1, NoL) * lerp(schlickSmithFactor0, 1, NoV));
    float ndf1 = pow(NoH, specPower1) * (specPower1 + 2.0) * 0.5;
    float schlickSmithFactor1 = rsqrt(specPower1 * (3.14159 * 0.25) + (3.14159 * 0.5));
    float visibilityFn1 = 0.25 / (lerp(schlickSmithFactor1, 1, NoL) * lerp(schlickSmithFactor1, 1, NoV));
    float ndfResult = lerp(ndf0 * visibilityFn0, ndf1 * visibilityFn1, specLobeBlend);

    float fresnel = lerp(specReflectance, 1.0, pow(1.0 - LoH, 5.0));
    float specResult = ndfResult * fresnel;
    
    return specResult * NoL * lightColor;
}

#endif 