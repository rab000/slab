//Nafio info 通过挤出的方式做描边
//相比与最简单的沿法线挤出方式解决了如下问题

//1 同一物体的描边距离屏幕远近不同，近粗远细，描边粗细不同
//具体方法为，只沿xy方向挤出固定距离len，因为xy在投影空间与z成正比，len再乘z，这样保证不同距离描边粗细一致

//2 当相邻面法线朝向变化剧烈时，描边会出现缝隙，比如Cube的描边
//具体方法为,把每个点当成向量，挤出时的方向，不直接沿法线方向挤出，而是沿着根据法线与向量方向计算出的新方向挤出

//这个shader的关注点是，只沿着屏幕方向挤出模型，去掉了z方向
Shader "N/mvp/3d/OutLine"
{
	Properties {
		_Outline("Out line",range(0,1))=0.02
		_Factor("Factor",range(1,100))=1
	}
	SubShader {
		//第一个pass用来渲描边
		pass{
		Tags{"LightMode"="Always"}
		Cull Front
		ZWrite On
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"
		float _Outline;
		float _Factor;
		struct v2f {
			float4 pos:SV_POSITION;
		};
		v2f vert (appdata_full v) {
			v2f o;
			o.pos=UnityObjectToClipPos(v.vertex);
			float3 dir=normalize(v.vertex.xyz);
			float3 dir2=v.normal;
			float D=dot(dir,dir2);
			//这个公式具体没看懂，作用是用来根据点法线和点向量的dot来计算一个新的挤出朝向
			//special/3d/toon/Cel_1.shader里的描边计算公式比较清除，这个公式看不懂
			D=(D/_Factor+1)/(1+1/_Factor);
			dir=lerp(dir2,dir,D);
			//把dir向V空间转换
			dir= mul ((float3x3)UNITY_MATRIX_IT_MV, dir);
			//把V空间的dir.xy转换到P空间
			//TransformViewToProjection(dir.xy) = mul((float2x2)UNITY_MATRIX_P, dir.xy);
			float2 offset = TransformViewToProjection(dir.xy);
			offset=normalize(offset);
			o.pos.xy += offset * o.pos.z *_Outline;
			return o;
		}
		float4 frag(v2f i):COLOR
		{
			return 0;
		}
		ENDCG
		}//end of pass


		pass{
		Tags{"LightMode"="ForwardBase"}
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"
		float4 _LightColor0;

		struct v2f {
			float4 pos:SV_POSITION;
			float3 lightDir:TEXCOORD0;
			float3 viewDir:TEXCOORD1;
			float3 normal:TEXCOORD2;
		};

		v2f vert (appdata_full v) {
			v2f o;
			o.pos=UnityObjectToClipPos(v.vertex);
			o.normal=v.normal;
			o.lightDir=ObjSpaceLightDir(v.vertex);
			o.viewDir=ObjSpaceViewDir(v.vertex);
			return o;
		}
		float4 frag(v2f i):COLOR
		{
			float4 c=1;
			float3 N=normalize(i.normal);
			float3 viewDir=normalize(i.viewDir);
			float diff=max(0,dot(N,i.lightDir));
			diff=(diff+1)/2;
			diff=smoothstep(0,1,diff);
			c=_LightColor0*diff;
			return c;
		}
		ENDCG
		}
	} 
}
