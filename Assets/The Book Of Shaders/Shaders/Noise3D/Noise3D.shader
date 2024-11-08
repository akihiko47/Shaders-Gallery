Shader "Custom/Noise3D" {

    Properties {
        _ColDif1 ("Diffuse Color 1", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColDif2 ("Diffuse Color 2", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColDif3 ("Diffuse Color 3", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColFres1 ("Fresnel Color 1", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColFres2 ("Fresnel Color 2", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColSpec ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColAmb ("Ambient Color", Color) = (0.0, 0.0, 0.0, 1.0)
        _Q ("Specular exponent", float) = 10.0
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {

            Tags {
                "LightMode" = "ForwardBase"
            }
            Blend One Zero

            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fog
            #pragma multi_compile _ SHADOWS_SCREEN
            #define FORWARD_BASE_PASS

            #include "Noise3D.cginc"

            ENDCG
        }

        Pass {
            Tags {
                "LightMode" = "ForwardAdd"
            }
            Blend One One

            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fog
            #pragma multi_compile_fwdadd_fullshadows //#pragma multi_compile DIRECTIONAL DIRECTIONAL_COOKIE POINT POINT_COOKIE SPOT + Multiple shadows

            #include "Noise3D.cginc"

            ENDCG
        }

        Pass {
            Tags {
                "LightMode" = "ShadowCaster"
            }

            CGPROGRAM

            #pragma multi_compile_shadowcaster

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "MyShadows.cginc"

            ENDCG
        }
    }
}
