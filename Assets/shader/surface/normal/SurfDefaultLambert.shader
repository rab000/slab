
Shader "N/surface/DefaultLambert" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}//变量名_MainText，显示名Base(RGB),类型2D,默认值白色white，最后{}里面可以放一些控制参数
	}
	SubShader {
		Tags { "RenderType"="Opaque" }   //处理不透明物体用这段shader
		LOD 200    //LOD 200如果Unity中配置的Lod小于这个值，那么这段shader就不起作用，unity中maxLod默认配的0，就是所有数值都起作用
		//另外可以用代码来制定具体shader的LOD限制
		CGPROGRAM  //CG开始
		#pragma surface surf Lambert  //surface使用surface shader   surf表面shader函数名     Lambert使用的光照模型为Lambert
 
		sampler2D _MainTex;  //定义一张2d图片（就是从属性中的_MainTex链接过来的，否则cg无法使用）
 
		struct Input {
			float2 uv_MainTex; //取MainTex的uv
		};
 
		void surf (Input IN, inout SurfaceOutput o) {   //IN是向表面着色器处理函数输入的函数，SurfaceOutput是向光照处理函数输出的参数
			half4 c = tex2D (_MainTex, IN.uv_MainTex); //获取—_MainText固定uv点的颜色出来
			o.Albedo = c.rgb;
			o.Alpha = c.a;
		}
		ENDCG
	} 
	FallBack "Diffuse"//如果当前shader不能正确执行，回调默认shader
}
