//NINFO 来自shaderlab的卡通着色
//卡通着色原理就是在漫反射基础上，将连续的光照离散化
//这个shader用的是公式的方法 float toon=floor(diff*_Steps)/_Steps;

Shader "N/special/3d/ShaderLabToon" {
	Properties {
		_Color("Main Color",color)=(1,1,1,1)
		_Outline("Thick of Outline",range(0,0.1))=0.02//描边宽度
		_Factor("Factor",range(0,1))=0.5//这个参数控制描边方向，0是法线方向，1是点的向量方向
		_ToonEffect("Toon Effect",range(0,1))=0.5 //这个参数用来在卡通离散与普通连续光照之间进行插值，为1是完全离散化，0是正常漫反射
		_Steps("Steps of toon",range(0,9))=3 //离散化参数，可以尝试用10，100，1000来理解公式，数值越大，离散程度应该越大
	}
	SubShader {

		//描边
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
			//顶点向量方向
			float3 dir=normalize(v.vertex.xyz);
			//顶点法线方向
			float3 dir2=v.normal;
			float D=dot(dir,dir2);
			dir=dir*sign(D);//根据d是正，负，0，来判断dir方向是否反转，D为负证明 法线和向量方向角度差较大在>90 或者<-90

			dir=dir*_Factor+dir2*(1-_Factor);//法线与（上面修正过正负朝向的）顶点向量方向做插值
			v.vertex.xyz+=dir*_Outline;
			o.pos=UnityObjectToClipPos(v.vertex);
			return o;
		}
		float4 frag(v2f i):COLOR
		{
			float4 c=0;
			return c;
		}
		ENDCG
		}//end of pass

		//处理主平行光源toon着色
		pass{
		Tags{"LightMode"="ForwardBase"}
		Cull Back
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"

		float4 _LightColor0;
		float4 _Color;
		float _Steps;
		float _ToonEffect;

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
			float3 lightDir=normalize(i.lightDir);
			float diff=dot(N,i.lightDir);
			diff=(diff+1)/2;
			diff=smoothstep(0,1,diff);
			float toon=floor(diff*_Steps)/_Steps;
			diff=lerp(diff,toon,_ToonEffect);

			c=_Color*_LightColor0*(diff);
			return c;
		}
		ENDCG
		}//

		//处理非主要光源高光
		pass{
		Tags{"LightMode"="ForwardAdd"}
		Blend One One
		Cull Back
		ZWrite Off
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"

		float4 _LightColor0;
		float4 _Color;
		float _Steps;
		float _ToonEffect;

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
			o.viewDir=ObjSpaceViewDir(v.vertex);
			o.lightDir=_WorldSpaceLightPos0-v.vertex;

			return o;
		}
		float4 frag(v2f i):COLOR
		{
			float4 c=1;
			float3 N=normalize(i.normal);
			float3 viewDir=normalize(i.viewDir);
			float dist=length(i.lightDir);
			float3 lightDir=normalize(i.lightDir);
			float diff=dot(N,i.lightDir);
			diff=(diff+1)/2;
			diff=smoothstep(0,1,diff);

			half3 h = normalize (lightDir + viewDir);
			float nh = max (0, dot (N, h));
			float spec = pow (nh, 32.0);

			float atten=1/(dist);
			float toon=floor(atten*_Steps)/_Steps;
			atten=lerp(atten,toon,_ToonEffect);
			c=_Color*_LightColor0*(diff+spec)*atten;
			return c;
		}
		ENDCG
		}
	} 
}
