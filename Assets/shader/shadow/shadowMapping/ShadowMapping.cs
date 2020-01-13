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
        //NINFO �ڵƹ�λ���½�һ��camera
		GameObject lCam=new GameObject("LightPosCam");
        lightPosCam = lCam.AddComponent<Camera>();
        lightPosCam.CopyFrom(cam);
		lCam.transform.position=shadowLight.transform.position;
		lCam.transform.rotation=shadowLight.transform.rotation;
		
		lightPosCam.aspect=cam.aspect;
        //NINFO ָ���ƹ�camera���������ݣ���Ⱦ��RenderTexture lightViewZDepth��
        lightPosCam.targetTexture=lightViewZDepth;
        //NINFO �Ȱѵƹ�camera enable= false����Ҫ��ʱ�ٴ�
		lightPosCam.enabled=false;
		lightPosCam.clearFlags=CameraClearFlags.SolidColor;
		//NINFO �ƹ�cameraֱ�ӹ��ڵ��ƹ�trm��
		lightPosCam.transform.parent=shadowLight.transform;
	}

    //NINFO �ڽ��г����޳�ǰ
	void OnPreCull()
	{
			//Shader.SetGlobalMatrix("_litSpace",lightPosCam.worldToCameraMatrix);
			
			lightPosCam.RenderWithShader(depShader,"RenderType");
			Shader.SetGlobalTexture("_myShadow",lightViewZDepth);
            //NINFO ֪ʶ�㣬ͶӰ�����ֱ�Ӵ�cameraȡ�����絽camera�ľ���Ҳ����ֱ��ͨ��cameraȡ
			Shader.SetGlobalMatrix("_litMVP",lightPosCam.projectionMatrix * lightPosCam.worldToCameraMatrix);
	}

	public void Switch2LightView()
	{
		cam.enabled=false;
		lightPosCam.enabled=true;
		lightPosCam.targetTexture=null;
        //NINFO api�鲻��������²�ʱ�л�targetTexture�����������Ⱦ��Ļ�Ĳ���
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
