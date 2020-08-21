Shader "N/BloomPostEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    CGINCLUDE

    #include "UnityCG.cginc"
    sampler2D _SourceTex;
    sampler2D _MainTex;
    float4 _MainTex_TexelSize;

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

    ENDCG

    SubShader
    {
        Cull Off
        ZTest Always
        ZWrite Off

        Pass { // 0 首次降采样后，处理高亮阈值
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                
                half4 frag(v2f i) : SV_Target
                {
                    //return half4(1,1,1,1);
                    return half4(SampleBox(i.uv, 1), 1);
                }
            ENDCG
        }

        Pass { // 2 升采样

            //Blend One One

            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                half4 frag(v2f i) : SV_Target
                {
                    return half4(SampleBox(i.uv, 0.5), 1);
                }
        ENDCG
    }
    }
}
