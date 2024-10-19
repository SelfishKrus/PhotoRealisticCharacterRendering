Shader "PRC/Hair_Marschner"
{
    Properties
    {
        [Header(Surface)]
        [Space(10)]
        _BaseColorMap ("Texture", 2D) = "white" {}
        _BaseColor ("Base Color Tint", Color) = (1,1,1,1)
        _S_Opacity ("Opacity", Range(0, 1)) = 1
        _CutOffThreshold ("CutOff Threshold", Range(0, 1)) = 0.33

        [Space(10)]
        _T_Normal ("Normal Map", 2D) = "bump" {}
        _S_Normal ("Normal Scale", Range(0,5)) = 1
        _LowNormalSmoothness ("Low Normal Smoothness", Range(0,1)) = 0.6

        [Space(10)]
        _T_Rmom ("RMO", 2D) = "white" {} 
        _S_Roughness ("Roughness Scale", Range(0, 5)) = 1
        _S_Metallic ("Metallic Scale", Range(0, 1)) = 1
        _S_AO ("AO Scale", Range(0, 1.5)) = 1

        [Space(10)]
        _T_DetailNormal ("Detail Normal Map", 2D) = "bump" {}
        _S_DetailNormal ("Detail Normal Scale", Range(0,10)) = 1
        _DetailNormalTiling ("Detail Normal Tiling", Float) = 1
        _DetailVisibleDistance ("Detail Visible Distance", Range(0.1, 100)) = 5
        [Space(20)]

        [Toggle(HAIR_SINGLE_SCATTERING_R)] _HairSingleScatteringR ("Hair Single Scattering R", Float) = 1
        [Toggle(HAIR_SINGLE_SCATTERING_TT)] _HairSingleScatteringTT ("Hair Single Scattering TT", Float) = 1
        [Toggle(HAIR_SINGLE_SCATTERING_TRT)] _HairSingleScatteringTRT ("Hair Single Scattering TRT", Float) = 1
        [Toggle(HAIR_MULTIPLE_SCATTERING)] _HairMultipleScattering ("Hair Multiple Scattering", Float) = 1

        [Space(20)]
        [Toggle(RECEIVE_DIRECTIONAL_SHADOW)] _ReceiveDirectionalShadow ("Receive Directional Shadow", Float) = 1

        // Alpha Clip Shadow
        [HideInInspector] _AlphaRemapMin("AlphaRemapMin", Float) = 0.0
        [HideInInspector] _AlphaRemapMax("AlphaRemapMax", Float) = 1.0
        [HideInInspector] _UseShadowThreshold("_UseShadowThreshold", Float) = 1.0
        [HideInInspector] _UVMappingMask("_UVMappingMask", Color) = (1, 0, 0, 0)
        _AlphaCutoffShadow("_AlphaCutoffShadow", Range(0.0, 1.0)) = 0.5

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

        //Pass
        //{   
        //    Name "Hair Prime Z"
        //    Tags
        //    {
        //        "LightMode" = "ForwardOnly"
        //        "Queue" = "Transparent"
        //    }

        //    ZTest Less
        //    ZWrite On
        //    Cull Off
        //    ColorMask 0

        //    HLSLPROGRAM
        //    #pragma vertex vert
        //    #pragma fragment frag

        //    #pragma multi_compile_fragment PUNCTUAL_SHADOW_LOW PUNCTUAL_SHADOW_MEDIUM PUNCTUAL_SHADOW_HIGH
	       // #pragma multi_compile_fragment DIRECTIONAL_SHADOW_LOW DIRECTIONAL_SHADOW_MEDIUM DIRECTIONAL_SHADOW_HIGH
        //    #pragma multi_compile_fragment AREA_SHADOW_MEDIUM AREA_SHADOW_HIGH
        //    #pragma multi_compile_fragment RECEIVE_DIRECTIONAL_SHADOW _
        //    #pragma multi_compile_fragment K_ALPHA_TEST _

        //    #pragma multi_compile_fragment HAIR_SINGLE_SCATTERING_R _
        //    #pragma multi_compile_fragment HAIR_SINGLE_SCATTERING_TT _
        //    #pragma multi_compile_fragment HAIR_SINGLE_SCATTERING_TRT _
        //    #pragma multi_compile_fragment HAIR_MULTIPLE_SCATTERING _

        //    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        //    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
        //    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
        //    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
        //    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"
        //    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinGIUtilities.hlsl"

        //    #define K_ALPHA_TEST
        //    #define SHADER_PASS HAIR_PRIME_Z

        //    #include "K_Utilities.hlsl"
        //    #include "K_ShadingInputs.hlsl"
        //    #include "K_ShadingSurface.hlsl"
        //    #include "K_Lighting.hlsl"
        //    #include "PRC_Hair.hlsl"

        //    #include "MarschnerHairShadingPass.hlsl"

        //    ENDHLSL
        //}

        Pass
        {   
            Name "Hair Opaque"
            Tags
            {
                "Queue" = "Transparent+5"
            }

            ZTest LEqual
            ZWrite On
            Cull Off
            //Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fragment PUNCTUAL_SHADOW_LOW PUNCTUAL_SHADOW_MEDIUM PUNCTUAL_SHADOW_HIGH
	        #pragma multi_compile_fragment DIRECTIONAL_SHADOW_LOW DIRECTIONAL_SHADOW_MEDIUM DIRECTIONAL_SHADOW_HIGH
            #pragma multi_compile_fragment AREA_SHADOW_MEDIUM AREA_SHADOW_HIGH
            #pragma multi_compile_fragment RECEIVE_DIRECTIONAL_SHADOW _
            #pragma multi_compile_fragment K_ALPHA_TEST _

            #pragma multi_compile_fragment HAIR_SINGLE_SCATTERING_R _
            #pragma multi_compile_fragment HAIR_SINGLE_SCATTERING_TT _
            #pragma multi_compile_fragment HAIR_SINGLE_SCATTERING_TRT _
            #pragma multi_compile_fragment HAIR_MULTIPLE_SCATTERING _

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinGIUtilities.hlsl"

            #define K_ALPHA_TEST
            #define SHADER_PASS HAIR_OPAQUE

            #include "K_Utilities.hlsl"
            #include "K_ShadingInputs.hlsl"
            #include "K_ShadingSurface.hlsl"
            #include "K_Lighting.hlsl"
            #include "PRC_Hair.hlsl"

            #include "MarschnerHairShadingPass.hlsl"

            ENDHLSL
        }
    }
}
