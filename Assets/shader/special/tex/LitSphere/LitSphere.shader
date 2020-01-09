Shader "Nafio/LitSphere" {
	Properties {
		_MainTint ("Diffuse Tint", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_NormalMap ("Normal Map", 2D) = "bump" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma target 3.0//这句不加会报错 Too many texture interpolators would be used for ForwardBase pass
		#pragma surface surf Unlit vertex:vert

		float4 _MainTint;
		sampler2D _MainTex;
		sampler2D _NormalMap;
		
		inline half4 LightingUnlit (SurfaceOutput s, fixed3 lightDir, fixed atten)
		{
			half4 c = half4(1,1,1,1); 
			c.rgb = s.Albedo;//直接使用了surf中的颜色结果(从贴图里得到的假光照)，没计算真正的光照
			c.a = s.Alpha;
			return c;
		}

		struct Input {
			float2 uv_MainTex;
			float2 uv_NormalMap;
			float3 tan1;
			float3 tan2;
		};
		
		void vert (inout appdata_full v, out Input o) 
		{
			UNITY_INITIALIZE_OUTPUT(Input,o);//Input类型变量o 置0,如果不是HSHL这句就是空的宏什么都不做
			TANGENT_SPACE_ROTATION; //产生rotation这个矩阵并赋值的一段宏
			o.tan1 = mul(rotation, UNITY_MATRIX_IT_MV[0].xyz);   //把观察坐标下的x轴转换到切向坐标系
			o.tan2 = mul(rotation, UNITY_MATRIX_IT_MV[1].xyz);  //把观察坐标下的y轴转换到切向坐标系
		}

		void surf (Input IN, inout SurfaceOutput o)
		{
			float3 normals = UnpackNormal(tex2D(_NormalMap, IN.uv_NormalMap));
			o.Normal = normals;
			float2 litSphereUV;
			litSphereUV.x = dot(IN.tan1, o.Normal);//tan1是从观察系被转换到切向坐标的x轴，Normal是法线贴图中法向量，法向量向x轴投，得到u
			litSphereUV.y = dot(IN.tan2, o.Normal); //tan2是从观察系被转换到切向坐标的y轴，Normal是法线贴图中法向量，法向量向y轴投，得到v

			//这里注意一点，上面dot的计算是因为用的是一张做好光照的贴图，简单说就是在这个<贴图中光方向是固定的，
			//如果法线朝向接近光源的位置，就取图上更亮的一点，
			//不好理解的是法线向观察系x，y坐标投影来决定使用图(含有光照方向)上哪一点
					
			half4 c = tex2D (_MainTex, litSphereUV*0.5+0.5);//*0.5+0.5是因为，dot的值是-1~1，而uv是0-1做了一下转换
			o.Albedo = c.rgb * _MainTint;
			o.Alpha = c.a;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}