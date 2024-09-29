#ifndef HD_SHADOW_UTILITIES_INCLUDED
#define HD_SHADOW_UTILITIES_INCLUDED

#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Shadow/HDShadowAlgorithms.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Shadow/HDShadowSampling.hlsl"

#define GET_DIRECTIONAL_SHADOW_MAP(sd, posSS, posTC, tex, samp, bias) SampleShadow_Gather_PCF_K(_CascadeShadowAtlasSize.zwxy, posTC, tex, samp, bias)
#define FIXED_UNIFORM_BIAS (1.0f / 65536.0f)
#define SAMPLER_K s_linear_clamp_sampler
#define SHRINK_VAL 0.005

real SampleShadow_Gather_PCF_K(float4 shadowAtlasSize, float3 coord, Texture2D tex, SamplerComparisonState compSamp, float depthBias)
{
#if SHADOW_USE_DEPTH_BIAS == 1
    // add the depth bias
    coord.z += depthBias;
#endif

    float2 f = frac(coord.xy * shadowAtlasSize.zw - 0.5f);

    float4 shadowMapTaps;
    shadowMapTaps.x = tex.Sample(SAMPLER_K, coord.xy + float2(-0.5, -0.5) * shadowAtlasSize.xy).r;
    shadowMapTaps.y = tex.Sample(SAMPLER_K, coord.xy + float2( 0.5, -0.5) * shadowAtlasSize.xy).r;
    shadowMapTaps.z = tex.Sample(SAMPLER_K, coord.xy + float2(-0.5,  0.5) * shadowAtlasSize.xy).r;
    shadowMapTaps.w = tex.Sample(SAMPLER_K, coord.xy + float2( 0.5,  0.5) * shadowAtlasSize.xy).r;
    float4 shadowResults = shadowMapTaps.x;
    
    float lerp1 = lerp(shadowResults.w, shadowResults.z, f.x);
    float lerp2 = lerp(shadowResults.x, shadowResults.y, f.x);
    return lerp(lerp1, lerp2, f.y);
}

real SampleShadow_PCF_Tent_7x7_K(float4 shadowAtlasSize, float3 coord, Texture2D tex, SamplerComparisonState compSamp, float depthBias)
{
#if SHADOW_USE_DEPTH_BIAS == 1
    // add the depth bias
    coord.z += depthBias;
#endif
    real shadowmap = 0.0;
    real fetchesWeights[16];
    real2 fetchesUV[16];

    SampleShadow_ComputeSamples_Tent_7x7(shadowAtlasSize, coord.xy, fetchesWeights, fetchesUV);

#if SHADOW_OPTIMIZE_REGISTER_USAGE == 1
    // the loops are only there to prevent the compiler form coalescing all 16 texture fetches which increases register usage
    int i;
    UNITY_LOOP
    for (i = 0; i < 1; i++)
    {
        shadowmap += fetchesWeights[ 0] * tex.Sample(SAMPLER_K, fetchesUV[ 0].xy).x;
        shadowmap += fetchesWeights[ 1] * tex.Sample(SAMPLER_K, fetchesUV[ 1].xy).x;
        shadowmap += fetchesWeights[ 2] * tex.Sample(SAMPLER_K, fetchesUV[ 2].xy).x;
        shadowmap += fetchesWeights[ 3] * tex.Sample(SAMPLER_K, fetchesUV[ 3].xy).x;
    }
    UNITY_LOOP
    for (i = 0; i < 1; i++)
    {
        shadowmap += fetchesWeights[ 4] * tex.Sample(SAMPLER_K, fetchesUV[ 4].xy).x;
        shadowmap += fetchesWeights[ 5] * tex.Sample(SAMPLER_K, fetchesUV[ 5].xy).x;
        shadowmap += fetchesWeights[ 6] * tex.Sample(SAMPLER_K, fetchesUV[ 6].xy).x;
        shadowmap += fetchesWeights[ 7] * tex.Sample(SAMPLER_K, fetchesUV[ 7].xy).x;
    }
    UNITY_LOOP
    for (i = 0; i < 1; i++)
    {
        shadowmap += fetchesWeights[ 8] * tex.Sample(SAMPLER_K, fetchesUV[ 8].xy).x;
        shadowmap += fetchesWeights[ 9] * tex.Sample(SAMPLER_K, fetchesUV[ 9].xy).x;
        shadowmap += fetchesWeights[10] * tex.Sample(SAMPLER_K, fetchesUV[10].xy).x;
        shadowmap += fetchesWeights[11] * tex.Sample(SAMPLER_K, fetchesUV[11].xy).x;
    }
    UNITY_LOOP
    for (i = 0; i < 1; i++)
    {
        shadowmap += fetchesWeights[12] * tex.Sample(SAMPLER_K, fetchesUV[12].xy).x;
        shadowmap += fetchesWeights[13] * tex.Sample(SAMPLER_K, fetchesUV[13].xy).x;
        shadowmap += fetchesWeights[14] * tex.Sample(SAMPLER_K, fetchesUV[14].xy).x;
        shadowmap += fetchesWeights[15] * tex.Sample(SAMPLER_K, fetchesUV[15].xy).x;
    }
#else
    for(int i = 0; i < 16; i++)
    {
        shadowmap += fetchesWeights[i] * tex.Sample(SAMPLER_K, fetchesUV[i].xy).x;
    }
#endif

    return shadowmap;
}

