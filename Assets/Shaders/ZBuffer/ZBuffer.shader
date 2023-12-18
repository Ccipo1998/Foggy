Shader "Custom/ZBuffer"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct v2f
            {
                float4 position: SV_POSITION;
                float2 screenUV : TEXCOORD0;
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.vertex);
                o.screenUV = ComputeScreenPos(o.position);
                return o;
            }

            sampler2D _CameraDepthTexture;

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.screenUV.xy;
                float depth = 1 - Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
                return fixed4(depth, depth, depth, 1);
            }
            ENDCG
        }
    }
}
