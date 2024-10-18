Shader "Custom/SDF" {

    Properties {
        _ColorS ("Color S", Color) = (0.5, 0.5, 0.5, 0.5)
        _ColorGlow ("Color Glow", Color) = (0.5, 0.5, 0.5, 0.5)
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _ColorS, _ColorGlow;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float dot2(float2 vec){
                return dot(vec, vec);
            }

            float sdfCoolS(in float2 p){
                float six = (p.y < 0.0) ? -p.x : p.x;
                p.x = abs(p.x);
                p.y = abs(p.y) - 0.2;
                float rex = p.x - min(round(p.x / 0.4), 0.4);
                float aby = abs(p.y - 0.2) - 0.6;

                float d = dot2(float2(six, -p.y) - clamp(0.5 * (six - p.y), 0.0, 0.2));
                d = min(d, dot2(float2(p.x, -aby) - clamp(0.5 * (p.x - aby), 0.0, 0.4)));
                d = min(d, dot2(float2(rex, p.y - clamp(p.y, 0.0, 0.4))));

                float s = 2.0 * p.x + aby + abs(aby + 0.4) - 0.4;
                return sqrt(d) * sign(s);
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

            float4 frag (v2f i) : SV_Target{

                i.uv = i.uv * 2.0 - 1.0;

                i.uv = abs(i.uv) - 0.3;


                float ssdf = sdfCoolS(rotate(i.uv * 1.5, -_Time.y));

                float3 col = float(step(ssdf, -0.02) * step(-ssdf, 0.05)) * _ColorS;

                float3 glow = saturate(0.003 / ssdf) * _ColorGlow * 2.0;
                col += glow;

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
