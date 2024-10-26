Shader "PRC/Eyes"
{
    Properties
    {   
        [Header(Surface_Inner)]
        [Space(10)]
        _BaseColorMap ("Texture", 2D) = "white" {}
        _BaseColorTint ("Tint", Color) = (1,1,1,1)
        _S_Opacity ("Opacity", Range(0, 1)) = 1
        _CutOffThreshold ("CutOff Threshold", Range(0, 1)) = 0.33

        [Space(10)]
        _T_Normal ("Normal Map", 2D) = "bump" {}
        _S_Normal ("Normal Scale", Range(0,5)) = 1

        [Space(10)]
        _T_Rmom ("RMOM", 2D) = "white" {} 
        _S_Roughness ("Roughness Scale", Range(0, 5)) = 1
        _S_Metallic ("Metallic Scale", Range(0, 1)) = 1
        _S_AO ("AO Scale", Range(0, 1.5)) = 1
        _S_Height ("Height Scale", Range(-0.2, 0.2)) = 0.05
        [Space(20)]

        [Header(Eye Mask)]
        _EyeScale ("Eye Scale", Range(0, 5)) = 1
        _PupilScale ("Pupil Scale", Range(0, 0.5)) = 0.1
        _PupilSmooth ("Pupil Smooth", Range(0, 0.5)) = 0.1
        _LimbusSmooth ("Limbus Smooth", Range(0, 0.5)) = 0.1

        [HideInInspector] _BaseColorMap_Outer ("Texture", 2D) = "white" {}
        [HideInInspector] _BaseColorTint_Outer ("Tint", Color) = (1,1,1,1)
        [HideInInspector] _S_Opacity_Outer ("Opacity", Range(0, 1)) = 1

        [Header(Limbus)]
        _LimbusColor ("Color", Color) = (0.5, 0.5, 0.5, 1)

        [Header(Surface_Outer)]
        [Space(10)]
        _T_Normal_Outer ("Normal Map", 2D) = "bump" {}
        _S_Normal_Outer ("Normal Scale", Range(0,5)) = 1

        [Space(10)]
        [HideInInspector] _T_Rmom_Outer ("RMOM", 2D) = "white" {}
        _S_Roughness_Outer ("Roughness Scale", Range(0, 5)) = 0.05
        _S_Metallic_Outer ("Metallic Scale", Range(0, 1)) = 0.05
        _S_AO_Outer ("AO Scale", Range(0, 1.5)) = 1.0

        [Space(10)]
        _CamOffsetY ("Camera Offset Y", Range(-5, 5)) = 0

        [Header(Caustic)]
        _CausticIntensity ("Intensity", Range(0, 10)) = 2
        _CausticContrast ("Contrast", Range(0, 10)) = 2


        [Space(10)]
        _T_DetailNormal ("Detail Normal Map", 2D) = "bump" {}
        _S_DetailNormal ("Detail Normal Scale", Range(0,10)) = 1
        _DetailNormalTiling ("Detail Normal Tiling", Float) = 1
        _DetailVisibleDistance ("Detail Visible Distance", Range(1, 100)) = 5
        [Space(20)]

        [Header(Rendering Feature)]
        [Space(10)]
        [Toggle(RECEIVE_DIRECTIONAL_SHADOW)] _ReceiveDirectionalShadow ("Receive Directional Shadow", Float) = 1
        [Toggle(DETAIL_NORMAL_K)] _DetailNormal_K ("Enable Detail Normal", Float) = 1
        [Toggle(SCLERA_SSS)] _ScleraSSS ("Enable Sclera SSS", Float) = 1
        [Toggle(IRIS_PARALLAX)] _IrisParallax ("Enable Iris Parallax", Float) = 1
        [Toggle(IRIS_CAUSTIC)] _IrisCaustic ("Enable Iris Caustic", Float) = 1
        [Toggle(PROCEDURAL_LIMBUS)] _ProceduralLimbus ("Enable Procedural Limbus", Float) = 1
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
            #pragma multi_compile_fragment SCLERA_SSS _
            #pragma multi_compile_fragment IRIS_PARALLAX _
            #pragma multi_compile_fragment _DISABLE_SSR _
            #pragma multi_compile_fragment IRIS_CAUSTIC _
            #pragma multi_compile_fragment PROCEDURAL_LIMBUS _

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinGIUtilities.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"

            #define DIRECTIONAL_SHADOW_HIGH

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

            TEXTURE2D(_BaseColorMap_Outer);
            half3 _BaseColorTint_Outer;
            float _S_Opacity_Outer;

            TEXTURE2D(_T_Rmom_Outer);
            float _S_Roughness_Outer;
            float _S_Metallic_Outer;
            float _S_AO_Outer;

            TEXTURE2D(_T_Normal_Outer);
            float _S_Normal_Outer;

            float _CamOffsetY;

            float _EyeScale;
            float _PupilScale;
            float _PupilSmooth;
            float _LimbusSmooth;

            float _CausticIntensity;
            float _CausticContrast;

            float3 _LimbusColor;

            float4 _Test;

            #include "K_Utilities.hlsl"

            #include "K_ShadingInputs.hlsl"
            #include "K_ShadingSurface.hlsl"
            #include "K_Lighting.hlsl"
            #include "Eyes.hlsl"

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.pos = TransformObjectToHClip(IN.posOS.xyz);
                OUT.posWS = TransformObjectToWorld(IN.posOS.xyz).xyz;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.tangentWS = float4(TransformObjectToWorldDir(IN.tangentOS.xyz).xyz, IN.tangentOS.w);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {   
                float height = GetEyeHeight(IN.uv, float2(0.5, 0.5));
                float3 frontNormalWS = normalize(IN.normalWS * float3(1,0,1));

                // INNER SHADING // 
                // Surface
                float distanceFromFragToCam = distance(IN.posWS, _WorldSpaceCameraPos);
                #ifdef IRIS_PARALLAX
                    ShadingSurface surf_inner = GetShadingSurface_Eyes(_BaseColorMap, _BaseColorTint, _S_Opacity, _T_Rmom, float3(_S_Roughness, _S_Metallic, _S_AO), _T_Normal, _S_Normal, IN.normalWS, _T_DetailNormal, _S_DetailNormal, _DetailNormalTiling, _DetailVisibleDistance, distanceFromFragToCam, IN.tangentWS, SamplerState_Linear_Repeat, IN.uv, IN.posWS, height, _S_Height, frontNormalWS);
                #else 
                    ShadingSurface surf_inner = GetShadingSurface(_BaseColorMap, _BaseColorTint, _S_Opacity, _T_Rmom, float3(_S_Roughness, _S_Metallic, _S_AO), _T_Normal, _S_Normal, IN.normalWS, _T_DetailNormal, _S_DetailNormal, _DetailNormalTiling, _DetailVisibleDistance, distanceFromFragToCam, IN.tangentWS, SamplerState_Linear_Repeat, IN.uv);
                #endif 

                // Shading Variables
                DirectionalLightData lightData = _DirectionalLightDatas[0];
                ShadingInputs si_inner = GetShadingInputs(surf_inner.normalWS_high, IN.posWS, lightData, _WrapLighting);

                // Lighting Data
                float2 posSS = IN.pos.xy / _ScreenParams.xy;
                HDShadowContext shadowContext = InitShadowContext();
                #if defined(RECEIVE_DIRECTIONAL_SHADOW)
                    float shadow = GetDirectionalShadowAttenuation(shadowContext,
					                    posSS, IN.posWS, surf_inner.normalWS_geom,
					                    lightData.shadowIndex, si_inner.L);
                #else 
                    float shadow = 1;
                #endif

                // Eye Mask 
                float4 eyeMask = ComputeEyeMask(IN.uv, _EyeScale, float2(0.5, 0.5), _PupilScale, _PupilSmooth, _LimbusSmooth);
                #ifdef PROCEDURAL_LIMBUS
                    surf_inner.baseColor = lerp(surf_inner.baseColor, surf_inner.baseColor * _LimbusColor, eyeMask.b);
                #endif

                float mask = eyeMask.g - eyeMask.r;
                // Directional Light - Diffuse
                float3 irradiance_DL_inner = si_inner.NoL_wrap * lightData.color * shadow;
                float3 diffuse_DL_inner = irradiance_DL_inner * surf_inner.baseColor;

                // Directional Light - Caustic
                #ifdef IRIS_CAUSTIC
                    float3 irisNormalWS = IN.normalWS * float3(1,-1,1);
                    float3 caustic_DL_inner = lightData.color * shadow * surf_inner.baseColor * ComputeCaustic(irisNormalWS, si_inner.L, _CausticIntensity, _CausticContrast) * mask;
                #else
                    float3 caustic_DL_inner = 0;
                #endif

                // Env Light - Diffuse
                float3 irradianceSH = EvaluateLightProbe(IN.normalWS);
                float3 diffuse_env_inner = irradianceSH * surf_inner.baseColor;

                float3 innerShading = diffuse_DL_inner + diffuse_env_inner + caustic_DL_inner;


                // OUTER SHADING // 
                // Surface 
                ShadingSurface surf_outer = GetShadingSurface(_BaseColorMap_Outer, _BaseColorTint_Outer, _S_Opacity_Outer, _T_Rmom_Outer, float3(_S_Roughness_Outer, _S_Metallic_Outer, _S_AO_Outer), _T_Normal_Outer, _S_Normal_Outer, IN.normalWS, _T_DetailNormal, _S_DetailNormal, _DetailNormalTiling, _DetailVisibleDistance, distanceFromFragToCam, IN.tangentWS, SamplerState_Linear_Repeat, IN.uv);

                // Shading Variables
                ShadingInputs si_outer = GetShadingInputs(surf_outer.normalWS_high, IN.posWS, _CamOffsetY,lightData, _WrapLighting);

                // Directional Light - Specular 
                float3 irradiance_DL_outer = si_outer.NoL * lightData.color * shadow;
                // Blinn phong specular 
                float D_DL_outer = NDF_Blinn(surf_outer.a2, si_outer.NoH);
                float3 F_DL_outer = Fresnel_Schlick(surf_outer.F0, si_outer.VoH);
                float V_DL_outer = Vis_Schlick(surf_outer.a2, si_outer.NoV, si_outer.NoL);
                float3 specularBrdf_DL_outer = D_DL_outer * F_DL_outer * V_DL_outer;

                float3 specular_DL_outer = irradiance_DL_outer * specularBrdf_DL_outer;

                // Env Light - Specular
                float3 reflectDir_outer = reflect(-si_outer.V, surf_outer.normalWS_geom);
                float3 irradiance_env_outer = SampleSkyTexture(reflectDir_outer, surf_outer.envMipLevel, 0).rgb;
                float3 specularBrdf_env_outer = EnvBRDF(surf_outer.F0, surf_outer.roughness, si_outer.NoV);
                float3 specular_env_outer = irradiance_env_outer * specularBrdf_env_outer;

                float3 outerShading = specular_env_outer + specular_DL_outer;
                
                half3 col = innerShading + outerShading;
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
