Shader "RayMarching/RayMarcherVolume" {

    Properties {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader {

        Tags { "RenderType" = "Overlay" "Queue" = "Overlay"}

        Cull Off ZWrite Off ZTest Always

        Pass {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ RM_SOFT_SHADOWS_ON 
            #pragma multi_compile __ RM_BLEND_ON_SCENE 
            #pragma multi_compile __ RM_POINT_LIGHT_ON
            #pragma multi_compile __ RM_AMB_MAP_ON

            #include "UnityCG.cginc"

            // rendered scene texture
            sampler2D _MainTex;

            // camera values
            uniform float3 _CameraWorldPos;
            uniform float4x4 _FrustumCornersMatrix;
            uniform float4x4 _CameraToWorldMatrix;

            // other values
            uniform float       _MaxDist;
            uniform int         _MaxSteps;
            uniform float       _SurfDist;
            uniform float3      _DirLightDir;
            uniform float4      _DirLightCol;
            uniform float       _DirLightInt;
            uniform float3      _PntLightPos;
            uniform float4      _PntLightCol;
            uniform float       _PntLightInt;
            uniform float       _ShadowsIntensity;
            uniform float       _ShadowsSoftness;
            uniform float2      _ShadowsDistance;
            uniform float       _AoStep;
            uniform float       _AoInt;
            uniform int         _AoIterations;
            uniform float4      _AmbCol;
            uniform samplerCUBE _ReflMap;
            uniform float       _ReflMaxDist;
            uniform int         _MaxRefl;

            // volumetric rendering
            uniform float3 _BoundsMin;
            uniform float3 _BoundsMax;
            uniform int    _IntegrationSteps;
            uniform int    _LightIntegrationSteps;
            uniform float  _VolAbsorption;
            uniform sampler2D _MainVolTex;

            // depth texture
            uniform sampler2D _CameraDepthTexture;


            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uvOriginal :TEXCOORD01;
                float3 ray: TEXCOORD2;
            };

            struct material {
                float3 kd;
                float3 ks;
                float  q;           // for Blinn-Phong specular
                float  reflInt;     // for true reflections
                float  ambReflInt;  // for cubemap reflections
            };

            struct hitInfo {
                float d;
                float3 pnt;
                material mat;
            };

            #include "../Base/DistanceFunctions.cginc"

            material DefaultMaterial(){
                material res;
                res.kd         = 1.0;
                res.ks         = 1.0;
                res.q          = 100.0;
                res.reflInt    = 0.0;
                res.ambReflInt = 0.0;
                return res;
            }

            // from Sebastian Lague video
            float2 RayBoxDist(float3 boundsMin, float3 boundsMax, float3 ro, float3 rd){
                float3 t0 = (boundsMin - ro) / rd;
                float3 t1 = (boundsMax - ro) / rd;
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);

                float dstA = max(max(tmin.x, tmin.y), tmin.z);
                float dstB = min(min(tmax.x, tmax.y), tmax.z);

                float dstToBox = max(0.0, dstA);
                float dstInsideBox = max(0.0, dstB - dstToBox);
                return float2(dstToBox, dstInsideBox);
            }
            
            hitInfo GetDist(float3 p) { 
                hitInfo dB;
                dB.d = sdRoundBox(p - float3(5.0, 1.2, 0.0), float3(1.0, 1.0, 1.0), 0.2);
                dB.mat = DefaultMaterial();
                dB.mat.kd = float3(1.0, 0.0, 0.0);
                dB.mat.q  = 10.0;

                hitInfo res; 
                res = dB;
                return res;
            }

            float HardShadows(float3 ro, float3 rd, float mint, float maxt){
                float t = mint;
                while(t < maxt){
                    float h = GetDist(ro + rd * t).d;
                    t += h;
                    if(h < _SurfDist) return 0.0;
                }
                return 1.0;
            }

            float SoftShadows(float3 ro, float3 rd, float mint, float maxt, float k){
                float result = 1.0;

                float t = mint;
                while(t < maxt){
                    float h = GetDist(ro + rd * t).d; 
                    t += h;
                    result = min(result, k * h / t);
                    if(h < _SurfDist) return 0.0;
                }
                return result;
            }

            float AmbientOcclusion(float3 p, float3 n){
                float step = _AoStep;
                float ao = 0.0;
                float dist;
                for(int i = 1; i < _AoIterations; i++){
                    dist = step * i;
                    ao += max(0.0, (dist - GetDist(p + n * dist).d) / dist);
                }
                return 1.0 - ao * _AoInt;
            }

            float3 GetNormal(float3 pnt){
                float d = GetDist(pnt).d;
                float2 e = float2(0.001, 0.0);

                float3 n = d - float3(GetDist(pnt - e.xyy).d,
                                      GetDist(pnt - e.yxy).d,
                                      GetDist(pnt - e.yyx).d);

                return normalize(n);
            }

            v2f vert (appdata v){
                v2f o;

                half index = v.vertex.z;
                v.vertex.z = 0.1;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uvOriginal = v.uv;  // screen space uvs
                o.uv = v.uv.xy * 2 - 1;

                o.ray = _FrustumCornersMatrix[(int)index].xyz;
                o.ray = mul(_CameraToWorldMatrix, o.ray);
                return o;
            }

            bool RayMarch(float3 ro, float3 rd, float from, float to, float depth, inout hitInfo hit){
                float OriginDistance = from;

                for(int n = 0; n < _MaxSteps; n++){
                    float3 p = ro + rd * OriginDistance;
                    hit = GetDist(p);
                    OriginDistance += hit.d;
                    if(hit.d < _SurfDist){
                        hit.pnt = p;
                        return true;
                    }
                    if(OriginDistance > to){
                        return false;
                    }
                    #ifdef RM_BLEND_ON_SCENE
                        if(OriginDistance >= depth){
                            return false;
                        }
                    #endif
                };
                return false;
            }

            // By IQ
            float3 hash(float3 p) // replace this by something better
            {
                p = float3(dot(p, float3(127.1, 311.7, 74.7)),
                           dot(p, float3(269.5, 183.3, 246.1)),
                           dot(p, float3(113.5, 271.9, 124.6)));
                p = -1.0 + 2.0 * frac(sin(p) * 43758.5453123);

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

                return lerp(lerp(lerp(dot(hash(i + float3(0.0, 0.0, 0.0)), f - float3(0.0, 0.0, 0.0)),
                            dot(hash(i + float3(1.0, 0.0, 0.0)), f - float3(1.0, 0.0, 0.0)), u.x),
                            lerp(dot(hash(i + float3(0.0, 1.0, 0.0)), f - float3(0.0, 1.0, 0.0)),
                            dot(hash(i + float3(1.0, 1.0, 0.0)), f - float3(1.0, 1.0, 0.0)), u.x), u.y),
                            lerp(lerp(dot(hash(i + float3(0.0, 0.0, 1.0)), f - float3(0.0, 0.0, 1.0)),
                            dot(hash(i + float3(1.0, 0.0, 1.0)), f - float3(1.0, 0.0, 1.0)), u.x),
                            lerp(dot(hash(i + float3(0.0, 1.0, 1.0)), f - float3(0.0, 1.0, 1.0)),
                            dot(hash(i + float3(1.0, 1.0, 1.0)), f - float3(1.0, 1.0, 1.0)), u.x), u.y), u.z);
            }

            #define OCTAVES 2
            float fbm(float3 uv){

                float value = 0.0;
                float amplitude = 0.5;

                for(int i = 0; i < OCTAVES; i++){
                    value += amplitude * (noise(uv) * 0.5 + 0.5);
                    uv *= 2.0;
                    amplitude *= 0.5;
                }
                return value;
            }


            float SampleDensity(float3 pnt){
                float nse = noise(pnt) * 0.5 + 0.5;
                return nse;
            }

            float3 Shading(hitInfo hit, float3 N){
                float3 color = 0.0;

                // LIGHT
                float3 V = normalize(_CameraWorldPos - hit.pnt);

                #ifdef RM_POINT_LIGHT_ON
                    float3 L = normalize(_PntLightPos - hit.pnt);
                    float3 lightColor = _PntLightCol * _PntLightInt;
                    float3 lightVec = _PntLightPos - hit.pnt;
                    float attenuation = 1 / dot(lightVec, lightVec);
                    lightColor = saturate(lightColor * attenuation);
                #else
                    float3 L = _DirLightDir;
                    float3 lightColor = saturate(_DirLightCol * _DirLightInt);
                #endif
                float3 H = normalize(L + V);

                // Blinn-Phong BRDF

                float  q = hit.mat.q;
                float3 kd = hit.mat.kd;
                float3 ks = hit.mat.ks;
                #ifdef RM_AMB_MAP_ON
                    float3 ka = max(0, ShadeSH9(float4(N, 1.0)));
                #else
                    float3 ka = _AmbCol.rgb;
                #endif 

                color.rgb = (kd * max(0.0, dot(N, L) * 0.5 + 0.5) + ks * pow(max(0.0, dot(N, H)), q)) * lightColor + ka;

                // SHADOWS
                float shadows;
                #ifdef RM_SOFT_SHADOWS_ON
                    shadows = SoftShadows(hit.pnt, L, _ShadowsDistance.x, _ShadowsDistance.y, _ShadowsSoftness) * 0.5 + 0.5;
                #else
                    shadows = HardShadows(hit.pnt, L, _ShadowsDistance.x, _ShadowsDistance.y) * 0.5 + 0.5;
                #endif
                shadows = max(0.0, pow(shadows, _ShadowsIntensity));
                color.rgb *= shadows;

                // FOG
                /*float3 fogColor = float3(1.0, 1.0, 1.0);
                float density = 0.03;
                float fog = pow(2, -pow((dist * density), 2));
                color.rgb = lerp(fogColor, color, fog);*/

                // AMBIENT OCCLUSION
                color.rgb *= AmbientOcclusion(hit.pnt, N);

                return color;
            }

            float4 frag(v2f i) : SV_Target{

                // DEPTH TEXTURE
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uvOriginal).r);
                depth *= length(i.ray);  // convert depth to distance

                // RAY MARCHING
                float3 ro = _CameraWorldPos;
                float3 rd = normalize(i.ray);

                // STAERT COLOR
                float4 color = float4(0.0, 0.0, 0.0, 0.0);
                
                // BOUNDING BOX
                float2 rayBoxInfo = RayBoxDist(_BoundsMin, _BoundsMax, ro, rd);
                float dstToBox = rayBoxInfo.x;
                float dstInBox = rayBoxInfo.y;
                bool rayInBox = dstInBox > 0 && dstToBox < depth;

                if(rayInBox){
                    float dt = dstInBox / _IntegrationSteps;
                    float dist = 0.0;
                    float maxDist = min(depth - dstToBox, dstInBox);

                    float trans = 1.0;
                    float totalDensity = 0.0;
                    float lightEnergy = 0.0;
                    float3 lightColor = 0.0;

                    while (dist < maxDist){
                        float3 pnt = ro + rd * (dstToBox + dist);
                        float pntDensity = SampleDensity(pnt) * dt * _VolAbsorption;
                        totalDensity += pntDensity;
                        trans *= exp(-pntDensity);

                        //float3 L = normalize(_PntLightPos - pnt);
                        float3 L = _DirLightDir;
                        float maxDistL = RayBoxDist(_BoundsMin, _BoundsMax, pnt, L).y;
                        float dtL = maxDistL / _LightIntegrationSteps;
                        float distL = 0.0;
                        float totalDensityL = 0.0;
                        while(distL < maxDistL){ 
                            float3 pntL = pnt + L * distL;
                            float pntDensityL = SampleDensity(pntL);
                            totalDensityL += pntDensityL * dtL * _VolAbsorption;
                            distL += dtL;
                        }
                        float transL = exp(-totalDensityL);
                        lightEnergy += transL * pntDensity * dt * trans;
                        
                        dist += dt;
                    }
                    color.w = (1.0 - saturate(trans));
                    color.rgb = lightEnergy;
                    
                    /*hitInfo hit;
                    if(RayMarch(ro, rd, dstToBox, dstToBox + dstInBox, depth, hit)){
                        color.w = 1.0;
                        float3 N = GetNormal(hit.pnt);
                        color.rgb += Shading(hit, N);
                    }*/
                }

                // BLENDING
                #ifdef RM_BLEND_ON_SCENE
                    float4 originalColor = tex2D(_MainTex, i.uvOriginal);
                    return float4(originalColor * (1.0 - color.w) + color.xyz * color.w, 1.0);
                #else
                    return float4(color.rgb * color.w, 1.0);
                #endif
            }

            ENDCG
        }
    }
}
