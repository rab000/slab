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
					//NINFO wldLightPos�Ǵ��ⲿ����Ĺ�Դλ�õ��������
					//����ƽ�й����һλw��0(�����������ָ������Զ)
					//���ڵ��Դw��1(��w=1ʱ��wldLightPos.xyz���ǵ��Դ����������)
					//(����w=0��1��ԭ�����ȥ������ξ�����ʵ4*4������Ҫ��������ͶӰ�ռ��)
					//���ϣ���ʵwֻ��ȡ0����1����ֵ������һ�䲢����ʲô��ʽ������w=0����ƽ�й⣬w=1������Դ
					//toLight����ָ���ķ���ĵ�λ����������w���Ϊ����ƽ�й�͵��Դ��boolֵ
					float3 toLight = normalize(wldLightPos.xyz - wldVex.xyz * wldLightPos.w);
					float3 wldNormal = UnityObjectToWorldDir(v.normal);
					float backFactor = dot(toLight, wldNormal);
					//NINFO ����90�ȵĲ��֣�extrude=1.0���ͼ���
					float extrude = (backFactor < 0.0) ? 1.0 : 0.0;
					toLight = UnityWorldToObjectDir(toLight);
					//NINFO ��ΪtoLight����ָ��ⷽ������������������ǹⷽ���෴�ķ�����������Ҫ��
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
