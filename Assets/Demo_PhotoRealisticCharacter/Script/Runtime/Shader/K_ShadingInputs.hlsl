#ifndef K_SHADING_INPUTS_INCLUDED
#define K_SHADING_INPUTS_INCLUDED

    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariablesFunctions.hlsl"

    float _WrapLighting;

    struct ShadingInputs
    {   
        float3 V;
        float3 L;
        float3 H;

        float NoL_wrap;
        float NoL;
        float NoH;
        float NoV;
        float LoH;
        float VoH;
    };

    ShadingInputs GetShadingInputs(float3 n, float3 posWS, DirectionalLightData lightData, float wrap)
    {
        ShadingInputs inputs;

        inputs.L = -normalize(lightData.forward);
        inputs.V = GetWorldSpaceNormalizeViewDir(posWS);
        inputs.H = normalize(inputs.V + inputs.L);

        float NoLUnclamped = dot(n, inputs.L);

        inputs.NoL_wrap = (NoLUnclamped + wrap) / (1.0f + wrap);
        inputs.NoL = saturate(NoLUnclamped);
        inputs.NoH = saturate(dot(n, inputs.H));
        inputs.NoV = saturate(dot(n, inputs.V));
        inputs.LoH = saturate(dot(inputs.L, inputs.H));
        inputs.VoH = saturate(dot(inputs.V, inputs.H));

        return inputs;
    }

    // Offset Cam pos 
    ShadingInputs GetShadingInputs(float3 n, float3 posWS, float camOffsetY, DirectionalLightData lightData, float wrap)
    {
        ShadingInputs inputs;

        inputs.L = -normalize(lightData.forward);
        inputs.V = GetWorldSpaceNormalizeViewDir(posWS);
        inputs.V.y += camOffsetY;
        inputs.V = normalize(inputs.V);
        inputs.H = normalize(inputs.V + inputs.L);

        float NoLUnclamped = dot(n, inputs.L);

        inputs.NoL_wrap = (NoLUnclamped + wrap) / (1.0f + wrap);
        inputs.NoL = saturate(NoLUnclamped);
        inputs.NoH = saturate(dot(n, inputs.H));
        inputs.NoV = saturate(dot(n, inputs.V));
        inputs.LoH = saturate(dot(inputs.L, inputs.H));
        inputs.VoH = saturate(dot(inputs.V, inputs.H));

        return inputs;
    }

#endif 