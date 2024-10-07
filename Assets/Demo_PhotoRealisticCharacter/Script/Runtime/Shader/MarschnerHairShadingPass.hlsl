#ifndef MARSCHNER_HAIR_SHADING_PASS_INCLUDED
#define MARSCHNER_HAIR_SHADING_PASS_INCLUDED

    #include "FastMathThirdParty.hlsl"
    #include "PRC_Hair.hlsl"

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
    float _CutOffThreshold;

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
            clip(surf.alpha - _CutOffThreshold);
        #endif

        // Shading Variables 
        DirectionalLightData lightData = _DirectionalLightDatas[0];

        ShadingInputs si = GetShadingInputs(surf.normalWS_high, IN.posWS, lightData, _WrapLighting);

        // Get directional light shadows 
        float2 posSS = IN.pos.xy / _ScreenParams.xy;
        HDShadowContext shadowContext = InitShadowContext();
        #if defined(RECEIVE_DIRECTIONAL_SHADOW)
            float shadow = GetDirectionalShadowAttenuation(shadowContext,
					            posSS, IN.posWS, surf.normalWS_geom,
					            lightData.shadowIndex, si.L);
        #else 
            float shadow = 1;
        #endif

        // Shading // 

        const float VoL = dot(si.V,si.L);                                                      
        const float SinThetaL = clamp(dot(surf.bitangentWS_geom,si.L), -1.f, 1.f);
	    const float SinThetaV = clamp(dot(surf.bitangentWS_geom,si.V), -1.f, 1.f);

        float CosThetaD = cos( 0.5 * abs( asinFast( SinThetaV ) - asinFast( SinThetaL ) ) );

        const float3 Lp = si.L - SinThetaL * surf.bitangentWS_geom;
	    const float3 Vp = si.V - SinThetaV * surf.bitangentWS_geom;
	    const float CosPhi = dot(Lp,Vp) * rsqrt( dot(Lp,Lp) * dot(Vp,Vp) + 1e-4 );
	    const float CosHalfPhi = sqrt( saturate( 0.5 + 0.5 * CosPhi ) );

        // This is used for faking area light sources by increasing the roughness of the surface. Disabled = 0.
        const float Area = 0;

        // IOR
        float n = 1.55;
        float n_prime = 1.19 / CosThetaD + 0.36 * CosThetaD;

        float Shift = 0.035;

        // based on cuticle scales’ tilt
	    float Alpha[] =
	    {
		    -Shift * 2,
		    Shift,
		    Shift * 4,
	    };	

        // based on roughness
	    float B[] =
	    {
		    Area + Pow2(surf.roughness),
		    Area + Pow2(surf.roughness) / 2,
		    Area + Pow2(surf.roughness) * 2,
	    };

        // SINGLE-SCATTERING // 
        float3 S = 0;

        // R // 
        #if defined(HAIR_SINGLE_SCATTERING_R)
		    const float sa = sin(Alpha[0]);
		    const float ca = cos(Alpha[0]);
            float ShiftR = 2 * sa * (ca * CosHalfPhi * sqrt(1 - SinThetaV * SinThetaV) + sa * SinThetaV);
            float M_R = Hair_g(B[0], SinThetaL + SinThetaV - ShiftR);
            float N_R = 0.25 * CosHalfPhi;
            float F_R = Hair_F(sqrt(saturate(0.5 + 0.5 * VoL)));
            S += M_R * N_R * F_R;
        #endif

        
        // TT // 
        #if defined(HAIR_SINGLE_SCATTERING_TT)
            float M_TT = Hair_g( B[1], SinThetaL + SinThetaV - Alpha[1] );
            float a = 1 / n_prime;
            float h = CosHalfPhi * ( 1 + a * ( 0.6 - 0.8 * CosPhi ) );
            //float h = 0; // Frosbite Engine

            float f_TT = Hair_F( CosThetaD * sqrt( saturate( 1 - h*h ) ) );
            float F_TT = Pow2(1 - f_TT);
            float3 T_TT = pow(abs(surf.baseColor), 0.5 * sqrt(1 - Pow2(h * a)) / CosThetaD);

            float D_TT = exp( -3.65 * CosPhi - 3.98 );
            float3 N_TT = D_TT * F_TT * T_TT;
            S += M_TT * N_TT;
        #endif

        // TRT // 
        #if defined(HAIR_SINGLE_SCATTERING_TRT)
            float M_TRT = Hair_g( B[2], SinThetaL + SinThetaV - Alpha[2] );
		    float f_TRT = Hair_F( CosThetaD * 0.5 );
		    float F_TRT = Pow2(1 - f_TRT) * f_TRT;

            float3 T_TRT = pow(abs(surf.baseColor), 0.8 / CosThetaD );
            float N_TRT = exp( 17 * CosPhi - 16.78 );

            S += M_TRT * N_TRT * F_TRT * T_TRT;
        #endif

        // Multi-Scattering //
        #if defined(HAIR_MULTIPLE_SCATTERING)
            float3 MS = MultiScattering_Empirical(surf.baseColor, si.L, si.V, surf.bitangentWS_geom, shadow);
        #else 
            float3 MS = 0;
        #endif

        //float4 ditherMask = Dither(normalize(IN.pos), posSS * _Test.x);

        //return float4(ditherMask.rgb, 1);

        float3 col = S + MS;
        return half4(col, surf.alpha);
    }

#endif 