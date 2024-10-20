Shader "Custom/HexGrid" {

    Properties {
        _ColHex ("Color Hexagons", Color) = (0.5, 0.5, 0.5, 1.0)
        _ColBg ("Color Background", Color) = (0.5, 0.5, 0.5, 1.0)
        _ColActive ("Color Highlight", Color) = (0.5, 0.5, 0.5, 1.0)
        _ColGlow ("Color Glow", Color) = (0.5, 0.5, 0.5, 1.0)
        _ColGlowActive ("Color Glow Active", Color) = (0.5, 0.5, 0.5, 1.0)
        _TexMetal ("Metal Texture", 2D) = "grey" {}
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

            float4 _ColHex, _ColBg, _ColActive, _ColGlow, _ColGlowActive;
            sampler2D _TexMetal;

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

            struct hexData{
                float2 uv; // uv of each hex
                float d;   // distance from edge
                float r;   // polar angle
                float2 id; // id of each hex
            };

            hexData hexCoords(float2 uv) {
                hexData res;

                float2 r = float2(1, 1.73);
                float2 h = r * 0.5;

                float2 a = mod(uv,     r) - h;
                float2 b = mod(uv - h, r) - h;

                float2 gv = dot(a, a) < dot(b, b) ? a : b;

                res.uv = gv;
                res.d = 1.0 - dfHex(gv) * 2.0;
                res.r = (atan2(-gv.x, -gv.y) / TWO_PI) + 0.5;
                res.id = uv - gv;

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
                float2 uvNorm = i.uv * 2.0 - 1.0;
                hexData hex = hexCoords(uvNorm * 5.0);

                float3 col = 0.0;

                // hexagons
                float pulse = saturate((sin(length(hex.id) - _Time.y)));
                float hexs = smoothstep(0.1 + pulse * 0.4, 0.1 + pulse * 0.4 + 0.01, hex.d);
                col += hexs * _ColHex;

                // background
                col += (1 - hexs) * _ColBg;

                // matal texture
                float3 metal = tex2D(_TexMetal, i.uv).rgb;
                col *= pow((metal + 0.5), 5.0) * hexs;

                // pulses
                col += pulse * _ColActive * hexs;

                // glow
                col += saturate(0.03 / (hex.d)) * _ColGlowActive * pulse;
                col += saturate(0.005 / (hex.d)) * _ColGlow * (1.0 - pulse);

                // flare
                col += pow(saturate(hex.uv.y), 2.9) * hexs * 0.15;
                col += pow(saturate(uvNorm.y), 1.7) * hexs * 0.15;

                // shadow
                col -= pow(saturate(-hex.uv.y), 1.7) * hexs * 0.25;
                col -= pow(saturate(-uvNorm.y), 1.7) * hexs * 0.045;

                // edge flare
                col += smoothstep(0.4, 0.42, saturate(dot(hex.uv, normalize(float2(1.0, 1.73))))) * hexs * 0.2;
                col += smoothstep(0.4, 0.42, saturate(dot(hex.uv, normalize(float2(-1.0, 1.73))))) * hexs * 0.2;

                // edge shadow
                col -= smoothstep(0.4, 0.42, saturate(dot(-hex.uv, normalize(float2(1.0, 1.73))))) * hexs * 0.06;
                col -= smoothstep(0.4, 0.42, saturate(dot(-hex.uv, normalize(float2(-1.0, 1.73))))) * hexs * 0.06;

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
