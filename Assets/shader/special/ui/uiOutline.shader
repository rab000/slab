//2D图片描边	 核心思路：检测某个图元的alpha值是否在某个阀值之间
//这个shader的问题是边缘不够柔和
//https://blog.csdn.net/dingxiaowei2013/article/details/89216434
Shader "N/ui/uiOutline"
{
    Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1) //图像回合颜色
		_OutLineColor("OutLineColor", Color) = (1,1,1,1) //边缘颜色
		_CheckRange("CheckRange",Float) = 1	  //检测的范围
		_CheckAccuracy("CheckAccuracy",Float) = 0.5//检测精度
		_LineWidth("LineWidth",Float) = 2	   //边缘宽度
	}
 
	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}
 
		Cull Off         //关闭背面剔除
		Lighting Off     //关闭灯光
		ZWrite Off       //关闭Z缓冲
		Blend One OneMinusSrcAlpha     //混合源系数one(1)  目标系数OneMinusSrcAlpha(1-one=0)
 
		Pass
		{
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ PIXELSNAP_ON       //告诉Unity编译不同版本的Shader,这里和后面vert中的PIXELSNAP_ON对应
			#include "UnityCG.cginc"
			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			
			fixed4 _Color;
			fixed4 _OutLineColor;
			float _CheckAccuracy;
			float _LineWidth;
			float _CheckRange;
			struct appdata_t                           //vert输入
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
			};
 
			struct v2f                                 //vert输出数据结构
			{
				float4 vertex   : SV_POSITION;
				fixed4 color    : COLOR;
				float2 texcoord  : TEXCOORD0;
			};
 
			v2f vert(appdata_t IN)
			{
				v2f OUT;
				OUT.vertex = UnityObjectToClipPos(IN.vertex);
				OUT.texcoord = IN.texcoord;
				OUT.color = IN.color * _Color;
				#ifdef PIXELSNAP_ON
				OUT.vertex = UnityPixelSnap (OUT.vertex);
				#endif
 
				return OUT;
			}
 
			fixed4 SampleSpriteTexture (float2 uv)
			{
				fixed4 color = tex2D (_MainTex, uv);
				return color;
			}
			
			fixed4 frag(v2f IN) : SV_Target
			{
				fixed4 c = SampleSpriteTexture (IN.texcoord) * IN.color;

				c.rgb *= c.a;

				float isOut = step(abs(1/_LineWidth),c.a);	//检测每个图元的aplha是否在某个值 那么他就是边缘	  //step(a, x) Returns (x >= a) ? 1 : 0	   abs(x) 返回绝对值
				
				//NINFO 只要a>(1/_LineWidth)，isOut会返回1
				
				if(isOut != 0)
				{
					//NINFO 注意_MainTex_TexelSize返回的是跟贴图分辨率相关的值，比如256*256贴图，那么对应xy就是1/256 ，1/256
					//这里对临近的4个偏移点采样
					fixed4 pixelUp = tex2D(_MainTex, IN.texcoord + fixed2(0, _MainTex_TexelSize.y*_CheckRange));  
					fixed4 pixelDown = tex2D(_MainTex, IN.texcoord - fixed2(0, _MainTex_TexelSize.y*_CheckRange));  
					fixed4 pixelRight = tex2D(_MainTex, IN.texcoord + fixed2(_MainTex_TexelSize.x*_CheckRange, 0));  
					fixed4 pixelLeft = tex2D(_MainTex, IN.texcoord - fixed2(_MainTex_TexelSize.x*_CheckRange, 0));  

					//周边4个点有a= 0 bOut就为=0 否则，如果a>1-_CheckAccuracy bOut=1，bOut=0就认为是边缘
					float bOut = step((1-_CheckAccuracy),pixelUp.a * pixelDown.a * pixelRight.a * pixelLeft.a);

					c = lerp(_OutLineColor,c,bOut);

					return c;
				}
				return c;
			}
		ENDCG
		}
	}

}
