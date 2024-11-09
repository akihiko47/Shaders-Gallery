#if !defined(MY_LIGHTS_INCLUDED)
#define MY_LIGHTS_INCLUDED

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

float4 _ColDif1, _ColDif2, _ColSpec, _ColAmb;
float _Q, _NormalsCoef;

struct appdata{
    float4 vertex : POSITION;
    float2 uv     : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
};

struct v2f{
    float4 pos      : SV_POSITION;
    float2 uv       : TEXCOORD0;
    float3 normal   : TEXCOORD1;
    float4 tangent  : TEXCOORD3;
    float3 worldPos : TEXCOORD4;
    float3 objPos   : TEXCOORD5;
    UNITY_FOG_COORDS(6)
    SHADOW_COORDS(7)
};

// By IQ
float3 hash(float3 p) {
    p = float3(dot(p, float3(127.1, 311.7, 74.7)),
               dot(p, float3(269.5, 183.3, 246.1)),
               dot(p, float3(113.5, 271.9, 124.6)));
    p = -1.0 + 2.0 * frac(sin(p) * 43758.5453123);

    // ROTATION PART
    float t = _Time.y * 2.0;
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

// return value noise (in x) and its derivatives (in yzw)
float4 noised(float3 x){
    // grid
    float3 i = floor(x);
    float3 f = frac(x);

    // quintic interpolant
    float3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    float3 du = 30.0 * f * f * (f * (f - 2.0) + 1.0);

    float3 ga = hash(i + float3(0.0, 0.0, 0.0));
    float3 gb = hash(i + float3(1.0, 0.0, 0.0));
    float3 gc = hash(i + float3(0.0, 1.0, 0.0));
    float3 gd = hash(i + float3(1.0, 1.0, 0.0));
    float3 ge = hash(i + float3(0.0, 0.0, 1.0));
    float3 gf = hash(i + float3(1.0, 0.0, 1.0));
    float3 gg = hash(i + float3(0.0, 1.0, 1.0));
    float3 gh = hash(i + float3(1.0, 1.0, 1.0));

    // projections
    float va = dot(ga, f - float3(0.0, 0.0, 0.0));
    float vb = dot(gb, f - float3(1.0, 0.0, 0.0));
    float vc = dot(gc, f - float3(0.0, 1.0, 0.0));
    float vd = dot(gd, f - float3(1.0, 1.0, 0.0));
    float ve = dot(ge, f - float3(0.0, 0.0, 1.0));
    float vf = dot(gf, f - float3(1.0, 0.0, 1.0));
    float vg = dot(gg, f - float3(0.0, 1.0, 1.0));
    float vh = dot(gh, f - float3(1.0, 1.0, 1.0));

    // interpolations
    return float4(va + u.x * (vb - va) + u.y * (vc - va) + u.z * (ve - va) + u.x * u.y * (va - vb - vc + vd) + u.y * u.z * (va - vc - ve + vg) + u.z * u.x * (va - vb - ve + vf) + (-va + vb + vc - vd + ve - vf - vg + vh) * u.x * u.y * u.z,    // value
                 ga + u.x * (gb - ga) + u.y * (gc - ga) + u.z * (ge - ga) + u.x * u.y * (ga - gb - gc + gd) + u.y * u.z * (ga - gc - ge + gg) + u.z * u.x * (ga - gb - ge + gf) + (-ga + gb + gc - gd + ge - gf - gg + gh) * u.x * u.y * u.z +   // derivatives
                 du * (float3(vb, vc, ve) - va + u.yzx * float3(va - vb - vc + vd, va - vc - ve + vg, va - vb - ve + vf) + u.zxy * float3(va - vb - ve + vf, va - vb - vc + vd, va - vc - ve + vg) + u.yzx * u.zxy * (-va + vb + vc - vd + ve - vf - vg + vh)));
}

#define OCTAVES 6
float4 fbm(float3 uv){

    float value = 0.0;
    float amplitude = 0.5;
    float3 normal = float3(0.0, 0.0, 0.0);

    for(int i = 0; i < OCTAVES; i++){
        float4 nsed = noised(uv);
        value += amplitude * abs(nsed.x);
        normal += normalize(float3(nsed.y, _NormalsCoef, nsed.z)) * amplitude;
        uv *= 2.0;
        amplitude *= 0.5;
    }
    return float4(value, normal);
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
    o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
    o.objPos = v.vertex;

    UNITY_TRANSFER_FOG(o, o.pos);
    TRANSFER_SHADOW(o);
    return o;
}

float4 frag (v2f i) : SV_Target{
    // COORDINATES
    float3 p = i.objPos * 5.0;

    // NORMALS
    float4 nsed = fbm(p);

    float3 tangentSpaceNormal = normalize(float3(nsed.y, nsed.z, nsed.w));
    
    float3 binormal = cross(i.normal, i.tangent.xyz) * (i.tangent.w * unity_WorldTransformParams.w);

    i.normal = normalize(
        tangentSpaceNormal.x * i.tangent +
        tangentSpaceNormal.y * i.normal +
        tangentSpaceNormal.z * binormal
    );
    

    //return float4(i.normal, 1.0);

    // VALUES
    float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
    float3 N = i.normal;
    
    // START COLOR
    float3 col = float3(0.0, 0.0, 0.0);

    // NOISE
    float nse = nsed.x;

    // COLOR
    float3 kd = lerp(_ColDif1, _ColDif2, nse);
    float3 ks = _ColSpec;
    
    // BRDF
    col += BlinnPhong(kd, ks, _ColAmb, _Q, i);

    // FOG
    UNITY_APPLY_FOG(i.fogCoord, col);

    return float4(col, 1.0);
}

#endif