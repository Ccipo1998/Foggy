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

            //sampler2D _CameraDepthTexture;

            //sampler2D _RenderTexSampler;
            //float4 _MainTex_ST;

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;

            uniform sampler2D _FogDensityTexture;
            uniform sampler3D _FogDensity3DTexture;

            uniform float4x4 InverseViewMatrix;
            uniform float4x4 InverseProjectionMatrix;

            uniform float FogDensity;
            uniform float4 FogColor;
            uniform float FogDensityTextureScale;

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

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the render texture
                float4 colorSample = tex2D(_MainTex, i.uv);

                // take fog color
                //float4 fogColor = FogColor;

                // sample distance texture
                float depth = 1 - Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
                float4 depthViewPos = float4(i.pixelViewPos.x * depth, i.pixelViewPos.y * depth, i.pixelViewPos.z * depth, 1);
                float3 depthWorldPos = mul(InverseViewMatrix, depthViewPos).xyz;
                float3 pixelWorldPos = mul(InverseViewMatrix, i.pixelViewPos).xyz;

                // create ray from intersection point to pixel position
                ray cameraRay;
                cameraRay.origin = depthWorldPos;
                cameraRay.direction = pixelWorldPos - cameraRay.origin;
                cameraRay.length = length(cameraRay.direction);
                cameraRay.direction = normalize(cameraRay.direction);

                // sample density noise
                float4 densitySample = tex2D(_FogDensityTexture, (i.uv + _Time.x) * FogDensityTextureScale) * FogDensity;
                //float3 uvw = float3(i.uv.x, i.uv.y, cameraRay.length);
                //float4 densitySample = tex3D(_FogDensity3DTexture, uvw * FogDensityTextureScale) * FogDensity;

                float stepSize = cameraRay.length / StepsNumber;
                float3 marchingPos;
                float transmittance;
                for (uint i = 0; i < StepsNumber; ++i)
                {
                    // marching position
                    marchingPos = cameraRay.origin + cameraRay.direction * stepSize * i;

                    // take new density sample
                    //uvw.z = stepSize * i;
                    //densitySample = tex3D(_FogDensity3DTexture, uvw * FogDensityTextureScale) * FogDensity;

                    // calculate transmittance with Beer Lambert Law (exponential)
                    transmittance = BeerLambertLaw(densitySample.x, stepSize); // value between 0 and 1

                    // calculate transmitted radiance and add fog color
                    colorSample = colorSample * transmittance + (1 - transmittance) * FogColor;
                }

                return colorSample;
            }
            ENDCG
        }
    }
}
