Shader "Custom/Water" {

    Properties{
        [Header(Colors)]
        [Space(10)]
        _ColSurf1 ("Surface Color 1", Color) = (0.5, 0.5, 0.5, 0.5)
        _ColSurf2 ("Surface Color 2", Color) = (0.5, 0.5, 0.5, 0.5)
        _ColDepth ("Depth Color", Color) = (0.5, 0.5, 0.5, 0.5)

        [Space(10)]
        _ColEdge ("Edge Color", Color) = (0.5, 0.5, 0.5, 0.5)
        _ColVor ("Voronoi Color", Color) = (0.5, 0.5, 0.5, 0.5)
        _ColSpec ("Specular Color", Color) = (0.5, 0.5, 0.5, 0.5)

        [Header(Settings)]
        [Space(10)]
        _EdgeWidth ("Edge Line Width", Float) = 0.5
        _DepthStrength ("Depth Strength", Float) = 0.5
        _VoronoiWidth ("Voronoi Width", Float) = 0.5
        _Q ("Specular Power", Float) = 0.5
        _WavesStrength ("Waves Strength", Float) = 0.05
    }

    SubShader {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}

        Cull Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass {

            Tags {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define FORWARD_BASE_PASS

            float4 _ColSurf1, _ColSurf2, _ColEdge, _ColVor, _ColDepth, _ColSpec;
            float _EdgeWidth, _DepthStrength, _VoronoiWidth, _Q, _WavesStrength;
        
            // depth
            sampler2D _CameraDepthTexture;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
            };

            struct v2f {
                float2 uv                  : TEXCOORD0;
                float4 screenPos           : TEXCOORD1;
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
                v.vertex.y += (fbm(v.uv * 2.0 + _Time.y * 0.1) - 1.0) * 1.2;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;
                o.screenPos = ComputeScreenPos(o.vertex);

                return o;
            }

            float4 frag (v2f i) : SV_Target{
                float2 UVscreen = i.screenPos.xy / i.screenPos.w;

                float4 col = 0.0;

                // DEPTH
                float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, UVscreen));
                float depthForCol = pow(saturate(_DepthStrength * (depth - i.screenPos.w)), 0.5);

                // VORONOI ZONES
                float voronoiZones = pow((noise(i.uv * 5.0 + _Time.y * 0.2) * 0.5 + 0.5), 4.0);

                // MAIN WATER COLOR
                float4 colSurface = lerp(_ColSurf1, _ColSurf2, pow(voronoiZones, 0.5));
                col = lerp(colSurface, _ColDepth, depthForCol);

                // VORONOI
                float nse = fbm(i.uv * 50.0);
                float2 uvDistort = float2(i.uv * 30.0 + nse * 0.6);
                cellData cell = cellCoords(uvDistort);
                float vor = smoothstep(_VoronoiWidth, _VoronoiWidth - 0.02, cell.bd) * voronoiZones;
                col += vor * _ColVor;

                // FOAMLINE
                float foam = 1.0 - saturate(_EdgeWidth * (depth - i.screenPos.w)) + (noise(i.uv * 30.0) * 0.5 + 0.5) * 0.3;
                float foamSin = (sin(foam * 25.0 + _Time.y * 2.0) * 0.5 + 0.5) * foam;
                foam = smoothstep(0.5, 0.52, foamSin) - smoothstep(1.5, 1.52, foamSin) * foam;
                foam *= (noise(i.uv * 20.0) * 0.5 + 0.5);
                foam = saturate(foam + (1.0 - saturate(_EdgeWidth * 10.0 * (depth - i.screenPos.w))));
                col += foam * _ColEdge;

                // NORMALS
                float2 p = i.uv * 20.0;
                float2 q;
                q.x = (noise(p + float2(6.9, 0.0)) * 0.5 + 0.5) * 0.08;
                q.y = (noise(p + float2(5.2, 1.3)) * 0.5 + 0.5) * 0.6 + _Time.y * 0.2;
                float2 UVnorm = p + 4.0 * q;
                float NseNormals = noise(UVnorm) * 0.5 + 0.5;

                float2 offset = float2(0.01, 0.0);
                float fdx = (noise(UVnorm + offset.xy) * 0.5 + 0.5) - NseNormals;
                float fdy = (noise(UVnorm + offset.yx) * 0.5 + 0.5) - NseNormals;

                float3 normal = normalize(float3(fdx, _WavesStrength, fdy));

                // SPECULAR
                float3 L;
                float dist;
                #if defined(POINT) || defined(SPOT) || defined(POINT_COOKIE)
                    L = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
                    dist = length(_WorldSpaceLightPos0 - i.worldPos);
                #else 
                    L = normalize(_WorldSpaceLightPos0.xyz);
                    dist = 1.0;
                #endif
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 N = normal;
                float3 H = normalize(L + V);

                float4 specCol = _ColSpec * pow(max(0.0, dot(N, H)), _Q);

                col += specCol * (length(specCol) > 0.5);

                // INDDIRECT LIGHT
                float3 indirectSpec = 0.0;
                float3 indirectDif = 0.0;
                #if defined(FORWARD_BASE_PASS)
                    indirectDif += max(0, ShadeSH9(float4(normal, 1)));
                    float3 reflectionDir = reflect(-V, normal);
                    float4 envSample = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectionDir);
                    indirectSpec = DecodeHDR(envSample, unity_SpecCube0_HDR);
                #endif
                col.rgb += indirectSpec * 0.5 * (length(indirectSpec) > 0.5);

                return saturate(col);
            }

            ENDCG
        }
    }
}
