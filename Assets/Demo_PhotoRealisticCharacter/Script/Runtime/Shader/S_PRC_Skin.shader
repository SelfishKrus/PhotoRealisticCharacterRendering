Shader "PRC/Skin"
{
    Properties
    {
        _T_BaseColor ("Texture", 2D) = "white" {}
        _T_Normal ("Normal Map", 2D) = "bump" {}
        _T_Rmo ("RMO", 2D) = "white" {}

        _StencilMask("Stencil Mask", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _Compare("Compare", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _Pass("Pass", Int) = 0
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

            Stencil
            {
                Ref [_StencilMask]
                Comp [_Compare]
                Pass [_Pass]
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
            TEXTURE2D(_T_BaseColor);
            TEXTURE2D(_T_Normal);
            TEXTURE2D(_T_Rmo);

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
                float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_T_Normal, SamplerState_Linear_Repeat, IN.uv));
                float3 rmo = SAMPLE_TEXTURE2D(_T_Rmo, SamplerState_Linear_Repeat, IN.uv).rgb;

                // TBN 
                float3 bitangentWS = cross(IN.normalWS, IN.tangentWS.xyz) * IN.tangentWS.w;
                float3x3 m_worldToTangent = float3x3(IN.tangentWS.xyz, bitangentWS.xyz, IN.normalWS.xyz);
                float3x3 m_tangentToWorld = transpose(m_worldToTangent);
                float3 normalWS = mul(m_tangentToWorld, normalTS);

                // PRE
                DirectionalLightData lightData = _DirectionalLightDatas[0];
                float3 lightDir;
                lightDir.x = lightData.forward;
                lightDir.y = lightData.up;
                lightDir.z = lightData.right;
                float3 lightDirection = normalize(-lightDir.xyz);

                float NoL01 = dot(normalWS, lightDirection);
                
                float3 col = NoL01;
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
