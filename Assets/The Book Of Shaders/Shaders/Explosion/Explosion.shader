Shader "Custom/Explosion" {

    Properties {
        _PulseColor ("Pulse Color", Color) = (0.8, 0.0, 0.0, 1.0)
        _ExplColor ("Explosion Color", Color) = (1.0, 0.2, 0.0, 1.0)
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _PulseColor, _ExplColor;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            float smoothstep(float edge0, float edge1, float x){
                float t = saturate((x - edge0) / (edge1 - edge0));
                return t * t * (3.0 - 2.0 * t);
            }

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target{

                float cycle = frac(_Time.y / 11.0);
                float pulse = sin(pow(12.0 * cycle, 2.35));

                pulse *= cycle < 0.7;
                float expl = (1 - smoothstep(0.8, 1.0, cycle)) * (cycle > 0.8);
                
                float4 col = pulse * _PulseColor + expl * _ExplColor;

                return col;
            }

            ENDCG
        }
    }
}
