//by nafio
//注意下自发光部分
//LightMap说明
//r通道  _SpecularThreshold共同决定高光强度
//g通道，与ModelColor.r _LightArea共同决定物体受光照程度
//b通道, 控制哪些区域容易出现高光，与默认高光spe 决定是否渲染高光
Shader "N/SelfBeng3"
{
    Properties
    {
		//主贴图
		_MainTex ("MainTex", 2D) = "white" {}
		//光照图
		_LightMap("LightMap", 2D) = "white" {}

		_Color("Color",Color) = (1,1,1,1)
		
		//描边宽度
        _OutlineWidth ("OutlineWidth", Range(0, 0.05)) = 0.01581197		
		//描边颜色
		_OutlineColor ("OutlineColor", Color) = (0,0,0,1)
		
		//光照影响范围
		//_LightArea值越小，受光照越明显
		//LightMap.g * ModelColor.r < _LightArea 则漫反射在原色与阴影1之间
		//LightMap.g * ModelColor.r > _LightArea 则漫反射在阴影1与阴影2之间
		_LightArea("LightArea",float) = 0.09

		//原色与阴影1的阈值
		_Shadow1Threshold("Shadow1Threshold",float) = 0.5
		//阴影1与阴影2的阈值
		_Shadow2Threshold("Shadow2Threshold",float) = 0.6

		//第一层阴影颜色
		_Shadow1Color("Shadow1Color", Color) = (0.8,0.8,0.8,1)
		//第二层阴影颜色
		_Shadow2Color("Shadow2Color", Color) = (0.4,0.4,0.4,1)

		//光泽度
		_Gloss("Gloss",float) = 20

		//高光强度(手动调整)
		_SpecularThreshold("SpecularThreshold",Range(0,1)) = 1

		//高光颜色
		_SpecularColor("SpecularColor", Color) = (1,1,1,1)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        //LOD 100

		Pass 
		{
            Name "Outline"
            Tags 
			{
            }
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float _OutlineWidth;

			fixed4 _OutlineColor;

            struct VertexInput 
			{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;
            };

            struct VertexOutput
			{
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
            };

            VertexOutput vert (VertexInput v)
			{
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.pos = UnityObjectToClipPos(float4(v.vertex.xyz + v.normal * _OutlineWidth,1) );
                return o;
            }

            float4 frag(VertexOutput i) : COLOR 
			{               
                return _OutlineColor;
            }
            ENDCG
        }

        Pass
        {

			Name "FORWARD"

            Tags 
			{
                "LightMode"="ForwardBase"
            }
			
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			sampler2D _MainTex; 
			float4 _MainTex_ST;
			sampler2D _LightMap; 
			float4 _Color;
			float _LightArea;
			float4 _Shadow1Color;
			float4 _Shadow2Color;
			float _Shadow1Threshold;
			float _Shadow2Threshold;
			float _Gloss;
			float _SpecularThreshold;
			float4 _SpecularColor;

            struct a2v
            {
                float4 posA2v : POSITION;
				float4 color : COLOR;
				float3 normal : NORMAL;
                float2 uv : TEXCOORD0;				
            };

            struct v2f
            {
				float4 posV2f : SV_POSITION;
				float4 color : COLOR;
                float2 uv : TEXCOORD0;              
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float halfLambert : TEXCOORD3;
            };

            v2f vert (a2v v)
            {
                v2f o;
				fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                o.posV2f = UnityObjectToClipPos(v.posA2v);			
				o.worldNormal = worldNormal;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.posA2v).xyz;
				//o.halfLambert = max(0, dot(worldNormal, worldLight));//下面是halfLambert
				o.halfLambert = dot(worldNormal,worldLight)*0.5+0.5;
				
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				//主贴图
                float3 albedo = tex2D(_MainTex, i.uv).rgb;

				//光照贴图
				float3 lightMap = tex2D(_LightMap,i.uv).rgb;

				//lightMap g通道与模型color.r 共同决定漫反射不受光照影响的程度
				//这里去掉了模型color.r的影响，因为不是原版模型				
				float lightMapG = lightMap.g;// * i.color.r;

				//阴影1颜色
				float3 fristShadowColor = albedo * _Shadow1Color.rgb;

				//阴影2颜色
				float3 secondShadowColor = albedo * _Shadow2Color.rgb;

				//漫反射颜色
				float shadowThreshold = (lightMapG + i.halfLambert) * 0.5;
				float3 otherColor = ( shadowThreshold >= _Shadow1Threshold) ? albedo : fristShadowColor;
				float3 shadowColor = ( shadowThreshold >= _Shadow2Threshold) ? fristShadowColor : secondShadowColor;
				float3 diffuseColor = lightMapG >= _LightArea ? otherColor : shadowColor;
				
				//高光
				fixed spe = pow(i.halfLambert,_Gloss);
				fixed3 black = (1.0,0.0,0.0);
				//lightMap.b与默认高光spe 决定是否渲染高光
				//lightMap.r与_SpecularThreshold共同决定高光强度
				fixed3 specularColor = ((lightMap.b + spe) > 1.0) ? (lightMap.r * _SpecularThreshold * _SpecularColor.rgb) : black;
				
				fixed3 color = (diffuseColor + specularColor)* _Color.rgb;
				
                return fixed4(color,1);
				
            }

            ENDCG
        }
    }
}
