//by nafio 170113
//注意单独设置写入红色，会在背景上产生的透明效果
//因为只写了红色，而没写其他导致
Shader "Nafio/Tags/ColorMaskR" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 100
		ColorMask R
		CGPROGRAM
		#pragma surface surf Lambert
		float4 _Color;
		struct Input {
			float2 uv_MainTex;
		};

		void surf (Input IN, inout SurfaceOutput o) {
			o.Albedo = _Color.rgb;
			//o.Alpha = 1;
		}

		ENDCG
	}
	FallBack Off
}
