// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//NINFO 这个shader直接被ShadowMapping脚本引用，用来渲染灯光空间的深度贴图
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

				//NINFO i.depth.x/i.depth.y是深度，-4/i.depth.y是深度偏移，这个没看懂
				float d=i.depth.x/i.depth.y-4/i.depth.y;

			    //d=Linear01Depth(d);
			    //d=frac(d);

				//NINFO UnityCG.cginc中的一个函数把float分散存成rgba，最大程度保证float精度，具体网上随意能搜到，
				//这里其实只是为了用图来存float值，只要能decode取出来就可以，不用太细究EncodeFloatRGBA本身的意义
			    float4 c=EncodeFloatRGBA(d);
			    return c;
			}
			ENDCG
			}//endpass
	}
}
