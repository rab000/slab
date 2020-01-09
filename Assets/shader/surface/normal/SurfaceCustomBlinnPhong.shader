
//blinnPhong公式  I = _LightColor0.rgb  *  pow(N.H,SpecularPower)      H是L(顶点到光源)和V(顶点到视点)的半向量  H = (L+V)/|L+V|
Shader "N/surface/CustomBlinnPhong" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_MainTint("Diffuse Tint",Color) = (1,1,1,1)
		_SpecularPower("Specular Power",Range(0.1,200)) = 1
		_SpecularColor("Specular Color",Color) = (1,1,1,1)
	}
	
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf CustomBlinnPhong
 
		sampler2D _MainTex;
		float4 _MainTint;
		float4 _SpecularColor;
		float _SpecularPower;
 
 
		struct Input {
			float2 uv_MainTex;
		};
 
		void surf (Input IN, inout SurfaceOutput o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb;
			o.Alpha = c.a;
		}
		
		inline half4 LightingCustomBlinnPhong(SurfaceOutput s,half3 lightDir,half3 viewDir,fixed atten){
			fixed3 halfVector = normalize(lightDir + viewDir);
			fixed diff = max(0,dot(s.Normal,lightDir));
			fixed nh = max(0,dot(s.Normal,halfVector));
			half spec = pow(nh,_SpecularPower);
			half4 c;
			c.rgb = s.Albedo * _LightColor0.rgb * (diff * atten) +(_LightColor0.rgb * _SpecularColor.rgb * spec);
			c.a = 1;
			return c;
		}
		
		ENDCG
	} 
	FallBack "Diffuse"

}