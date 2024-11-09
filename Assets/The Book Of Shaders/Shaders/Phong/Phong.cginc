#if !defined(MY_LIGHTS_INCLUDED)
#define MY_LIGHTS_INCLUDED

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

float4 _ColDif, _ColSpec, _ColAmb;
float _Q;

struct appdata{
    float4 vertex : POSITION;
    float2 uv     : TEXCOORD0;
    float3 normal : NORMAL;
};

struct v2f{
    float4 pos      : SV_POSITION;
    float2 uv       : TEXCOORD0;
    float3 normal   : TEXCOORD1;
    float3 worldPos : TEXCOORD2;
    UNITY_FOG_COORDS(3)
    SHADOW_COORDS(4)
};

float3 BlinnPhong(float3 kd, float3 ks, float3 ka, float q, v2f i){
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
    float3 N = i.normal;
    float3 H = normalize(L + V);
    float3 Li = _LightColor0;
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);

    float3 col = (kd * max(0.0, dot(N, L) + 0.1) + ks * pow(max(0.0, dot(N, H)), q)) * attenuation * _LightColor0.rgb;

    #ifdef FORWARD_BASE_PASS
        col += ka;
    #endif

    return col;
}

v2f vert (appdata v){
    v2f o;
    o.uv = v.uv;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    o.normal = UnityObjectToWorldNormal(v.normal);

    UNITY_TRANSFER_FOG(o, o.pos);
    TRANSFER_SHADOW(o);
    return o;
}

float4 frag (v2f i) : SV_Target{
    i.normal = normalize(i.normal);

    float3 col = float3(0.0, 0.0, 0.0);

    col += BlinnPhong(_ColDif, _ColSpec, _ColAmb, _Q, i);

    UNITY_APPLY_FOG(i.fogCoord, col);

    return float4(pow(col, 2.2), 1.0);
}

#endif