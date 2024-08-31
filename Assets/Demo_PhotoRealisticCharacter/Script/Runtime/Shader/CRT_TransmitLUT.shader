Shader "CustomRenderTexture/CRT_TransmitLUT"
{
    Properties 
    {
        _RadiusRange ("Radius Range", Range(0, 100)) = 10
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

            #include "LUTGenerator.hlsl"

            float _RadiusRange;

            float4 frag(v2f_customrendertexture IN) : SV_Target
            {
                float2 uv = IN.localTexcoord.xy;
                // radius - [0,5]
                float3 color = T(uv.x * _RadiusRange);

                return float4(color, 1.0);
            }
            ENDHLSL
        }
    }
}
