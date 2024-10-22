Shader "Custom/Matrix" {

    Properties{
        _N ("Grid Dimension", float) = 30.0
        _ColMain ("Main Color", Color) = (0.5, 0.5, 0.5, 1.0)
        _ColTrail ("Trail Color", Color) = (0.5, 0.5, 0.5, 1.0)
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

            float4 _ColMain, _ColTrail;
            float _N;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float random (float2 st){
                return frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43756.657);
            }

            struct squareData{
                float2 uv; // uv of each sqr
                float2 id; // id of each sqr
                float d;   // distance from center
                float r;   // polar angle
            };

            squareData squareCoords(float2 uv){
                squareData res;

                res.uv = frac(uv);
                res.uv = res.uv * 2.0 - 1.0;

                res.id = floor(uv);
                res.d = length(res.uv);
                res.r = (atan2(-res.uv.x, -res.uv.y) / TWO_PI) + 0.5;

                return res;
            }

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target{
                // coordinates
                float N = _N;
                float2 uvScale = i.uv * N;
                float2 id = floor(uvScale);
                float2 uvMove = float2(uvScale.x, uvScale.y + _Time.y * random(id.x + 1.234) * 30.0 + 5.0);
                squareData sqr = squareCoords(uvMove);

                // base color
                float3 col = 0.0;

                // moving columns
                float lineInt = smoothstep(random(sqr.id.x + 1.23) * 0.6 + 0.2, 0.0, frac(sqr.id.y * 0.06 * random(sqr.id.x + 1.2323) + 0.03));
                float part = lineInt * (random(sqr.id) * 0.7 + 0.3);
                col += part * lerp(_ColTrail, _ColMain, lineInt);



                // coordinates 2
                float2 uvScale2 = i.uv * N * 2.3213;
                float2 id2 = floor(uvScale2);
                float2 uvMove2 = float2(uvScale2.x, uvScale2.y + _Time.y * random(id2.x + 1.234) * 30.0 + 5.0);
                squareData sqr2 = squareCoords(uvMove2);

                // base color 2
                float3 col2 = 0.0;

                // moving columns 2
                float lineInt2 = smoothstep(random(sqr2.id.x + 1.23) * 0.6 + 0.2, 0.0, frac(sqr2.id.y * 0.06 * random(sqr2.id.x + 1.2323) + 0.03));
                float part2 = lineInt2 * (random(sqr2.id) * 0.7 + 0.3);
                col += part2 * lerp(_ColTrail, _ColMain, lineInt2) * 0.3 * (1.0 - lineInt);



                // glow
                float glow = saturate(0.015 / (-i.uv.y + 1.2));
                col += glow * _ColMain;

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
