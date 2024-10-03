#ifndef PRC_HAIR_INCLUDED
#define PRC_HAIR_INCLUDED

    // GDC 2004 - ATI Research - Hair Rendering and Shading 
    float3 ShiftTangent_PRC (float3 t, float3 n, float shift)
    {
        float3 shiftedT = t + shift * n;
        return normalize(shiftedT);
    }

    float StrandSpecular (float3 t, float3 h, float exp)
    {
        float ToH = dot(t, h);
        float sinTH = sqrt(1.0 - ToH * ToH);
        float dirAtten = smoothstep(-1.0, 0.0, ToH);

        return dirAtten * pow(sinTH, exp);
    }

#endif 