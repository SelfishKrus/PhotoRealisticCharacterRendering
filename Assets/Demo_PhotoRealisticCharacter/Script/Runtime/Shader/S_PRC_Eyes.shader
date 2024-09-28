Shader "PRC/Eyes"
{
    Properties
    {   
        [Header(Sclera)]
        [Space(10)]
        _T_Sclera_BaseColor ("Sclera Base Color", 2D) = "white" {}
        _BaseColorTint_Sclera ("Base Color Tint", Color) = (1,1,1,1)
        _T_Sclera_Normal ("Normal Map", 2D) = "bump" {}
        _NormalScale_K ("Normal Scale", Range(-5,5)) = 1

        _T_RMOM_Sclera ("RMO", 2D) = "white" {} 
        _RoughnessScale ("Roughness Scale", Range(0, 3)) = 1
        _MetallicScale ("Metallic Scale", Range(0, 3)) = 1
        _AOScale ("AO Scale", Range(0, 3)) = 1

        _WrapLighting ("Wrap Lighting", Range(0, 5)) = 1
        _SSS_n ("SSS n", Float) = 3
        _IrisMask ("Iris Mask From Sclera", Range(-1, 1)) = -0.65
        [Space(20)]

        [Header(Iris)]
        [Space(10)]
        _T_Iris_BaseColor ("Iris Base Color", 2D) = "white" {}
        _BaseColorTint_Iris ("Base Color Tint", Color) = (1,1,1,1)

        _T_Normal_Iris ("Normal Map", 2D) = "bump" {}
        _NormalScale_Iris ("Normal Scale", Range(0,5)) = 1

        _T_Rmom_Iris ("RMO", 2D) = "white" {}
        _RoughnessScale_Iris ("Roughness Scale", Range(0, 1.5)) = 1
        _MetallicScale_Outer ("Metallic Scale", Range(0, 1.5)) = 1
        _AOScale_Outer ("AO Scale", Range(0, 1.5)) = 1

        _T_Height ("Height Map", 2D) = "black" {}
        _HeightScale ("Height Scale", Float) = 1
        [Space(20)]

        [Header(Limbus)]
        [Space(10)]
        _LimbusColor ("Limbus Color", Color) = (1,1,1,1)
        _LimbusPos ("Limbus Position", Range(0, 1)) = 0.5
        _LimbusSmoothness ("Limbus Smoothness", Range(0, 1)) = 0.5
        [Space(20)]

        [Header(Caustic)]
        [Space(10)]
        _CausticIntensity ("Intensity", Range(0, 5)) = 0.5

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
            TEXTURE2D(_T_Sclera_BaseColor);
            TEXTURE2D(_T_Iris_BaseColor);
            TEXTURE2D(_T_Sclera_Normal);
            TEXTURE2D(_T_Height);
            TEXTURE2D(_T_RMOM_Sclera);

            TEXTURE2D(_T_Normal_Iris);
            TEXTURE2D(_T_Rmom_Iris);

            float3 _BaseColorTint_Sclera;
            float3 _BaseColorTint_Iris;
            float _WrapLighting;
            float _RoughnessScale;
            float _MetallicScale;
            float _AOScale;
            float _NormalScale_K;
            float _HeightScale;
            float _IrisMask;
            float4 _Test;

            float _NormalScale_Iris;
            float _RoughnessScale_Iris;
            float _MetallicScale_Outer;
            float _AOScale_Outer;

            float _SSS_n;

            float3 _LimbusColor;
            float _LimbusPos;
            float _LimbusSmoothness;

            float _CausticIntensity;

            #include "K_Lighting.hlsl"
            #include "Eyes.hlsl"

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
                // NormalTS to NormalWS
                float3 bitangentWS = cross(IN.normalWS, IN.tangentWS.xyz) * IN.tangentWS.w;
                float4x4 m_worldToTangent = float4x4(float4(IN.tangentWS.xyz, 0), float4(bitangentWS.xyz, 0), float4(IN.normalWS.xyz, 0), float4(0,0,0,1));
                float4x4 m_tangentToWorld = transpose(m_worldToTangent);
                
                float3 posOS = TransformWorldToObject(IN.posWS);

                // parallax 
                // precision problems 
                // float3 camDirWS = normalize(_WorldSpaceCameraPos.xyz - IN.posWS.xyz);
                // float3 camDirWS = mul(transpose(UNITY_MATRIX_V), float3(0,0,1));
                float3 camDirWS = GetWorldSpaceNormalizeViewDir(IN.posWS);
                float3 camDirOS = TransformWorldToObjectDir(camDirWS);
                float height = SAMPLE_TEXTURE2D(_T_Height, SamplerState_Linear_Repeat, IN.uv).r;
                height *= _HeightScale;
                
                float3 eyeMask = ComputeEyeMask(IN.uv, float2(0.5, 0.5), _LimbusPos, _LimbusSmoothness);

                #if defined(IRIS_PARALLAX)
                    float2 offsetTS = ParallaxOffset_PhysicallyBased(float3(1,0,0), IN.normalWS, camDirWS, height, UNITY_MATRIX_M, m_worldToTangent);
                    float parallaxMask = (1-eyeMask.b);
                    float2 uv_parallax = IN.uv + float2(parallaxMask, parallaxMask) * offsetTS;
                #else 
                    float2 uv_parallax = IN.uv;
                #endif

                // TEX - iris
                float4 rmo = SAMPLE_TEXTURE2D(_T_RMOM_Sclera, SamplerState_Linear_Repeat, uv_parallax);
                float roughness = lerp(0.01, 1.0, rmo.r * _RoughnessScale);
                float metallic = lerp(0.01, 1.0, rmo.g * _MetallicScale);
                float ao = lerp(0.01, 1.0, rmo.b * _AOScale);

                // normal - iris
                float3 normalTS_high = UnpackNormal(SAMPLE_TEXTURE2D_LOD(_T_Sclera_Normal, SamplerState_Linear_Repeat, uv_parallax, 0));
                normalTS_high.xy *= _NormalScale_K;
                normalTS_high.z = sqrt(1 - saturate(dot(normalTS_high.xy, normalTS_high.xy)));
                float3 normalWS_high = mul(m_tangentToWorld, normalTS_high);
                float3 normalWS_geom = IN.normalWS;
                float3 normalOS_geom = TransformWorldToObjectDir(IN.normalWS);

                float a = roughness * roughness;
                float a2 = a*a;
                float mipmapLevelLod = PerceptualRoughnessToMipmapLevel(a);

                // PRE
                DirectionalLightData lightData = _DirectionalLightDatas[0];                

                float3 baseColor = SAMPLE_TEXTURE2D(_T_Sclera_BaseColor, SamplerState_Linear_Repeat, uv_parallax).rgb * _BaseColorTint_Sclera;
                float3 F0 = lerp(0.04, baseColor, metallic);

                float3 lightDirWS = -normalize(lightData.forward);
                float3 lightDirOS = TransformWorldToObjectDir(lightDirWS);
                float3 H = normalize(camDirWS + lightDirWS);

                float NoLUnclamped = dot(normalWS_high, lightDirWS);
                float NoL = saturate(NoLUnclamped);
                float NoH = saturate(dot(normalWS_high, H));
                float VoH = saturate(dot(camDirWS, H));
                float NoV = saturate(dot(normalWS_high, camDirWS));

                // get directional light shadows 
                float2 posSS = IN.pos / _ScreenParams.xy;
                HDShadowContext shadowContext = InitShadowContext();
                #if defined(RECEIVE_DIRECTIONAL_SHADOW)
                    float shadow = GetDirectionalShadowAttenuation(shadowContext,
					                    posSS, IN.posWS, normalWS_geom,
					                    lightData.shadowIndex, lightDirWS);
                #else 
                    float shadow = 1;
                #endif

                // LIMBUS - START //
                float limbusMask = eyeMask.g;
                baseColor = lerp(baseColor, _LimbusColor * baseColor, limbusMask);
                // LIMBUS - END // 


                // IRIS SHADING - START // 
                // directional light - diffuse // 
                #if defined(SCLERA_SSS)
                    float n = _SSS_n;
                    float3 directionalDiffuseIrradiance_iris = pow((NoL + _WrapLighting) / (1 + _WrapLighting), n) * (n + 1) / (2 * (1 + _WrapLighting)) * lightData.color * shadow;
                #else
                    float3 directionalDiffuseIrradiance_iris = NoL * lightData.color * shadow;
                #endif 

                // caustic 
                #if defined(IRIS_CAUSTIC)
                    directionalDiffuseIrradiance_iris *= 1.0 + _CausticIntensity * ComputeCaustic(camDirWS, normalWS_high, lightDirWS, eyeMask);
                #endif 

                float3 diffuseBRDF_iris = Diffuse_Lambert(baseColor);

                float3 directionalDiffuse_iris = diffuseBRDF_iris * directionalDiffuseIrradiance_iris;

                // directional light shading // 
                float3 directionalShading_iris = directionalDiffuse_iris;

                // env lighting - specular //
                // float3 reflectDir = reflect(-camDirWS, normalWS_high);
                // float3 envSpecularBRDF_iris = EnvBRDF(0.04, roughness, NoV);
                // float3 envIBL_iris = SampleSkyTexture(reflectDir, mipmapLevelLod, 0);

                // float3 envSpecular_iris = envSpecularBRDF_iris * envIBL_iris * ao;


                // env lighting - diffuse // 
                float3 envSH_iris = EvaluateLightProbe(normalWS_high);
                float3 envDiffuse_iris = diffuseBRDF_iris * envSH_iris * (1-Fresnel_Schlick(F0, NoV)) * ao;
                // environment shading //
                float3 envShading_iris = envDiffuse_iris;

                float3 shading_iris = directionalShading_iris + envShading_iris;
                // IRIS SHADING - END //


                // OUTER LAYER SHADING - START //
                // normal - outer 
                float3 normalTS_outer = UnpackNormal(SAMPLE_TEXTURE2D_LOD(_T_Normal_Iris, SamplerState_Linear_Repeat, uv_parallax, 0));
                normalTS_outer.xy *= _NormalScale_Iris;
                normalTS_outer.z = sqrt(1 - saturate(dot(normalTS_outer.xy, normalTS_outer.xy)));
                float3 normalWS_outer = mul(m_tangentToWorld, normalTS_outer);
                // Tex - outer
                float3 rmom_outer = SAMPLE_TEXTURE2D(_T_Rmom_Iris, SamplerState_Linear_Repeat, IN.uv);
                float roughness_outer = lerp(0.01, 1.0, rmom_outer.r * _RoughnessScale_Iris);
                float metallic_outer = lerp(0.01, 1.0, rmom_outer.g * _MetallicScale_Outer);
                float ao_outer = lerp(0.01, 1.0, rmom_outer.b * _AOScale_Outer);
                float a_outer = roughness_outer * roughness_outer;
                float a2_outer = a_outer * a_outer;
                // Pre - outer 
                float NoV_outer = saturate(dot(normalWS_outer, camDirWS));
                float NoH_outer = saturate(dot(normalWS_outer, H));
                float NoL_outer = saturate(dot(normalWS_outer, lightDirWS));
                float3 reflectDir_outer = reflect(-camDirWS, normalWS_outer);

                // directional lighting - specular // 
                float D_specular_outer = NDF_GGX(a2_outer, NoH_outer);
                float3 F_specular_outer = Fresnel_Schlick_Fitting(F0, VoH);
                float V_specular_outer = Vis_Schlick(a2_outer, NoV_outer, NoL_outer);
                float3 specularBRDF_outer = D_specular_outer * F_specular_outer * V_specular_outer;

                float3 directionalSpecularIrradiance_outer = NoL_outer * lightData.color * shadow;

                float3 directinalSpecular_outer = specularBRDF_outer * directionalSpecularIrradiance_outer;

                // env lighting - specular // 
                float mipmapLevelLod_outer = PerceptualRoughnessToMipmapLevel(a_outer);
                float3 envSpecularBRDF_outer = EnvBRDF(0.04, roughness_outer, NoV_outer);
                float3 envIBL_outer = SampleSkyTexture(reflectDir_outer, mipmapLevelLod_outer, 0);
                float3 envSpecular_outer = (envSpecularBRDF_outer * envIBL_outer) * ao_outer;

                float3 shading_outer = envSpecular_outer + directinalSpecular_outer;
                // OUTER LAYER SHADING - END //

                float3 col = shading_iris + shading_outer;
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
