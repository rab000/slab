Shader "N/SelfBeng3"
{
    Properties
    {
		//主贴图
        _MainTex ("MainTex", 2D) = "white" {}
		//光照图
		_LightMap("LightMap", 2D) = "white" {}

		//描边宽度
        _OutlineWidth ("OutlineWidth", Range(0, 0.05)) = 0.01581197		
		//描边颜色
		 _OutlineColor ("OutlineColor", Color) = (0,0,0,1)

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
			#include "AutoLight.cginc"

			sampler2D _MainTex; 
			float4 _MainTex_ST;
			sampler2D _LightMap; 
			//float4 _LightMap_ST;

            struct a2v
            {
                float4 posA2v : POSITION;
				float3 normal : NORMAL;
                float2 uv : TEXCOORD0;				
            };

            struct v2f
            {
				float4 posV2f : SV_POSITION;
                float2 uv : TEXCOORD0;              
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
            };

            v2f vert (a2v v)
            {
                v2f o;

				fixed3 wordNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

                o.posV2f = UnityObjectToClipPos(v.posA2v);			
				o.worldNormal = wordNormal;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldPos = mul(unity_ObjectToWorld, v.posA2v).xyz;
				fixed lambert = saturate(dot(wordNormal,worldLight));
				
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                fixed4 col = tex2D(_MainTex, i.uv);

                return col;

            }

            ENDCG
        }
    }
}
