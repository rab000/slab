
//逐顶点着色(高洛德着色)

Shader "N/Light/NLightGouraudShading"
{
    Properties
    {
		//普通贴图(贴图用于描述漫反射材质颜色)
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
			Tags{"LightMode"="ForwardBase"}

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
                UNITY_FOG_COORDS(1)
                float4 posV2f : SV_POSITION;
				fixed3 color : COLOR;				
				float2 uv : TEXCOORD0;				
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

				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

				//法线转从物体空间转世界空间
				//fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);//unity内置方法
				fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
				
				//常规计算世界光方向				
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
			
				//半兰伯特漫反射,会把较暗得地方变得更亮一些
				//fixed halfLambert = dot(worldNormal, worldLight) * 0.5 + 0.5;
				//漫反射,saturate把值限制到0-1
				fixed lambert = saturate(dot(worldNormal,worldLight));		
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * lambert;

				//---开始计算billionPhong高光
				//顶点世界坐标
				float3 worldPos = mul(unity_ObjectToWorld, v.posA2v).xyz;
				//世界空间观察者方向（朝向是由点方向指向观察者方向）
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos.xyz);
				//计算bilinphong得h值
				fixed3 halfDir = normalize(worldLight + viewDir);
				//计算billinphong高光
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

				//----开始计算phong高光
				//计算光反射方向
				//fixed3 reflectDir = normalize(reflect(-worldLight, worldNormal));
				//计算观察者方向
				//fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.posA2v).xyz);			
				//计算phong高光
				//fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(reflectDir, viewDir)), _Gloss);

				o.color = ambient + diffuse + specular;
				
				//计算uv偏移量和缩放，一般来说法线的可以和普通贴图的一致，但这里做了区分
				//下面计算与TRANSFORM_TEX内部计算方法一致
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				//o.uv.xy = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				
                UNITY_TRANSFER_FOG(o,o.posV2f);
				
                return o;

            }

            fixed4 frag (v2f i) : SV_Target
            {
				

                // sample the texture
                fixed4 albedo = tex2D(_MainTex, i.uv);

				fixed4 col = albedo * fixed4(i.color,1.0);

				//fixed4 col = fixed4(i.color,1.0);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                return col;
            }
            ENDCG
        }

    }
	FallBack "Specular"
}
