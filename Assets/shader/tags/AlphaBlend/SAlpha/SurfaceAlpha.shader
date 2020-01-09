//by nafio 170113 surface Alpha
//最简单的surface alpha
Shader "Nafio/Tags/Blend/SurfaceAlpha" 
{

Properties
{
	_MainTex("Tex",2D) = "white" {}
	_AlphaValue("Alpha",Range(0,1)) = 0
}

SubShader
{
	Tags{"Queue" = "Transparent" "IgnoreProjector" = "True"}
	Lighting Off
	ZWrite off
	LOD 150
	CGPROGRAM
	#pragma surface surf Lambert alpha
	#pragma target 3.0
	sampler2D _MainTex;
	fixed _AlphaValue;
	struct Input
	{
		half2 uv_MainTex;
	};

	void surf(Input IN,inout SurfaceOutput o)
	{
		fixed4 c = tex2D(_MainTex,IN.uv_MainTex);
		o.Albedo = c.rgb;
		o.Alpha = _AlphaValue;
	}

	ENDCG
}

FallBack Off


}