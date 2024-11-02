Shader "Custom/NoiseWaves" {

    Properties {
        _Col1 ("Color 1", Color) = (0.5, 0.5, 0.5, 1.0)
        _Col2 ("Color 2", Color) = (0.5, 0.5, 0.5, 1.0)
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define TWO_PI 6.28318530718
            #define PI     3.14159265359

            float4 _Col1, _Col2;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            // By IQ
            float2 grad(int2 z) {
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

            float2 rotate(float2 uv, float th){
                return mul(float2x2(cos(th), sin(th), -sin(th), cos(th)), uv);
            }

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target {
                float3 col = float3(0.0, 0.0, 0.0);

                float nse = 0.0;
                float2 uvn = i.uv * 1.0 + float2(_Time.y * 0.1, 0.0);
                float2x2 m = float2x2(1.6, 1.2, -1.2, 1.6);
                nse  = 0.5000 * noise(uvn); uvn = mul(m, uvn);
                nse += 0.2500 * noise(uvn); uvn = mul(m, uvn);
                nse += 0.1250 * noise(uvn); uvn = mul(m, uvn);
                nse += 0.0625 * noise(uvn); uvn = mul(m, uvn);
                nse += 0.0312 * noise(uvn); uvn = mul(m, uvn);

                float2 uvRot = rotate(i.uv, nse * 6.0);

                float lines = sin(uvRot.y * TWO_PI * 3.0) * 0.5 + 0.5;
                //lines = smoothstep(0.2, 0.3, lines) - smoothstep(0.6, 0.7, lines);
                col += lerp(_Col1, _Col2, lines);

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
