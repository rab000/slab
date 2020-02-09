//逐像素着色(Phong着色)
Shader "N/Light/NLightPhongShading"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

		//漫反射颜色
		_Diffuse("Diffuse",Color)=(1,1,1,1)

		//高光颜色
		_Specular ("Specular", Color) = (1, 1, 1, 1)

		//光泽度
		_Gloss ("Gloss", Range(8.0, 256)) = 20

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
			Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
			#include "Lighting.cginc"

            struct a2v
            {
                float4 posA2v : POSITION;
				float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 posV2f : SV_POSITION;
				fixed3 color : COLOR;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			fixed3 _Diffuse;
			fixed3 _Specular;
			float _Gloss;

            v2f vert (a2v v)
            {
                v2f o;
                o.posV2f = UnityObjectToClipPos(v.posA2v);
				o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
				o.worldPos = mul(unity_ObjectToWorld, v.posA2v).xyz;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.posV2f);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;	
				
				//---开始计算漫反射
				fixed3 worldNormal = normalize(i.worldNormal);
				//用内置函数计算光方向
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				//常规计算世界光方向
				//fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				//计算lanbert漫反射
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));	
				
				//---开始计算billionPhong高光
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);	
				
				//----开始计算phong高光
				//计算光反射方向
				//fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
				//计算观察者方向
				//fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.posA2v).xyz);			
				//计算phong高光
				//fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(reflectDir, viewDir)), _Gloss);


				fixed3 result = ambient + diffuse + specular;



                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

				col = col * fixed4(result,1.0);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }

	FallBack "Specular"

}
