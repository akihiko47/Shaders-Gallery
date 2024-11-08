#if !defined(MY_LIGHTS_INCLUDED)
#define MY_LIGHTS_INCLUDED

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

float4 _ColDif1, _ColDif2, _ColDif3, _ColFres1, _ColFres2, _ColSpec, _ColAmb;
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
    float3 objPos   : TEXCOORD3;
    UNITY_FOG_COORDS(4)
    SHADOW_COORDS(5)
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

#define OCTAVES 6
float fbm(float3 uv){

    float value = 0.0;
    float amplitude = 0.5;

    for(int i = 0; i < OCTAVES; i++){
        value += amplitude * abs((noise(uv)));
        uv *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

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

    float3 col = (kd * max(0.0, dot(N, L)) + ks * pow(max(0.0, dot(N, H)), q)) * attenuation;

    #ifdef FORWARD_BASE_PASS
        col += ka;
    #endif

    return col * _LightColor0.rgb;
}

v2f vert (appdata v){
    v2f o;
    o.uv = v.uv;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    o.normal = UnityObjectToWorldNormal(v.normal);
    o.objPos = v.vertex;

    UNITY_TRANSFER_FOG(o, o.pos);
    TRANSFER_SHADOW(o);
    return o;
}

float4 frag (v2f i) : SV_Target{
    i.normal = normalize(i.normal);

    // VALUES
    float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
    float3 N = i.normal;

    // COORDINATES
    float3 p = i.objPos * 2.0 + float3(_Time.y * 0.3, 0.0, _Time.y * 0.3);

    // START COLOR
    float3 col = float3(0.0, 0.0, 0.0);

    // FRESNEL
    float fresnel = saturate(pow(1.0 - saturate(dot(V, N)), 2.0) + (fbm(p + _Time.y * 0.5) * 0.3));
    float edge = smoothstep(0.2, 0.75, fresnel);
    col += edge * lerp(_ColFres1, _ColFres2, edge);

    // NOISE
    float3 q;
    q.x = fbm(p + float3(6.9, 0.0, 1.1));
    q.y = fbm(p + float3(5.2, 1.3, 9.9));
    q.z = fbm(p + float3(2.2, 7.7, 3.3));

    float nse = fbm(p + q);

    // COLOR
    float3 flow;
    flow = lerp(_ColDif1, _ColDif2, saturate(nse));
    flow = lerp(flow, _ColDif3, saturate(pow(length(q), 2.0)));

    float3 kd = _ColDif1 + flow;
    float3 ks = _ColSpec * flow;
    
    // BRDF
    col += BlinnPhong(kd, ks, _ColAmb, _Q, i);

    // FOG
    UNITY_APPLY_FOG(i.fogCoord, col);

    return float4(col, 1.0);
}

#endif