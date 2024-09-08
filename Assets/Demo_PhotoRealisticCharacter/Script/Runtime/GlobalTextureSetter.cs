using UnityEngine;
using UnityEngine.Rendering;

[ExecuteAlways]
public class GlobalTextureSetter : MonoBehaviour
{
    public Texture2D LUT_IntegrateBRDF;

    private static readonly int IntegrateBrdfLutFID = Shader.PropertyToID("T_LUT_IntegrateBRDF");

    private void OnEnable()
    {
        SetGlobalTexture();
    }


    private void SetGlobalTexture()
    {
        if (LUT_IntegrateBRDF != null)
        {
            Shader.SetGlobalTexture(IntegrateBrdfLutFID, LUT_IntegrateBRDF);
            Debug.Log("Set Global Texture");
        }
        else
        {
            Debug.LogError("Global texture is not assigned.");
        }
    }
}