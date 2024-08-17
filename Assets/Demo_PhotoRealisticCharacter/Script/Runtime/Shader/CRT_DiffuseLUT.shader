Shader "CustomRenderTexture/CRT_DiffuseLUT"
{
    Properties
    {
        _Wrap ("Wrap", Range(0, 1)) = 0
        _Gamma ("Gamma", Float) = 0
        _CurvatureScaleBias ("Curvature Scale Bias", Vector) = (1, 0, 0, 0)
     }

     SubShader
     {
        Blend One Zero

        Pass
        {
            Name "CRT_DiffuseLUT"

            HLSLINCLUDE

            ENDHLSL

            HLSLPROGRAM
            #include "UnityCustomRenderTexture.cginc"
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            #pragma target 3.0

            float _Wrap;
            float _Gamma;
            float2 _CurvatureScaleBias;

            #include "LUTGenerator.hlsl"

            float4 frag(v2f_customrendertexture IN) : SV_Target
            {
                float2 uv = IN.localTexcoord.xy;
                float3 color = GenerateDiffuseLUT((PI - PI * uv.x), uv.y);
                color = pow(color, _Gamma);

                return float4(color, 1.0);
            }
            ENDHLSL
        }
    }
}
