#ifndef K_UTILITIES_INCLUDED
#define K_UTILITIES_INCLUDED

SAMPLER(SamplerState_Linear_Repeat);
SAMPLER(SamplerState_Linear_Clamp);

float3 ScaleNormalTS(float3 normalTS, float scale)
{
    normalTS.xy *= scale;
    normalTS.z = sqrt(1 - saturate(dot(normalTS.xy, normalTS.xy)));
    
    return normalTS;

}

// From UE Material function Lerp_3Color
float3 Lerp3Color(float3 color1, float3 color2, float3 color3, float a)
{
    float3 lerp0 = lerp(color1, color2, saturate(a * 2));
    float3 lerp1 = lerp(lerp0, color3, saturate(a * 2 - 1));
    
    return lerp1;
}


#endif 