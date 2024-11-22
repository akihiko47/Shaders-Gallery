Shader "RayMarching/RayMarcherBase" {

    Properties {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader {

        Cull Off ZWrite Off ZTest Always

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #define MAX_STEPS 100
            #define MAX_DIST 100.0
            #define SURF_DIST 0.01

            #include "UnityCG.cginc"
            #include "DistanceFunctions.cginc"

            sampler2D _MainTex;
            uniform float3 _CameraWorldPos;
            uniform float4x4 _FrustumCornersMatrix;
            uniform float4x4 _CameraToWorldMatrix;

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

            float GetDist(float3 pnt) {
                float dS = sdSphere(pnt - float3(0.0, 1.0, 0.0), 0.5);
                Shell(dS, 0.05);
                CutWithPlane(dS, pnt - float3(0.0, 1.0, 0.0), normalize(float3(1.0, 1.0, 0.0)));
                // more operations in "DistanceFunctions.cginc"

                float d = dS;
                return d;
            }

            float3 GetNormal(float3 pnt) {
                float d = GetDist(pnt);
                float2 e = float2(0.001, 0.0);

                float3 n = d - float3(GetDist(pnt - e.xyy),
                                      GetDist(pnt - e.yxy),
                                      GetDist(pnt - e.yyx));

                return normalize(n);
            }

            v2f vert (appdata v) {
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

            float4 frag(v2f i) : SV_Target{

                // DEPTH TEXTURE
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uvOriginal).r);
                depth *= length(i.ray);  // convert depth to distance

                // MARCHING
                float3 rayOrigin = _CameraWorldPos;
                float3 rayDir = normalize(i.ray);   

                float OriginDistance = 0.0;

                for (int n = 0; n < MAX_STEPS; n++) {
                    float3 pnt = rayOrigin + rayDir * OriginDistance;
                    float deltaDistance = GetDist(pnt);
                    OriginDistance += deltaDistance;
                    if (OriginDistance < SURF_DIST || OriginDistance > MAX_DIST || deltaDistance >= depth) break;
                };
                float dist = OriginDistance;

                float4 color = float4(0.0, 0.0, 0.0, 1.0);
                color.w = (dist >= SURF_DIST) && (dist <= MAX_DIST) && (dist <= depth);

                float3 pnt = rayOrigin + rayDir * dist;

                // LIGHT
                float3 albedo = float3(0.7, 0.0, 0.0);
                float3 ambient = float3(0.0, 0.0, 0.02);

                float3 lightColor = float3(1, 0.8, 0.5) * 0.5;
                float3 dirLightDir = normalize(float3(1, 1, 1));
                float3 lightPos = float3(0.0, 5.0, 6.0);

                lightPos.xz = float2(sin(_Time.y), cos(_Time.y));

                //float3 L = normalize(lightPos - pnt);  // point light
                float3 L = dirLightDir;                  // directional light
                float3 N = GetNormal(pnt);
                float3 V = normalize(_CameraWorldPos - pnt);
                float3 H = normalize(L + V);

                //float3 lightVec = lightPos - pnt;
                //float attenuation = 1 / (1 + dot(lightVec, lightVec));
                //lightColor *= attenuation;

                float3 diffuse = saturate(dot(L, N));
                diffuse *= lightColor;
                float3 specular = pow(saturate(dot(N, H)), 70.0) * (diffuse > 0);
                specular *= lightColor;

                color.rgb = albedo * diffuse + specular;


                // SHADOWS
                //float lightDistance = length(lightPos - pnt);
                //float rayToLightLength = RayMarch(pnt + N * SURF_DIST * 8.0, L);
                //color.rgb *= !(rayToLightLength < lightDistance);

                // AMBIENT
                //color.rgb += ambient;

                // FOG
                /*float3 fogColor = float3(1.0, 1.0, 1.0);
                float density = 0.03;
                float fog = pow(2, -pow((dist * density), 2));
                color.rgb = lerp(fogColor, color, fog);*/

                // BLENDING
                //return float4(color);
                float4 originalColor = tex2D(_MainTex, i.uvOriginal);
                return float4(originalColor * (1.0 - color.w) + color.xyz * color.w, 1.0);
            }

            ENDCG
        }
    }
}
