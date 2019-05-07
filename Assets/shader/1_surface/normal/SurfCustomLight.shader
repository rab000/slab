//自定义光照
Shader "N/surface/CustomLight" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf CustomDiffuse //CustomDiffuse自定义光照模型函数名
 
		sampler2D _MainTex;
 
		struct Input {
			float2 uv_MainTex;
		};
 
		void surf (Input IN, inout SurfaceOutput o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb;
			o.Alpha = c.a;
		}
		
		inline float4 LightingCustomDiffuse (SurfaceOutput s, fixed3 lightDir, fixed atten) {  //LightingCustomDiffuse名称与上面定义有关，s是surf函数的输出，lightDir光方向，atten衰减系数
    		float difLight = max(0, dot (s.Normal, lightDir));
    		float4 col;
    		col.rgb = s.Albedo * _LightColor0.rgb * (difLight * atten * 2);
    		col.a = s.Alpha;
    		return col;
		}
		ENDCG
	} 
	FallBack "Diffuse"

}