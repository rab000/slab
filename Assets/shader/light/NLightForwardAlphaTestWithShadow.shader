Shader "N/Light/Alpha Test With Shadow" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		//注意这个变量名是固定的
		//因为这个shader本身没有shadowCast pass(用于计算该物体的阴影投射信息)
		//是使用FallBack "Transparent/Cutout/VertexLit"的shadowCast pass
		//而这个Transparent/Cutout/VertexLit中使用了名称为_Cutoff，不定义这个计算不出正确的阴影
		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
	}
	SubShader {
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			Cull Off
			
			CGPROGRAM
			
			#pragma multi_compile_fwdbase
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
				SHADOW_COORDS(3)
			};
			
			v2f vert(a2v v) {
			 	v2f o;
			 	o.pos = UnityObjectToClipPos(v.vertex);
			 	
			 	o.worldNormal = UnityObjectToWorldNormal(v.normal);
			 	
			 	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

			 	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			 	
			 	// Pass shadow coordinates to pixel shader
			 	TRANSFER_SHADOW(o);
			 	
			 	return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				
				fixed4 texColor = tex2D(_MainTex, i.uv);

				clip (texColor.a - _Cutoff);
				
				fixed3 albedo = texColor.rgb * _Color.rgb;
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
							 	
			 	// UNITY_LIGHT_ATTENUATION not only compute attenuation, but also shadow infos
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
			 	
				return fixed4(ambient + diffuse * atten, 1.0);
			}
			
			ENDCG
		}
	} 

	//注意Transparent/Cutout/VertexLit使用了名称为_Cutout的变量，所以本shader也必须有这个变量，否则计算结果错误
	//因为这个shader本身没有shadowCast pass(用于计算该物体的阴影投射信息)
	//是使用FallBack "Transparent/Cutout/VertexLit"的shadowCast pass
	//而这个Transparent/Cutout/VertexLit中使用了名称为_Cutoff，不定义这个计算不出正确的阴影
	FallBack "Transparent/Cutout/VertexLit"
}
