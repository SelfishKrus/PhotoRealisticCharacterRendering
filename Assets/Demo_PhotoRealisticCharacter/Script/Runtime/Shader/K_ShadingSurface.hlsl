#ifndef K_SHADING_SURFACE_INCLUDED
#define K_SHADING_SURFACE_INCLUDED

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
    #include "K_Utilities.hlsl"

    TEXTURE2D(_T_BaseColor); // use _BaseColorMap instead in HDRP
    TEXTURE2D(_T_Normal);
    TEXTURE2D(_T_DetailNormal);
    TEXTURE2D(_T_Rmom);

    half3 _BaseColorTint; // use _BaseColor instead in HDRP
    half _S_Opacity;
    float _S_Normal;
    float _S_DetailNormal;
    float _DetailNormalTiling;
    float _DetailVisibleDistance;
    float _S_Roughness;
    float _S_Metallic;
    float _S_AO;
    float _S_Height;

    float _CutOffThreshold;

    struct ShadingSurface
    {   
        float3 baseColor;
        float alpha;

        float roughness;
        float a;
        float a2;
        float envMipLevel;
        float metallic;
        float3 F0;
        float ao;
        float detailMask;

        float3 normalWS_high;
        float3 normalWS_geom;
        float3 normalWS_detail;

        float3 tangentWS_geom;
        float3 bitangentWS_geom;
    };

    // Generic 
    ShadingSurface GetShadingSurface(Texture2D baseColorMap, float3 tint, float alphaScale, Texture2D rmomMap, float3 rmomScale, Texture2D normalMap, float normalScale, float3 normalWS_geom, Texture2D detailNormalMap, float detailNormalScale, float detailNormalTiling, float detailVisibleDistance, float distanceFromFragToCam, float4 tangentWS_geom, SamplerState ss, float2 uv)
    {
        ShadingSurface surf;

        float4 baseColor = SAMPLE_TEXTURE2D(baseColorMap, ss, uv);
        surf.baseColor = baseColor.rgb * tint;
        surf.alpha = baseColor.a * alphaScale;

        half4 rmom = SAMPLE_TEXTURE2D(rmomMap, ss, uv);
        surf.roughness = lerp(0.01, 0.99, rmom.r * rmomScale.r);
        surf.a = surf.roughness * surf.roughness;
        surf.a2 = surf.a * surf.a;
        surf.envMipLevel = PerceptualRoughnessToMipmapLevel(surf.a);
        surf.metallic = lerp(0.01, 0.99, rmom.g * rmomScale.g);
        surf.F0 = lerp(0.04, surf.baseColor, surf.metallic);
        surf.ao = rmom.b * rmomScale.b;
        surf.detailMask = rmom.a;

        float3 normalTS = UnpackNormal_K(normalMap, ss, uv, normalScale);
        float3x3 m_tangentToWorld = GetTangentToWorldMatrix(normalWS_geom, tangentWS_geom);
        surf.normalWS_high = mul(m_tangentToWorld, normalTS);
        surf.normalWS_geom = normalWS_geom;

        #ifdef DETAIL_NORMAL_K
            float3 normalTS_detail = UnpackNormal(SAMPLE_TEXTURE2D(detailNormalMap, ss, uv * detailNormalTiling));
            
            detailNormalScale = lerp(detailNormalScale, 0.0, distanceFromFragToCam / detailVisibleDistance);
            normalTS_detail = ScaleNormalTS(normalTS_detail, detailNormalScale);

            normalTS_detail = BlendNormal_RNM(normalTS*0.5+0.5, normalTS_detail*0.5+0.5);
            float3 normalWS_detail = mul(m_tangentToWorld, normalTS_detail);
        #else 
            float3 normalWS_detail = surf.normalWS_high;
        #endif
        surf.normalWS_detail = normalWS_detail;

        surf.tangentWS_geom = tangentWS_geom.xyz;
        surf.bitangentWS_geom = cross(normalWS_geom, tangentWS_geom.xyz) * tangentWS_geom.w;

        return surf;
    }

    #include "Eyes.hlsl"

    // Eyes 
    ShadingSurface GetShadingSurface_Eyes(Texture2D baseColorMap, float3 tint, float alphaScale, Texture2D rmomMap, float3 rmomScale, Texture2D normalMap, float normalScale, float3 normalWS_geom, Texture2D detailNormalMap, float detailNormalScale, float detailNormalTiling, float detailVisibleDistance, float distanceFromFragToCam, float4 tangentWS_geom, SamplerState ss, inout float2 uv, float3 posWS, float height, float heightScale, float3 frontNormalWS)
    {
        ShadingSurface surf;

        // parallax 
        float3x3 m_tangentToWorld = GetTangentToWorldMatrix(normalWS_geom, tangentWS_geom);
        float3x3 m_worldToTangent = transpose(m_tangentToWorld);
        float3 viewDirWS = GetWorldSpaceNormalizeViewDir(posWS);

        height *= heightScale;
        float2 offsetTS = ParallaxOffset_PhysicallyBased(frontNormalWS, normalWS_geom, viewDirWS, height, m_worldToTangent);
        uv += offsetTS;

        float4 baseColor = SAMPLE_TEXTURE2D(baseColorMap, ss, uv);
        surf.baseColor = baseColor.rgb * tint;
        surf.alpha = baseColor.a * alphaScale;

        half4 rmom = SAMPLE_TEXTURE2D(rmomMap, ss, uv);
        surf.roughness = lerp(0.01, 0.99, rmom.r * rmomScale.r);
        surf.a = surf.roughness * surf.roughness;
        surf.a2 = surf.a * surf.a;
        surf.envMipLevel = PerceptualRoughnessToMipmapLevel(surf.a);
        surf.metallic = lerp(0.01, 0.99, rmom.g * rmomScale.g);
        surf.F0 = lerp(0.04, surf.baseColor, surf.metallic);
        surf.ao = rmom.b * rmomScale.b;
        surf.detailMask = rmom.a;

        float3 normalTS = UnpackNormal_K(normalMap, ss, uv, normalScale);
        surf.normalWS_high = mul(m_tangentToWorld, normalTS);
        surf.normalWS_geom = normalWS_geom;

        #ifdef DETAIL_NORMAL_K
            float3 normalTS_detail = UnpackNormal(SAMPLE_TEXTURE2D(detailNormalMap, ss, uv * detailNormalTiling));
            
            detailNormalScale = lerp(detailNormalScale, 0.0, distanceFromFragToCam / detailVisibleDistance);
            normalTS_detail = ScaleNormalTS(normalTS_detail, detailNormalScale);

            normalTS_detail = BlendNormal_RNM(normalTS*0.5+0.5, normalTS_detail*0.5+0.5);
            float3 normalWS_detail = mul(m_tangentToWorld, normalTS_detail);
        #else 
            float3 normalWS_detail = surf.normalWS_high;
        #endif
        surf.normalWS_detail = normalWS_detail;

        surf.tangentWS_geom = tangentWS_geom.xyz;
        surf.bitangentWS_geom = cross(normalWS_geom, tangentWS_geom.xyz) * tangentWS_geom.w;

        return surf;
    }

#endif 