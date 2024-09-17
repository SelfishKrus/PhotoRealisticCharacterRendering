#ifndef EYES_INCLUDED
#define EYES_INCLUDED

    float2 ParallaxOffset_K(float height, float parallaxScale, float3 view)
    {
        float2 offset = height * view;
        //offset.y = -offset.y;
        return parallaxScale * offset;
    }

    // Real-Time Rendering book (Section 9.5. Refractions)
    // IOR ranges from -1 to 1 otherwise artifacts will appear (don't know why)
    float3 GetEyeRefractDir(float IOR, float3 normal, float3 view)
    {
        float w = IOR * dot(normal, view);
        float k = sqrt( 1 + (w - IOR) * (w + IOR));
        return (w - k) * normal - IOR * view;
    }

    float CircleSDF(float2 uv, float2 center, float radius)
    {
        return saturate(length(uv - center) - radius);
    }

    float2 ParallaxOffset_PhysicallyBased(float3 frontNormalOS, float3 normalWS, float3 viewWS, float height, float4x4 m_ObjectToWorld, float4x4 m_worldToTangent)
    {
        float3 frontNormalWS = mul(m_ObjectToWorld, frontNormalOS);
        float3 refractDirWS = GetEyeRefractDir(1.0, normalWS, viewWS);
        float cosAlpha = dot(frontNormalWS, -refractDirWS);
        float dist = height / cosAlpha;
        float3 offsetWS = dist * refractDirWS;
        float2 offsetTS = mul(m_worldToTangent, offsetWS).xy;

        return offsetTS;
    }

#endif 