float EvaluateThickness(inout HDShadowContext shadowContext, Texture2D tex, SamplerComparisonState samp, float2 positionSS, float3 positionWS, float3 normalWS, int index, float3 L, out int shadowSplitIndex)
{
    float   alpha;
    int     cascadeCount;
    float   shadow = 1.0;
    shadowSplitIndex = EvalShadow_GetSplitIndex(shadowContext, index, positionWS, alpha, cascadeCount);
#ifdef SHADOWS_SHADOWMASK
    shadowContext.shadowSplitIndex = shadowSplitIndex;
    shadowContext.fade = alpha;
#endif
    float thicknessNormalized = 0.0f;

    float3 basePositionWS = positionWS;

    if (shadowSplitIndex >= 0.0)
    {
        HDShadowData sd = shadowContext.shadowDatas[index];
        LoadDirectionalShadowDatas(sd, shadowContext, index + shadowSplitIndex);
        positionWS = basePositionWS + sd.cacheTranslationDelta.xyz;

        /* normal based bias */
        float worldTexelSize = sd.worldTexelSize;
        float3 orig_pos = positionWS;
        float3 normalBias = EvalShadow_NormalBiasOrtho(sd.worldTexelSize, sd.normalBias, normalWS);
        positionWS += normalBias;

        /* get shadowmap texcoords */
        float3 posTC = EvalShadow_GetTexcoordsAtlas(sd, _CascadeShadowAtlasSize.zw, positionWS - SHRINK_VAL * normalWS, false);
        /* evalute the first cascade */
        shadow = GET_DIRECTIONAL_SHADOW_MAP(sd, positionSS, posTC, tex, samp, FIXED_UNIFORM_BIAS);
        float  shadow1    = 1.0;

        shadowSplitIndex++;
        if (shadowSplitIndex < cascadeCount)
        {
            shadow1 = shadow;

            if (alpha > 0.0)
            {
                LoadDirectionalShadowDatas(sd, shadowContext, index + shadowSplitIndex);

                // We need to modify the bias as the world texel size changes between splits and an update is needed.
                float biasModifier = (sd.worldTexelSize / worldTexelSize);
                normalBias *= biasModifier;

                float3 evaluationPosWS = basePositionWS + sd.cacheTranslationDelta.xyz + normalBias;
                float3 posNDC;
                posTC = EvalShadow_GetTexcoordsAtlas(sd, _CascadeShadowAtlasSize.zw, evaluationPosWS, posNDC, false);
                /* sample the texture */
                UNITY_BRANCH
                if (all(abs(posNDC.xy) <= (1.0 - sd.shadowMapSize.zw * 0.5)))
                    shadow1 = GET_DIRECTIONAL_SHADOW_MAP(sd, positionSS, posTC, tex, samp, FIXED_UNIFORM_BIAS);
            }
        }
        shadow = lerp(shadow, shadow1, alpha); 

        // posTC.z - camera depth 
        // shadow - light depth 
        thicknessNormalized = saturate(shadow - posTC.z);
    }

    return thicknessNormalized;
}


#endif 