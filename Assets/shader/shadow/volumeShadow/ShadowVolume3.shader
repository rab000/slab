Shader "NShader/shadow/ShadowVolume3" {
Properties {
	_Extrusion ("Extrusion", Range(0,30)) = 5.0
}


SubShader {
		Tags { "Queue" = "Transparent+10" }
		pass {
			Blend DstColor One
			Cull Back ZWrite Off ColorMask R Offset 1,1
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			float _Extrusion;
			// World space light position
			float4 _LightPosition;
			float4 vert(appdata_base v) : POSITION
			{
				// point to light vector
				float4 wldLightPos = _LightPosition;
				float4 wldVex = mul(unity_ObjectToWorld,v.vertex);
				float3 toLight = normalize(wldLightPos.xyz - wldVex.xyz * wldLightPos.w);
				float3 wldNormal = UnityObjectToWorldDir(v.normal);
				float backFactor = dot(toLight, wldNormal);
				float extrude = (backFactor < 0.0) ? 1.0 : 0.0;
				toLight = UnityWorldToObjectDir(toLight);
				v.vertex.xyz -= toLight * (extrude * _Extrusion);
				return UnityObjectToClipPos(v.vertex);
			}
			float4 frag(float4 pos:POSITION) :COLOR
			{
				return float4(1,1,1,1);
			}
			ENDCG
		}//endpass
	
		pass {
				Blend DstColor Zero
				Cull Front ZWrite Off ColorMask R Offset 1,1
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"
				float _Extrusion;
				// World space light position
				float4 _LightPosition;
				float4 vert(appdata_base v) : POSITION
				{
					// point to light vector
					float4 wldLightPos = _LightPosition;
					float4 wldVex = mul(unity_ObjectToWorld,v.vertex);
					//NINFO wldLightPos是从外部传入的光源位置的齐次向量
					//对于平行光最后一位w是0(齐次向量代表指向无穷远)
					//对于点光源w是1(当w=1时，wldLightPos.xyz就是点光源的世界坐标)
					//(关于w=0和1的原理可以去看下齐次矩阵，其实4*4矩阵主要就是描述投影空间的)
					//综上，其实w只能取0，和1两个值，下面一句并不是什么公式，而是w=0代表平行光，w=1代表点光源
					//toLight就是指向光的方向的单位向量，这里w理解为区分平行光和点光源的bool值
					float3 toLight = normalize(wldLightPos.xyz - wldVex.xyz * wldLightPos.w);
					float3 wldNormal = UnityObjectToWorldDir(v.normal);
					float backFactor = dot(toLight, wldNormal);
					//NINFO 大于90度的部分（extrude=1.0）就挤出
					float extrude = (backFactor < 0.0) ? 1.0 : 0.0;
					toLight = UnityWorldToObjectDir(toLight);
					//NINFO 因为toLight代表指向光方向的向量，挤出方向是光方向相反的方向，所以这里要减
					v.vertex.xyz -= toLight * (extrude * _Extrusion);
					return UnityObjectToClipPos(v.vertex);
				}
				float4 frag(float4 pos:POSITION) :COLOR
				{
					return float4(1,1,1,1)*0.5;
				}
				ENDCG
		}//endpass
	}//sub
FallBack Off
}
