using UnityEngine;
using UnityEngine.Rendering;

[ExecuteAlways]
public class GlobalTextureSetter : MonoBehaviour
{
    public Texture2D T_LUT_IntegrateBRDF;
    public Texture2D T_LUT_PHBeckmann;

    private static readonly int IntegrateBrdfLutID = Shader.PropertyToID("T_LUT_IntegrateBRDF");
    private static readonly int PHBeckmannID = Shader.PropertyToID("T_LUT_PHBeckmann");

    private void OnEnable()
    {
        SetGlobalTexture(IntegrateBrdfLutID, T_LUT_IntegrateBRDF);
        SetGlobalTexture(PHBeckmannID, T_LUT_PHBeckmann);
    }


    private void SetGlobalTexture(int shaderPropertyID, Texture2D tex)
    {
        if (shaderPropertyID != 0)
        {
            Shader.SetGlobalTexture(shaderPropertyID, tex);
            Debug.Log($"Set Global Texture: {tex}");
        }
        else
        {
            Debug.LogError($"Global texture {tex} is not assigned.");
        }
    }
}