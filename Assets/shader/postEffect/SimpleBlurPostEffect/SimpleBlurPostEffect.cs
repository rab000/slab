
using UnityEngine;

//均值模糊
public class SimpleBlurPostEffect : MonoBehaviour
{
    public Material _Material;

    [Range(0.1f, 10)]
    public float _BlurRadius = 0.1f;

    //缩小采样
    [Range(0, 10)]
    public int downSample = 1;

    //采样次数(模糊次数)
    [Range(0, 10)]
    public int iteration = 1;

    public void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        if (null == _Material) return;

        //nafio info 创建两张图，长宽是原图一半
        RenderTexture rt1 = RenderTexture.GetTemporary(src.width >> downSample, src.height >> downSample, 0, src.format);

        RenderTexture rt2 = RenderTexture.GetTemporary(src.width >> downSample, src.height >> downSample, 0, src.format);

        _Material.SetFloat("_BlurRadius", _BlurRadius);

        Graphics.Blit(src, rt1, _Material);

        for (int i = 0; i < iteration; i++)
        {
            Graphics.Blit(rt1, rt2, _Material);
            Graphics.Blit(rt2, rt1, _Material);
        }

        Graphics.Blit(rt1, dst, _Material);

        RenderTexture.ReleaseTemporary(rt1);

        RenderTexture.ReleaseTemporary(rt2);


    }

}
