// Upgrade NOTE: replaced 'unity_World2Shadow' with 'unity_WorldToShadow'

Shader "Unlit/RayMarchingFog"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        //FogDensity ("Fog Density", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            UNITY_DECLARE_SHADOWMAP(ShadowMap);

            struct ray
            {
                float3 origin;
                float3 direction;
                float length;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 pixelViewPos: TEXCOORD1;
            };

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;

            uniform sampler2D _FogDensityTexture;
            uniform sampler3D _FogDensity3DTexture; // TODO

            uniform float4x4 InverseViewMatrix;
            uniform float4x4 InverseProjectionMatrix;

            uniform float FogDensity;
            uniform float4 LightColor;
            uniform float LightIntensity;
            uniform float4 AmbientLightColor;
            uniform float AmbientLightIntensity;
            uniform float FogDensityTextureScale;
            uniform float3 LightDirection;
            uniform float ScatteringAnisotropy;
            uniform float FogDepth;

            // ray marching parameters
            uniform uint StepsNumber;

            v2f vert (appdata_img v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;

                //transform clip pos to view space
                float4 clipPos = float4( v.texcoord * 2.0 - 1.0, 1.0, 1.0); 
                float4 pixelViewPos = mul(InverseProjectionMatrix, clipPos);
                pixelViewPos = pixelViewPos / pixelViewPos.w; // perspective division
                
                //o.ray = mul(unity_ObjectToWorld, v.vertex);
                o.pixelViewPos = pixelViewPos;

                return o;
            }


            float BeerLambertLaw(float density, float distance)
            {
                return exp(-distance * density);
            }

            float PhaseFunctionSphere()
            {
                return 1.0 / (4.0 * 3.14);
            }

            float HenyeyGreensteinSchlickPhaseFunction(float cosLightView, float g)
            {
                float k = 1.55 * g - 0.55 * pow(g, 3.0);
                return (1.0 - pow(k, 2.0)) / (4.0 * 3.14 * pow((1.0 + k * cosLightView), 2.0));
            }

            float HenyeyGreensteinPhaseFunction(float cosLightView, float g)
            {
                return (1.0 - pow(g, 2.0)) / (4.0 * 3.14 * pow((1.0 + pow(g, 2.0) - 2.0 * g * cosLightView), 1.5));
            }

            float RayleighPhaseFunction(float cosLightView)
            {
                return (3.0 / 16.0 * 3.14) * (1.0 * pow(cosLightView, 2.0));
            }

            fixed4 GetCascadeWeights(float z)
            {
                float4 zNear = float4(z >= _LightSplitsNear); 
                float4 zFar = float4(z < _LightSplitsFar); 
                float4 weights = zNear * zFar; 
                
			    return weights;
			}

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the render texture
                float4 colorSample = tex2D(_MainTex, i.uv);

                // sample distance texture
                float depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
                float4 depthViewPos = float4(i.pixelViewPos.xyz * depth, 1);
                float3 depthWorldPos = mul(InverseViewMatrix, depthViewPos).xyz;

                // create ray from intersection point to pixel position                
                ray lightRay;
                lightRay.origin = _WorldSpaceCameraPos.xyz;
                lightRay.direction = depthWorldPos - lightRay.origin;
                lightRay.length = length(lightRay.direction);
                lightRay.length = clamp(lightRay.length, 0.0, FogDepth);
                lightRay.direction = normalize(lightRay.direction);

                // calculate weights to sample unity's shadow map
                fixed4 weights = GetCascadeWeights(-depthViewPos.z);

                // sample density noise
                float4 densitySample = tex2D(_FogDensityTexture, (i.uv + _Time.x) * FogDensityTextureScale) * FogDensity;


                // ray marching data
                float stepSize = lightRay.length / StepsNumber;
                float3 marchingPos;
                float transmittance = 1.0; // 1.0 -> no exctinction (no absorption nor out scattering), 0.0 -> maximum exctinction
                float shadowTerm = 1.0; // 0.0 -> point in shadow, 1.0 -> lit point
                float4 inScattering = float4(0.0, 0.0, 0.0, 1.0);
                for (uint i = 0; i < StepsNumber; ++i)
                {
                    // marching position
                    marchingPos = lightRay.origin + lightRay.direction * stepSize * i;

                    // calculate transmittance with Beer Lambert Law (exponential)
                    float deltaTransmittance = BeerLambertLaw(densitySample.x, stepSize);
                    //deltaTransmittance = max(deltaTransmittance, ExctinctionCoefficient);
                    transmittance *= deltaTransmittance; // value between 0 and 1

                    // calculate shadow term for current marching position for sun light
                    float3 shadowCoord0 = mul(unity_WorldToShadow[0], float4(marchingPos,1.0)).xyz;
                    float3 shadowCoord1 = mul(unity_WorldToShadow[1], float4(marchingPos,1.0)).xyz;
                    float3 shadowCoord2 = mul(unity_WorldToShadow[2], float4(marchingPos,1.0)).xyz;
                    float3 shadowCoord3 = mul(unity_WorldToShadow[3], float4(marchingPos,1.0)).xyz;
 
                    float4 shadowCoord = float4(shadowCoord0 * weights[0] + shadowCoord1 * weights[1] + shadowCoord2 * weights[2] + shadowCoord3 * weights[3],1);
                    shadowTerm = UNITY_SAMPLE_SHADOW(ShadowMap, shadowCoord);

                    // at maximum depth (i.e. the sky) -> always lit point
                    if (depth >= 0.9999)
                    {
                        shadowTerm = 1.0;
                    }

                    // for each step: apply transmittance to light incoming from previous step ...
                    colorSample = colorSample * deltaTransmittance;
                    // ... and add in scattering light basing on shadow map, fog and phase function
                    float cosLightView = -dot(lightRay.direction, LightDirection);
                    //float phaseFunction = HenyeyGreensteinSchlickPhaseFunction(cosLightView, ScatteringAnisotropy); -> problems with anisotropy values between 0.94 and 0.99
                    //float phaseFunction = RayleighPhaseFunction(cosLightView);
                    float phaseFunction = HenyeyGreensteinPhaseFunction(cosLightView, ScatteringAnisotropy);
                    inScattering = LightColor * LightIntensity * shadowTerm * (1.0 - deltaTransmittance) * phaseFunction;
                    //inScattering += AmbientLightColor * AmbientLightIntensity * (1.0 - shadowTerm) * (1.0 - deltaTransmittance) * phaseFunction;
                    colorSample += inScattering;
                }

                // calculate transmitted radiance and add fog color
                //return colorSample * transmittance + inScattering * LightIntensity + AmbientLightColor * (1.0 - transmittance) * AmbientLightIntensity;
                return colorSample + AmbientLightColor * AmbientLightIntensity * (1.0 - transmittance);
            }
            ENDCG
        }
    }
}
