// WORKING WITH THESE STRUCTS

//struct material{
//    float3 kd;
//    float3 ks;
//    float q;  // for Blinn-Phong specular
//};
//
//struct hitInfo{
//    float d;
//    material mat;
//};

// DISTANCE FUNCTIONS //

float sdPlane(float3 p, float3 n){
    return dot(p, n);
}

float sdSphere(float3 p, float s){
	return length(p) - s;
}

float sdBox(float3 p, float3 b){
	float3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) +
		length(max(d, 0.0));
}

float sdRoundBox(float3 p, float3 b, float r){
    float3 q = abs(p) - b;
    return min(max(q.x, max(q.y, q.z)), 0.0) + length(max(q, 0.0)) - r;
}

float sdTorus(float3 p, float R, float r){
    float x = length(p.xz) - R;
    float y = p.y;
    float d = length(float2(x, y)) - r;
    return d;
}

float sdCapsule(float3 p, float3 a, float3 b, float3 r){
    float3 ap = p - a;
    float3 ab = b - a;

    float t = dot(ap, ab) / dot(ab, ab);
    t = saturate(t);

    float3 c = a + t * (b - a);
    float d = length(p - c) - r;

    return d;
}

#define POWER 8.0
float sdFractal(float3 pos){
    float3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    for(int i = 0; i < 16; i++){
        r = length(z);
        if(r > 1.5) break;

        // convert to polar coordinates
        float theta = acos(z.z / r);
        float phi = atan(float2(z.y, z.x));

        dr = pow(r, POWER - 1.0) * POWER * dr + 1.0;

        // scale and rotate the point
        float zr = pow(r, POWER);
        theta = theta * POWER;
        phi = phi * POWER;

        // convert back to cartesian coordinates
        z = pos + zr * float3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
    }
    return 0.5 * log(r) * r / dr;
}


// BOOLEAN OPERATORS //
material BlendMaterials(material mat1, material mat2, float h){
    material mat;
    mat.kd = lerp(mat1.kd, mat2.kd, h);
    mat.ks = lerp(mat1.ks, mat2.ks, h);
    mat.q  = lerp(mat1.q,  mat2.q,  h);
    return mat;
}

// Union
hitInfo opU(hitInfo d1, hitInfo d2){
	float d = min(d1.d, d2.d);
    bool first = (d == d1.d);

    hitInfo res;
    res.d = d;
    if(first){
        res.mat = d1.mat;
    }else{
        res.mat = d2.mat;
    }
    return res; 
}

// Subtraction (what from where)
hitInfo opS(hitInfo d1, hitInfo d2){
    float d = max(-d1.d, d2.d);
    bool first = (d == d1.d);

    hitInfo res;
    res.d = d;
    res.mat = d2.mat;
    return res;
}

// Intersection
hitInfo opI(hitInfo d1, hitInfo d2){
    float d = max(d1.d, d2.d);
    bool first = (d == d1.d);

    hitInfo res;
    res.d = d;
    if(first){
        res.mat = d1.mat;
    }else{
        res.mat = d2.mat;
    }
    
    return res;
}

// Lerping (between 2 shapes)
hitInfo opL(hitInfo d1, hitInfo d2, float t){
    hitInfo res;
    res.d = lerp(d1.d, d2.d, t);
    res.mat = BlendMaterials(d2.mat, d1.mat, t);

    return res;
}

// Smooth union
hitInfo opUS(hitInfo d1, hitInfo d2, float k){
    float h = saturate(0.5 + 0.5 * (d2.d - d1.d) / k);

    hitInfo res;
    res.d = lerp(d2.d, d1.d, h) - k * h * (1.0 - h);
    res.mat = BlendMaterials(d2.mat, d1.mat, h);

    return res;
}

// Smooth subtraction
hitInfo opSS(hitInfo d1, hitInfo d2, float k){
    float h = saturate(0.5 - 0.5 * (d2.d + d1.d) / k);

    hitInfo res;
    res.d = lerp(d2.d, -d1.d, h) + k * h * (1.0 - h);
    res.mat = BlendMaterials(d2.mat, d1.mat, h);

    return res;
}

// Smooth intersection
hitInfo opIS(hitInfo d1, hitInfo d2, float k){
    float h = saturate(0.5 - 0.5 * (d2.d - d1.d) / k);

    hitInfo res;
    res.d = lerp(d2.d, d1.d, h) + k * h * (1.0 - h);
    res.mat = BlendMaterials(d2.mat, d1.mat, h);

    return res;
}


// SPACE OPERATIONS //

float2x2 Rot(float a){
    float s = sin(a);
    float c = cos(a);
    return float2x2(c, -s, s, c);
}

// Mirroring X
void MirrorX(inout float3 p){
    p.x = abs(p.x);
}

// Mirroring Y
void MirrorY(inout float3 p){
    p.y = abs(p.y);
}

// Mirroring Z
void MirrorZ(inout float3 p){
    p.z = abs(p.z);
}

// Rotate around X
void RotX(inout float3 p, float phi){
    p.yz = mul(Rot(phi), p.yz);
}

// Rotate around Y
void RotY(inout float3 p, float phi){
    p.xz = mul(Rot(phi), p.xz);
}

// Rotate around Z
void RotZ(inout float3 p, float phi){
    p.xy = mul(Rot(phi), p.xy);
}


// DISTANCE OPERATIONS //

// Shell
void Shell(inout float d, float shellSize){
    d = abs(d) - shellSize;
}

// Cutting with plane
// p: point on plane
// n: plane normal
void CutWithPlane(inout float d, float3 p, float3 n){
    float cutPlaneD = dot(p, normalize(n));  // Creating plane
    d = max(cutPlaneD, d);  // Cutting with plane
}

// Mod Position Axis
float pMod1 (inout float p, float size){
	float halfsize = size * 0.5;
	float c = floor((p+halfsize)/size);
	p = fmod(p+halfsize,size)-halfsize;
	p = fmod(-p+halfsize,size)-halfsize;
	return c;
}