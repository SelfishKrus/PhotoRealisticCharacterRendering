#ifndef K_SHADING_INPUTS_INCLUDED
#define K_SHADING_INPUTS_INCLUDED

    struct ShadingInputs
    {
        float3 H;

        float NoL_wrap;
        float NoL;
        float NoH;
        float NoV;
        float LoH;
        float VoH;
    };

    ShadingInputs GetShadingInputs(float3 n, float3 v, float3 l, float wrap)
    {
        ShadingInputs inputs;

        float3 h = normalize(v+l);
        float NoLUnclamped = dot(n, l);

        inputs.H = h;

        inputs.NoL_wrap = (NoLUnclamped + wrap) / (1.0f + wrap);
        inputs.NoL = saturate(NoLUnclamped);
        inputs.NoH = saturate(dot(n, h));
        inputs.NoV = saturate(dot(n, v));
        inputs.LoH = saturate(dot(l, h));
        inputs.VoH = saturate(dot(v, h));

        return inputs;
    }

#endif 