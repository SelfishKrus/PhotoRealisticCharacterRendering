#ifndef PRE_INTEGRATED_SKIN_INCLUDED
#define PRE_INTEGRATED_SKIN_INCLUDED

    #include "BxDF.hlsl"

    #define F0_SKIN 0.04

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
            float metallic)
    {
        float a = roughness * roughness;
        float a2 = a * a;
        float3 F0 = lerp(float3(0.028,0.028,0.028), baseColor, metallic);

        float h = normalize(v + l);
        float NoH = saturate(dot(n_high, h));
        float NoL = saturate(dot(n_high, l));
        float NoV = saturate(dot(n_high, v));
        float VoH = saturate(dot(v, h));

        float D = NDF_GGX(a2, NoH);
        //D = NDF_Beckmann(a2, NoH);
        //D = NDF_Blinn(a2, NoH);
        float V = Vis_Schlick(a2, NoV, NoL);
        //V = Vis_Kelemen(VoH);
        float3 F = Fresnel_Schlick(F0, VoH);
        float3 brdf = D * F * V;
        float3 irradiance = saturate(dot(n_high, l)) * lightColor;

        //return pow(NoH, _Test.x);
        return brdf * irradiance;
    }

#endif 