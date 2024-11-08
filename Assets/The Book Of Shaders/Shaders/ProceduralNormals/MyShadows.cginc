#if !defined(MY_SHADOWS_INCLUDED)


#define MY_SHADOWS_INCLUDED

#include "UnityCG.cginc"

struct MeshData {
	float4 position : POSITION;
	float3 normal : NORMAL;
};

#ifdef SHADOWS_CUBE
	struct Interpolators {
		float4 position : SV_POSITION;
		float3 lightVec : TEXCOORD0;
	};

	Interpolators vert(MeshData v) {
		Interpolators i;
		i.position = UnityObjectToClipPos(v.position);
		i.lightVec = mul(unity_ObjectToWorld, v.position).xyz - _LightPositionRange.xyz;
		return i;
	}

	float4 frag(Interpolators i) : SV_TARGET{
		float depth = length(i.lightVec) + unity_LightShadowBias.x;
		depth *= _LightPositionRange.w;
		return UnityEncodeCubeShadowDepth(depth);
	}
#else
	float4 vert(MeshData v) : SV_POSITION{
		float4 position = UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
		return UnityApplyLinearShadowBias(position);
	}

	float4 frag() : SV_TARGET{
		return 0;
	}
#endif


#endif