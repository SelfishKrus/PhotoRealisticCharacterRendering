﻿#ifndef K_UTILITIES_INCLUDED
#define K_UTILITIES_INCLUDED

    SAMPLER(SamplerState_Linear_Repeat);
    SAMPLER(SamplerState_Linear_Clamp);

    // === NORMAL === // 
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"

    float3 ScaleNormalTS(float3 normalTS, float scale)
    {
        normalTS.xy *= scale;
        normalTS.z = sqrt(1 - saturate(dot(normalTS.xy, normalTS.xy)));
    
        return normalTS;
    }

    float3 UnpackNormal_K(Texture2D normalMap, SamplerState ss, float2 uv, float normalScale)
    {
        float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(normalMap, ss, uv)).xyz;
        normalTS = ScaleNormalTS(normalTS, normalScale);

        return normalTS;
    }

    float3x3 GetWorldToTangentMatrix(float3 normalWS, float4 tangentWS)
    {
        float3 bitangentWS = cross(normalWS, tangentWS.xyz) * tangentWS.w;
        return float3x3(
            float3(tangentWS.xyz),
            float3(bitangentWS.xyz),
            float3(normalWS.xyz)
        );
    }

    float3x3 GetTangentToWorldMatrix(float3 normalWS, float4 tangentWS)
    {
        return transpose(GetWorldToTangentMatrix(normalWS, tangentWS));
    }

    // From UE Material function Lerp_3Color
    float3 Lerp3Color(float3 color1, float3 color2, float3 color3, float a)
    {
        float3 lerp0 = lerp(color1, color2, saturate(a * 2));
        float3 lerp1 = lerp(lerp0, color3, saturate(a * 2 - 1));
    
        return lerp1;
    }

    float Luminance_K(float3 color)
    {
        return dot(color, float3(0.2126, 0.7152, 0.0722));
    }

    // https://docs.unity3d.com/Packages/com.unity.shadergraph@6.9/manual/Dither-Node.html
    float4 Dither(float4 In, float2 ScreenPosition)
    {
        float2 uv = ScreenPosition.xy * _ScreenParams.xy;
        float DITHER_THRESHOLDS[16] =
        {
            1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
            13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
            4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
            16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
        };
        uint index = (uint(uv.x) % 4) * 4 + uint(uv.y) % 4;
        return In - DITHER_THRESHOLDS[index];
    }


#endif 