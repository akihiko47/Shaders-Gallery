Shader "Custom/HexGrid" {

    Properties {
        _Tint ("Tint", Color) = (0.5, 0.5, 0.5, 0.5)
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

            float4 _Tint;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float2 mod(float2 x, float2 y) {
                return x - y * floor(x / y);
            }

            float dfHex(float2 p){
                p = abs(p);
                float vert = abs(p.x);
                float hor = dot(p, normalize(float2(1.0, 1.73)));
                return max(vert, hor);
            }

            // x    - distance
            // y    - polar angle
            // z, w - id of hex
            float4 hexCoords(float2 uv) {
                float2 r = float2(1, 1.73);
                float2 h = r * 0.5;

                float2 a = mod(uv,     r) - h;
                float2 b = mod(uv - h, r) - h;

                float2 gv = dot(a, a) < dot(b, b) ? a : b;

                
                float x = 1.0 - dfHex(gv) * 2.0;
                float y = (atan2(-gv.x, -gv.y) / TWO_PI) + 0.5;
                float2 id = uv - gv;
                return float4(x, y, id.x, id.y);
            }

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target{

                // coordinates
                float2 uvNorm = i.uv * 2.0 - 1.0;
                float4 hex = hexCoords(i.uv * 10.0);

                float3 col = 0.0;

                return float4(hex.xxx, 1.0);
            }

            ENDCG
        }
    }
}
