#ifndef PRC_HAIR_INCLUDED
#define PRC_HAIR_INCLUDED

    // GDC 2004 - ATI Research - Hair Rendering and Shading 
    float3 ShiftTangent_PRC (float3 t, float3 n, float shift)
    {
        float3 shiftedT = t + shift * n;
        return normalize(shiftedT);
    }

#endif 