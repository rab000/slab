//圆角图片
//https://blog.csdn.net/dingxiaowei2013/article/details/89216434
Shader "N/ui/uiRiders"
{
    Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_RADIUSBUCE("Radius(圆角半径)",Range(0,0.5))= 0.2   //圆角半径
	}
	SubShader
	{
		pass
		{
			CGPROGRAM
			#pragma exclude_renderers gles
			#pragma vertex vert
			#pragma fragment frag
			#include "unitycg.cginc"
			float _RADIUSBUCE;
			sampler2D _MainTex;

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 ModeUV: TEXCOORD0;
				float2 RadiusBuceVU : TEXCOORD1;
			};
			v2f vert(appdata_base v)
			{
				v2f o;
				o.pos=UnityObjectToClipPos(v.vertex); //v.vertex;
				o.ModeUV=v.texcoord;
				o.RadiusBuceVU=v.texcoord-float2(0.5,0.5);       //将模型UV坐标原点置为中心原点,为了方便计算  原本坐标原点在左下角
				return o;
			}


			fixed4 frag(v2f i):COLOR
			{
				fixed4 col;
				col=(0,1,1,0);

				if(abs(i.RadiusBuceVU.x)<0.5-_RADIUSBUCE||abs(i.RadiusBuceVU.y)<0.5-_RADIUSBUCE)   //像素点坐标在中间一块	不在四个角落	渲染原本的图元颜色
				{
					col=tex2D(_MainTex,i.ModeUV);
				}
				else //如果在四个角落
				{
					if(length(abs(i.RadiusBuceVU)-float2(0.5-_RADIUSBUCE,0.5-_RADIUSBUCE)) <_RADIUSBUCE)  //在圆角的内的像素 坐标到圆心的距离是否小于半径 小于则在圆角之内
					{
						col=tex2D(_MainTex,i.ModeUV);
					}
					else
					{
						discard;  //舍弃图元 相当于clip
					}		
				}
				return col;		
			}
			ENDCG
		}
	}

}
