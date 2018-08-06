Shader "Hidden/SH/MsaaShadowFix"
{
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always
        GrabPass
        {
            "_SHShadowCopy"
        }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _SHShadowCopy;
            float4 _SHShadowCopy_TexelSize;

            #ifndef FXAA_REDUCE_MIN
                #define FXAA_REDUCE_MIN   (1.0/ 128.0)
            #endif
            #ifndef FXAA_REDUCE_MUL
                #define FXAA_REDUCE_MUL   (1.0 / 8.0)
            #endif
            #ifndef FXAA_SPAN_MAX
                #define FXAA_SPAN_MAX     8.0
            #endif
       
            float4 fxaa(sampler2D tex, float2 fragCoord, float4 resolution,
                        float2 v_rgbNW, float2 v_rgbNE, 
                        float2 v_rgbSW, float2 v_rgbSE, 
                        float2 v_rgbM) 
            {
                float4 color;
                float2 inverseVP = resolution.xy;
                float lumaNW = tex2D(tex, v_rgbNW).x;
                float lumaNE = tex2D(tex, v_rgbNE).x;
                float lumaSW = tex2D(tex, v_rgbSW).x;
                float lumaSE = tex2D(tex, v_rgbSE).x;
                
                float4 texColor = tex2D(tex, v_rgbM);
                float3 lumaM  = texColor.x;

                float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
                float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));
                
                float2 dir;
                dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
                dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));
                
                float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) *
                                      (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
                
                float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
                dir = min(float2(FXAA_SPAN_MAX, FXAA_SPAN_MAX),
                          max(float2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
                          dir * rcpDirMin)) * inverseVP;
                
                float lumaA = 0.5 * (
                    tex2D(tex, fragCoord + dir * (1.0 / 3.0 - 0.5)).x +
                    tex2D(tex, fragCoord + dir * (2.0 / 3.0 - 0.5)).x);

                float lumaB = lumaA * 0.5 + 0.25 * (
                    tex2D(tex, fragCoord + dir * -0.5).x +
                    tex2D(tex, fragCoord + dir * 0.5).x);

                if ((lumaB < lumaMin) || (lumaB > lumaMax)) {
                    color = float4(lumaA.xxx, texColor.a);
                } else {
                    color = float4(lumaB.xxx, texColor.a);
                }

                return color;
            }

			fixed4 frag (v2f i) : SV_Target
			{
                float2 inverseVP = _SHShadowCopy_TexelSize.xy;
            	float2 v_rgbNW = i.uv + float2(-1.0, -1.0) * inverseVP;
            	float2 v_rgbNE = i.uv + float2(1.0, -1.0) * inverseVP;
            	float2 v_rgbSW = i.uv + float2(-1.0, 1.0) * inverseVP;
            	float2 v_rgbSE = i.uv + float2(1.0, 1.0) * inverseVP;
            	float2 v_rgbM = float2(i.uv);

                fixed4 col = fxaa(_SHShadowCopy, i.uv, _SHShadowCopy_TexelSize,
                    v_rgbNW, v_rgbNE, v_rgbSW, v_rgbSE, v_rgbM
                );

				return col;
			}
			ENDCG
		}
	}
}
