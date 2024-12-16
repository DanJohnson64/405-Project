Shader "Custom/HolographicCardShaderWithLighting"
{
    Properties
    {
        _MainTex("Base Texture (Grayscale)", 2D) = "white" {}
        _NoiseTex("Holographic Noise Texture", 2D) = "white" {}
        _ColorRamp("Color Gradient Ramp", 2D) = "white" {}
        _Color("Tint Color", Color) = (1, 1, 1, 1)
        _LightPosition("Light Position (Screen Space)", Vector) = (0.5, 0.5, 0, 0)
        _DistortionStrength("Distortion Strength", Float) = 0.1
        _ColorShiftIntensity("Color Shift Intensity", Float) = 1.0
        _ScrollSpeed("Scroll Speed", Float) = 1.0
        _Alpha("Transparency", Range(0,1)) = 1.0
    }

        SubShader
        {
            Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
            LOD 200

            Pass
            {
                Blend SrcAlpha OneMinusSrcAlpha
                ZWrite Off
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"

                sampler2D _MainTex;
                sampler2D _NoiseTex;
                sampler2D _ColorRamp;
                float4 _Color; // Tint color
                float4 _LightPosition; // Light position in screen space
                float _DistortionStrength;
                float _ColorShiftIntensity;
                float _ScrollSpeed;
                float _Alpha;

                struct appdata_t
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                };

                struct v2f
                {
                    float2 uv : TEXCOORD0;
                    float4 vertex : SV_POSITION;
                    float4 worldPos : TEXCOORD1;
                };

                v2f vert(appdata_t v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv = v.uv;
                    o.worldPos = mul(unity_ObjectToWorld, v.vertex); // Get world position
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    // Base texture sample (grayscale conversion)
                    float2 uv = i.uv;
                    fixed4 baseTex = tex2D(_MainTex, uv);
                    float grayscale = dot(baseTex.rgb, float3(0.3, 0.59, 0.11)); // Luminance formula for grayscale
                    fixed4 grayscaleColor = float4(grayscale, grayscale, grayscale, baseTex.a);

                    // Add scrolling distortion using noise texture
                    float2 noiseUV = uv + float2(_Time.y * _ScrollSpeed, _Time.y * _ScrollSpeed);
                    float2 distortion = tex2D(_NoiseTex, noiseUV).rg * 2.0 - 1.0; // Get distortion vectors
                    uv += distortion * _DistortionStrength;

                    // Re-sample base texture with distortion
                    baseTex = tex2D(_MainTex, uv);
                    grayscale = dot(baseTex.rgb, float3(0.3, 0.59, 0.11));
                    grayscaleColor = float4(grayscale, grayscale, grayscale, baseTex.a);

                    // Add color tint
                    fixed4 tintedColor = float4(grayscaleColor.rgb * _Color.rgb, grayscaleColor.a);

                    // Lighting calculation
                    float3 lightDir = normalize(_LightPosition.xyz - i.worldPos.xyz);
                    float3 normal = float3(0, 0, 1); // Assume a flat normal for 2D
                    float lightIntensity = max(0, dot(normal, lightDir)); // Lambertian reflection

                    // Apply lighting to tinted color
                    fixed4 litColor = tintedColor * lightIntensity;

                    // Add color shift using the ramp texture and UV Y-coordinate
                    float colorShift = tex2D(_NoiseTex, noiseUV).r * _ColorShiftIntensity;
                    float2 rampUV = float2(colorShift, uv.y);
                    fixed4 colorShiftEffect = tex2D(_ColorRamp, rampUV);

                    // Combine base color, lighting, and color shift
                    fixed4 finalColor = litColor + colorShiftEffect;

                    // Apply transparency
                    finalColor.a *= _Alpha;

                    return finalColor;
                }
                ENDCG
            }
        }

            FallBack "Transparent/Diffuse"
}
