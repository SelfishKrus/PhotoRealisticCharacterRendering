#ifndef PRC_HAIR_INCLUDED
#define PRC_HAIR_INCLUDED

    #include "FastMathThirdParty.hlsl"
    #include "K_Utilities.hlsl"
    
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

    float3 KajiyaKaySpecular (float shift1, float shift2, float3 tangent, float3 normal, float3 h, float3 specCol_R, float3 specCol_TRT, float gloss1, float gloss2, float lerpFac)
    {
        float3 t1 = ShiftTangent_PRC(tangent, normal, shift1);
        float3 t2 = ShiftTangent_PRC(tangent, normal, shift2);

        float3 specular_R = specCol_R * StrandSpecular(t1, h, gloss1);
        float3 specular_TRT = specCol_TRT * StrandSpecular(t2, h, gloss2);

        return lerp(specular_R, specular_TRT, lerpFac);
    }

    float3 BacklitScatter(float cosThetaV, float cosThetaL, float scatterPower, float3 V, float3 L, float lightScale)
    {   
        float scatterFresnel = pow(cosThetaV, scatterPower);
        float scatterLight = pow(saturate(dot(V, -L)), scatterPower) * (1-cosThetaV) * (1.0 - cosThetaL);
        float transAmount = scatterFresnel + lightScale * scatterLight;
        return transAmount;
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

    float3 MultiScattering_Empirical(float3 baseColor, float metallic, float3 L, float3 V, float3 N, float shadow)
    {   
        float KajiyaDiffuse = 1 - abs(dot(N, L));

        float3 fakeNormal = normalize(V - N * dot(V, N));
        float wrap = 1; 
        float NoL = saturate((dot(fakeNormal, L) + wrap) / (1+wrap));
        float DiffuseScatter = lerp(NoL, KajiyaDiffuse, 0.33) * metallic;
        float luma = Luminance_K(baseColor);
        float3 baseOverLuma = abs(baseColor / max(luma, 0.001));
        float3 scatterTint = shadow < 1 ? pow(baseOverLuma, 1 - shadow) : 1;
        
        return sqrt(abs(baseColor)) * DiffuseScatter * scatterTint;
    }

#endif 