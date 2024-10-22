Shader "Custom/SquareGrid" {

    Properties {
        _TexImage ("Texture", 2D) = "white" {}
        _Color1 ("Color 1", Color) = (0.5, 0.5, 0.5, 1.0)
        _Color2 ("Color 2", Color) = (0.5, 0.5, 0.5, 1.0)
        _ColorEdge ("Color Edge", Color) = (0.5, 0.5, 0.5, 1.0)
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

            float4 _Color1, _Color2, _ColorEdge;
            sampler2D _TexImage;

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

            float mod(float x, float y){
                return x - y * floor(x / y);
            }

            float2 rotate(float2 uv, float th){
                return mul(float2x2(cos(th), sin(th), -sin(th), cos(th)), uv);
            }

            float sdCircle(float2 p, float r){
                return length(p) - r;
            }

            float2 rotateOnThes(in float2 uv, in float i){
                if(i > 0.75){
                    uv = rotate(uv, PI * 0.5);
                } else if(i > 0.5){
                    uv = rotate(uv, PI);
                } else if(i > 0.25){
                    uv = rotate(uv, -PI * 0.5);;
                }
                return uv;
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

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target{

                // coordinates;
                float2 uvNorm = i.uv * 2.0 - 1.0;

                float N = 10.0;
                float2 uvs = i.uv * N;

                float hor = (mod(floor(uvs.y), 2.0) == 0.0 ? 1.0 : 0.0);
                float ver = (mod(floor(uvs.x), 2.0) == 0.0 ? 1.0 : 0.0);

                float2 uvMove = float2(
                    i.uv.x + hor * (smoothstep(0.0, 1.0, mod(_Time.y, 8.0))       - smoothstep(2.0, 3.0, mod(_Time.y, 8.0))) * 0.4,
                    i.uv.y + ver * (smoothstep(0.0, 1.0, mod(_Time.y - 4.0, 8.0)) - smoothstep(2.0, 3.0, mod(_Time.y - 4.0, 8.0))) * 0.4
                    );
                squareData sqr = squareCoords(uvMove * N);

                float2 uv2 = (sqr.uv * 0.5 + 0.5) * 0.1 + sqr.id / N;

                // base color
                float3 col = float3(0.0, 0.0, 0.0);

                // edges
                float edge = (saturate(smoothstep(0.9, 0.91, abs(sqr.uv.x)) + smoothstep(0.9, 0.91, abs(sqr.uv.y))));
                col += edge * _ColorEdge;

                // lines
                float2 uvRot = rotateOnThes(sqr.uv, random(sqr.id)) * 0.5 + 0.5;
                float lines = ((step(length(uvRot), 0.6) - step(length(uvRot), 0.4)) + (step(length(uvRot - 1.0), 0.6) - step(length(uvRot -1.0), 0.4))) * (1.0 - edge);
                float4 grad = lerp(_Color1, _Color2, sqr.id.y / N);
                col += lines * grad.rgb;

                // random brightness
                float brightness = pow(random(sqr.id + _Time.y * 0.0000003), 0.5);
                col *= brightness;

                // glow
                float glow = (saturate(0.05 / (abs(sdCircle(uvRot, 0.5))) + saturate(0.05 / abs(sdCircle(1.0 - uvRot, 0.5))))) * (1.0 - edge) * brightness;
                col += glow * grad;

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
