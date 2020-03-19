
//不在vert中计算切空间的lightDir viewDir
//而是在frag中把从法线贴图中得到的法线转到世界坐标再进行光照等计算
Shader "N/texture/dump/NTextureDumpWorld"
{
    Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_BumpScale ("Bump Scale", Float) = 1.0
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader {
		Pass { 
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 TangentToWorld0 : TEXCOORD1;  
				float4 TangentToWorld1 : TEXCOORD2;  
				float4 TangentToWorld2 : TEXCOORD3; 
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
				
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				
				//直接将tangent相关世界坐标，和顶点世界坐标传给frag
				o.TangentToWorld0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TangentToWorld1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TangentToWorld2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				// Get the position in world space		
				float3 worldPos = float3(i.TangentToWorld0.w, i.TangentToWorld1.w, i.TangentToWorld2.w);
				// Compute the light and view dir in world space
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				
				// Get the normal in tangent space
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
				bump.xy *= _BumpScale;
				bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));

				//把切空间法线转到世界空间
				//dot(i.TangentToWorld0.xyz, bump)的解释
				// 将法线方向从切线空间 变换 到世界空间
                // 矩阵的乘法如下(行列相乘相加)：
                // Tx,Bx,Nx   Px   Tx*Px + Bx*Py + Nx*Pz
                // Ty,By,Ny * Py = Ty*Px + By*Py + Ny*Pz
                // Tz,Bz,Nz   Pz   Tz*Px + Bz*Py + Nz*Pz
				// 比较下下面写法，跟直接乘矩阵是一致的，可以当结论使用，主要是当矩阵是按多个向量传入的时候
				bump = normalize(half3(dot(i.TangentToWorld0.xyz, bump), dot(i.TangentToWorld1.xyz, bump), dot(i.TangentToWorld2.xyz, bump)));
				
				
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump, lightDir));

				fixed3 halfDir = normalize(lightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(bump, halfDir)), _Gloss);
				
				return fixed4(ambient + diffuse + specular, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Specular"
}
