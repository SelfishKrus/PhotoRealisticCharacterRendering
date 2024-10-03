#ifndef K_UTILITIES_INCLUDED
#define K_UTILITIES_INCLUDED

    SAMPLER(SamplerState_Linear_Repeat);
    SAMPLER(SamplerState_Linear_Clamp);

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

    float4x4 GetWorldToTangentMatrix(float3 normalWS, float4 tangentWS)
    {
        float3 bitangentWS = cross(normalWS, tangentWS.xyz) * tangentWS.w;
        return float4x4(
            float4(tangentWS.xyz, 0),
            float4(bitangentWS.xyz, 0),
            float4(normalWS.xyz, 0),
            float4(0, 0, 0, 1)
        );
    }

    float4x4 GetTangentToWorldMatrix(float3 normalWS, float4 tangentWS)
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


#endif 