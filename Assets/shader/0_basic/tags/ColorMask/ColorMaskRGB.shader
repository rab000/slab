//by nafio 170113
Shader "Nafio/Tags/ColorMaskRGB" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 100
		ColorMask RGB
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
