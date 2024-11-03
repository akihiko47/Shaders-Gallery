Shader "Custom/CellNoise" {

    Properties {
        _Col1 ("Color 1", Color) = (0.5, 0.5, 0.5, 1.0)
        _Col2 ("Color 2", Color) = (0.5, 0.5, 0.5, 1.0)
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

            float4 _Col1, _Col2;

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

            struct cellData{
                float2 uv; // uv of each sqr
                float2 id; // id of each sqr
                float d;   // distance from center
                float bd;  // distance from edges
            };

            cellData cellCoords(float2 uv){
                cellData res;

                float2 sqrId = floor(uv);
                float2 sqrUv = frac(uv);

                float2 minOffset;
                float2 minP;

                float d = 3.402823466e+38F;
                float2 id;
                for(int y = -1; y <= 1; y++){
                    for(int x = -1; x <= 1; x++){
                        float2 idOffset = float2(x, y);
                        float2 randPoint = random2(sqrId + idOffset);

                        // ANIMATION HERE
                        randPoint = sin(_Time.y * 0.2 * randPoint) * 0.5 + 0.5;

                        float2 p = randPoint + idOffset - sqrUv;
                        float sqrDist = dot(p, p);
                        if(sqrDist < d){
                            d = sqrDist;
                            id = sqrId + idOffset;
                            minOffset = idOffset;
                            minP = p;
                        }
                    }
                }

                float bd = 3.402823466e+38F;
                for(int j = -2; j <= 2; j++){
                    for(int i = -2; i <= 2; i++){
                        float2 idOffset = minOffset + float2(i, j);
                        float2 randPoint = random2(sqrId + idOffset);

                        // ANIMATION HERE
                        randPoint = sin(_Time.y * 0.2 * randPoint) * 0.5 + 0.5;

                        float2 p = randPoint + idOffset - sqrUv;
                        float dist = dot(0.5 * (minP + p), normalize(p - minP));

                        bd = min(bd, dist);
                    }
                }
                
                res.d = sqrt(d);
                res.id = id;
                res.uv = float2(-minP.x, -minP.y);
                res.bd = bd;

                return res;
            }

            float4 frag (v2f i) : SV_Target{

                // coordinates
                cellData cell = cellCoords((i.uv * 2.0 - 1.0) * 5.0);
                cellData cell2 = cellCoords((i.uv * 2.0 - 1.0) * 1.0);

                // main color
                float3 col = 0.0;

                // cracks
                float cracs = smoothstep(0.05, 0.06, saturate(cell.bd));
                col += cracs * lerp(_Col1, _Col2, cell.id.y * 0.1 + 0.55) * cracs;

                // shadow
                col *= (smoothstep(0.08, 0.02, cell2.bd));

                // big cracks
                col += cell2.bd > 0.1;
                col += lerp(_Col1, _Col2, cell.id.y * 0.1 + 0.55) * (cell2.bd > 0.07) * (cell2.bd < 0.1) * 0.4;
                

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
