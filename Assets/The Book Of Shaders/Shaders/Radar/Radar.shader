Shader "Custom/Radar" {

    Properties {
        _ColDark ("Color Dark", Color) = (0.5, 0.5, 0.5, 1.0)
        _ColMed ("Color Medium", Color) = (0.5, 0.5, 0.5, 1.0)
        _ColBright ("Color Bright", Color) = (0.5, 0.5, 0.5, 1.0)
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex   vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define TWO_PI 6.28318530718
            #define PI     3.14159265359

            float4 _ColDark, _ColMed, _ColBright;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float sdCircle(float2 p, float r){
                return length(p) - r;
            }

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target {

                // coordinates
                float2 uvNorm = i.uv * 2.0 - 1.0;
                float r = length(uvNorm);
                float a = (atan2(-uvNorm.x, -uvNorm.y) / TWO_PI) + 0.5;

                float3 col = float3(0.0, 0.0, 0.0);

                // main circle
                float mainCircleR = 0.8;
                float sdMainCircle = sdCircle(uvNorm, mainCircleR);
                float3 mainCircle = (smoothstep(0.01, 0.0, sdMainCircle) - smoothstep(0.0, -0.01, sdMainCircle));
                col += mainCircle * _ColBright;

                // inner glow
                float glowInner = saturate(cos(r * PI * 0.6));
                col += glowInner * _ColDark * 1.5;

                // outer glow
                float glowOuter = saturate(0.001 / sdMainCircle);
                col += glowOuter * _ColBright * (1 - mainCircle);

                // dot center
                float dotCenter = smoothstep(0.001, 0.0, sdCircle(uvNorm, 0.01));
                col += dotCenter * _ColBright;

                // rotating line
                float la = frac(_Time.y * 0.2);  // line angle
                float rotLine = (smoothstep(la + 0.005, la, a) - smoothstep(la, la - 0.005, a)) * (r <= mainCircleR) * (1 - mainCircle) * (1 - dotCenter);
                col += rotLine * _ColBright;

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
