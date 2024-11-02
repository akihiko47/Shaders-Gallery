Shader "Custom/CellNoise" {

    Properties {
        _Tint ("Tint", Color) = (0.5, 0.5, 0.5, 1.0)
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

            v2f vert (appdata v){
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float random (float2 st){
                return frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43756.657);
            }

            float2 random2 (float2 st){
                return float2(frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43756.657),
                              frac(sin(dot(st.xy, float2(31.6197, 42.442))) * 73185.853));
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
                res.uv = res.uv;

                res.id = floor(uv);
                res.d = length(res.uv);
                res.r = (atan2(-res.uv.x, -res.uv.y) / TWO_PI) + 0.5;

                return res;
            }

            struct cellData{
                float2 uv; // uv of each sqr
                float id;  // id of each sqr
                float d;   // distance from edges
                float r;   // polar angle
            };

            cellData cellCoords(float2 uv){
                cellData res;

                float2 sqrId = floor(uv);
                float2 sqrUv = frac(uv);

                float d = 3.402823466e+38F;
                float id;
                for(int y = -1; y <= 1; y++){
                    for(int x = -1; x <= 1; x++){
                        float2 idOffset = float2(x, y);
                        float2 cellId = random2(sqrId + idOffset);
                        float2 p = (0.5 + 0.5 * sin(_Time.y * cellId)) - sqrUv + idOffset;
                        float dist = dot(p, p);
                        if(dist < d){
                            d = dist;
                            id = cellId;
                        }
                    }
                }
                
                res.d = sqrt(d);
                res.id = id;
                res.uv = 0.0;
                res.r = 0.0;

                return res;
            }

            float4 frag (v2f i) : SV_Target{

                // coordinates
                cellData cell = cellCoords(i.uv * 10.0);

                float3 col = 0.0;

                col += cell.d;

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
