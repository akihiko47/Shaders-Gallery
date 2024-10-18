Shader "Custom/Squares" {

    Properties {
        _ColorBg ("Background Color", Color) = (0.5, 0.5, 0.5, 0.5)
        _ColorSmile ("Smile Color", Color) = (0.5, 0.5, 0.5, 0.5)
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _ColorBg, _ColorSmile;

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

            float sqr(float2 bl, float2 tr, float2 uv){
                float result;

                float2 bl2 = step(bl, uv);
                result = bl2.x * bl2.y;

                float2 tr2 = step(1.0 - tr, 1.0 - uv);
                result *= tr2.x * tr2.y;

                return result;
            }

            float4 frag (v2f i) : SV_Target{

                float mouthMask = sqr(float2(0.1, 0.1), float2(0.9, (sin(_Time.y * 8.0) * 0.5 + 0.5) * 0.2 + 0.2), i.uv);
                
                float eyesMove  = sin(_Time.y * 5.0) * 0.05;
                float eyeLeft   = sqr(float2(0.2 + eyesMove, 0.5), float2(0.4 + eyesMove, 0.8), i.uv);
                float eyeRight  = sqr(float2(0.6 + eyesMove, 0.5), float2(0.8 + eyesMove, 0.8), i.uv);
                
                float smile = mouthMask + eyeLeft + eyeRight;

                float4 col = smile * _ColorSmile + (1 - smile) * _ColorBg;

                return col;
            }

            ENDCG
        }
    }
}
