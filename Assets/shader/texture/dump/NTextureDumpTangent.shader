
//切空间计算法线贴图
//另外一种处理法线贴图的方法是在frag中把法线贴图信息转换到世界坐标进行计算
//1 是相对具体点得坐标系，方便做动画(比如物体表面整体朝z轴方向波动)
//2 法线贴图可以压缩成只有x,y坐标，省体积
//3 省计算量，可以在vert中直接把光方向，观察者方向计算好，传入frag后取出法线图值就能直接计算
Shader "N/texture/dump/NTextureDumpTangent"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

		_BumpMap ("Normal Map", 2D) = "bump" {}

		//凹凸程度，0时不会表现出凹凸效果
		_BumpScale ("Bump Scale", Float) = 1.0
		//漫反射颜色
		_Diffuse ("_Diffuse", Color) = (1, 1, 1, 1)
		//高光颜色
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		//高光光泽度
		_Gloss ("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
			Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
			#include "Lighting.cginc"

			sampler2D _MainTex;
            float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
				float4 tangent : TANGENT;
            };

            struct v2f
            {
				//如果没有dump的_BumpMap_ST，可以直接使用float2
                float4 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
				//切向空间计算出光方向，和观察者方向，传递到frag中，根据法线贴图中得值直接在切空间计算
				float3 lightDir: TEXCOORD1;
				float3 viewDir : TEXCOORD2;
            };

            
            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

				//计算偏移量，一般bump和mainTex偏移量一致，这里假设是不一致的情况
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.xy = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.uv.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
				
				//---开始计算切空间的光照方向，观察者方向
				//法线从物体空间转到世界空间，这里返回的向量是单位向量
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				//切线从物体空间转世界空间 
				//v.tangent.xyz就是切空间的x轴，是单位向量
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				//利用差乘计算出切空间下点的y轴worldBinormal，v.tangent.w里存的y轴正负方向1或-1
				//因为是用前两个单位向量计算出来的，也是单位向量
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				//构建构建切空间到世界空间的矩阵，这个矩阵只有旋转没有缩放，所以是正交矩阵
				//注意这里构建出的是行矩阵，因为unity shader用的cg语法，所以是行矩阵
				float3x3 worldToTangent = float3x3(worldTangent, worldBinormal, worldNormal);
				//把光方向，观察者方向转到切空间，传到frag中使用,因为是行矩阵，所以矩阵在前		
				o.lightDir = mul(worldToTangent, WorldSpaceLightDir(v.vertex));
				o.viewDir = mul(worldToTangent, WorldSpaceViewDir(v.vertex));

				//--另一种方式计算切空间的光照方向，观察者方向				
				//TANGENT_SPACE_ROTATION;//这个方法用于得到物体空间到切空间的矩阵rotation
				//o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex));
				//o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex));

                UNITY_TRANSFER_FOG(o,o.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				//得到法线贴图中颜色
				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
				//从法线贴图颜色中取出法线信息
				fixed3 tangentNormal = UnpackNormal(packedNormal);
				//这里解释下_BumpScale，这个数越大，z就会越小,
				//_BumpScale=0时，法线会完全沿着模型法线方向，看起来就没有凹凸
				//_BumpScale<0法线会反向，出现内凹
				//_BumpScale特别大或特别小时，法线会趋向于与(法线贴图中)正常法线垂直的方向，表现出奇怪的效果，没必要过度思考
				tangentNormal.xy *= _BumpScale;
				//这里单独计算z是因为，法线是单位向量，如果直接tangentNormal.xyz *= _BumpScale;结果就不是单位向量了
				//所以先计算xy缩放，然后按单位向量求出z
				//sqrt是开方，dot内写法看不懂，自己替换了后面的写法，从效果上看等价
				//tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				tangentNormal.z = sqrt(1.0 - saturate(pow(tangentNormal.xy,2)));
				//注意这里从贴图中得到的颜色实际是材质颜色，所以后面是*albedo
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Diffuse.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				//漫反射
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));
				//billionPhong高光
				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);

                // sample the texture
                fixed4 col = fixed4(ambient + diffuse + specular, 1.0);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                return col;
            }
            ENDCG
        }
    }
	FallBack "Specular"
}
