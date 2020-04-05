//�����NRP2ToonTest1��һ��
//һ���������õ�toon
//һЩ����:
//����Լ�����õ�����ͼ������Կ��Ǵ�������滻��������,���ֱ���ط��߷��򼷳��ˣ���ô��������벻ͬ����ϸ�Ͳ�ͬ�ˣ����Կ�����Ļ�ռ伷��
//��������������

//��������
//������lightMap��
//rͨ�����߹�����
//gͨ��, ��_ShadowRangeһ������������Ӱλ��,��ɢ����Ӱ
//bͨ��, ��_SpecularRangeһ���������ɸ߹�λ��,��ɢ���߹�

//�ܵ���˵�����toon shader�����Ƿ±�3��
//��3��Ӱ��2�㣬����ֻ��һ�㣬����������ȱ�ٲ�θ�
Shader "N/nrp" {
    Properties {
        _MainTex ("MainTex", 2D) = "white" {}
		//����ͼ��ֹ�Ǹ߹���ͼ��rgbͨ�������ô�
        _LightMapTex ("LightMapTex", 2D) = "white" {}
		//����ͼ������Ӱ������outline����ɫ������Ҳ̫����ˣ�����Ҳ��һ��ô�������Ҫ��ߵ�λ�ã��������������ɫ�����Բ��������
        _OutlineTex ("ShadowColorTex", 2D) = "white" {}
		//��Ӱ��ɫ
        _ShadowColor ("ShadowColor", Color) = (0.6663285,0.6544118,1,1)
		//��Ӱ��Χ��������ɢ����Ӱ����ָ����Χ�ڲ���ʾ��Ӱ
        _ShadowRange ("ShadowRange", Range(0, 1)) = 0
		//��Ӱ(��ɫ)ǿ��(˥��)
        _ShadowIntensity ("ShadowIntensity", Range(0, 1)) = 0.7956449
		//�߹ⷶΧ��������ɢ���߹⣬��ָ����Χ�ڲ���ʾ�߹�
        _SpecularRange ("SpecularRange", Range(0.9, 1)) = 0.9820514
		//�߹�ǿ��(˥��)
        _SpecularMult ("SpecularMult", Range(0, 1)) = 1
		//��߿��
        _OutlineWidth ("OutlineWidth", Range(0, 0.05)) = 0.01581197
		//�����ɫǿ��
        _OutlineLightness ("OutlineLightness", Range(0, 1)) = 1
    }
    SubShader {
        Tags {
            "RenderType"="Opaque"
        }
        Pass {
            Name "Outline"
            Tags {
            }
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma only_renderers d3d9 d3d11 glcore gles gles3 metal d3d11_9x 
            #pragma target 3.0
            uniform sampler2D _OutlineTex; uniform float4 _OutlineTex_ST;
            uniform float _OutlineLightness;
            uniform float _OutlineWidth;

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
                float4 _ShadowColorTex_var = tex2D(_OutlineTex,TRANSFORM_TEX(i.uv0, _OutlineTex));
                return fixed4((_ShadowColorTex_var.rgb * _OutlineLightness),0);
            }
            ENDCG
        }

        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            //#pragma only_renderers d3d9 d3d11 glcore gles gles3 metal d3d11_9x 
            #pragma target 3.0
            uniform float _ShadowRange;
            uniform float _SpecularRange;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform float _ShadowIntensity;
            uniform float _SpecularMult;
            uniform sampler2D _LightMapTex; uniform float4 _LightMapTex_ST;
            uniform float4 _ShadowColor;

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
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                LIGHTING_COORDS(3,4)
            };

            VertexOutput vert (VertexInput v) 
			{
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex );
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            float4 frag(VertexOutput i) : COLOR 
			{
                i.normalDir = normalize(i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 normalDirection = i.normalDir;
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);

				//��������
                float4 SpeData = tex2D(_LightMapTex,TRANSFORM_TEX(i.uv0, _LightMapTex));
				//������
                float4 MainData = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
				
				/**
				float3 c = float3(0,0,0);
				float3 cc = float3(0,0,1);
				float3 bb = saturate(cc > 0.5 ? (c = float3(1,0,1) ) : (c = float3(0,1,0)));
				return float4(bb,1);
				**/
				
				//NINFO ������MainData.rgb > 0.5��rgb�ֱ���0.5�Ƚϣ�Ȼ��Mp��ֵ�Ƿֱ�����õ���ֵ
				//����˵��rgb��ɫǿ��0.5����ǰ����߼�

				//ǰһ����˼��rgb�ֱ�����Ĳ���	,
				//ͨ��ʵ���ȶԵó�'
				//������ȽϷ��������Լ���rgbԭʼΪ868Ȼ�󣬸ı�gֵ���ֱ��������
				//gͨ��<0.5�Ĳ��֣��ᱻ������=0.5���䣬>0.5�䰵
				float3 t1 = 1.0 - (1.0 - 2.0 * (MainData.rgb-0.5) ) * (1.0-SpeData.g);
						
				//��һ����˼��rgb�ֱ�ϰ��Ĳ���,
				//�����ȱ�����Ȼ��ͨ��lightMap.gͨ����������
				//g>0.5�ͱ�����=0.5���䣬<0.5�䰵
				float3 t2 = 2.0 * MainData.rgb * SpeData.g;

				//�ⲽ��ԭʼ��ɫ����һЩ���������Է��ֲ���������ʵ��ಢ����
                float3 NewMainTexColor = saturate( MainData.rgb > 0.5 ? t1 : t2);
				//���Բ�������
				//NewMainTexColor = MainData.rgb;
				

				//��������
				float dotLight2Normal = max(dot(lightDirection,normalDirection),0);

				//0����shadow��1�Ͳ���shadow
				//����ʵ��ʹ����ͼgͨ��+_ShadowRange������� ʵ������Ӱ��ɢ��
				float beShadow = step(_ShadowRange,(dotLight2Normal-(0.5-SpeData.g)));	

				//�����䲿�� ��Ӱ����ȫ�ڣ�����Ӱ�����ǲ���Ӱ���������
                float3 Diffuse = (NewMainTexColor * beShadow);

				//NINFO �߹ⲿ��,rͨ������ǹ����
				float dotView2Normal = max(dot(viewDirection,normalDirection),0);
				//NINFO ע������_SpecularRange����ɢ���߹������
				float beSpecular = step(_SpecularRange,saturate(pow(dotView2Normal,SpeData.r)));

				//����bͨ���������߹�����
				beSpecular = step(0.1,(beSpecular* SpeData.b));

				//�߹ⲿ��
				float3 SpeColor =  beShadow * beSpecular * _SpecularMult * Diffuse ;

				//��Ӱ���֣�ע����Ӱ��ʹ���������MainTex�����������
				//(1.0 - beShadow)������Ӱ�Ĳ��־�ֱ�Ӻ���
				float3 ShadowColor = (1.0 - beShadow) * _ShadowIntensity * NewMainTexColor * _ShadowColor.rgb;

                float3 finalColor = Diffuse + ShadowColor + SpeColor;
				
                return fixed4(finalColor,1);
				

            }
            ENDCG
        }
    }
    FallBack "Legacy Shaders/Diffuse"
    //CustomEditor "ShaderForgeMaterialInspector"
}
