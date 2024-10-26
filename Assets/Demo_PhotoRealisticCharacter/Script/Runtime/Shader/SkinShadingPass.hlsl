#ifndef SKIN_SHADING_PASS_INCLUDED
#define SKIN_SHADING_PASS_INCLUDED

    #define DIRECTIONAL_SHADOW_HIGH
    #define LIGHT_FAR_PLANE 30.0

    struct Attributes
    {
        float4 posOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float2 uv : TEXCOORD0;
    };

    struct Varyings
    {
        float2 uv : TEXCOORD0;
        float3 posWS : TEXCOORD1;
        float3 normalWS : NORMAL;
        float4 tangentWS : TANGENT;
        float4 pos : SV_POSITION;
    };


    TEXTURE2D(_T_Thickness);
    TEXTURE2D(_T_Curvature);

    TEXTURE2D(_T_LUT_Diffuse);
    TEXTURE2D(_T_LUT_Trans);

    float _LowNormalSmoothness;
    float _CurvatureScale;
    float _ThicknessScale;
    float3 _TransmittanceTint;
    float _MinThicknessNormalized;
    float _EnvLodBias;

    float3 _WrapLightingRGB;
            
    float4 _Test;

    Varyings vert (Attributes IN)
    {
        Varyings OUT;
        OUT.pos = TransformObjectToHClip(IN.posOS.xyz);
        OUT.posWS = TransformObjectToWorld(IN.posOS.xyz);
        OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
        OUT.tangentWS = float4(TransformObjectToWorldDir(IN.tangentOS.xyz).xyz, IN.tangentOS.w);
        OUT.uv = IN.uv;
        return OUT;
    }

    half4 frag (Varyings IN) : SV_Target
    {   
        // Surface 
        float distanceFromFragToCam = distance(IN.posWS, _WorldSpaceCameraPos);
        _S_Roughness = lerp(_S_Roughness, 1.0, distanceFromFragToCam / _DetailVisibleDistance);

        ShadingSurface surf = GetShadingSurface(_BaseColorMap, _BaseColorTint, _S_Opacity, _T_Rmom, float3(_S_Roughness, _S_Metallic, _S_AO), _T_Normal, _S_Normal, IN.normalWS, _T_DetailNormal, _S_DetailNormal, _DetailNormalTiling, _DetailVisibleDistance, distanceFromFragToCam, IN.tangentWS, SamplerState_Linear_Repeat, IN.uv);

        float2 posSS = IN.pos.xy / _ScreenParams.xy;
        float4 ditherMask = Dither(normalize(IN.pos), posSS);
        float dither = _TaaFrameInfo.r;

        clip(surf.alpha - ditherMask.r * 0.15 - _CutOffThreshold);
        //return float4(ditherMask.rrr, 1);

        // Shading Variables
        DirectionalLightData lightData = _DirectionalLightDatas[0];
        ShadingInputs si = GetShadingInputs(surf.normalWS_high, IN.posWS, lightData, _WrapLighting);

        // Skin Variables 
        float thickness = SAMPLE_TEXTURE2D(_T_Thickness, SamplerState_Linear_Repeat, IN.uv).r;
        thickness = WrapLighting(thickness, _ThicknessScale);
        half3 transmittanceColor = surf.baseColor * _TransmittanceTint;
        float3 normalWS_low = lerp(surf.normalWS_high, surf.normalWS_geom, _LowNormalSmoothness);
        float curvature = SAMPLE_TEXTURE2D(_T_Curvature, SamplerState_Linear_Repeat, IN.uv).r;
        curvature = WrapLighting(curvature, _CurvatureScale);

        HDShadowContext shadowContext = InitShadowContext();
        #if defined(RECEIVE_DIRECTIONAL_SHADOW)
            float shadow = GetDirectionalShadowAttenuation(shadowContext,
					            posSS, IN.posWS, surf.normalWS_geom,
					            lightData.shadowIndex, si.L);
        #else 
            float shadow = 1;
        #endif


        // Get thickness from cam depth and light depth
        // but artefacts
        // use thickness instead 
        // int unusedSplitIndex;
        // float thicknessNormalized = EvaluateThickness(shadowContext, _ShadowmapCascadeAtlas, s_linear_clamp_compare_sampler, posSS, IN.posWS, normalWS_geom, lightData.shadowIndex, lightDir, unusedSplitIndex);
        // float thickness = max(thicknessNormalized, _MinThicknessNormalized) * LIGHT_FAR_PLANE;

        // LIGHTING // 
        // Directional Light 
        // diffuse
        float3 diffuse_DL = EvaluateSSSDirectLight(surf.normalWS_high, normalWS_low, surf.baseColor, si.L, lightData.color.rgb, _WrapLightingRGB, curvature, _T_LUT_Diffuse, SamplerState_Linear_Clamp, shadow);
        // specular
        float3 specular_DL = EvaluateDualLobeDirectionalSpecular(surf.normalWS_detail, si.L, si.V, surf.roughness, 0.5, lightData.color, shadow);
        // transmittance 
        float3 transmittance_DL = EvaluateTransmittanceDirectLight(transmittanceColor, normalWS_low, si.L, lightData.color.rgb, thickness, _T_LUT_Trans, SamplerState_Linear_Clamp);

        // Environment Light // 
        // diffuse
        float NoV_low = saturate(dot(normalWS_low, si.V));
        float3 F_env = Fresnel_Schlick_Roughness(0.028, NoV_low, surf.roughness);
        float3 irradiance_SH = EvaluateLightProbe(normalWS_low);
        float3 diffuse_env = irradiance_SH * surf.baseColor * (1 - F_env) * surf.ao;
        // trans
        float3 transmittance_env = EvaluateTransmittanceEnv(transmittanceColor, thickness, irradiance_SH, _T_LUT_Trans, SamplerState_Linear_Clamp);
        // specular
        float NoV_detail = saturate(dot(surf.normalWS_detail, si.V));
        float3 brdf_specular_env = EnvBRDF(0.028, surf.roughness, NoV_detail);
        float3 reflectDir = reflect(-si.V, surf.normalWS_detail);
        float3 irradiance_IBL = SampleSkyTexture(reflectDir, surf.envMipLevel+2, 0).rgb;
        float3 specular_env = brdf_specular_env * irradiance_IBL * surf.ao;

        float3 lighting_DL = diffuse_DL + specular_DL + transmittance_DL;
        float3 lighting_env = transmittance_env + specular_env + diffuse_env;
                
        float3 col = lighting_DL + lighting_env;
        return half4(col, 1);
    }

#endif 