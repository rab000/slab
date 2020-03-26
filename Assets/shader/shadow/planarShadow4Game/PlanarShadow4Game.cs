using System.Collections;
using System.Collections.Generic;
using UnityEngine;
//平面阴影辅助类
//搜集
//1 灯光方向，
//2 角色所在(地表)位置
//3 地表所在位置(y值)
public class PlanarShadow4Game : MonoBehaviour
{

    private List<Material> mMatList = new List<Material>();

    //产生影子的那个灯
    public Light mLight;

    private void Awake()
    {
        Renderer[] renderlist = GetComponentsInChildren<Renderer>();

        foreach (var render in renderlist)
        {
            if (render == null)
                continue;

            mMatList.Add(render.material);
        }

    }   
   
    void Update()
    {
        UpdateShader();
    }
   
    private void UpdateShader()
    {
        //角色（站立）世界位置坐标
        Vector4 worldpos = transform.position;
       
        //(产生阴影的)灯光方向
        Vector4 lightDir = mLight.transform.forward;

        foreach (var mat in mMatList)
        {
            if (mat == null)
                continue;

            mat.SetVector("_ObjWorldPos", worldpos);
            mat.SetVector("_ShadowLightDir", lightDir);

            //mat.SetVector("_ShadowPlane", new Vector4(0.0f, 1.0f, 0.0f, 0.1f));
            //mat.SetVector("_ShadowFadeParams", new Vector4(0.0f, 1.5f, 0.7f, 0.0f));

            //这个参数用来控制另一种处理衰减方法的衰减系数
            //mat.SetFloat("_ShadowFalloff", 1.35f);
        }
    }

}
