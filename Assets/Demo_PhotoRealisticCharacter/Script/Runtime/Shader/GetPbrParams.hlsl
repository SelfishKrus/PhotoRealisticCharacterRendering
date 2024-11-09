// Surface 
float distanceFromFragToCam = distance(IN.posWS, _WorldSpaceCameraPos);
_S_Roughness = lerp(_S_Roughness, 1.0, distanceFromFragToCam / _DetailVisibleDistance);

ShadingSurface surf = GetShadingSurface(_BaseColorMap, _BaseColorTint, _S_Opacity, _T_Rmom, float3(_S_Roughness, _S_Metallic, _S_AO), _T_Normal, _S_Normal, IN.normalWS, _T_DetailNormal, _S_DetailNormal, _DetailNormalTiling, _DetailVisibleDistance, distanceFromFragToCam, IN.tangentWS, SamplerState_Linear_Repeat, IN.uv);

float2 posSS = IN.pos.xy / _ScreenParams.xy;

// Shading Variables
DirectionalLightData lightData = _DirectionalLightDatas[0];
ShadingInputs si = GetShadingInputs(surf.normalWS_detail, IN.posWS, lightData, _WrapLighting);
HDShadowContext shadowContext = InitShadowContext();
#if defined(RECEIVE_DIRECTIONAL_SHADOW)
    float shadow = GetDirectionalShadowAttenuation(shadowContext,
					    posSS, IN.posWS, surf.normalWS_geom,
					    lightData.shadowIndex, si.L);
#else 
    float shadow = 1;
#endif