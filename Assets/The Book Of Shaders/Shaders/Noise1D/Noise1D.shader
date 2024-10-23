Shader "Custom/Noise1D" {

    Properties {
        _ColBlob ("Blob COlor", Color) = (0.5, 0.5, 0.5, 1.0)
        _ColGlow ("Glow COlor", Color) = (0.5, 0.5, 0.5, 1.0)
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

            float4 _ColGlow, _ColBlob;

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

            float noise(float x){
                float f = frac(x);
                float i = floor(x);

                float y = lerp(random(i), random(i + 1.0), smoothstep(0.0, 1.0, f));

                return y;
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
                float d = length(uvNorm);
                float r = (atan2(-uvNorm.x, -uvNorm.y) / TWO_PI) + 0.5;
                float3 col = float3(1.0, 1.0, 1.0);

                // blob
                float disp = noise(abs(r - 0.5) * 20.0) * sin(_Time.y * TWO_PI * 0.4) * 0.1;
                float dfBlob = d + noise(abs(r - 0.5) * 30.0 + _Time.y) * 0.1 + disp;
                float blob = smoothstep(0.405, 0.4, dfBlob);
                col -= blob * _ColBlob;

                // glow
                float glow = saturate(0.2 / (dfBlob -  0.4));
                col -= pow(glow, 2.0);

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
