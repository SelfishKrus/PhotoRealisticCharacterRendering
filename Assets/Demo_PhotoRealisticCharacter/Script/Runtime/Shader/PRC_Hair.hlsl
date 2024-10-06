#ifndef PRC_HAIR_INCLUDED
#define PRC_HAIR_INCLUDED

    #include "FastMathThirdParty.hlsl"
    
    // ----------------------------------------------------
    // Kajiya-Kay Hair Model
    // GDC 2004 - ATI Research - Hair Rendering and Shading 
    // ----------------------------------------------------

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

    float3 KajiyaKaySpecular (float shift1, float shift2, float3 tangent, float3 normal, float3 h, float3 lightColor, float3 baseColor, float gloss1, float gloss2)
    {
        float3 t1 = ShiftTangent_PRC(tangent, normal, shift1);
        float3 t2 = ShiftTangent_PRC(tangent, normal, shift2);

        float3 specular_R = lightColor * StrandSpecular(t1, h, gloss1);
        float3 specular_TRT = baseColor * lightColor * StrandSpecular(t2, h, gloss2);

        return specular_R + specular_TRT;
    }

    // ----------------------------------------------------
    // Marschner Hair Shading Model 
    // ----------------------------------------------------



    // Fit longitudinal scattering with gaussian function
    // M term
    float Hair_g(float B, float Theta)
    {
	    return exp(-0.5 * Pow2(Theta) / (B * B)) / (sqrt(2 * PI) * B);
    }

    float Hair_F(float CosTheta)
    {
	    const float n = 1.55;
	    const float F0 = Pow2((1 - n) / (1 + n));
	    return F0 + (1 - F0) * Pow5(1 - CosTheta);
    }

#endif 