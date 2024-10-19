#ifndef EYES_INCLUDED
#define EYES_INCLUDED

float2 ParallaxOffset_K(float height, float parallaxScale, float3 view)
{
    float2 offset = height * view.xy;
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

float2 ParallaxOffset_PhysicallyBased(float3 frontNormalWS, float3 normalWS, float3 viewWS, float height, float3x3 m_worldToTangent)
{
    float3 refractDirWS = GetEyeRefractDir(1, normalWS, viewWS);
    // cosAlpha is approaching 0 at grazing angles, which leads to artefacts
    // need to set a minimum value
    float cosAlpha = max(dot(frontNormalWS, -refractDirWS), 0.2);
    float dist = height / cosAlpha;
    float3 offsetWS = dist * refractDirWS;
    float2 offsetTS = mul(m_worldToTangent, offsetWS).xy;
    
    return offsetTS;
}

float GetEyeHeight(float2 uv, float2 center)
{
    float sdf = CircleSDF(uv, center, 0);

    return smoothstep(0.5, 0.0, sdf);
}

// mask.r - pupil
// mask.g - iris 
// mask.b - limbus
// mask.a - sclera
float4 ComputeEyeMask(float2 uv, float eyeScale, float2 center, float pupilScale, float pupilSmooth, float limbusSmooth)
{   
    uv = (uv - center) * eyeScale + center;
    float sdf = CircleSDF(uv, center, 0);
    float pupil = smoothstep(pupilScale, pupilScale - pupilSmooth * 0.5, sdf);
    float iris = smoothstep(0.5 + limbusSmooth * 2, pupilScale, sdf);
    float limbus = smoothstep(0.5 + limbusSmooth, 0.5, sdf) - smoothstep(0.5, 0.5 - limbusSmooth, sdf);
    float sclera = 1- smoothstep(0.5 + limbusSmooth, 0.5, sdf);
    
    return float4(pupil, iris, limbus, sclera);
}

float3 GetIrisTint(float3 irisColor_inner, float3 irisColor_outer, float3 limbusColor, float4 eyeMask)
{
    float3 iris_tint = lerp(irisColor_outer, irisColor_inner, eyeMask.g);
    iris_tint = lerp(iris_tint, limbusColor, eyeMask.b);
    iris_tint *= 1 - eyeMask.r;
    
    return iris_tint;
}

// ref: Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Eye/Eye.hlsl
float ComputeCaustic(float3 normal, float3 lightDir, float intensity, float contrast)
{
    
    float causticIris = intensity * pow(saturate(dot(normal, lightDir)), contrast);
    // float causticSclera = min(2000.0 * pow(saturate(dot(-normalize(pos.xyz), lightDir.xyz)), 20), 100.0);
    
    return causticIris;
}

float3 EvaluateScleraSSS(float NoL, float3 _WrapLighting, float n)
{   
    float3 val = (NoL + _WrapLighting) / (1 + _WrapLighting);

    return pow(max(val, 0), n) * (n + 1) / (2 * (1 + _WrapLighting));
}



#endif 