Shader "Custom/Water" {

    Properties{
        _ColWater ("Water Color", Color) = (0.5, 0.5, 0.5, 0.5)
        _ColEdge ("Edge Color", Color) = (0.5, 0.5, 0.5, 0.5)
        _EdgeWidth ("Edge Line Width", Float) = 0.5
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

            float4 _ColWater, _ColEdge;
            float _EdgeWidth;
        
            // depth
            sampler2D _CameraDepthTexture;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
            };

            struct v2f {
                float2 uv        : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                float4 vertex    : SV_POSITION;
            };

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target{
                float2 UVscreen = i.screenPos.xy / i.screenPos.w;

                float4 col = 0.0;

                // DEPTH
                float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, UVscreen));

                // FOAMLINE
                float foam = 1.0 - saturate(_EdgeWidth * (depth - i.screenPos.w));

                col += lerp(_ColWater, _ColEdge, foam);

                return col;
            }

            ENDCG
        }
    }
}
