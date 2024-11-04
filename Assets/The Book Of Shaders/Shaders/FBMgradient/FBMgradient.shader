Shader "Custom/FBMgradient" {

    Properties {
        _Col1 ("Color 1", Color) = (0.5, 0.5, 0.5, 1.0)
        _Col2 ("Color 2", Color) = (0.5, 0.5, 0.5, 1.0)
        _Col3 ("Color 3", Color) = (0.5, 0.5, 0.5, 1.0)
        _Col4 ("Color 4", Color) = (0.5, 0.5, 0.5, 1.0)
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _Col1, _Col2, _Col3, _Col4;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float2 rotate(float2 uv, float th){
                return mul(float2x2(cos(th), sin(th), -sin(th), cos(th)), uv);
            }

            // By IQ
            float2 grad(int2 z, float rot){
                int n = z.x + z.y * 11111;

                n = (n << 13) ^ n;
                n = (n * (n * n * 15731 + 789221) + 1376312589) >> 16;

                n &= 7;
                float2 gr = float2(n & 1, n >> 1) * 2.0 - 1.0;
                float2 res = (n >= 6) ? float2(0.0, gr.x) :
                             (n >= 4) ? float2(gr.x, 0.0) :
                             gr;
                return rotate(res, _Time.y * rot * 0.2);
            }

            // by IQ
            float noise(in float2 p, float rot){
                int2 i = int2(floor(p));
                float2 f = frac(p);

                float2 u = f * f * (3.0 - 2.0 * f);

                return lerp(lerp(dot(grad(i + int2(0, 0), rot), f - float2(0.0, 0.0)),
                                 dot(grad(i + int2(1, 0), rot), f - float2(1.0, 0.0)), u.x),
                            lerp(dot(grad(i + int2(0, 1), rot), f - float2(0.0, 1.0)),
                                 dot(grad(i + int2(1, 1), rot), f - float2(1.0, 1.0)), u.x), u.y);
            }

            #define OCTAVES 9
            float fbm(float2 uv){

                float value = 0.0;
                float amplitude = 0.5;
                float rot = 1.5;

                for(int i = 0; i < OCTAVES; i++){
                    value += amplitude * (noise(uv, rot) * 0.5 + 0.5);
                    uv *= 2.0;
                    amplitude *= 0.5;
                    rot *= 1.5;
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
                float2 p = i.uv * 5.0;

                // BASE COLOR
                float3 col = 0.0;

                // NOISE
                float2 q;
                q.x = fbm(p + float2(6.9, 0.0)) + (sin(_Time.y * 0.5)) * 0.08;
                q.y = fbm(p + float2(5.2, 1.3)) + (cos(_Time.y * 0.3)) * 0.1;

                float2 r;
                r.x = fbm(p + 4.0 * q + float2(1.7, 9.2));
                r.y = fbm(p + 4.0 * q + float2(8.3, 2.8));

                float nse = fbm(p + 4.0 * r);

                // COLOR
                col = lerp(_Col1, _Col2, saturate(pow(nse, 1.5)));
                col = lerp(col, _Col3, q.y * q.y);
                col = lerp(col, _Col4, smoothstep(0.8, 0.85, r.x + r.y) - smoothstep(0.85, 0.9, r.x + r.y));

                return float4(pow(col, 3.0), 1.0);
            }

            ENDCG
        }
    }
}
