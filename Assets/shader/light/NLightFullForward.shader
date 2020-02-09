//完整的前向渲染，包含内置函数处理的光的衰减，内置函数处理的的阴影计算
//其实并不完整，没包括forwardBase中没包括4个顶点光和sh函数的计算等
//里面计算光衰减和阴影用了unity内置函数
//这里forwardAdd与forwardBase主要区别是去掉了环境光，如果有自发光，4个顶点光，sh函数计算也在forwardBase中做
Shader "N/Light/NLightFullForward"
{
    Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		//主贴图，漫反射颜色
		_MainTex ("Main Tex", 2D) = "white" {}
		//法线贴图
		_BumpMap ("Normal Map", 2D) = "bump" {}
		//高光颜色
		_Specular ("Specular Color", Color) = (1, 1, 1, 1)
		//高光光泽度
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		
		Pass { 
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			//这个必须写，否则unity不会给一些光照参数赋值(貌似这个说的是光衰减参数)
			#pragma multi_compile_fwdbase	
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			//计算阴影的一些宏
			#include "AutoLight.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
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
				float4 TtoW0 : TEXCOORD1;  
                float4 TtoW1 : TEXCOORD2;  
                float4 TtoW2 : TEXCOORD3; 
				//使用内置阴影计算1/3
				SHADOW_COORDS(4)
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
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  

  				//使用内置阴影计算2/3
  				TRANSFER_SHADOW(o);
			 	
			 	return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
				//把切空间法线转到世界空间
				//dot(i.TangentToWorld0.xyz, bump)的解释
				// 将法线方向从切线空间 变换 到世界空间
                // 矩阵的乘法如下(行列相乘相加)：
                // Tx,Bx,Nx   Px   Tx*Px + Bx*Py + Nx*Pz
                // Ty,By,Ny * Py = Ty*Px + By*Py + Ny*Pz
                // Tz,Bz,Nz   Pz   Tz*Px + Bz*Py + Nz*Pz
				// 比较下下面写法，跟直接乘矩阵是一致的，可以当结论使用，主要是当矩阵是按多个向量传入的时候
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

				fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
			 	fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump, lightDir));
			 	
			 	fixed3 halfDir = normalize(lightDir + viewDir);
			 	fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(bump, halfDir)), _Gloss);
			
				//使用内置阴影计算3/3
				//这句也会帮助
				UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

				return fixed4(ambient + (diffuse + specular) * atten, 1.0);
			}
			
			ENDCG
		}
		
		Pass { 
			Tags { "LightMode"="ForwardAdd" }
			
			Blend One One
		
			CGPROGRAM
			
			#pragma multi_compile_fwdadd

			//forwardAdd 默认不开启阴影，如果要开始使用下面这句替换上面，并且使用内置阴影的3部ForwardAdd中也要有
//			#pragma multi_compile_fwdadd_fullshadows
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
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
				float4 TtoW0 : TEXCOORD1;  
                float4 TtoW1 : TEXCOORD2;  
                float4 TtoW2 : TEXCOORD3;
				SHADOW_COORDS(4)
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
	
  				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
			  	o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
			  	o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  
			 	
			 	TRANSFER_SHADOW(o);
			 	
			 	return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				
				fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;
				
			 	fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump, lightDir));
			 	
			 	fixed3 halfDir = normalize(lightDir + viewDir);
			 	fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(bump, halfDir)), _Gloss);
			
				UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

				return fixed4((diffuse + specular) * atten, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Specular"
}
