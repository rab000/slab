using System;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class BloomPostEffect : MonoBehaviour
{

    //标识第0个pass
    const int BoxDownPrefilterPass = 0;
    //标识第1个pass
    const int BoxDownPass = 1;
    //标识第2个pass
    const int BoxUpPass = 2;
    //标识第3个pass
    const int ApplyBloomPass = 3;
    //标识第4个pass
    //const int DebugBloomPass = 4;

    public Shader bloomShader;

    [NonSerialized] Material bloom;

    [Range(0, 10)]public float intensity = 1;

    [Range(0, 10)]public float threshold = 1;


    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (bloom == null)
        {
            bloom = new Material(bloomShader);
            bloom.hideFlags = HideFlags.HideAndDontSave;
        }

        bloom.SetFloat("_Intensity", Mathf.GammaToLinearSpace(intensity));

        RenderTextureFormat format = source.format;

        int width = (source.width >> 1);

        int height = (source.height >> 1);

        RenderTexture currentDestination = RenderTexture.GetTemporary(width, height, 0, format);

        Graphics.Blit(source, currentDestination, bloom, 0);

        bloom.SetTexture("_SourceTex", source);
        Graphics.Blit(currentDestination, destination, bloom, 1);


        RenderTexture.ReleaseTemporary(currentDestination);

    }


}
