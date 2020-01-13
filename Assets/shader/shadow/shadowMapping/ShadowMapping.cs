using UnityEngine;
using System.Collections;

public class ShadowMapping : MonoBehaviour {
	
	public Shader depShader;
	public Light shadowLight;
	
	public RenderTexture lightViewZDepth;
	private Camera lightPosCam;

	public Camera cam;

	//
	//public GUISkin skin;

	// Use this for initialization
	void Start () {
        //NINFO 在灯光位置新建一个camera
		GameObject lCam=new GameObject("LightPosCam");
        lightPosCam = lCam.AddComponent<Camera>();
        lightPosCam.CopyFrom(cam);
		lCam.transform.position=shadowLight.transform.position;
		lCam.transform.rotation=shadowLight.transform.rotation;
		
		lightPosCam.aspect=cam.aspect;
        //NINFO 指定灯光camera看到的内容，渲染到RenderTexture lightViewZDepth上
        lightPosCam.targetTexture=lightViewZDepth;
        //NINFO 先把灯光camera enable= false，需要用时再打开
		lightPosCam.enabled=false;
		lightPosCam.clearFlags=CameraClearFlags.SolidColor;
		//NINFO 灯光camera直接挂在到灯光trm下
		lightPosCam.transform.parent=shadowLight.transform;
	}

    //NINFO 在进行场景剔除前
	void OnPreCull()
	{
			//Shader.SetGlobalMatrix("_litSpace",lightPosCam.worldToCameraMatrix);
			
			lightPosCam.RenderWithShader(depShader,"RenderType");
			Shader.SetGlobalTexture("_myShadow",lightViewZDepth);
            //NINFO 知识点，投影阵可以直接从camera取，世界到camera的矩阵也可以直接通过camera取
			Shader.SetGlobalMatrix("_litMVP",lightPosCam.projectionMatrix * lightPosCam.worldToCameraMatrix);
	}

	public void Switch2LightView()
	{
		cam.enabled=false;
		lightPosCam.enabled=true;
		lightPosCam.targetTexture=null;
        //NINFO api查不到这个，猜测时切换targetTexture后，重启相机渲染屏幕的操作
		Camera.SetupCurrent(lightPosCam);
	}

	public void Switch2MainView()
	{
		cam.enabled=true;
		lightPosCam.enabled=false;
		cam.targetTexture=null;
		Camera.SetupCurrent(cam);
	}
	
}
