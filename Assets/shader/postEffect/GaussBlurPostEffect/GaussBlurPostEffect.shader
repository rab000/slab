//高斯模糊
Shader "N/GaussBlurPostEffect"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }

    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        float4 _MainTex_TexelSize;
        half _BlurRadius;

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float4 vertex : SV_POSITION;
            float4 uvs[5] : TEXCOORD1;
        };

        v2f vert(appdata v) {

            v2f o;

            o.vertex = UnityObjectToClipPos(v.vertex);

            o.uvs[0].xy = v.uv;
            o.uvs[1].xy = v.uv + float2(0, _MainTex_TexelSize.y * 1) * _BlurRadius;
            o.uvs[2].xy = v.uv + float2(0, _MainTex_TexelSize.y * -1) * _BlurRadius;
            o.uvs[3].xy = v.uv + float2(0, _MainTex_TexelSize.y * 2) * _BlurRadius;
            o.uvs[4].xy = v.uv + float2(0, _MainTex_TexelSize.y * -2) * _BlurRadius;

            o.uvs[0].zw = v.uv;
            o.uvs[1].zw = v.uv + float2(_MainTex_TexelSize.x * 1, 0) * _BlurRadius;
            o.uvs[2].zw = v.uv + float2(_MainTex_TexelSize.x * -1, 0) * _BlurRadius;
            o.uvs[3].zw = v.uv + float2(_MainTex_TexelSize.x * 2, 0) * _BlurRadius;
            o.uvs[4].zw = v.uv + float2(_MainTex_TexelSize.x * -2, 0) * _BlurRadius;

            return o;

        }

        fixed4 frag(v2f i) : SV_Target
        {
            //ninfo 这里这个数值有待商榷，gausse卷积核
            float weight[3] = {0.4026, 0.2442, 0.0545};

            float4 col = tex2D(_MainTex, i.uvs[0].xy) * weight[0];

            col += tex2D(_MainTex, i.uvs[1].xy) * weight[1];
            col += tex2D(_MainTex, i.uvs[2].xy) * weight[1];
            col += tex2D(_MainTex, i.uvs[3].xy) * weight[2];
            col += tex2D(_MainTex, i.uvs[4].xy) * weight[2];

            col = tex2D(_MainTex, i.uvs[0].zw) * weight[0];
            col += tex2D(_MainTex, i.uvs[1].zw) * weight[1];
            col += tex2D(_MainTex, i.uvs[2].zw) * weight[1];
            col += tex2D(_MainTex, i.uvs[3].zw) * weight[2];
            col += tex2D(_MainTex, i.uvs[4].zw) * weight[2];

            return col;
        }

        ENDCG

        ZTest Always
        Cull Off
        ZWrite Off

        Pass
        {
            NAME "gausse"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }

       
    }

    FallBack Off

}
