Shader "Custom/NoiseBlur" {

    Properties{
        _Tint ("Tint", Color) = (0.5, 0.5, 0.5, 0.5)
        _BlurStrength("Blur Strength", Float) = 1.0
        _Iterations("Iterations", Float) = 100
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #define TWO_PI 6.28318530718
            #define PI     3.14159265359

            #include "UnityCG.cginc"

            float4 _Tint;
            uniform sampler2D _RenderTexture;
            uniform sampler2D _BluredTexture;
            float _BlurStrength, _Iterations;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
            };

            struct v2f {
                float4 vertex    : SV_POSITION;
                float2 uv        : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            };

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.uv = v.uv;
                return o;
            }

            float2 random2 (float2 st){
                return float2(frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43756.657),
                              frac(sin(dot(st.xy, float2(31.6197, 42.442))) * 73185.853));
            }

            #define ITERATIONS 30
            float3 NoiseBlur(sampler2D tex, float2 uv, float strength){
                float3 res = 0.0;
                for(int i = 0; i < ITERATIONS; i++){
                    float2 offset = random2(float2(i + uv.x, uv.y)) * strength;
                    res += tex2D(tex, uv + (offset - strength * 0.5));
                }
                return res / float(ITERATIONS);
            }

            float4 frag (v2f i) : SV_Target{

                float2 UVscreen = i.screenPos.xy / i.screenPos.w;

                float3 col = 0.0;

                // NOISE BLUR
                col += NoiseBlur(_RenderTexture, UVscreen, _BlurStrength);

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
