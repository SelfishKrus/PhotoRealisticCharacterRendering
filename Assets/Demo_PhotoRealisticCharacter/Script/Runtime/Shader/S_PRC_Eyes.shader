Shader "PRC/Eyes"
{
    Properties
    {   
        [Header(Eye)]
        [Space(10)]
        _T_BaseColor_Inner ("Inner Base Color", 2D) = "white" {}
        _BaseColorTint_Inner ("Inner Base Color Tint", Color) = (1,1,1,1)
        _T_Normal_Outer ("Outer Normal Map", 2D) = "bump" {}
        _NormalScale_Outer ("Outer Normal Scale", Range(-5,5)) = 1
        _T_Normal_Inner ("Inner Normal Map", 2D) = "bump" {}
        _NormalScale_Inner ("Inner Normal Scale", Range(-5,5)) = 1

        [Space(10)]
        _T_RMOM_Inner ("Inner RMO", 2D) = "white" {} 
        _RoughnessScale_Inner ("Inner Roughness Scale", Range(0, 3)) = 1
        _MetallicScale_Inner ("Inner Metallic Scale", Range(0, 3)) = 1

        [Space(10)]
        _RoughnessScale_Outer ("Outer Roughness Scale", Range(0, 3)) = 1
        _MetallicScale_Outer ("Outer Metallic Scale", Range(0, 3)) = 1

        [Space(10)]
        _T_Height ("Height Map", 2D) = "black" {}
        _HeightScale ("Height Scale", Float) = 1

        [Space(10)]
        _T_Mask ("Mask", 2D) = "white" {}

        [Space(20)]

        [Header(Sclera SSS)]
        [Space(10)]
        _SSS_n ("SSS n", Float) = 3
        _WrapLighting ("Wrap Lighting", Range(0, 5)) = 1
        [Space(20)]

        _CausticIntensity ("Caustic Intensity", Range(0, 10)) = 2
        _CausticContrast ("Caustic Contrast", Range(0, 50)) = 2

        [Header(Rendering Feature)]
        [Space(10)]
        [Toggle(RECEIVE_DIRECTIONAL_SHADOW)] _ReceiveDirectionalShadow ("Receive Directional Shadow", Float) = 1
        [Toggle(DETAIL_NORMAL_K)] _DetailNormal_K ("Enable Detail Normal", Float) = 1
        [Toggle(SCLERA_SSS)] _ScleraSSS ("Enable Sclera SSS", Float) = 1
        [Toggle(IRIS_PARALLAX)] _IrisParallax ("Enable Iris Parallax", Float) = 1
        [Toggle(IRIS_CAUSTIC)] _IrisCaustic ("Enable Iris Caustic", Float) = 1
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

            float4 _T_DetailNormal_ST;

            SAMPLER(SamplerState_Linear_Repeat);
            SAMPLER(SamplerState_Linear_Clamp);
            TEXTURE2D(_T_BaseColor_Inner);
            TEXTURE2D(_T_Normal_Outer);
            TEXTURE2D(_T_Normal_Inner);
            TEXTURE2D(_T_Height);
            TEXTURE2D(_T_RMOM_Inner);
            TEXTURE2D(_T_Mask);

            TEXTURE2D(_T_Rmom_Iris);

            float3 _BaseColorTint_Inner;
            float _WrapLighting;
            float _RoughnessScale_Inner;
            float _MetallicScale_Inner;
            float _RoughnessScale_Outer;
            float _MetallicScale_Outer;
            float _NormalScale_Outer;
            float _NormalScale_Inner;
            float _HeightScale;

            float4 _Test;

            float _SSS_n;
            float _CausticIntensity;
            float _CausticContrast;

            #include "K_Utilities.hlsl"
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
                // === NORMAL === // 
                // Outer Normal // 
                // geom 
                // flip eye's geom normal to simulate iris structure 
                float3 posOS = TransformWorldToObject(IN.posWS);
                float3 normalWS_geom_outer = IN.normalWS;

                float3 bitangentWS = cross(IN.normalWS, IN.tangentWS.xyz) * IN.tangentWS.w;
                float4x4 m_worldToTangent_outer = float4x4(float4(IN.tangentWS.xyz, 0), float4(bitangentWS.xyz, 0), float4(IN.normalWS.xyz, 0), float4(0,0,0,1));
                float4x4 m_tangentToWorld_outer = transpose(m_worldToTangent_outer);

                // outer normal
                float3 normalTS_high_outer = UnpackNormal(SAMPLE_TEXTURE2D_LOD(_T_Normal_Outer, SamplerState_Linear_Repeat, IN.uv, 0));
                normalTS_high_outer = ScaleNormalTS(normalTS_high_outer, _NormalScale_Outer);
                float3 normalWS_high_outer = mul(m_tangentToWorld_outer, float4(normalTS_high_outer,1)).xyz;
                
                // Inner Normal // 
                // geom 
                float3 normalOS_geom_inner = normalize(posOS) * float3(1,1,-1);
                float3 normalWS_geom_inner = TransformObjectToWorldDir(normalOS_geom_inner);

                float3 bitangentWS_inner = cross(normalWS_geom_inner, IN.tangentWS.xyz) * IN.tangentWS.w;
                float4x4 m_worldToTangent_inner = float4x4(float4(IN.tangentWS.xyz, 0), float4(bitangentWS_inner.xyz, 0), float4(normalWS_geom_inner, 0), float4(0,0,0,1));
                float4x4 m_tangentToWorld_inner = transpose(m_worldToTangent_inner);

                // high 
                float3 normalTS_high_inner = UnpackNormal(SAMPLE_TEXTURE2D_LOD(_T_Normal_Inner, SamplerState_Linear_Repeat, IN.uv, 0));
                normalTS_high_inner = ScaleNormalTS(normalTS_high_inner, _NormalScale_Inner);
                float3 normalWS_high_inner = mul(m_tangentToWorld_outer, float4(normalTS_high_inner,1)).xyz;

                // === PARALLAX === // 
                // height 
                float height = _HeightScale * 0.1 *SAMPLE_TEXTURE2D(_T_Height, SamplerState_Linear_Repeat, IN.uv).r;

                // parallax 
                float3 camDirWS = GetWorldSpaceNormalizeViewDir(IN.posWS);
                #if defined(IRIS_PARALLAX)
                    float3 frontNormalOS = float3(1.0, 0.0, 0.0);
                    float2 offsetTS = ParallaxOffset_PhysicallyBased(frontNormalOS, IN.normalWS, camDirWS, height, UNITY_MATRIX_M, m_worldToTangent_outer);
                    IN.uv += offsetTS;
                #endif

                // === Surface === // 
                // Inner // 
                // rmo
                float4 rmo_inner = SAMPLE_TEXTURE2D(_T_RMOM_Inner, SamplerState_Linear_Repeat, IN.uv);
                float roughness_inner = lerp(0.01, 1.0, rmo_inner.r * _RoughnessScale_Inner);
                float metallic_inner = lerp(0.01, 1.0, rmo_inner.g * _MetallicScale_Inner);

                float a_inner = roughness_inner * roughness_inner;
                float a2_inner = a_inner*a_inner;
                float mipmapLevelLod_inner = PerceptualRoughnessToMipmapLevel(a_inner);

                // base color
                float3 baseColor_inner = SAMPLE_TEXTURE2D(_T_BaseColor_Inner, SamplerState_Linear_Repeat, IN.uv).rgb * _BaseColorTint_Inner;
                float3 F0_inner = lerp(0.04, baseColor_inner, metallic_inner);

                // Outer // 
                // rmom 
                float roughness_outer = lerp(0.01, 1.0, _RoughnessScale_Outer);
                float metallic_outer = lerp(0.01, 1.0, _MetallicScale_Outer);

                float a_outer = roughness_outer * roughness_outer;
                float a2_outer = a_outer * a_outer;
                float mipmapLevelLod_outer = PerceptualRoughnessToMipmapLevel(a_outer);

                // base color 
                float3 baseColor_outer = float3(1.0, 1.0, 1.0);
                float3 F0_outer = lerp(0.04, baseColor_outer, metallic_outer);

                // Mask
                // r - pupil, g - iris, b - limbus
                float3 eyeMask = SAMPLE_TEXTURE2D(_T_Mask, SamplerState_Linear_Repeat, IN.uv).rgb;

                // === SHADING VARIABLES === // 
                DirectionalLightData lightData = _DirectionalLightDatas[0];                
                float3 lightDirWS = -normalize(lightData.forward);
                float3 lightDirOS = TransformWorldToObjectDir(lightDirWS);
                float3 H = normalize(camDirWS + lightDirWS);
                float VoH = saturate(dot(camDirWS, H));

                // outer 
                float NoLUnclamped_outer = dot(normalWS_high_outer, lightDirWS);
                float NoL_outer = saturate(NoLUnclamped_outer);
                float NoH_outer = saturate(dot(normalWS_high_outer, H));
                float NoV_outer = saturate(dot(normalWS_high_outer, camDirWS));

                // inner 
                float NoLUnclamped_inner = dot(normalWS_high_inner, lightDirWS);
                float NoL_inner = saturate(NoLUnclamped_inner);
                float NoH_inner = saturate(dot(normalWS_high_inner, H));
                float NoV_inner = saturate(dot(normalWS_high_inner, camDirWS));

                // Get directional light shadows 
                float2 posSS = IN.pos.xy / _ScreenParams.xy;
                HDShadowContext shadowContext = InitShadowContext();
                #if defined(RECEIVE_DIRECTIONAL_SHADOW)
                    float shadow = GetDirectionalShadowAttenuation(shadowContext,
					                    posSS, IN.posWS, normalWS_geom_outer,
					                    lightData.shadowIndex, lightDirWS);
                #else 
                    float shadow = 1;
                #endif

                // === SHADING === // 
                // Outer // 
                // directional specular - outer 
                float D_outer = NDF_GGX(a2_outer, NoH_outer);
                float3 F_outer = Fresnel_Schlick_Fitting(F0_outer, VoH);
                float V_outer = Vis_Schlick(a2_outer, NoV_outer, NoL_outer);
                float3 directionalSpecularBRDF_outer = D_outer * F_outer * V_outer;
                float3 directionalIrradiance_outer = lightData.color * NoL_outer * shadow;
                float3 directionalSpecular_outer = directionalSpecularBRDF_outer * directionalIrradiance_outer;

                // environment specular - outer 
                float3 reflectDir = reflect(-camDirWS, normalWS_high_outer);
                float3 envBRDF_outer = EnvBRDF(F0_outer, roughness_outer, NoV_outer);
                float3 envIrradiance = SampleSkyTexture(reflectDir, mipmapLevelLod_outer, 0).rgb;
                float3 envSpecular_outer = envBRDF_outer * envIrradiance;

                // Inner // 
                // directional caustic - inner 
                float3 mirrorDir = float3(1,1,-1);
                float3 caustic_inner = baseColor_inner * ComputeCaustic(normalWS_geom_inner, lightDirWS, _CausticIntensity, _CausticContrast) * eyeMask.g;

                // environment specular - inner 
                float3 reflectDir_inner = reflect(-camDirWS, normalWS_high_inner);


                // directional diffuse - inner
                float3 directionalDiffuseBRDF = Diffuse_Lambert(baseColor_inner);

                #if defined(SCLERA_SSS)
                    float n = _SSS_n;
                    float3 directionalDiffuseIrradiance = EvaluateScleraSSS(NoL_inner, _WrapLighting, n);
                #else 
                    float3 directionalDiffuseIrradiance = directionalIrradiance_outer;
                #endif 

                float3 directionalDiffuse_inner = directionalDiffuseBRDF * directionalDiffuseIrradiance;

                // environment diffuse - inner 
                float3 envSH = EvaluateLightProbe(normalWS_geom_outer);
                float3 envDiffuse_inner = baseColor_inner * envSH;

                float3 diffuse = directionalDiffuse_inner + envDiffuse_inner;
                float3 specular = directionalSpecular_outer + envSpecular_outer;

                float3 col = specular + diffuse + caustic_inner;
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
