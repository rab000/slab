using System;
using UnityEngine;

//https://catlikecoding.com/unity/tutorials/advanced-rendering/bloom/
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
    const int DebugBloomPass = 4;

    public Shader bloomShader;

    [NonSerialized] Material bloom;

    /// <summary>
    /// 降采样次数
    /// </summary>
    [Range(1, 16)]public int iterations = 4;

    [Range(0, 10)]public float intensity = 1;

    /// <summary>
    /// 能产生bloom效果的亮度的阈值
    /// </summary>
    [Range(0, 10)]public float threshold = 1;

    /// <summary>
    /// 这个值可以认为用来调整threshold的百分比
    /// </summary>
    [Range(0, 1)]public float softThreshold = 0.5f;

    //这个用来存储降采样时的中间图，用来blend one one到升采样的中间图中
    //之所以是16是16个数能代表65535，一张图缩放一倍，那么16张图可以缩65535倍，实际根本用不到这么多
    //demo只缩3次就是1/8
    RenderTexture[] textures = new RenderTexture[16];

    /// <summary>
    /// 开启就只输出最终的模糊图，而不输出模糊图叠加到原始图上的效果
    /// </summary>
    public bool debug;

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (bloom == null)
        {
            bloom = new Material(bloomShader);
            bloom.hideFlags = HideFlags.HideAndDontSave;
        }


        float knee = threshold * softThreshold;
        Vector4 filter;

        //除了x外，其他3个参数都配合公式，因为具体像素计算在shader中，这里尽可能把能提前在cpu中算好的部分算好，然后再传入gpu
        //像素最大亮度相关的值只能是针对单个像素在gpu中计算，所以这里不能把所有东西都算好再传入gpu
        filter.x = threshold;//阈值
        filter.y = filter.x - knee;
        filter.z = 2f * knee;
        filter.w = 0.25f / (knee + 0.00001f);
        bloom.SetVector("_Filter", filter);       
        //nafio info这里把强度从gamma转到线性要注意下
        bloom.SetFloat("_Intensity", Mathf.GammaToLinearSpace(intensity));


        int width = source.width / 2;
        int height = source.height / 2;
        RenderTextureFormat format = source.format;

        textures[0] = RenderTexture.GetTemporary(width, height, 0, format);
        RenderTexture currentDestination = textures[0];
        Graphics.Blit(source, currentDestination, bloom, BoxDownPrefilterPass);
        RenderTexture currentSource = currentDestination;

        int i = 1;
        //降采样，注意在这之前已经执行了第0次降采样，所以这里从1开始
        for (i=1; i < iterations; i++)
        {
            width = (width>>1);

            height= (height>>1);

            if (height < 2)
            {
                //这里代表缩放次数过多，都已经缩放到低于2像素了，没有意义了
                Debug.LogError("降采样 height:"+height);
                break;
            }

            textures[i] = RenderTexture.GetTemporary(width, height, 0, format);
            currentDestination = textures[i];
            Graphics.Blit(currentSource, currentDestination, bloom, BoxDownPass);
            currentSource = currentDestination;
        }

        // 升采样，注意在循环最后一定会再执行一次渲染到相机的操作，所以这里i -= 2
        //假设降采样迭代2次，那么这里循环就执行1次，最后还会通过Graphics.Blit(currentSource, destination, bloom, ApplyBloomPass);
        //再执行一次，那么升降次数就相同了
        for (i -= 2; i >= 0; i--)
        {
            currentDestination = textures[i];
            textures[i] = null;
            Graphics.Blit(currentSource, currentDestination, bloom, BoxUpPass);
            RenderTexture.ReleaseTemporary(currentSource);
            currentSource = currentDestination;
        }

        if (debug)
        {
            Graphics.Blit(currentSource, destination, bloom, DebugBloomPass);
        }
        else
        {
            bloom.SetTexture("_SourceTex", source);
            Graphics.Blit(currentSource, destination, bloom, ApplyBloomPass);
        }
        RenderTexture.ReleaseTemporary(currentSource);




    }


}
