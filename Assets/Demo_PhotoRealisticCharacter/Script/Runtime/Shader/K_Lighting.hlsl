#ifndef K_LIGHTING_INCLUDED
#define K_LIGHTING_INCLUDED

    // DL - Directional Light 
    
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinGIUtilities.hlsl"

    #include "K_BxDF.hlsl"
    #include "K_ShadingInputs.hlsl"
    #include "K_ShadingSurface.hlsl"

    float3 EvaluateEnvDiffuse(ShadingSurface surf)
    {   
        float3 irradiance_SH = EvaluateLightProbe(surf.normalWS_geom);
        return surf.baseColor * irradiance_SH;
    }

    float3 EvaluateEnvSpecular(ShadingSurface surf, ShadingInputs si)
    {   
        float3 brdf = EnvBRDF(surf.F0, surf.roughness, si.NoV);

        float3 reflectDir = reflect(-si.V, surf.normalWS_detail);
        float3 irradiance_IBL = SampleSkyTexture(reflectDir, surf.envMipLevel, 0).rgb;

        return brdf * irradiance_IBL;
    }

    float3 EvaluateEnvLighting(ShadingSurface surf, ShadingInputs si)
    {
        float3 diffuse = EvaluateEnvDiffuse(surf);
        float3 specular = EvaluateEnvSpecular(surf, si);

        return diffuse + specular;
    }

#endif 