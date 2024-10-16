Shader "Custom/ShapingFunctions" {

    Properties{
        _ColorGround ("Color Ground", Color)   = (0.0, 0.8, 0.0, 1.0)
        _ColorHouse1 ("Color House 1", Color)  = (0.0, 0.0, 0.5, 1.0)
        _ColorHouse2 ("Color House 2", Color)  = (0.0, 0.0, 0.8, 1.0)
        _ColorSun ("Color Sun", Color)         = (0.8, 0.8, 0.0, 1.0)
        _ColorBack ("Color Background", Color) = (0.1, 0.0, 0.1, 1.0)
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _ColorGround, _ColorHouse1, _ColorHouse2, _ColorSun, _ColorBack;

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

            float4 frag (v2f i) : SV_Target {
                i.uv = i.uv * 2.0 - 1.0;
                i.uv.y += 0.2;
                float houseMask1 = (i.uv.y > -0.1) * (i.uv.y < 0.5);
                houseMask1 = houseMask1 * ceil(sin(i.uv.x * 20.0 + _Time.y));

                float houseMask2 = (i.uv.y > -0.2) * (i.uv.y < 0.2);
                houseMask2 = houseMask2 * ceil(sin(i.uv.x * 10.0 + _Time.y));
                
                houseMask1 *= (1 - houseMask2);

                float groundMask = saturate((i.uv.y < 0.0) * (1 - houseMask1) * (1 - houseMask2));
                float sunMask = (1 - (length(i.uv) > 0.6)) * (1 - houseMask1) * (1 - houseMask2) * (1 - groundMask);

                float4 col = _ColorBack * (1 - groundMask) * (1 - houseMask1) * (1 - houseMask2) * (1 - sunMask);
                col += groundMask * _ColorGround;
                col += houseMask1 * _ColorHouse1;
                col += houseMask2 * _ColorHouse2;
                col += sunMask * _ColorSun;

                return col;
            }

            ENDCG
        }
    }
}
