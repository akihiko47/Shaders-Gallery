#if !defined(MY_LIGHTS_INCLUDED)
#define MY_LIGHTS_INCLUDED

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

float4 _ColDif, _ColSpec, _ColAmb, _ColFres1, _ColFres2;
float _Q;

uniform sampler2D _RenderTexture;

// grab pass
uniform sampler2D _BGTex;
uniform float4 _BGTex_TexelSize;

struct appdata{
    float4 vertex : POSITION;
    float2 uv     : TEXCOORD0;
    float3 normal : NORMAL;
};

struct v2f{
    float4 pos       : SV_POSITION;
    float2 uv        : TEXCOORD0;
    float3 normal    : TEXCOORD1;
    float3 worldPos  : TEXCOORD2;
    float4 screenPos : TEXCOORD3;
    UNITY_FOG_COORDS(4)
    SHADOW_COORDS(5)
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

float2 random2 (float2 st){
    return float2(frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43756.657),
                  frac(sin(dot(st.xy, float2(31.6197, 42.442))) * 73185.853));
}

#define ITERATIONS 30
float3 NoiseBlur(sampler2D tex, float2 uv, float strength){
    float3 res = 0.0;
    for(int i = 0; i < ITERATIONS; i++){
        float2 offset = random2(float2(i + uv.x, i + uv.y)) * strength;
        res += tex2D(tex, uv + (offset - strength * 0.5));
    }
    return res / float(ITERATIONS);
}

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

v2f vert (appdata v){
    v2f o;
    o.uv = v.uv;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.screenPos = ComputeScreenPos(o.pos);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    o.normal = UnityObjectToWorldNormal(v.normal);

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
    float2 UVscreen = i.screenPos.xy / i.screenPos.w;
    UVscreen += noise(i.worldPos * 5.0 + _Time.y) * 0.1;
    float3 p = i.worldPos * 2.0 + float3(_Time.y * 0.3, 0.0, _Time.y * 0.3);

    // START COLOR
    float3 col = float3(0.0, 0.0, 0.0);

    // FRESNEL
    float fresnel = saturate(pow(1.0 - saturate(dot(V, N)), 2.0) + (noise(p + _Time.y * 0.5) * 0.3));
    float edge = smoothstep(0.2, 0.75, fresnel);
    col += edge * lerp(_ColFres1, _ColFres2, edge);

    // BLUR
    float3 ka = 0.0;
    #ifdef FORWARD_BASE_PASS
        ka = NoiseBlur(_BGTex, UVscreen, 0.1) + _ColAmb;
    #endif

    // BRDF
    col += BlinnPhong(_ColDif, _ColSpec, ka, _Q, i);


    // INDDIRECT LIGHT
    float3 indirectSpec = 0.0;
    float3 indirectDif = 0.0;
    #if defined(FORWARD_BASE_PASS)
        indirectDif += max(0, ShadeSH9(float4(i.normal, 1)));
        float3 reflectionDir = reflect(-V, i.normal);
        float4 envSample = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectionDir);
        indirectSpec = DecodeHDR(envSample, unity_SpecCube0_HDR);
    #endif
    col += indirectSpec * 0.5;

    // FOG
    UNITY_APPLY_FOG(i.fogCoord, col);

    return float4(col, 1.0);
}

#endif