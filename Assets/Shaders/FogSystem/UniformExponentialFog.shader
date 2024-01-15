Shader "Unlit/UniformExponentialFog"
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

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 pixelViewPos: TEXCOORD1;
            };

            //sampler2D _CameraDepthTexture;

            //sampler2D _RenderTexSampler;
            //float4 _MainTex_ST;

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;

            uniform float4x4 InverseViewMatrix;
            uniform float4x4 InverseProjectionMatrix;

            uniform float FogDensity;

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

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the render texture
                float4 colorSample = tex2D(_MainTex, i.uv);
                // sample distance texture
                float depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
                // beer lambert law
                float4 depthViewPos = float4(i.pixelViewPos * depth, 1);
                float3 depthWorldPos = mul(InverseViewMatrix, depthViewPos).xyz;
                float distance = length(depthWorldPos - _WorldSpaceCameraPos.xyz);
                float expFog = 1 - exp(-distance * FogDensity);
                //if (expFog > 0.7)
                //    expFog = 0.7;
                return colorSample + float4(expFog, expFog, expFog, 1);
            }
            ENDCG
        }
    }
}
