//by nafio 170113
//这里注意是没有RB组合的
Shader "Nafio/Tags/ColorMaskRB" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 100
		ColorMask RG
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
