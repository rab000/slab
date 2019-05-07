/*
法线贴图
*/
Shader "N/surface/DumpSurf" {  
    Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Bump ("Bump", 2D) = "bump" {} //法线贴图
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Lambert

        sampler2D _MainTex;
        sampler2D _Bump;                

        struct Input {
            float2 uv_MainTex;
            float2 uv_Bump;
        };

        void surf (Input IN, inout SurfaceOutput o) {
            half4 c = tex2D (_MainTex, IN.uv_MainTex);
            o.Normal = UnpackNormal(tex2D(_Bump, IN.uv_Bump));   //获取法线信息
            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }
        ENDCG
    }
     
    FallBack "Diffuse"
}
