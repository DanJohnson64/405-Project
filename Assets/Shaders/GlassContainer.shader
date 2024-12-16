Shader "Custom/URPGlassDistortionDynamicRefined"
{
    Properties
    {
        _MainTex("Base Texture", 2D) = "white" {}
        _NormalMap("Normal Map", 2D) = "bump" {}
        _NormalMapTiling("Normal Map Tiling", Vector) = (0.2, 0.2, 0, 0)
        _NormalMapOffset("Normal Map Offset", Vector) = (0, 0, 0, 0)
        _TintColor("Tint Color", Color) = (1, 1, 1, 1)
        _Transparency("Transparency", Range(0, 1)) = 0.5
        _DistortionStrength("Distortion Strength", Range(0, 1)) = 0.1
    }

        SubShader
        {
            Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
            LOD 200

            Pass
            {
                Blend SrcAlpha OneMinusSrcAlpha
                ZWrite Off

                HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

                TEXTURE2D(_CameraOpaqueTexture);
                SAMPLER(sampler_CameraOpaqueTexture);

                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);

                TEXTURE2D(_NormalMap);
                SAMPLER(sampler_NormalMap);

                float4 _NormalMapTiling;
                float4 _NormalMapOffset;
                float4 _TintColor;
                float _Transparency;
                float _DistortionStrength;

                struct Attributes
                {
                    float4 positionOS : POSITION;
                    float2 uv : TEXCOORD0;
                };

                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    float2 uv : TEXCOORD0;
                    float4 screenPos : TEXCOORD1;
                };

                Varyings vert(Attributes v)
                {
                    Varyings o;

                    // Transform object-space position to clip-space
                    o.positionCS = TransformObjectToHClip(v.positionOS); // Clip-space for rasterization

                    // Pass UVs as-is
                    o.uv = v.uv;

                    // Use ComputeScreenPos for screen-space UV calculations
                    o.screenPos = ComputeScreenPos(o.positionCS);

                    return o;
                }

                half4 frag(Varyings i) : SV_Target
                {
                    // Compute normalized screen-space UVs
                    float2 screenUV = i.screenPos.xy / i.screenPos.w;
                    screenUV = screenUV * 0.5 + 0.5; // Normalize to [0, 1]

                    // Sample the opaque texture directly
                    half4 backgroundColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV);

                    // Return the background color
                    return backgroundColor;
                }








                ENDHLSL
            }
        }

            FallBack "Transparent/Diffuse"
}
