Shader "PRC/Skin_PISSS"
{
    Properties
    {   
        [Header(Base Map)]
        [Space(10)]
        _T_BaseColor ("Texture", 2D) = "white" {}
        _T_Normal ("Normal Map", 2D) = "bump" {}
        _NormalScale_K ("Normal Scale", Range(0,5)) = 1
        _LowNormalLod ("Low Normal LOD", Range(0,10)) = 5
        _T_Rmo ("RMO", 2D) = "white" {} 
        _RoughnessScale ("Roughness Scale", Range(0, 5)) = 1
        _AOScale ("AO Scale", Range(0, 1.5)) = 1

        _T_DetailNormal ("Detail Normal Map", 2D) = "bump" {}
        _DetailNormalScale_K ("Detail Normal Scale", Range(0,10)) = 1
        [Space(20)]

        [Header(Subsurface Scattering)]
        [Space(10)]
        _T_Curvature ("Curvature", 2D) = "gray" {}
        _CurvatureScaleBias ("Curvature Scale and Bias", Vector) = (1,0,0,0)
        _T_LUT_Diffuse ("Diffuse LUT", 2D) = "white" {}
        [HDR]_WrapLighting ("Wrap", Color) = (1,1,1,1)
        [Space(20)]

        [Header(Specular)]
        [Space(10)]
        _DirectionalSpecularIntensity ("Directional Specular Intensity", Range(0, 15)) = 8
        _DirectionalSpecularIrradianceBias ("Directional Specular Irradiance Bias", Range(-1, 1)) = 0.725
        [Space(20)]
        
        [Header(Transmittance)]
        [Space(10)]
        _T_Thickness ("Thickness", 2D) = "white" {}
        _TransScaleBiasEnv ("Transmittance Scale and Bias Env", Vector) = (1,0,0,0)
        _TransmittanceTint ("Transmittance Tint", Color) = (1,1,1,1)
        _T_LUT_Trans ("Transmittance LUT", 2D) = "white" {}
        _TransScaleBias ("Transmittance Scale and Bias", Vector) = (1,0,0,0)
        _MinThicknessNormalized ("Min Thickness Normalized", Range(0, 0.01)) = 0.0045
        [Space(20)]
        
        [Toggle(RECEIVE_DIRECTIONAL_SHADOW)] _ReceiveDirectionalShadow ("Receive Directional Shadow", Float) = 1
        [Toggle(DETAIL_NORMAL_K)] _DetailNormal_K ("Enable Detail Normal", Float) = 1
        [Space(20)]

        _Test ("Test", Vector) = (1,1,1,1)
    }

    HLSLINCLUDE

    #pragma target 4.5
    //#pragma enable_d3d11_debug_symbols

    //-------------------------------------------------------------------------------------
    // Variant
    //-------------------------------------------------------------------------------------

    #pragma shader_feature_local _DEPTHOFFSET_ON
    #pragma shader_feature_local _DOUBLESIDED_ON
    #pragma shader_feature_local _ _VERTEX_DISPLACEMENT _PIXEL_DISPLACEMENT
    #pragma shader_feature_local_vertex _VERTEX_DISPLACEMENT_LOCK_OBJECT_SCALE
    #pragma shader_feature_local _DISPLACEMENT_LOCK_TILING_SCALE
    #pragma shader_feature_local_fragment _PIXEL_DISPLACEMENT_LOCK_OBJECT_SCALE
    #pragma shader_feature_local_raytracing _ _REFRACTION_PLANE _REFRACTION_SPHERE _REFRACTION_THIN

    #pragma shader_feature_local_fragment _ _EMISSIVE_MAPPING_PLANAR _EMISSIVE_MAPPING_TRIPLANAR _EMISSIVE_MAPPING_BASE
    #pragma shader_feature_local _ _MAPPING_PLANAR _MAPPING_TRIPLANAR
    #pragma shader_feature_local_raytracing _ _EMISSIVE_MAPPING_PLANAR _EMISSIVE_MAPPING_TRIPLANAR _EMISSIVE_MAPPING_BASE
    #pragma shader_feature_local_raytracing _NORMALMAP_TANGENT_SPACE

    #pragma shader_feature_local _ _REQUIRE_UV2 _REQUIRE_UV3

    #pragma shader_feature_local_raytracing _MASKMAP
    #pragma shader_feature_local_raytracing _BENTNORMALMAP
    #pragma shader_feature_local_raytracing _EMISSIVE_COLOR_MAP

    // _ENABLESPECULAROCCLUSION keyword is obsolete but keep here for compatibility. Do not used
    // _ENABLESPECULAROCCLUSION and _SPECULAR_OCCLUSION_X can't exist at the same time (the new _SPECULAR_OCCLUSION replace it)
    // When _ENABLESPECULAROCCLUSION is found we define _SPECULAR_OCCLUSION_X so new code to work
    #pragma shader_feature_local_fragment _ENABLESPECULAROCCLUSION
    #pragma shader_feature_local_fragment _ _SPECULAR_OCCLUSION_NONE _SPECULAR_OCCLUSION_FROM_BENT_NORMAL_MAP
    #pragma shader_feature_local_raytracing _ENABLESPECULAROCCLUSION
    #pragma shader_feature_local_raytracing _ _SPECULAR_OCCLUSION_NONE _SPECULAR_OCCLUSION_FROM_BENT_NORMAL_MAP

    #ifdef _ENABLESPECULAROCCLUSION
    #define _SPECULAR_OCCLUSION_FROM_BENT_NORMAL_MAP
    #endif

    #pragma shader_feature_local _HEIGHTMAP
    #pragma shader_feature_local_raytracing _TANGENTMAP
    #pragma shader_feature_local_raytracing _ANISOTROPYMAP
    #pragma shader_feature_local_raytracing _DETAIL_MAP
    #pragma shader_feature_local_raytracing _SUBSURFACE_MASK_MAP
    #pragma shader_feature_local_raytracing _THICKNESSMAP
    #pragma shader_feature_local_raytracing _IRIDESCENCE_THICKNESSMAP
    #pragma shader_feature_local_raytracing _SPECULARCOLORMAP
    #pragma shader_feature_local_raytracing _TRANSMITTANCECOLORMAP

    #pragma shader_feature_local_raytracing _DISABLE_SSR

    // MaterialFeature are used as shader feature to allow compiler to optimize properly
    #pragma shader_feature_local_raytracing _MATERIAL_FEATURE_SUBSURFACE_SCATTERING
    #pragma shader_feature_local_raytracing _MATERIAL_FEATURE_TRANSMISSION
    #pragma shader_feature_local_raytracing _MATERIAL_FEATURE_ANISOTROPY
    #pragma shader_feature_local_raytracing _MATERIAL_FEATURE_CLEAR_COAT
    #pragma shader_feature_local_raytracing _MATERIAL_FEATURE_IRIDESCENCE
    #pragma shader_feature_local_raytracing _MATERIAL_FEATURE_SPECULAR_COLOR

    //-------------------------------------------------------------------------------------
    // Define
    //-------------------------------------------------------------------------------------

    // Enable the support of global mip bias in the shader.
    // Only has effect if the global mip bias is enabled in shader config and DRS is enabled.
    #define SUPPORT_GLOBAL_MIP_BIAS

    // This shader support recursive rendering for raytracing
    #define HAVE_RECURSIVE_RENDERING

    // This shader support vertex modification
    #define HAVE_VERTEX_MODIFICATION

    #define SUPPORT_BLENDMODE_PRESERVE_SPECULAR_LIGHTING

    // If we use subsurface scattering, enable output split lighting (for forward pass)
    #if defined(_MATERIAL_FEATURE_SUBSURFACE_SCATTERING) && !defined(_SURFACE_TYPE_TRANSPARENT)
    #define OUTPUT_SPLIT_LIGHTING
    #endif

    #if (defined(_TRANSPARENT_WRITES_MOTION_VEC) || defined(_TRANSPARENT_REFRACTIVE_SORT)) && defined(_SURFACE_TYPE_TRANSPARENT)
    #define _WRITE_TRANSPARENT_MOTION_VECTOR
    #endif

    // Define _DEFERRED_CAPABLE_MATERIAL for shader capable to run in deferred pass
    #ifndef _SURFACE_TYPE_TRANSPARENT
    #define _DEFERRED_CAPABLE_MATERIAL
    #endif

    // In this shader, the heightmap implies depth offsets away from the camera.
    #ifdef _HEIGHTMAP
    #define _CONSERVATIVE_DEPTH_OFFSET
    #endif

    //-------------------------------------------------------------------------------------
    // Include
    //-------------------------------------------------------------------------------------

    // Disable half-precision types in the lit shader since this causes visual corruption in some cases
    #define PREFER_HALF 0

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"

    //-------------------------------------------------------------------------------------
    // variable declaration
    //-------------------------------------------------------------------------------------

    // #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.cs.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitProperties.hlsl"

    // TODO:
    // Currently, Lit.hlsl and LitData.hlsl are included for every pass. Split Lit.hlsl in two:
    // LitData.hlsl and LitShading.hlsl (merge into the existing LitData.hlsl).
    // LitData.hlsl should be responsible for preparing shading parameters.
    // LitShading.hlsl implements the light loop API.
    // LitData.hlsl is included here, LitShading.hlsl is included below for shading passes only.

    ENDHLSL

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
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }

            Cull[_CullMode]

            ZClip [_ZClip]
            ZWrite On
            ZTest LEqual

            ColorMask 0

            HLSLPROGRAM

            #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch
            //enable GPU instancing support
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #pragma multi_compile _ DOTS_INSTANCING_ON
            // enable dithering LOD crossfade
            #pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma shader_feature_local _ALPHATEST_ON

            #define SHADERPASS SHADERPASS_SHADOWS
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitDepthPass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDepthOnly.hlsl"

            #pragma vertex Vert
            #pragma fragment Frag

            ENDHLSL
        }

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

            #pragma multi_compile_fragment PUNCTUAL_SHADOW_LOW PUNCTUAL_SHADOW_MEDIUM PUNCTUAL_SHADOW_HIGH
	        #pragma multi_compile_fragment DIRECTIONAL_SHADOW_LOW DIRECTIONAL_SHADOW_MEDIUM DIRECTIONAL_SHADOW_HIGH
            #pragma multi_compile_fragment AREA_SHADOW_MEDIUM AREA_SHADOW_HIGH
            #pragma multi_compile_fragment RECEIVE_DIRECTIONAL_SHADOW _
            #pragma multi_compile_fragment DETAIL_NORMAL_K _

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinGIUtilities.hlsl"

            // for directional shadow
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/NormalBuffer.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/PunctualLightCommon.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoop.cs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/HDShadow.hlsl"

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Shadow/HDShadowAlgorithms.hlsl"

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

            float4 _MainTex_ST;
            float4 _T_DetailNormal_ST;

            SAMPLER(SamplerState_Linear_Repeat);
            SAMPLER(SamplerState_Linear_Clamp);
            TEXTURE2D(_T_BaseColor);
            TEXTURE2D(_T_Normal);
            TEXTURE2D(_T_DetailNormal);
            TEXTURE2D(_T_Rmo);
            TEXTURE2D(_T_Thickness);

            TEXTURE2D(_T_Curvature);

            TEXTURE2D(_T_LUT_Diffuse);
            TEXTURE2D(_T_LUT_Trans);

            float _RoughnessScale;
            float _AOScale;
            float _NormalScale_K;
            float _DetailNormalScale_K;
            float _LowNormalLod;
            float2 _CurvatureScaleBias;
            float4 _Test;
            float3 _TransmittanceTint;
            float2 _TransScaleBias;
            float2 _TransScaleBiasEnv;
            float _MinThicknessNormalized;
            float4 _WrapLighting;
            float _DirectionalSpecularIntensity;
            float _DirectionalSpecularIrradianceBias;

            #include "PreIntegratedSkin.hlsl"
            #include "HDShadowUtilities.hlsl"

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
                float3 transmittanceColor = _TransmittanceTint;
                float4 rmo = SAMPLE_TEXTURE2D(_T_Rmo, SamplerState_Linear_Repeat, IN.uv);
                float ao = lerp(0, 1, rmo.b * _AOScale);

                // normal 
                float3 normalTS_high = UnpackNormal(SAMPLE_TEXTURE2D_LOD(_T_Normal, SamplerState_Linear_Repeat, IN.uv, 0));
                normalTS_high.xy *= _NormalScale_K;
                normalTS_high.z = sqrt(1 - saturate(dot(normalTS_high.xy, normalTS_high.xy)));
                // specular normal 
                #ifdef DETAIL_NORMAL_K
                    float3 normalTS_detail = UnpackNormal(SAMPLE_TEXTURE2D(_T_DetailNormal, SamplerState_Linear_Repeat, IN.uv * _T_DetailNormal_ST.xx + _T_DetailNormal_ST.zw));
                    normalTS_detail.xy *= _DetailNormalScale_K * rmo.a;
                    normalTS_detail.z = sqrt(1 - saturate(dot(normalTS_detail.xy, normalTS_detail.xy)));
                    float3 normalTS_specular = BlendNormal_RNM(normalTS_high*0.5+0.5, normalTS_detail*0.5+0.5);
                #else 
                    float3 normalTS_specular = normalTS_high;
                #endif

                float3 normalTS_low = UnpackNormal(SAMPLE_TEXTURE2D_LOD(_T_Normal, SamplerState_Linear_Repeat, IN.uv, _LowNormalLod));


                float roughness = lerp(0.001, 1.0, rmo.r * _RoughnessScale);
                float a = roughness * roughness;
                float curvature = SAMPLE_TEXTURE2D(_T_Curvature, SamplerState_Linear_Repeat, IN.uv).r * _CurvatureScaleBias.x + _CurvatureScaleBias.y;

                // NormalTS to NormalWS
                float3 bitangentWS = cross(IN.normalWS, IN.tangentWS.xyz) * IN.tangentWS.w;
                float3x3 m_worldToTangent = float3x3(IN.tangentWS.xyz, bitangentWS.xyz, IN.normalWS.xyz);
                float3x3 m_tangentToWorld = transpose(m_worldToTangent);
                float3 normalWS_high = mul(m_tangentToWorld, normalTS_high);
                float3 normalWS_specular = mul(m_tangentToWorld, normalTS_specular);
                float3 normalWS_low = mul(m_tangentToWorld, normalTS_low);
                float3 normalWS_geom = IN.normalWS;

                // PRE
                DirectionalLightData lightData = _DirectionalLightDatas[0];
                float3 lightDir = -normalize(lightData.forward);
                float3 camDir = normalize(_WorldSpaceCameraPos - IN.posWS);

                float2 posSS = IN.pos / _ScreenParams.xy;
                HDShadowContext shadowContext = InitShadowContext();
                #if defined(RECEIVE_DIRECTIONAL_SHADOW)
                    float shadow = GetDirectionalShadowAttenuation(shadowContext,
					                    posSS, IN.posWS, normalWS_geom,
					                    lightData.shadowIndex, lightDir);
                #else 
                    float shadow = 1;
                #endif

                float NoV = saturate(dot(normalWS_high, camDir));

                // Get thickness from cam depth and light depth
                int unusedSplitIndex;
                float thicknessNormalized = EvaluateThickness(shadowContext, _ShadowmapCascadeAtlas, s_linear_clamp_compare_sampler, posSS, IN.posWS, normalWS_geom, lightData.shadowIndex, lightDir, unusedSplitIndex);
                float thickness = max(thicknessNormalized, _MinThicknessNormalized) * LIGHT_FAR_PLANE;

                // lighting
                // diffuse DL
                float3 diffuse = EvaluateSSSDirectLight(normalWS_high, normalWS_low, baseColor, lightDir, lightData.color, _WrapLighting, curvature, _T_LUT_Diffuse, SamplerState_Linear_Clamp,  shadow);
                // specular DL
                float3 specular = EvaluateSpecularDirectLight(normalWS_specular, camDir, lightDir, lightData.color, roughness, _DirectionalSpecularIntensity, _DirectionalSpecularIrradianceBias, shadow);
                // trans DL
                float3 transmittance = EvaluateTransmittanceDirectLight(transmittanceColor, normalWS_geom, lightDir, lightData.color, thickness, _TransScaleBias.xy, _T_LUT_Trans, SamplerState_Linear_Clamp);
                
                // more transmittance at the edge
                // less transmittance in the center
                //transmittance *= saturate(pow(1-dot(normalWS_geom, camDir), 2));

                // diffuse env
                float3 irradiance_SH = EvaluateLightProbe(normalWS_low);
                float3 diffuse_env = EvaluateSSSEnv(irradiance_SH, baseColor, curvature, _T_LUT_Diffuse, SamplerState_Linear_Clamp, ao);
                // trans env 
                float thickness_env = SAMPLE_TEXTURE2D(_T_Thickness, SamplerState_Linear_Repeat, IN.uv).r;
                float3 transmittance_env = EvaluateTransmittanceEnv(transmittanceColor, thickness_env, _TransScaleBiasEnv.xy, irradiance_SH, _T_LUT_Trans, SamplerState_Linear_Clamp);
                // specular env
                float3 brdf_specular_env = EnvBRDF(0.028, roughness, NoV);
                float mipmapLevelLod = PerceptualRoughnessToMipmapLevel(a);
                float3 reflectDir = reflect(-camDir, normalWS_high);
                float3 irradiance_IBL = SampleSkyTexture(reflectDir, mipmapLevelLod, 0);
                float3 specular_env = brdf_specular_env * irradiance_IBL * ao;

                float3 lighting_DL = diffuse + specular + transmittance;
                float3 lighting_env = transmittance_env + specular_env + diffuse_env;
                
                float3 col = lighting_DL + lighting_env;
                //col = transmittance_env;
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
