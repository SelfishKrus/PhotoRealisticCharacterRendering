#ifndef MARSCHNER_HAIR_SHADING_PASS_INCLUDED
#define MARSCHNER_HAIR_SHADING_PASS_INCLUDED

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

    float4 _T_DetailNormal_ST;

    TEXTURE2D(_T_BaseColor);
    TEXTURE2D(_T_Normal);
    TEXTURE2D(_T_Rmo);
    TEXTURE2D(_T_Shift);

    float3 _BaseColorTint;
    float _WrapLighting;
    float _RoughnessScale;
    float _MetallicScale;
    float _AOScale;
    float _NormalScale_K;
    float4 _Test;

    float _SpecularRShift;
    float _SpecularTRTShift;
    float _SpecularRGloss;
    float _SpecularTRTGloss;

    float _Transparency;

    Varyings vert (Attributes IN)
    {
        Varyings OUT;
        OUT.pos = TransformObjectToHClip(IN.posOS.xyz);
        OUT.posWS = TransformObjectToWorld(IN.posOS.xyz);
        OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS.xyz);
        OUT.tangentWS = float4(TransformObjectToWorldDir(IN.tangentOS.rgb), IN.tangentOS.w);
        OUT.uv = IN.uv;
        return OUT;
    }

    half4 frag (Varyings IN) : SV_Target
    {   
        // Surface
        ShadingSurface surf = GetShadingSurface(_T_BaseColor, _BaseColorTint, _Transparency, _T_Rmo, float3(_RoughnessScale, _MetallicScale, _AOScale), _T_Normal, _NormalScale_K, IN.normalWS, IN.tangentWS, SamplerState_Linear_Repeat, IN.uv);
        
        #if defined(K_ALPHA_TEST)
            clip(surf.alpha - 0.33);
        #endif

        // Shading Variables 
        DirectionalLightData lightData = _DirectionalLightDatas[0];

        ShadingInputs si = GetShadingInputs(surf.normalWS_high, IN.posWS, lightData, _WrapLighting);

        // Shading // 
        // diffuse 
        float3 diffuse = si.NoL_wrap * surf.baseColor;

        // specular
        float shift = SAMPLE_TEXTURE2D(_T_Shift, SamplerState_Linear_Repeat, IN.uv).r - 0.5;
        float3 specular = KajiyaKaySpecular(shift+_SpecularRShift, shift+_SpecularTRTShift, surf.bitangentWS_geom, surf.normalWS_high, si.H, lightData.color, _BaseColorTint, _SpecularRGloss, _SpecularTRTGloss);

        float3 col = diffuse + specular;
        return half4(col, surf.alpha);
    }

#endif 