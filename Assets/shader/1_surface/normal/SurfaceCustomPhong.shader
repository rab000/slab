Shader "N/surface/CustomPhong" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_MainTint("Diffuse Tint",Color) = (1,1,1,1)
		_SpecularColor("Specular Color",Color) = (1,1,1,1)
		_SpecularPower("Specular Power",Range(0,30)) = 1
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf Phong
 
		sampler2D _MainTex;
		float4 _MainTint;//nafio 这些变量为何不用fixed:fixed范围-2 - 2
		float4 _SpecularColor;
		float _SpecularPower;
 
		struct Input {
			float2 uv_MainTex;//nafio 为何只有uv在这里传：这是input用来从vertex shader向fragram shader传递数据，需要什么定义什么
		};
 
		void surf (Input IN, inout SurfaceOutput o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb;
			o.Alpha = c.a;
		}
		
		//nafio phong光照公式 
		//入射光反射向量的单位向量 r = 2*(n点乘l)*n
		//反射光和视角方向的 差别用dot(reflectionVector,viewDir)表示
		//镜面反射分量强度  pow(max(0,dot(reflectionVector,viewDir)),_SpecularPower);
		//最后结果是漫反射结果+镜面反射结果
		//总结phong实际计算公式就是  pow(r点乘v，材质高光系数)
		//而bilnnPhong实际就是这个公式的简化 pow(n点乘h，材质高光系数)，所以bilnnPhong更快
		inline half4 LightingPhong(SurfaceOutput s,half3 lightDir,half3 viewDir,fixed atten){
		 float diff = max(0,dot(s.Normal,lightDir));
		 float3 reflectionVector = normalize(2.0 * s.Normal * diff - lightDir);
		 float spec = pow(max(0,dot(reflectionVector,viewDir)),_SpecularPower);
		 float3 finalSpec = _SpecularColor.rgb * spec;
		 half4 c;
		 c.rgb = s.Albedo * _LightColor0.rgb * (diff * atten) + (_LightColor0.rgb * finalSpec);
		 c.a = 1;
		 return c;
		}
		
		ENDCG
	} 
	FallBack "Diffuse"
}
