Shader "Custom/SparkleShader"
{
    Properties
    {
        _MainTex("Sparkle Texture", 2D) = "white" {}
        _RotationSpeed("Rotation Speed", Float) = 1.0
        _ShimmerIntensity("Shimmer Intensity", Float) = 0.5
    }
        SubShader
        {
            Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
            LOD 100
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"

                // Properties
                sampler2D _MainTex;
                float _RotationSpeed;
                float _ShimmerIntensity;

                // Input/output structs
                struct appdata_t
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                    fixed4 color : COLOR; // Vertex color from the particle system
                };

                struct v2f
                {
                    float2 uv : TEXCOORD0;
                    float4 vertex : SV_POSITION;
                    fixed4 color : COLOR;
                };

                // Vertex shader
                v2f vert(appdata_t v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv = v.uv;
                    o.color = v.color; // Pass vertex color to fragment shader
                    return o;
                }

                // Fragment shader
                fixed4 frag(v2f i) : SV_Target
                {
                    // Time for rotation
                    float time = _Time.y;
                    float angle = _RotationSpeed * time;

                    // Rotate UVs around center
                    float2 uvCenter = float2(0.5, 0.5);
                    float2 uv = i.uv - uvCenter;
                    float2x2 rotationMatrix = {
                        float2(cos(angle), -sin(angle)),
                        float2(sin(angle), cos(angle))
                    };
                    uv = mul(rotationMatrix, uv) + uvCenter;

                    // Sample the texture
                    fixed4 texColor = tex2D(_MainTex, uv);

                    // Convert to grayscale
                    float grayscale = dot(texColor.rgb, float3(0.299, 0.587, 0.114));

                    // Apply shimmer effect
                    float shimmer = sin(_Time.y * 10.0 + grayscale * 10.0) * _ShimmerIntensity;
                    float finalGrayscale = saturate(grayscale + shimmer);

                    // Use vertex color (from particle system) as the custom color
                    fixed3 finalColor = i.color.rgb * finalGrayscale;

                    // Output final color with texture alpha
                    return fixed4(finalColor, texColor.a * i.color.a);
                }
                ENDCG
            }
        }
            FallBack "Unlit"
}
