Shader "Custom/Water" {

    Properties{
        [Header(Colors)]
        [Space(10)]
        _ColWater ("Water Color", Color) = (0.5, 0.5, 0.5, 0.5)
        _ColDepth ("Depth Color", Color) = (0.5, 0.5, 0.5, 0.5)
        _ColEdge ("Edge Color", Color) = (0.5, 0.5, 0.5, 0.5)
        _ColVor ("Voronoi Color", Color) = (0.5, 0.5, 0.5, 0.5)

        [Header(Settings)]
        [Space(10)]
        _EdgeWidth ("Edge Line Width", Float) = 0.5
        _DepthStrength ("Depth Strength", Float) = 0.5
        _VoronoiWidth ("Voronoi Width", Float) = 0.5
    }

    SubShader {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}

        Cull Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _ColWater, _ColEdge, _ColVor, _ColDepth;
            float _EdgeWidth, _DepthStrength, _VoronoiWidth;
        
            // depth
            sampler2D _CameraDepthTexture;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
            };

            struct v2f {
                float2 uv                  : TEXCOORD0;
                float4 screenPos           : TEXCOORD1;
                float3 camRelativeWorldPos : TEXCOORD2;
                float3 worldPos            : TEXCOORD3;
                float4 vertex              : SV_POSITION;
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

            // By IQ
            float2 grad(int2 z){
                int n = z.x + z.y * 11111;

                n = (n << 13) ^ n;
                n = (n * (n * n * 15731 + 789221) + 1376312589) >> 16;

                n &= 7;
                float2 gr = float2(n & 1, n >> 1) * 2.0 - 1.0;
                return (n >= 6) ? float2(0.0, gr.x) :
                    (n >= 4) ? float2(gr.x, 0.0) :
                    gr;
            }

            // by IQ
            float noise(in float2 p){
                int2 i = int2(floor(p));
                float2 f = frac(p);

                float2 u = f * f * (3.0 - 2.0 * f);

                return lerp(lerp(dot(grad(i + int2(0, 0)), f - float2(0.0, 0.0)),
                            dot(grad(i + int2(1, 0)), f - float2(1.0, 0.0)), u.x),
                            lerp(dot(grad(i + int2(0, 1)), f - float2(0.0, 1.0)),
                            dot(grad(i + int2(1, 1)), f - float2(1.0, 1.0)), u.x), u.y);
            }

            #define OCTAVES 2
            float fbm(float2 uv){

                float value = 0.0;
                float amplitude = 0.5;

                for(int i = 0; i < OCTAVES; i++){
                    value += amplitude * noise(uv) * 0.5 + 0.5;
                    uv *= 2.0;
                    amplitude *= 0.5;
                }
                return value;
            }

            v2f vert (appdata v) {
                v2f o;

                // WAVES
                v.vertex.y += (fbm(v.uv * 2.0 + _Time.y * 0.1) - 1.0) * 1.0;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;
                o.screenPos = ComputeScreenPos(o.vertex);

                o.camRelativeWorldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz - _WorldSpaceCameraPos;

                return o;
            }

            float4 frag (v2f i) : SV_Target{
                float2 UVscreen = i.screenPos.xy / i.screenPos.w;

                float4 col = 0.0;

                // DEPTH
                float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, UVscreen));
                float3 viewPlane = i.camRelativeWorldPos.xyz / dot(i.camRelativeWorldPos.xyz, unity_WorldToCamera._m20_m21_m22);
                float3 worldPos = viewPlane * depth + _WorldSpaceCameraPos;
                worldPos = mul(unity_CameraToWorld, float4(worldPos, 1.0));

                // DEPTH COL
                float depthForCol = saturate(_DepthStrength * (depth - i.screenPos.w));
                col = _ColDepth * depthForCol;

                // FOAMLINE
                float foam = 1.0 - saturate(_EdgeWidth * (depth - i.screenPos.w)) + (noise(i.uv * 30.0) * 0.5 + 0.5) * 0.3;
                float foamSin = (sin(foam * 25.0 + _Time.y * 2.0) * 0.5 + 0.5) * foam;
                foam = smoothstep(0.5, 0.52, foamSin) - smoothstep(1.5, 1.52, foamSin) * foam;
                foam *= (noise(i.uv * 20.0) * 0.5 + 0.5);
                foam = saturate(foam + (1.0 - saturate(_EdgeWidth * 10.0 * (depth - i.screenPos.w))));
                col += lerp(_ColWater, _ColEdge, foam) * (1.0 - depthForCol);

                // VORONOI
                float nse = fbm(i.uv * 50.0);
                float2 uvDistort = float2(i.uv * 30.0 + nse * 0.6);
                cellData cell = cellCoords(uvDistort);
                float vor = smoothstep(_VoronoiWidth, _VoronoiWidth - 0.02, cell.bd) * pow((noise(i.uv * 5.0 + _Time.y * 0.2) * 0.5 + 0.5), 4.0);
                col += vor * _ColVor;

                return saturate(col);
            }

            ENDCG
        }
    }
}
