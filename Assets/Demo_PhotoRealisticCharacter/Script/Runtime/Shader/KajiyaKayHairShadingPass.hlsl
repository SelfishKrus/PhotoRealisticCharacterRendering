#ifndef KAJIYA_KAY_HAIR_SHADING_PASS_INCLUDED
#define KAJIYA_KAY_HAIR_SHADING_PASS_INCLUDED

    struct Attributes
    {
        float4 posOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float2 uv : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
        float3 color : COLOR;
    };

    struct Varyings
    {
        float2 uv : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
        float3 posWS : TEXCOORD2;
        float3 normalWS : NORMAL;
        float4 tangentWS : TANGENT;
        float4 pos : SV_POSITION;
        float3 color : COLOR;
    };

    TEXTURE2D(_T_Shift);
    float4 _T_Shift_ST;
    TEXTURE2D(_T_AO);

    float4 _Test;

    float _SpecularFactor;

    float _SpecularRShift;
    float _SpecularTRTShift;
    float _SpecularRGloss;
    float _SpecularTRTGloss;
    float4 _SpecularR_Tint;
    float4 _SpecularTRT_Tint;

    float _ShadowLuminance;

    float _ScatterPower;
    float _LightScale;

    Varyings vert (Attributes IN)
    {
        Varyings OUT;
        OUT.pos = TransformObjectToHClip(IN.posOS.xyz);
        OUT.posWS = TransformObjectToWorld(IN.posOS.xyz);
        OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS.xyz);
        OUT.tangentWS = float4(TransformObjectToWorldDir(IN.tangentOS.rgb), IN.tangentOS.w);
        OUT.uv = IN.uv;
        OUT.uv1 = IN.uv1;
        OUT.color = IN.color;
        return OUT;
    }

    half4 frag (Varyings IN, float face:VFACE) : SV_Target
    {   

        float distanceFromFragToCam = distance(IN.posWS, _WorldSpaceCameraPos);
        // Surface
        ShadingSurface surf = GetShadingSurface(_BaseColorMap, _BaseColor, _S_Opacity, _T_Rmom, float3(_S_Roughness, _S_Metallic, _S_AO), _T_Normal, _S_Normal, IN.normalWS, _T_DetailNormal, _S_DetailNormal, _DetailNormalTiling, _DetailVisibleDistance, distanceFromFragToCam, IN.tangentWS, SamplerState_Linear_Repeat, IN.uv);

        float2 posSS = IN.pos.xy / _ScreenParams.xy;
        float4 ditherMask = Dither(normalize(IN.pos), posSS);
        float dither = _TaaFrameInfo.r;
        //return float4(ditherMask.rrr, 1);
        
        #if defined(K_ALPHA_TEST)
            clip(surf.alpha - ditherMask.r * 0.1- _CutOffThreshold);
        #endif

        // Shading Variables 
        DirectionalLightData lightData = _DirectionalLightDatas[0];

        ShadingInputs si = GetShadingInputs(surf.normalWS_high, IN.posWS, lightData, _WrapLighting);

        // Shading // 

        // hair shadow
        //float hairShadow = HairShadow(0.5, si.L, surf.normalWS_high, surf.baseColor, _ShadowLuminance);

        // ao
        //float ao = SAMPLE_TEXTURE2D(_T_AO, SamplerState_Linear_Repeat, IN.uv1);
        float ao = SAMPLE_TEXTURE2D(_T_Shift, SamplerState_Linear_Repeat, IN.uv);
        ao = WrapLighting(ao, _S_AO);

        float shadow = ao;

        // diffuse 
        float3 diffuse = si.NoL_wrap * surf.baseColor * lightData.color;

        // specular
        float shift = SAMPLE_TEXTURE2D(_T_Shift, SamplerState_Linear_Repeat, IN.uv * _T_Shift_ST.x).r - 0.5;
        float3 specular = KajiyaKaySpecular(shift+_SpecularRShift, shift+_SpecularTRTShift, surf.bitangentWS_geom, surf.normalWS_high, si.H, _SpecularR_Tint, _SpecularTRT_Tint, _SpecularRGloss, _SpecularTRTGloss, _SpecularFactor) * si.NoL * shadow;

        // backlit scatter 
        float fre = Fresnel_Schlick(0, si.NoV);
        float lightIn = saturate(dot(-surf.normalWS_geom*face, si.L));
        float3 backlitScatter = fre * lightIn * lerp(surf.baseColor, lightData.color, 0.1) * shadow;
        //backlitScatter = lightIn;

        float3 directionalLighting = specular + diffuse + backlitScatter;

        // env specular 
        float3 irradiance_SH = EvaluateLightProbe(surf.normalWS_geom);
        float3 reflectDir = reflect(-si.V, surf.normalWS_high);
        float3 irradiance_IBL = SampleSkyTexture(reflectDir, surf.envMipLevel, 0).rgb;
        
        float3 diffuse_env = irradiance_SH * surf.baseColor * (ao);

        float3 envLighting = diffuse_env;

        float3 col = directionalLighting + envLighting;
        return half4(col, surf.alpha);
    }

    half4 frag_primeZ (Varyings IN) : SV_Target
    {   
        float distanceFromFragToCam = distance(IN.posWS, _WorldSpaceCameraPos);
        ShadingSurface surf = GetShadingSurface(_BaseColorMap, _BaseColorTint, _S_Opacity, _T_Rmom, float3(_S_Roughness, _S_Metallic, _S_AO), _T_Normal, _S_Normal, IN.normalWS, _T_DetailNormal, _S_DetailNormal, _DetailNormalTiling, _DetailVisibleDistance, distanceFromFragToCam, IN.tangentWS, SamplerState_Linear_Repeat, IN.uv);

        clip(surf.alpha - _CutOffThreshold);

        half3 col = 1;
        return half4(col, 1);
    }

#endif 