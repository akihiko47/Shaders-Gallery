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
            uniform float4 _ColMid;
            uniform float4 _ColEdge;
            uniform float _NoiseScale;
            uniform float _RandomCeof;
            uniform float _Attenuation;

            float hash21(float2 st){
                return frac(sin(dot(st.xy, float2(12.989348, 71.2334343))) * 436.657);
            }

            float2 hash22(float2 st){
                return float2(frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43756.657),
                              frac(sin(dot(st.xy, float2(31.6197, 42.442))) * 73185.853));
            }

            float3 hash33(float3 p) // replace this by something better
            {
                p = float3(dot(p, float3(1237.1, 31211.7, 7324.7)),
                           dot(p, float3(239.5, 133383.3, 2146.1)),
                           dot(p, float3(113.5, 27221.9, 1214.6)));
                p = -1.0 + 2.0 * frac(sin(p) * 435.5423);

                // ROTATION PART
                //float t = _Time.y * 1.0;
                //float2x2 m = float2x2(cos(t), -sin(t), sin(t), cos(t));
                //p.xz = mul(m, p.xz);

                return p;
            }

            // By IQ
            float noise(float3 p){
                float3 i = floor(p);
                float3 f = frac(p);

                float3 u = f * f * (3.0 - 2.0 * f);

                return lerp(lerp(lerp(dot(hash33(i + float3(0.0, 0.0, 0.0)), f - float3(0.0, 0.0, 0.0)),
                            dot(hash33(i + float3(1.0, 0.0, 0.0)), f - float3(1.0, 0.0, 0.0)), u.x),
                            lerp(dot(hash33(i + float3(0.0, 1.0, 0.0)), f - float3(0.0, 1.0, 0.0)),
                            dot(hash33(i + float3(1.0, 1.0, 0.0)), f - float3(1.0, 1.0, 0.0)), u.x), u.y),
                            lerp(lerp(dot(hash33(i + float3(0.0, 0.0, 1.0)), f - float3(0.0, 0.0, 1.0)),
                            dot(hash33(i + float3(1.0, 0.0, 1.0)), f - float3(1.0, 0.0, 1.0)), u.x),
                            lerp(dot(hash33(i + float3(0.0, 1.0, 1.0)), f - float3(0.0, 1.0, 1.0)),
                            dot(hash33(i + float3(1.0, 1.0, 1.0)), f - float3(1.0, 1.0, 1.0)), u.x), u.y), u.z);
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
                        float2 randPoint = hash22(sqrId + idOffset);

                        // ANIMATION HERE
                        //randPoint = sin(_Time.y * 0.2 * randPoint) * 0.5 + 0.5;

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
                        float2 randPoint = hash22(sqrId + idOffset);

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

            struct appdata {
                float4 vertex  : POSITION;
                float3 normal  : NORMAL;
                float2 uv      : TEXCOORD0;
            };

            struct v2f {
                float2 uv     : TEXCOORD0;
                float3 objPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v) {
                v2f o;
                float displacement = _ShellsDistance / _TotalShells * _ShellIndex;
                v.vertex.xyz += v.normal * displacement;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.objPos = v.vertex;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target{
                i.normal = normalize(i.normal);

                // COORDINATES
                cellData sqr = cellCoords(i.uv * _NoiseDensity);

                // BASE COLOR
                float3 col = 0.0;

                // SHELLS
                float shellAttenuation = float(_ShellIndex) / float(_TotalShells);

                float nseRand = hash21(sqr.id);
                float nse3d = noise(i.objPos * _NoiseScale) * 0.5 + 0.5;
                float clipCoef = (nseRand * _RandomCeof) + (nse3d * (1.0 - _RandomCeof)) - shellAttenuation;

                float mask = (length(sqr.uv) > (1.0 - shellAttenuation)) * (_ShellIndex > 0);

                clip(clipCoef - mask * 1.1);

                // COLOR
                float3 shellCol = lerp(_ColBase, _ColMid,  saturate(shellAttenuation * 2.0));
                shellCol        = lerp(shellCol, _ColEdge, saturate(shellAttenuation * 2.0 - 1.0));

                // LIGHTING
                float attenuation = pow(shellAttenuation, _Attenuation);
                float diffuse = max(0.0, dot(i.normal, _WorldSpaceLightPos0)) * 0.5 + 0.5;

                col = shellCol * attenuation * diffuse;

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
