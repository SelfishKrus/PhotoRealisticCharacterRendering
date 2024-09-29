#ifndef EYES_INCLUDED
#define EYES_INCLUDED

float2 ParallaxOffset_K(float height, float parallaxScale, float3 view)
{
    float2 offset = height * view;
    //offset.y = -offset.y;
    return parallaxScale * offset;
}

// Real-Time Rendering book (Section 9.5. Refractions)
// n ranges from -1 to 1 otherwise artifacts will appear (don't know why)
float3 GetEyeRefractDir(float n, float3 normal, float3 view)
{
    float w = n * dot(normal, view);
    float k = sqrt( 1 + (w - n) * (w + n));
    float3 refractDirWS = (w - k) * normal - n * view;
    
    return normalize(refractDirWS);

}

float CircleSDF(float2 uv, float2 center, float radius)
{
    return saturate(length(uv - center) - radius);
}

float2 ParallaxOffset_PhysicallyBased(float3 frontNormalOS, float3 normalWS, float3 viewWS, float height, float4x4 m_ObjectToWorld, float4x4 m_worldToTangent)
{
    float3 frontNormalWS = normalize(mul(m_ObjectToWorld, frontNormalOS));
    float3 refractDirWS = GetEyeRefractDir(1, normalWS, viewWS);
    // cosAlpha is approaching 0 at grazing angles, which leads to artefacts
    // need to set a minimum value
    float cosAlpha = max(dot(frontNormalWS, -refractDirWS), 0.2);
    float dist = height / cosAlpha;
    float3 offsetWS = dist * refractDirWS;
    float2 offsetTS = mul(m_worldToTangent, offsetWS).xy;
    
    return offsetTS;
}

// mask.r - iris
// mask.g - limbus
// mask.b - sclera
float3 ComputeEyeMask(float2 uv, float2 center, float limbusPos, float limbusSmooth)
{
    float3 eyeMask;
    eyeMask.r = smoothstep(limbusPos, limbusPos - limbusSmooth, CircleSDF(uv, center, 0));
    eyeMask.b = smoothstep(limbusPos, limbusPos + limbusSmooth, CircleSDF(uv, center, 0));
    eyeMask.g = 1 - eyeMask.r - eyeMask.b;
    
    return eyeMask;
}

float Limbus(float2 uv, float threshold, float smoothness)
{   
    float sdf0 = smoothstep(threshold, threshold + smoothness, CircleSDF(uv, float2(0.5, 0.5), 0));
    float sdf1 = smoothstep(threshold, threshold - smoothness, CircleSDF(uv, float2(0.5, 0.5), 0));
    float limbus = sdf1 + sdf0;
    
    return limbus;

}

// ref: Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Eye/Eye.hlsl
float ComputeCaustic(float3 V, float3 normal, float3 lightDir, float3 eyeMask)
{
    if (eyeMask.r < 0.001)
    {
        return 0.0;
    }

    // Totally empirical! TODO: need to revisit
    float causticIris = 2 * pow(saturate(dot(normalize(normal.xz), lightDir.xz)), 2);
    // float causticSclera = min(2000.0 * pow(saturate(dot(-normalize(pos.xyz), lightDir.xyz)), 20), 100.0);
    
    return causticIris * eyeMask.r;
}



#endif 