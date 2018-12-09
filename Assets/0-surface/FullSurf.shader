/*
比较完整的surfaceShader
*/
Shader "Nafio/FullSurf" {
Properties
{
	_MainTex("_MainTex",2D) = "white" {}
	_Color("Color",Color) = (1,1,1,1)
}

SubShader
{
	Tags{"RenderType" = "Opaque"}
	LOD 200
	CGPROGRAM
	#pragma surface surf CustomLambert vertex:vert finalcolor:final
	sampler2D _MainTex;
	fixed4 _Color;
	struct Input{
		half2 uv_MainTex;
		float4 vertcolor;
	};

	void vert(inout appdata_full v,out Input IN)
	{
		UNITY_INITIALIZE_OUTPUT(Input,IN);//不初始化会报错..
		IN.vertcolor = v.color;
	}

	void surf(Input IN,inout SurfaceOutput o)
	{
		half4 c = tex2D(_MainTex,IN.uv_MainTex) * _Color;
		o.Albedo = c.rgb;
		o.Alpha = c.a;
	}

	inline half4 LightingCustomLambert(SurfaceOutput s,half3 LightDir,half atten)
	{
		half nl = max(0,dot(s.Normal,LightDir));
		half4 c;
		c.rgb = s.Albedo * _LightColor0.rgb * (nl * atten * 2);
		c.a = s.Albedo;
		return c;
	}

	void final(Input IN,SurfaceOutput s,inout fixed4 c)
	{
		c = c * 0.9+0.1;
	}

	ENDCG
}
FallBack "Diffuse"

}