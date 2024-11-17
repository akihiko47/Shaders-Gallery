Shader "Custom/Shell" {

    Properties {
        _Tint ("Tint", Color) = (0.5, 0.5, 0.5, 0.5)
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        Cull Off

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _Tint;

            #define TWO_PI 6.28318530718
            #define PI     3.14159265359

            // values from script
            uniform int _TotalShells;
            uniform int _ShellIndex;
            uniform float _ShellsDistance;
            uniform int _NoiseDensity;
            uniform float4 _ColBase;
            uniform float4 _ColEdge;

            float hash21 (float2 st){
                return frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43756.657);
            }

            struct squareData{
                float2 uv; // uv of each sqr
                float2 id; // id of each sqr
                float d;   // distance from center
                float r;   // polar angle
            };

            squareData squareCoords(float2 uv){
                squareData res;

                res.uv = frac(uv);
                res.uv = res.uv * 2.0 - 1.0;

                res.id = floor(uv);
                res.d = length(res.uv);
                res.r = (atan2(-res.uv.x, -res.uv.y) / TWO_PI) + 0.5;

                return res;
            }

            struct appdata {
                float4 vertex  : POSITION;
                float3 normal  : NORMAL;
                float2 uv      : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v) {
                v2f o;
                float displacement = _ShellsDistance / _TotalShells * _ShellIndex;
                v.vertex.xyz += v.normal * displacement;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target{

                // COORDINATES
                squareData sqr = squareCoords(i.uv * _NoiseDensity);

                // BASE COLOR
                float3 col = 0.0;

                // SHELLS
                float nse = hash21(sqr.id);
                float shellAttenuation = float(_ShellIndex) / float(_TotalShells);
                clip(nse - shellAttenuation);

                col += lerp(_ColBase, _ColEdge, shellAttenuation);

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
