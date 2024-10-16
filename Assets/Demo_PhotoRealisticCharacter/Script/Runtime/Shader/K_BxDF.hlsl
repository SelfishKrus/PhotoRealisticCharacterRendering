#ifndef BXDF_INCLUDED
#define BXDF_INCLUDED
	
	#ifndef PI
		#define PI 3.14159265359
	#endif 

	// replace lut with tex in the script 
	#define PreIntegratedGF T_LUT_IntegrateBRDF
	#define sampler_PreIntegratedGF sampler_T_LUT_IntegrateBRDF

	// to deal with the difference between unity and ue
	#define Texture2DSampleLevel(tex, sampler, uv, lod) SAMPLE_TEXTURE2D_LOD(tex, sampler, uv, lod)
	#define PreIntegratedGFSampler sampler_PreIntegratedGF

	TEXTURE2D(PreIntegratedGF);
	SAMPLER(sampler_PreIntegratedGF);

	// Physically based shading model
	// parameterized with the below options
	// [ Karis 2013, "Real Shading in Unreal Engine 4" slide 11 ]

	// E = Random sample for BRDF.
	// N = Normal of the macro surface.
	// H = Normal of the micro surface.
	// V = View vector going from surface's position towards the view's origin.
	// L = Light ray direction

	// D = Microfacet NDF
	// G = Shadowing and masking
	// F = Fresnel

	// Vis = G / (4*NoL*NoV)
	// f = Microfacet specular BRDF = D*G*F / (4*NoL*NoV) = D*Vis*F

	// [Blinn 1977, "Models of light reflection for computer synthesized pictures"]
	float NDF_Blinn( float a2, float NoH )
	{
		float n = 2 / a2 - 2;
		return (n+2) / (2*PI) * pow( NoH, n );		// 1 mad, 1 exp, 1 mul, 1 log
	}

	

	// [Beckmann 1963, "The scattering of electromagnetic waves from rough surfaces"]
	float NDF_Beckmann( float a2, float NoH )
	{
		float NoH2 = NoH * NoH;
		return exp( (NoH2 - 1) / (a2 * NoH2) ) / ( PI * a2 * NoH2 * NoH2 );
	}

	// GGX / Trowbridge-Reitz
	// [Walter et al. 2007, "Microfacet models for refraction through rough surfaces"]
	float NDF_GGX( float a2, float NoH )
	{
		float d = ( NoH * a2 - NoH ) * NoH + 1;	// 2 mad
		return a2 / ( PI*d*d );					// 4 mul, 1 rcp
	}
	
	// GPU Gems3
	// origin - left bottom
	// uv.x - NoH
	// uv.y - roughness 
	float NDF_Beckmann_LUT(float NoH, float roughness, Texture2D lutBeckmann, SamplerState ss)
	{
		float2 uv = float2(NoH, roughness);
		return pow(2.0 * lutBeckmann.Sample(ss, uv), 10);
	}


	// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
	float3 Fresnel_Schlick( float3 SpecularColor, float VoH)
	{
		float Fc = pow( 1 - VoH , 5);					// 1 sub, 3 mul
		//return Fc + (1 - Fc) * SpecularColor;		// 1 add, 3 mad
	
		// Anything less than 2% is physically impossible and is instead considered to be shadowing
		return saturate( 50.0 * SpecularColor.g ) * Fc + (1 - Fc) * SpecularColor;
	}

	float3 Fresnel_Schlick(float3 F0, float3 F90, float VoH)
	{
		float Fc = pow(1 - VoH, 5);
		return F90 * Fc + (1 - Fc) * F0;
	}
	
	// https://seblagarde.wordpress.com/2011/08/17/hello-world/
	float3 Fresnel_Schlick_Roughness(float3 F0, float cosTheta, float roughness)
	{	
		float3 gloss = 1 - roughness;
		return F0 + (max(gloss, F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
	}


	// Fresnel - UE Schilick 
	float3 Fresnel_Schlick_Fitting(float3 F0, float cosTheta)
    {
        float Fre = exp2((-5.55473 * cosTheta - 6.98316) * cosTheta);
        return lerp(Fre, 1, F0);
    }

	float3 Fresnel_AdobeF82(float3 F0, float3 F82, float VoH)
	{
		// [Kutz et al. 2021, "Novel aspects of the Adobe Standard Material" ]
		// See Section 2.3 (note the formulas in the paper do not match the code, the code is the correct version)
		// The constants below are derived by just constant folding the terms dependent on CosThetaMax=1/7
		const float Fc = pow(1 - VoH, 5);
		const float K = 49.0 / 46656.0;
		float3 b = (K - K * F82) * (7776.0 + 9031.0 * F0);
		return saturate(F0 + Fc * ((1 - F0) - b * (VoH - VoH * VoH)));
	}

	float3 Fresnel_Textbook( float3 SpecularColor, float VoH )
	{
		float3 SpecularColorSqrt = sqrt( clamp(SpecularColor, float3(0, 0, 0), float3(0.99, 0.99, 0.99) ) );
		float3 n = ( 1 + SpecularColorSqrt ) / ( 1 - SpecularColorSqrt );
		float3 g = sqrt( n*n + VoH*VoH - 1 );
		return 0.5 * sqrt( (g - VoH) / (g + VoH) ) * ( 1 + sqrt( ((g+VoH)*VoH - 1) / ((g-VoH)*VoH + 1) ) );
	}

	// [Neumann et al. 1999, "Compact metallic reflectance models"]
	float Vis_Neumann( float NoV, float NoL )
	{
		return 1 / ( 4 * max( NoL, NoV ) );
	}

	// [Kelemen 2001, "A microfacet based coupled specular-matte brdf model with importance sampling"]
	float Vis_Kelemen( float VoH )
	{
		// constant to prevent NaN
		return rcp( 4 * VoH * VoH + 1e-5);
	}

	// Tuned to match behavior of Vis_Smith
	// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
	float Vis_Schlick( float a2, float NoV, float NoL )
	{
		float k = sqrt(a2) * 0.5;
		float Vis_SchlickV = NoV * (1 - k) + k; // = lerp(NoV, 1, k)
		float Vis_SchlickL = NoL * (1 - k) + k;
		return 0.25 / ( Vis_SchlickV * Vis_SchlickL );
	}

	// Smith term for GGX
	// [Smith 1967, "Geometrical shadowing of a random rough surface"]
	float Vis_Smith( float a2, float NoV, float NoL )
	{
		float Vis_SmithV = NoV + sqrt( NoV * (NoV - NoV * a2) + a2 );
		float Vis_SmithL = NoL + sqrt( NoL * (NoL - NoL * a2) + a2 );
		return rcp( Vis_SmithV * Vis_SmithL );
	}

	// Appoximation of joint Smith term for GGX
	// [Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"]
	float Vis_SmithJointApprox( float a2, float NoV, float NoL )
	{
		float a = sqrt(a2);
		float Vis_SmithV = NoL * ( NoV * ( 1 - a ) + a );
		float Vis_SmithL = NoV * ( NoL * ( 1 - a ) + a );
		return 0.5 * rcp( Vis_SmithV + Vis_SmithL );
	}

	// [Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"]
	float Vis_SmithJoint(float a2, float NoV, float NoL) 
	{
		float Vis_SmithV = NoL * sqrt(NoV * (NoV - NoV * a2) + a2);
		float Vis_SmithL = NoV * sqrt(NoL * (NoL - NoL * a2) + a2);
		return 0.5 * rcp(Vis_SmithV + Vis_SmithL);
	}

	// [Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"]
	float Vis_SmithJointAniso(float ax, float ay, float NoV, float NoL, float XoV, float XoL, float YoV, float YoL)
	{
		float Vis_SmithV = NoL * length(float3(ax * XoV, ay * YoV, NoV));
		float Vis_SmithL = NoV * length(float3(ax * XoL, ay * YoL, NoL));
		return 0.5 * rcp(Vis_SmithV + Vis_SmithL);
	}

	// [Karis 2013, "Real Shading in Unreal Engine 4" slide 11]
	half3 EnvBRDF( half3 SpecularColor, half Roughness, half NoV )
	{
		// Importance sampled preintegrated G * F
		float2 AB = Texture2DSampleLevel( PreIntegratedGF, PreIntegratedGFSampler, float2( NoV, Roughness ), 0 ).rg;

		// Anything less than 2% is physically impossible and is instead considered to be shadowing 
		float3 GF = SpecularColor * AB.x + saturate( 50.0 * SpecularColor.g ) * AB.y;
		return GF;
	}

	half3 EnvBRDF(half3 F0, half3 F90, half Roughness, half NoV)
	{
		// Importance sampled preintegrated G * F
		float2 AB = Texture2DSampleLevel(PreIntegratedGF, PreIntegratedGFSampler, float2(NoV, Roughness), 0).rg;
		float3 GF = F0 * AB.x + F90 * AB.y;
		return GF;
	}

	half2 EnvBRDFApproxLazarov(half Roughness, half NoV)
	{
		// [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
		// Adaptation to fit our G term.
		const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
		const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
		half4 r = Roughness * c0 + c1;
		half a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
		half2 AB = half2(-1.04, 1.04) * a004 + r.zw;
		return AB;
	}

	half3 EnvBRDFApprox( half3 SpecularColor, half Roughness, half NoV )
	{
		half2 AB = EnvBRDFApproxLazarov(Roughness, NoV);

		// Anything less than 2% is physically impossible and is instead considered to be shadowing
		// Note: this is needed for the 'specular' show flag to work, since it uses a SpecularColor of 0
		float F90 = saturate( 50.0 * SpecularColor.g );

		return SpecularColor * AB.x + F90 * AB.y;
	}

	half3 EnvBRDFApprox(half3 F0, half3 F90, half Roughness, half NoV)
	{
		half2 AB = EnvBRDFApproxLazarov(Roughness, NoV);
		return F0 * AB.x + F90 * AB.y;
	}

	half EnvBRDFApproxNonmetal( half Roughness, half NoV )
	{
		// Same as EnvBRDFApprox( 0.04, Roughness, NoV )
		const half2 c0 = { -1, -0.0275 };
		const half2 c1 = { 1, 0.0425 };
		half2 r = Roughness * c0 + c1;
		return min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
	}

	void EnvBRDFApproxFullyRough(inout half3 DiffuseColor, inout half3 SpecularColor)
	{
		// Factors derived from EnvBRDFApprox( SpecularColor, 1, 1 ) == SpecularColor * 0.4524 - 0.0024
		DiffuseColor += SpecularColor * 0.45;
		SpecularColor = 0;
		// We do not modify Roughness here as this is done differently at different places.
	}
	void EnvBRDFApproxFullyRough(inout half3 DiffuseColor, inout half SpecularColor)
	{
		DiffuseColor += SpecularColor * 0.45;
		SpecularColor = 0;
	}
	void EnvBRDFApproxFullyRough(inout half3 DiffuseColor, inout half3 F0, inout half3 F90)
	{
		DiffuseColor += F0 * 0.45;
		F0 = F90 = 0;
	}

	float3 Diffuse_Lambert ( float3 DiffuseColor )
    {
        return DiffuseColor;
    }

#endif 