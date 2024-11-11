Shader "Hidden/VoronoiPixels" {

    Properties {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader {

        Tags { "RenderType" = "Opaque" }

        Cull Off ZWrite Off ZTest Always

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;

            uniform float3 _CameraWorldPos;
            uniform float4x4 _FrustumCornersMatrix;
            uniform float4x4 _CameraToWorldMatrix;

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
                        //randPoint = sin(_Time.y * 0.2 * randPoint) * 0.5 + 0.5;

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

            v2f vert (appdata v) {
                v2f o;

                half index = v.vertex.z;
                v.vertex.z = 0.1;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target{

                float aspect = _ScreenParams.y / _ScreenParams.x;
                float2 uvScreen = i.uv;

                float3 col = 0.0;
                float N = 100.0;

                cellData cell = cellCoords(uvScreen * N);
                col += tex2D(_MainTex, cell.id / N);

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
