Shader "Custom/FBM" {

    Properties {
        _Col1 ("Color 1", Color) = (0.5, 0.5, 0.5, 1.0)
        _Col2 ("Color 2", Color) = (0.5, 0.5, 0.5, 1.0)
        _Col3 ("Color 3", Color) = (0.5, 0.5, 0.5, 1.0)
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _Col1, _Col2, _Col3;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            // By IQ
            float2 grad(int2 z){
                int n = z.x + z.y * 11111;

                n = (n << 13) ^ n;
                n = (n * (n * n * 15731 + 789221) + 1376312589) >> 16;

                n &= 7;
                float2 gr = float2(n & 1, n >> 1) * 2.0 - 1.0;
                return (n >= 6) ? float2(0.0, gr.x) :
                    (n >= 4) ? float2(gr.x, 0.0) :
                    gr;
            }

            // by IQ
            float noise(in float2 p){
                int2 i = int2(floor(p));
                float2 f = frac(p);

                float2 u = f * f * (3.0 - 2.0 * f);

                return lerp(lerp(dot(grad(i + int2(0, 0)), f - float2(0.0, 0.0)),
                            dot(grad(i + int2(1, 0)), f - float2(1.0, 0.0)), u.x),
                            lerp(dot(grad(i + int2(0, 1)), f - float2(0.0, 1.0)),
                            dot(grad(i + int2(1, 1)), f - float2(1.0, 1.0)), u.x), u.y);
            }

            #define OCTAVES 6
            float fbm(float2 uv){

                float value = 0.0;
                float amplitude = 0.5;

                for(int i = 0; i < OCTAVES; i++){
                    value += amplitude * (noise(uv) * 0.5 + 0.5);
                    uv *= 2.0;
                    amplitude *= 0.5;
                }
                return value;
            }

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target{

                // p      = i.uv
                // result = fbm(p + fbm(p))
                // q      = fbm(p)---this

                // COORDS
                float2 p = i.uv * 4;

                // BASE COLOR
                float3 col = 0.0;

                // NOISE
                // because fbm is 1 dimension, we need to displace p in two dimensions separately
                float2 q;
                q.x = fbm(p + float2(6.9, 0.0)) + (sin(_Time.y * 0.5)) * 0.08;
                q.y = fbm(p + float2(5.2, 1.3)) + (cos(_Time.y * 0.3)) * 0.1;

                float nse = fbm(p + 4.0 * q);

                // COLOR
                col = lerp(_Col1, _Col2, saturate(nse * nse * 2.5));
                col = lerp(col,   _Col3, saturate(pow(length(q), 4.0)));

                return float4(pow(col, 6.0), 1.0);
            }

            ENDCG
        }
    }
}
