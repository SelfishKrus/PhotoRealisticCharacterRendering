Shader "PRC/Eyeline"
{
    Properties
    {
        [Header(Surface)]
        [Space(10)]
        _BaseColorMap ("Texture", 2D) = "white" {}
        _BaseColor ("Tint", Color) = (1,1,1,1)
        _S_Opacity ("Opacity", Range(0, 1)) = 1
        _CutOffThreshold ("CutOff Threshold", Range(0, 1)) = 0.33
        _WrapLighting ("Wrap Lighting", Range(0, 5)) = 0.5

        [Space(10)]
        _T_Normal ("Normal Map", 2D) = "bump" {}
        _S_Normal ("Normal Scale", Range(0,5)) = 1
        _LowNormalSmoothness ("Low Normal Smoothness", Range(0,1)) = 0.6

        [Space(10)]
        _T_Rmom ("RMO", 2D) = "white" {} 
        _S_Roughness ("Roughness Scale", Range(0, 5)) = 1
        _S_Metallic ("Metallic Scale", Range(0, 1)) = 1

        [Space(10)]
        _T_DetailNormal ("Detail Normal Map", 2D) = "bump" {}
        _S_DetailNormal ("Detail Normal Scale", Range(0,10)) = 1
        _DetailNormalTiling ("Detail Normal Tiling", Float) = 1
        _DetailVisibleDistance ("Detail Visible Distance", Range(1, 100)) = 5
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
            "Queue" = "Transparent"
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

            #define _ALPHATEST_ON

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
            Name "META"
            Tags{ "LightMode" = "META" }

            Cull Off

            HLSLPROGRAM

            #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch
            //enable GPU instancing support
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #pragma shader_feature EDITOR_VISUALIZATION
            #pragma multi_compile _ DOTS_INSTANCING_ON
            // enable dithering LOD crossfade
            #pragma multi_compile _ LOD_FADE_CROSSFADE

            // Lightmap memo
            // DYNAMICLIGHTMAP_ON is used when we have an "enlighten lightmap" ie a lightmap updated at runtime by enlighten.This lightmap contain indirect lighting from realtime lights and realtime emissive material.Offline baked lighting(from baked material / light,
            // both direct and indirect lighting) will hand up in the "regular" lightmap->LIGHTMAP_ON.

            #define SHADERPASS SHADERPASS_LIGHT_TRANSPORT

            // Use Unity's built-in matrices for meta pass rendering
            #define SCENEPICKINGPASS
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/PickingSpaceTransforms.hlsl"

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitSharePass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassLightTransport.hlsl"

            #pragma vertex Vert
            #pragma fragment Frag

            ENDHLSL
        }

        Pass
        {   
            Name "Eyeline"
            Tags
            {   
                "LightMode" = "ForwardOnly"
                "Queue" = "Transparent+10"
            }

            Cull Off
            ZWrite Off
            //ZWrite On
            //ZTest Equal
            ZTest LEqual
            Blend SrcAlpha DstAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fragment PUNCTUAL_SHADOW_LOW PUNCTUAL_SHADOW_MEDIUM PUNCTUAL_SHADOW_HIGH
	        #pragma multi_compile_fragment DIRECTIONAL_SHADOW_LOW DIRECTIONAL_SHADOW_MEDIUM DIRECTIONAL_SHADOW_HIGH
            #pragma multi_compile_fragment AREA_SHADOW_MEDIUM AREA_SHADOW_HIGH
            #pragma multi_compile_fragment RECEIVE_DIRECTIONAL_SHADOW _
            #pragma multi_compile_fragment K_ALPHA_TEST _
            #pragma multi_compile_fragment HAIR_SELF_SHADOW _

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinGIUtilities.hlsl"

            #define DIRECTIONAL_SHADOW_HIGH
            #define K_ALPHA_TEST

            #include "K_Utilities.hlsl"
            #include "K_ShadingInputs.hlsl"
            #include "K_ShadingSurface.hlsl"
            #include "K_Lighting.hlsl"
            #include "PRC_Hair.hlsl"

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
                HDShadowContext shadowContext = InitShadowContext();
                #if defined(RECEIVE_DIRECTIONAL_SHADOW)
                    float shadow = GetDirectionalShadowAttenuation(shadowContext,
					                    posSS, IN.posWS, surf.normalWS_geom,
					                    lightData.shadowIndex, si.L);
                #else 
                    float shadow = 1;
                #endif

                // Shading Variables 
                DirectionalLightData lightData = _DirectionalLightDatas[0];

                ShadingInputs si = GetShadingInputs(surf.normalWS_high, IN.posWS, lightData, _WrapLighting);

                // Shading // 

                // env specular 
                float3 reflectDir = reflect(-si.V, surf.normalWS_detail);
                float3 irradiance_IBL = SampleSkyTexture(reflectDir, surf.envMipLevel, 0).rgb;
                float3 brdf_specular_env = EnvBRDF(surf.F0, surf.roughness, si.NoV);
                float3 specular_env = irradiance_IBL * brdf_specular_env;

                // directional specular 
                float3 brdf = BlinnPhongBrdf(surf, si);
                float3 irradiance = si.NoL * lightData.color * shadow;
                float3 specular_DL = brdf * irradiance;

                float3 col = specular_env + specular_DL;
                return half4(col, surf.alpha);
            }

            ENDHLSL
        }
    }
}
