Shader "N/BloomPostEffect"
{
    Properties
    {
		//nafio info 这个图虽然没有具体图片但也是必要的，用来取单个图像素大小
        _MainTex ("Texture", 2D) = "white" {}
    }

    CGINCLUDE

    #include "UnityCG.cginc"
    sampler2D _SourceTex;
    sampler2D _MainTex;
    float4 _MainTex_TexelSize;

	//用于传入softThread 公式需要使用的一些参数
	half4 _Filter;

	half _Intensity;

    struct a2v
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    };

    struct v2f 
    {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
    };

    v2f vert(a2v i) 
    {
        v2f o;
        o.pos = UnityObjectToClipPos(i.vertex);
        o.uv = i.uv;
        return o;
    }

    half3 Sample(float2 uv)
    {
        return tex2D(_MainTex, uv).rgb;
    }
    //ninfo 盒式采样，采集一个点(0.0)周围4个点来合成这个点
    //这四个点分别为(-1,-1)   (-1,1)  (1, -1) (-1,-1)
     //delta是采样半径或采样距离
    half3 SampleBox(float2 uv, float delta)
    {
        float4 o = _MainTex_TexelSize.xyxy * float2(-delta, delta).xxyy;
        half3 s =
            Sample(uv + o.xy) + Sample(uv + o.zy) +
            Sample(uv + o.xw) + Sample(uv + o.zw);
        return s * 0.25f;
    }

	//ninfo
	//这个函数的目的是
	//1 找出亮度超出阈值BloomEffect.threshold的部分，超出越多模糊越大
	//2 BloomEffect.softThreshold的作用是修正BloomEffect.threshold，使原来陡峭的过渡曲线变得平滑
	//3 Prefilter计算亮度对最终bloom效果的影响contribution，只需要在第一次降采样时计算就可以，不需要多次计算
	//https://catlikecoding.com/unity/tutorials/advanced-rendering/bloom/
	half3 Prefilter (half3 c)
	{
		half brightness = max(c.r, max(c.g, c.b));
		half soft = brightness - _Filter.y;
		soft = clamp(soft, 0, _Filter.z);
		soft = soft * soft * _Filter.w;
		half contribution = max(soft, brightness - _Filter.x);
		contribution /= max(brightness, 0.00001);		
		return c * contribution;
	}

    ENDCG

    SubShader
    {
        Cull Off
        ZTest Always
        ZWrite Off

		Pass { // 0
			CGPROGRAM
				#pragma vertex vert
                #pragma fragment frag

				half4 frag (v2f i) : SV_Target
				{
					return half4(Prefilter(SampleBox(i.uv, 1)), 1);
				}
			ENDCG
		}

        Pass { // 1 非首次降采样
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                
                half4 frag(v2f i) : SV_Target
                {
                    return half4(SampleBox(i.uv, 1), 1);
                }
            ENDCG
        }

        Pass { // 2 非最后一次升采样

            Blend One One

            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                half4 frag(v2f i) : SV_Target
                {
                    return half4(SampleBox(i.uv, 0.5), 1);
                }
			ENDCG
		}

		Pass { // 3
			CGPROGRAM
				#pragma vertex vert
                #pragma fragment frag

				half4 frag (v2f i) : SV_Target {
					half4 c = tex2D(_SourceTex, i.uv);
					c.rgb += _Intensity * SampleBox(i.uv, 0.5);
					return c;
				}
			ENDCG
		}

		//ninfo 这个pass只有debug开启后才用，用来查看bloom生效最明显的部分
		//就是输出与原始图片叠加前，最后计算出的bloom效果
		Pass { // 4 最后一次升采样，也是模糊图与原图
			CGPROGRAM
				#pragma vertex vert
                #pragma fragment frag

				half4 frag (v2f i) : SV_Target {
					return half4(_Intensity * SampleBox(i.uv, 0.5), 1);
				}
			ENDCG
		}

    }
}
