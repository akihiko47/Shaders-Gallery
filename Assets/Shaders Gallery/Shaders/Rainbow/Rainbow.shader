Shader "Custom/Rainbow" {

    Properties {
        _Red ("Red", Color) = (0.5, 0.5, 0.5, 1.0)
        _Orange ("Orange", Color) = (0.5, 0.5, 0.5, 1.0)
        _Yellow ("Yellow", Color) = (0.5, 0.5, 0.5, 1.0)
        _Green ("Green", Color) = (0.5, 0.5, 0.5, 1.0)
        _Blue ("Blue", Color) = (0.5, 0.5, 0.5, 1.0)
        _Purple ("Purple", Color) = (0.5, 0.5, 0.5, 1.0)
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define PI 3.14159265359

            float4 _Red, _Orange, _Yellow, _Green, _Blue, _Purple;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target{

                i.uv.x = frac(i.uv.x + _Time.y * 0.5);

                float4 red1   = 1                                        - smoothstep(0.0, 1.0/6.0, i.uv.x);
                float4 orange = smoothstep(0.0, 1.0 / 6.0, i.uv.x)       - smoothstep(1.0 / 6.0, 2.0 / 6.0, i.uv.x);
                float4 yellow = smoothstep(1.0 / 6.0, 2.0 / 6.0, i.uv.x) - smoothstep(2.0 / 6.0, 3.0 / 6.0, i.uv.x);
                float4 green  = smoothstep(2.0 / 6.0, 3.0 / 6.0, i.uv.x) - smoothstep(3.0 / 6.0, 4.0 / 6.0, i.uv.x);
                float4 blue   = smoothstep(3.0 / 6.0, 4.0 / 6.0, i.uv.x) - smoothstep(4.0 / 6.0, 5.0 / 6.0, i.uv.x);
                float4 purple = smoothstep(4.0 / 6.0, 5.0 / 6.0, i.uv.x) - smoothstep(5.0 / 6.0, 1.0, i.uv.x);
                float4 red2   = smoothstep(5.0 / 6.0, 1.0, i.uv.x);

                red1   *= _Red;
                orange *= _Orange;
                yellow *= _Yellow;
                green  *= _Green;
                blue   *= _Blue;
                purple *= _Purple;
                red2   *= _Red;

                return red1 + orange + yellow + green + blue + purple + red2;
            }

            ENDCG
        }
    }
}
