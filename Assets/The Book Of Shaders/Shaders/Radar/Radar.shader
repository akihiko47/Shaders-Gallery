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

                // coordinates
                float2 uvNorm = i.uv * 2.0 - 1.0;
                
                float r = length(uvNorm);
                float a = (atan2(-uvNorm.x, -uvNorm.y) / TWO_PI) + 0.5;

                float2 uvNormR = rotate(uvNorm, -_Time.y * 0.8);  // rotated normalized uv
                float ra = (atan2(-uvNormR.x, -uvNormR.y) / TWO_PI) + 0.5;  // rotated angle

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
                float rotLine = (smoothstep(1.0, 0.995, ra) - smoothstep(0.995, 0.99, ra)) * (r <= mainCircleR) * (1 - mainCircle) * (1 - dotCenter);
                col += rotLine * _ColBright;

                // gradient behind line
                float gradLine = saturate(smoothstep(0.55, 0.995, ra) * (r <= mainCircleR) * (1 - mainCircle) * (1 - dotCenter));
                col += gradLine * _ColMed * 0.15;

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
