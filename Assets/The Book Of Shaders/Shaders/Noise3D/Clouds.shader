Shader "Custom/Clouds" {

    Properties {
        _Col ("Color", Color) = (0.5, 0.5, 0.5, 1.0)
    }

    SubShader {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent"}

        Pass {

            Cull Off
            ZWrite Off
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _Col;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 objPos : TEXCOORD1;
            };

            // By IQ
            float3 hash(float3 p) // replace this by something better
            {
                p = float3(dot(p, float3(127.1, 311.7, 74.7)),
                           dot(p, float3(269.5, 183.3, 246.1)),
                           dot(p, float3(113.5, 271.9, 124.6)));
                p = -1.0 + 2.0 * frac(sin(p) * 43758.5453123);

                // ROTATION PART
                float t = _Time.y * 1.0;
                float2x2 m = float2x2(cos(t), -sin(t), sin(t), cos(t));
                p.xz = mul(m, p.xz);

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

            #define OCTAVES 9
            float fbm(float3 uv){

                float value = 0.0;
                float amplitude = 0.5;

                for(int i = 0; i < OCTAVES; i++){
                    value += amplitude * noise(uv);
                    uv *= 2.0;
                    amplitude *= 0.5;
                }
                return value;
            }

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.objPos = v.vertex;
                return o;
            }

            float4 frag (v2f i) : SV_Target{

                // p      = i.uv
                // result = fbm(p + fbm(p))
                // q      = fbm(p)---this

                // COORDS
                float3 p = i.objPos * float3(1.0, 6.0, 1.0);
                float t = _Time.y * 2.0;
                float2x2 m = float2x2(cos(t), -sin(t), sin(t), cos(t));
                p.xz = mul(m, p.xz);


                // BASE COLOR
                float3 col = 0.0;

                // NOISE
                // because fbm is 1 dimension, we need to displace p in two dimensions separately
                float nse = saturate(fbm(p) - 0.1);

                // COLOR
                col = nse * _Col;

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
