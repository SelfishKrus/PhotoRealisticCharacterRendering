Shader "PRC/Skin_PISSS"
{
    Properties
    {
        _T_BaseColor ("Texture", 2D) = "white" {}
        _T_Normal ("Normal Map", 2D) = "bump" {}
        _NormalScale ("Normal Scale", Range(0,5)) = 1
        _T_Rmo ("RMO", 2D) = "white" {} 
        _RoughnessScale ("Roughness Scale", Float) = 1

        _LowNormalLod ("Low Normal LOD", Range(0,10)) = 5
        _WrapRGB ("Wrap", Range(0, 1)) = 1
        _WrapR ("Wrap Red", Range(0, 1)) = 1
        
        _T_Curvature ("Curvature", 2D) = "gray" {}
        _CurvatureScaleBias ("Curvature Scale and Bias", Vector) = (1,0,0,0)
        _T_LUT_Diffuse ("Diffuse LUT", 2D) = "white" {}
        _T_LUT_Shadow ("Shadow LUT", 2D) = "white" {}
        
        _Test ("Test", Vector) = (1,1,1,1)
    }
    SubShader
    {
        Tags 
        {
            "RenderPipeline"="HDRenderPipeline"
            "Queue"="Geometry"
        }
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode" = "ForwardOnly"
            }

            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"

            #pragma multi_compile_fragment PUNCTUAL_SHADOW_LOW PUNCTUAL_SHADOW_MEDIUM PUNCTUAL_SHADOW_HIGH
	        #pragma multi_compile_fragment DIRECTIONAL_SHADOW_LOW DIRECTIONAL_SHADOW_MEDIUM DIRECTIONAL_SHADOW_HIGH
            #pragma multi_compile_fragment AREA_SHADOW_MEDIUM AREA_SHADOW_HIGH


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

            float4 _MainTex_ST;

            SAMPLER(SamplerState_Linear_Repeat);
            SAMPLER(SamplerState_Linear_Clamp);
            TEXTURE2D(_T_BaseColor);
            TEXTURE2D(_T_Normal);
            TEXTURE2D(_T_Rmo);

            TEXTURE2D(_T_Curvature);

            TEXTURE2D(_T_LUT_Diffuse);
            TEXTURE2D(_T_LUT_Shadow);

            float _NormalScale;
            float _RoughnessScale;
            float _WrapRGB;
            float _WrapR;
            float _LowNormalLod;
            float2 _CurvatureScaleBias;
            float4 _Test;

            #include "PreIntegratedSkin.hlsl"

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.pos = TransformObjectToHClip(IN.posOS.xyz);
                OUT.posWS = TransformObjectToWorld(IN.posOS);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.tangentWS = float4(TransformObjectToWorldDir(IN.tangentOS).rgb, IN.tangentOS.w);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {   
                // TEX 
                float3 baseColor = SAMPLE_TEXTURE2D(_T_BaseColor, SamplerState_Linear_Repeat, IN.uv).rgb;
                float3 normalTS_high = UnpackNormal(SAMPLE_TEXTURE2D_LOD(_T_Normal, SamplerState_Linear_Repeat, IN.uv, 0));
                normalTS_high.xy *= _NormalScale;
                normalTS_high.z = sqrt(1 - saturate(dot(normalTS_high.xy, normalTS_high.xy)));
                float3 normalTS_low = UnpackNormal(SAMPLE_TEXTURE2D_LOD(_T_Normal, SamplerState_Linear_Repeat, IN.uv, _LowNormalLod));
                float3 rmo = SAMPLE_TEXTURE2D(_T_Rmo, SamplerState_Linear_Repeat, IN.uv).rgb;
                float roughness = lerp(0.001, 1.0, rmo.r * _RoughnessScale);
                //roughness = saturate(roughness);
                float curvature = SAMPLE_TEXTURE2D(_T_Curvature, SamplerState_Linear_Repeat, IN.uv).r * _CurvatureScaleBias.x + _CurvatureScaleBias.y;

                // NormalTS to NormalWS
                float3 bitangentWS = cross(IN.normalWS, IN.tangentWS.xyz) * IN.tangentWS.w;
                float3x3 m_worldToTangent = float3x3(IN.tangentWS.xyz, bitangentWS.xyz, IN.normalWS.xyz);
                float3x3 m_tangentToWorld = transpose(m_worldToTangent);
                float3 normalWS_high = mul(m_tangentToWorld, normalTS_high);
                float3 normalWS_low = mul(m_tangentToWorld, normalTS_low);
                float3 normalWS_geom = IN.normalWS;

                // PRE
                DirectionalLightData lightData = _DirectionalLightDatas[0];
                float3 lightDir = -normalize(lightData.forward);
                float3 camDir = normalize(_WorldSpaceCameraPos - IN.posWS);

                // Pre-integrated SSS
                float3 diffuse = EvaluateSSSDirectLight(normalWS_high, normalWS_low, baseColor, lightDir, curvature, _T_LUT_Diffuse, SamplerState_Linear_Clamp, _WrapRGB, _WrapR);
                float3 specular = EvaluateSpecularDirectLight(normalWS_high, normalWS_geom, camDir, lightDir, lightData.color, baseColor, roughness, rmo.g);
                
                float3 col =  diffuse + specular;
                col *= rmo.b;
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
