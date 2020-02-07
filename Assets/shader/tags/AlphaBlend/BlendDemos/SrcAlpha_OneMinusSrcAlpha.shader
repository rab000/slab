
Shader "N/Tags/AlphaBlend/BlendDemo_SrcAlpha_OneMinusSrcAlpha" {

Properties
{
	_MainTex("Tex",2D)="white" {}
	_Color("Color",Color) = (1,1,1,1)
	_Alpha("Alpha",Range(0,1)) = .5
}

SubShader
{
	Tags{"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
	LOD 150

	Blend SrcAlpha OneMinusSrcAlpha
	//Blend one one
	ZWrite off
	Pass
	{
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"
		sampler2D _MainTex;
		float4 _MainTex_ST;
		fixed4 _Color;
		fixed _Alpha;
		struct v2f
		{
			float4 pos:SV_POSITION;
			float2 uv:TEXCOORD0;
		};

		v2f vert(appdata_base IN)
		{
			v2f v;
			v.pos = UnityObjectToClipPos(IN.vertex);
			v.uv = TRANSFORM_TEX(IN.texcoord,_MainTex);
			return v;
		}

		fixed4 frag(v2f v):SV_Target
		{
			fixed4 c = tex2D(_MainTex,v.uv) * _Color;
			c.a = _Alpha;
			return c;
		}

		ENDCG
	}
}
FallBack Off
}