//by nafio 170113
//注意默认是alpha小于cutoff的不通过测试
//这里去掉alphatest:_CutOff并加上AlphaTest Less [_CutOff]是不管用的
Shader "Nafio/Tags/AlphaTest/SAlphaTest" {

Properties
{
	_MainTex("Tex",2D) ="white" {}
	_CutOff("AlphaTest",Range(0,1)) = 0.5
}

SubShader
{
	Tags{"Queue"="AlphaTest"}
	LOD 100
	//AlphaTest Less [_CutOff]
	CGPROGRAM
	#pragma surface surf Lambert alphatest:_CutOff

	sampler2D _MainTex;

	struct Input{
		fixed2 uv_MainTex;
	};

	void surf(Input IN,inout SurfaceOutput o)
	{
		fixed4 c = tex2D(_MainTex,IN.uv_MainTex);
		o.Albedo = c.rgb;
		o.Alpha = c.r;
	}

	ENDCG
}

FallBack Off
}