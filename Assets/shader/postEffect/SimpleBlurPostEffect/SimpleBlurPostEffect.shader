// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "N/post/SimpleBlurPostEffect"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }
        SubShader
    {
        Pass
        {
            //nafio info 注意下后处理这几个开关的处理
            ZTest Always
            Cull Off
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                half2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
                half2 uv1 : TEXCOORD1;
                half2 uv2 : TEXCOORD2;
                half2 uv3 : TEXCOORD3;
                half2 uv4 : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            //nafio info (相对与原始Texture)1像素大小  Vector4(1 / width, 1 / height, width, height)
            //1/width 这种格式的意义是方便计算uv，简单说就是1像素的uv            
            // 比如第一个像素uv就是      1 / width,            1 / height
            // 最后一个就是          width / width,       height / height
            float4 _MainTex_TexelSize;

            float _BlurRadius;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv.xy;
                o.uv1 = v.uv + _BlurRadius * _MainTex_TexelSize * half2(0,1);
                o.uv2 = v.uv + _BlurRadius * _MainTex_TexelSize * half2(0,-1);
                o.uv3 = v.uv + _BlurRadius * _MainTex_TexelSize * half2(1,0);
                o.uv4 = v.uv + _BlurRadius * _MainTex_TexelSize * half2(-1,0);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                col += tex2D(_MainTex, i.uv1);
                col += tex2D(_MainTex, i.uv2);
                col += tex2D(_MainTex, i.uv3);
                col += tex2D(_MainTex, i.uv4);
                col *= 0.2;//因为采样5次求平均值，所以这里*0.2

                return col;
            }
            ENDCG
        }
    }
       
}
