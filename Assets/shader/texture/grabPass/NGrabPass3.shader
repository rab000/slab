﻿Shader "N/texture/grabPass/NGrabPass3"
{
   Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        Tags{"Queue"="Transparent"}
     
	
		GrabPass{"TNTex"}


        pass
        {
            Name "pass2"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
           
            #include "UnityCG.cginc"


			sampler2D TNTex;
			float4 TNTex_ST;

            struct v2f {
                float4  pos : SV_POSITION;
                float2  uv : TEXCOORD0;
            } ;
            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
               
				o.uv =  TRANSFORM_TEX(v.texcoord,TNTex);
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
                
				float4 texCol = tex2D(TNTex,uv);
                return texCol;
            }
            ENDCG
        }
    }
}
