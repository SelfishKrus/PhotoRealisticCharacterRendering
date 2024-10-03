#ifndef K_SHADING_SURFACE_INCLUDED
#define K_SHADING_SURFACE_INCLUDED

    #include "K_Utilities.hlsl"

    struct ShadingSurface
    {   
        float3 baseColor;

        float roughness;
        float metallic;
        float ao;
        float detailMask;

        float3 normalWS_high;
        float3 normalWS_geom;
    };

    ShadingSurface GetShadingSurface(Texture2D baseColorMap, float3 tint, Texture2D rmomMap, float3 rmoScale, Texture2D normalMap, float normalScale, float3 normalWS_geom, float4 tangentWS_geom, SamplerState ss, float2 uv)
    {
        ShadingSurface surf;

        surf.baseColor = SAMPLE_TEXTURE2D(baseColorMap, ss, uv).rgb * tint;

        surf.roughness = lerp(0.01, 0.99, SAMPLE_TEXTURE2D(rmomMap, ss, uv).r * rmoScale.r);
        surf.metallic = lerp(0.01, 0.99, SAMPLE_TEXTURE2D(rmomMap, ss, uv).g * rmoScale.g);
        surf.ao = SAMPLE_TEXTURE2D(rmomMap, ss, uv).b * rmoScale.b;

        float3 normalTS = UnpackNormal_K(normalMap, ss, uv, normalScale);
        float3x3 m_tangentToWorld = GetTangentToWorldMatrix(normalWS_geom, tangentWS_geom);
        surf.normalWS_high = mul(m_tangentToWorld, normalTS);
        surf.normalWS_geom = normalWS_geom;

        return surf;
    }

#endif 