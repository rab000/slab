// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//NINFO ���shaderֱ�ӱ�ShadowMapping�ű����ã�������Ⱦ�ƹ�ռ�������ͼ
Shader "N/shadow/shadowMapping" {
	SubShader {
	    Tags { "RenderType"="Opaque" }
	    Pass {
	        Fog { Mode Off }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			struct v2f {
			    float4 pos : SV_POSITION;
			    float2 depth : TEXCOORD0;
			};
			
			v2f vert (appdata_base v) {
			    v2f o;
			    o.pos = UnityObjectToClipPos (v.vertex);
			    o.depth.xy=o.pos.zw;
			    return o;
			}
			
			float4 frag(v2f i) : COLOR {
			    //float d=i.depth.x/i.depth.y-_ZBufferParams.w/i.depth.y*4;

				//NINFO i.depth.x/i.depth.y����ȣ�-4/i.depth.y�����ƫ�ƣ����û����
				float d=i.depth.x/i.depth.y-4/i.depth.y;

			    //d=Linear01Depth(d);
			    //d=frac(d);

				//NINFO UnityCG.cginc�е�һ��������float��ɢ���rgba�����̶ȱ�֤float���ȣ����������������ѵ���
				//������ʵֻ��Ϊ����ͼ����floatֵ��ֻҪ��decodeȡ�����Ϳ��ԣ�����̫ϸ��EncodeFloatRGBA���������
			    float4 c=EncodeFloatRGBA(d);
			    return c;
			}
			ENDCG
			}//endpass
	}
}
