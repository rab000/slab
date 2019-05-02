
//这个demo主要用来说明 offset出现的位置
Shader "N/Unlit/TOffset"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }


		Pass
		{
			Offset -1,-1
			Material{Diffuse(1,1,1,1)}
			Lighting On
			SetTexture[_MainTex]{
				combine texture*primary
			}
		}
	}
}
