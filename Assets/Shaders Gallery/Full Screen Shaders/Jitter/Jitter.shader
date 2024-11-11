Shader "Hidden/CustomScreenShader" {

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

            float2 rotate(float2 uv, float th){
                return mul(float2x2(cos(th), sin(th), -sin(th), cos(th)), uv);
            }

            // By IQ
            float2 hash(float2 p) // replace this by something better
            {
                p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
                p = -1.0 + 2.0 * frac(sin(p) * 43758.5453123);

                // ROTATION PART
                p = rotate(p, _Time.y * 5.0);

                return p;
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

                float3 col = 0.0;
                float3 texCol = tex2D(_MainTex, i.uv + hash(i.uv) * 0.005);

                col += texCol;

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
