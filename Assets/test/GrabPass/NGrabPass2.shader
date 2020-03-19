// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//来自风雨冲
//与官网效果不同的是，这里抓的真的是整个屏幕，然后把整个屏幕的图像直接显示出来
Shader "N/NGrabPass2"
{
     Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        Tags{"Queue"="Transparent"}
     
        GrabPass
        {
        }
       
        pass
        {
            Name "pass2"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
           
            #include "UnityCG.cginc"
            sampler2D _GrabTexture;
            float4 _GrabTexture_ST;
            struct v2f {
                float4  pos : SV_POSITION;
                float2  uv : TEXCOORD0;
            } ;
            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv =  TRANSFORM_TEX(v.texcoord,_GrabTexture);
                return o;
            }
            float4 frag (v2f i) : COLOR
            { 
#if UNITY_UV_STARTS_AT_TOP
                float2 uv = float2(i.uv.x,1-i.uv.y);
				//float2 uv = i.uv;
            #else
                float2 uv = i.uv;
            #endif
                float4 texCol = tex2D(_GrabTexture,uv);
                return texCol;
            }
            ENDCG
        }
    }
}
