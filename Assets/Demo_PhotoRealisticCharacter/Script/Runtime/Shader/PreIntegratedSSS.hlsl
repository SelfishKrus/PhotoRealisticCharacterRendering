#ifndef PRE_INTEGRATED_SSS_SKIN_INCLUDED
#define PRE_INTEGRATED_SSS_SKIN_INCLUDED

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
    
    return SkinSSS(curvature, NoLRGB, texDiffuseLUT, ss);
}

#endif 