//这个和NRP2ToonTest1是一个
//一个初步能用的toon
//一些问题:
//描边以及描边用到的贴图后面可以考虑处理掉，替换其他方法,描边直接沿法线方向挤出了，那么离相机距离不同秒表粗细就不同了，可以考虑屏幕空间挤出
//或者用其他方法

//简单描述下
//核心在lightMap上
//r通道，高光光泽度
//g通道, 与_ShadowRange一起限制生成阴影位置,离散化阴影
//b通道, 与_SpecularRange一起限制生成高光位置,离散化高光

//总的来说，这个toon shader还不是仿崩3的
//崩3阴影有2层，这里只有一层，看起来还是缺少层次感
Shader "N/nrp" {
    Properties {
        _MainTex ("MainTex", 2D) = "white" {}
		//这种图不止是高光贴图，rgb通道各有用处
        _LightMapTex ("LightMapTex", 2D) = "white" {}
		//这张图不是阴影，而是outline的颜色，起名也太奇怪了，这样也有一点好处，不需要描边的位置，可以用相近的颜色，就显不出描边了
        _OutlineTex ("ShadowColorTex", 2D) = "white" {}
		//阴影颜色
        _ShadowColor ("ShadowColor", Color) = (0.6663285,0.6544118,1,1)
		//阴影范围，用于离散化阴影，在指定范围内才显示阴影
        _ShadowRange ("ShadowRange", Range(0, 1)) = 0
		//阴影(颜色)强弱(衰减)
        _ShadowIntensity ("ShadowIntensity", Range(0, 1)) = 0.7956449
		//高光范围，用于离散化高光，在指定范围内才显示高光
        _SpecularRange ("SpecularRange", Range(0.9, 1)) = 0.9820514
		//高光强弱(衰减)
        _SpecularMult ("SpecularMult", Range(0, 1)) = 1
		//描边宽度
        _OutlineWidth ("OutlineWidth", Range(0, 0.05)) = 0.01581197
		//描边颜色强弱
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

				//光照纹理
                float4 SpeData = tex2D(_LightMapTex,TRANSFORM_TEX(i.uv0, _LightMapTex));
				//主纹理
                float4 MainData = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
				
				/**
				float3 c = float3(0,0,0);
				float3 cc = float3(0,0,1);
				float3 bb = saturate(cc > 0.5 ? (c = float3(1,0,1) ) : (c = float3(0,1,0)));
				return float4(bb,1);
				**/
				
				//NINFO 经测试MainData.rgb > 0.5是rgb分别与0.5比较，然后Mp的值是分别计算后得到的值
				//就是说，rgb颜色强于0.5的走前面的逻辑

				//前一句意思，rgb分别较亮的部分	,
				//通过实践比对得出'
				//（具体比较方法，可以假设rgb原始为868然后，改变g值，分别计算结果）
				//g通道<0.5的部分，会被变量，=0.5不变，>0.5变暗
				float3 t1 = 1.0 - (1.0 - 2.0 * (MainData.rgb-0.5) ) * (1.0-SpeData.g);
						
				//后一句意思，rgb分别较暗的部分,
				//首先先变亮，然后通过lightMap.g通道调节亮度
				//g>0.5就变亮，=0.5不变，<0.5变暗
				float3 t2 = 2.0 * MainData.rgb * SpeData.g;

				//这步对原始颜色做了一些修正，测试发现不做修正其实差距并不大
                float3 NewMainTexColor = saturate( MainData.rgb > 0.5 ? t1 : t2);
				//测试不做修正
				//NewMainTexColor = MainData.rgb;
				

				//漫反部分
				float dotLight2Normal = max(dot(lightDirection,normalDirection),0);

				//0就是shadow，1就不是shadow
				//这里实际使用贴图g通道+_ShadowRange这个参数 实现了阴影离散画
				float beShadow = step(_ShadowRange,(dotLight2Normal-(0.5-SpeData.g)));	

				//漫反射部分 阴影部分全黑，非阴影部分是不受影响的漫反射
                float3 Diffuse = (NewMainTexColor * beShadow);

				//NINFO 高光部分,r通道存的是光泽度
				float dotView2Normal = max(dot(viewDirection,normalDirection),0);
				//NINFO 注意这里_SpecularRange起到离散化高光的作用
				float beSpecular = step(_SpecularRange,saturate(pow(dotView2Normal,SpeData.r)));

				//这里b通道用来做高光遮罩
				beSpecular = step(0.1,(beSpecular* SpeData.b));

				//高光部分
				float3 SpeColor =  beShadow * beSpecular * _SpecularMult * Diffuse ;

				//阴影部分，注意阴影是使用修正后的MainTex来辅助计算的
				//(1.0 - beShadow)不是阴影的部分就直接黑了
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
