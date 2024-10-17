Shader "Custom/HSV" {

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

            float4 _Tint;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float3 hsb2rgb(in float3 c){
                float3 rgb = clamp(abs(fmod(c.x * 6.0 + float3(0.0, 4.0, 2.0),
                                 6.0) - 3.0) - 1.0,
                                 0.0,
                                 1.0);
                rgb = rgb * rgb * (3.0 - 2.0 * rgb);
                return c.z * lerp(float3(1.0, 1.0, 1.0), rgb, c.y);
            }

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target{

                float2 normUV = i.uv * 2 - 1;
                float dist = saturate(length(normUV));
                float angle = (atan2(normUV.y, normUV.x) / TWO_PI) + 0.5;

                float3 col = hsb2rgb(float3(angle + _Time.y * 0.2, dist, 1.0));

                col *= (dist > 0.3) * (dist < 1.0);

                return pow(float4(col, 1.0), 2.2);
            }

            ENDCG
        }
    }
}
