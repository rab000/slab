//王者荣耀平面阴影，适合移动端平面地形
Shader "N/shadow/PlanarShadow4Game"
{
    Properties
	{
		_MainTex ("Texture", 2D) = "white" {}

		//距离对光衰减影响系数，如果=1，那么光的衰减就完全与距离相关
		//想下2米，100米的物体都有影子，100米物体影子只有边缘才会有较明显衰减(而不是超出一定距离影子alpha就=0了)，2米的同理
		//所以不同高度的物体影子衰减不能完全由影子到物体的距离决定
		_ShadowDisPer ("ShadowInvLen", float) = 1.0 //0.4449261
		
		//阴影随距离衰减系数
		_ShadowAtten("ShadowAtten",float) = 1.5

		//阴影开始衰减的（相对角色位置的）距离(注意阴影一般在阴影的远处，边缘处衰减的才比较严重，而在一定范围内几乎看不出衰减)
		_ShadowAttenDis("ShadowAttenDis",float) = 0.0

		//计算出的阴影最后会根据这个值调整最后的alpha值
		_ShadowAlpha("ShadowAlpha",Range(0,1.0)) = 1.0

		//地表法线,第4位是空参数
		_TerrainNormalDir("TerrainNormalDir",Vector) = (0.0 ,1.0 , 0.0, 0.0)

		//影子距离地表距离
		_ShadowDistance2Terrain("ShadowDistance2Terrain",float) = 0.1

	}
	
	SubShader
	{
		Tags{ "RenderType" = "Opaque" "Queue" = "Geometry+10" }

		LOD 100
		
		Pass
		{

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			
			ENDCG
		}

		Pass
		{		
			Blend SrcAlpha  OneMinusSrcAlpha
			ZWrite Off
			Cull Back
			ColorMask RGB
			
			Stencil
			{
				Ref 0			
				Comp Equal			
				WriteMask 255		
				ReadMask 255
				//Pass IncrSat
				Pass Invert
				Fail Keep
				ZFail Keep
			}
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag

			//float4 _ShadowPlane;

			float4 _ShadowLightDir;

			//角色(脚底板)所在世界位置
			float4 _ObjWorldPos;

			float _ShadowDisPer;

			//阴影开始衰减的距离
			float _ShadowAttenDis;

			//阴影随距离衰减系数
			float _ShadowAtten;

			//阴影总体透明度
			float _ShadowAlpha;

			//地表平面法线方向
			float4 _TerrainNormalDir;

			//影子距离地表距离
			float _ShadowDistance2Terrain;

			//float4 _ShadowFadeParams;
			
			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 ObjWorldPos : TEXCOORD0;
				float3 ShadowWorldpos : TEXCOORD1;
			};

			v2f vert(appdata v)
			{
				v2f o;

				float3 lightDir = normalize(_ShadowLightDir);

				float3 vertWorldpos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				//这里算出的distance就是vertex到阴影点的距离
				//dot(_TerrainNormalDir.xyz, vertWorldpos)代表点vertex到平面的垂直距离
				//_ShadowDistance2Terrain代表点vertex到平面的垂直距离的偏移，这里之所以计算出一个负数，
				//原因是，后面dot(_TerrainNormalDir, lightDir.xyz)灯光方向的原因，会计算出一个负数
				//dot(_TerrainNormalDir, lightDir.xyz)代表一个cos(o)				
				float distance = (_ShadowDistance2Terrain - dot(_TerrainNormalDir.xyz, vertWorldpos)) / dot(_TerrainNormalDir.xyz, lightDir.xyz);
				
				//计算出阴影位置点位置
				float3 shadowWorldPos = vertWorldpos + distance * lightDir.xyz;

				o.vertex = mul(unity_MatrixVP, float4(shadowWorldPos, 1.0));

				o.ObjWorldPos = _ObjWorldPos.xyz;

				o.ShadowWorldpos = shadowWorldPos;

				return o;
			}
			
			float4 frag(v2f i) : SV_Target
			{
				//从vertex计算出的阴影点，到角色（脚底）世界位置的向量
				float3 VectorShadow2Role = (i.ObjWorldPos - i.ShadowWorldpos);

				//这里不赋值也可以
				float4 color = float4(0.0, 0.0, 0.0, 0.0);
								
				//---开始计算阴影衰减

				// 王者荣耀的原始衰减公式，后面是拆解后公式
				//color.w = (pow((1.0 - clamp(((sqrt(dot(posToPlane_2, posToPlane_2)) * _ShadowInvLen) - _ShadowFadeParams.x), 0.0, 1.0)), _ShadowFadeParams.y) * _ShadowFadeParams.z);

				//阴影点 到 角色（脚底）世界位置的距离
				float DistanceShadow2Role = sqrt(dot(VectorShadow2Role, VectorShadow2Role));

				//继续处理这个距离，
				//让距离乘一个系数_ShadowDisPer(虽然衰减跟距离有关，但是要有个随距离衰减的系数，_ShadowDisPer就是这个系数)
				//至于后面为什么-_ShadowAttenDis，这个参数应该是控制在一定距离内阴影不发生衰减，可以认为是开始衰减的最小距离
				//注意后面公式如果_ShadowFadeParams比较大，那么clamp结果一定是0,计算pow0时 1-clamp0就是1，就代表透明度是1，这时是完全不衰减
				float clamp0 = clamp( ( DistanceShadow2Role * _ShadowDisPer - _ShadowAttenDis), 0.0, 1.0);

				//_ShadowFadeParams.y就代表衰减的快慢程度，衰减系数？
				float pow0 = pow((1.0 - clamp0), _ShadowAtten);

				//最后_ShadowFadeParams.z用来控制整体阴影的透明度
				color.a = pow0 * _ShadowAlpha;

				// 另外的阴影衰减公式，这种比较简陋
				//color.w = 1.0 - saturate(distance(i.xlv_TEXCOORD0, i.xlv_TEXCOORD1) * _ShadowFalloff);

				return color;
			}
			
			ENDCG
		}
	}
}
