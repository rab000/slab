﻿//图片变灰
//采样之后的图元xyz分别各自乘以灰度系数0.299,0.518,0.184之后的值就是灰色的
Shader "N/ui/gray"
{
    Properties
    {
        _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _GrayScale ("GrayScale", Float) = 1
		[Toggle]_Open("Open", Int) = 1	//Toggle控制是否开启
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

        Cull Off
        Lighting Off
        ZWrite Off
        Blend One OneMinusSrcAlpha

        Pass
        {
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ PIXELSNAP_ON	  //告诉Unity编译不同版本的Shader,这里和后面vert中的PIXELSNAP_ON对应
            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                half2 texcoord  : TEXCOORD0;
            };

            fixed4 _Color;
			fixed _Open;
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

            sampler2D _MainTex;
            float _GrayScale;

            fixed4 frag(v2f IN) : SV_Target
            {
				if(_Open > 0)
				{
					fixed4 color = tex2D(_MainTex, IN.texcoord);// * IN.color;

					//NINFO 变灰的关键是乘一个灰度系数
					float3 grayFlag = float3(0.299, 0.587, 0.114);

					grayFlag *= _GrayScale;


					float gray = dot(color.rgb, grayFlag);

				    //float cc = (c.r * 0.299 + c.g * 0.518 + c.b * 0.184);  //乘以一个灰度系数
					//cc *= _GrayScale;

					//c.r = c.g = c.b = gray;
					//或
					color.rgb = float3(gray, gray, gray);
					
					color.rgb *= IN.color.rgb;

					color.rgb *= color.a;

					return color;
				}
                else
				{
				   return tex2D(_MainTex, IN.texcoord) * IN.color;
				}
            }
        ENDCG
        }
    }

}
