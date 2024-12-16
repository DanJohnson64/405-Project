Shader "Custom/PersonaStarShader"
{
    Properties
    {
        _Resolution("Resolution", Vector) = (1920, 1080, 0, 0)
        _Mouse("Mouse Position", Vector) = (0, 0, 0, 0)
        _GlobalPixelWidth("Global Pixel Width", Float) = 0.01
        _Color1("Primary Color", Color) = (1, 1, 1, 1)
        _Color2("Secondary Color", Color) = (0, 0, 0, 1)
        _Color3("Gray Primary Color", Color) = (0.8, 0.8, 0.8, 1)
        _Color4("Gray Secondary Color", Color) = (0.2, 0.2, 0.2, 1)
        _RippleSpeed("Ripple Speed", Float) = 1.0
        _StarPositions("Star Positions", Vector) = (0, 0, 0, 0)
        _StarSizes("Star Sizes", Float) = 0.5
        _StarRotations("Star Rotations", Float) = 0.0
        _MainTex("Sprite Texture", 2D) = "white" {} // Added _MainTex property
    }

        SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float4 _Resolution;
            float4 _Mouse;
            float _GlobalPixelWidth;
            float4 _Color1;
            float4 _Color2;
            float4 _Color3;
            float4 _Color4;
            float _RippleSpeed;
            sampler2D _MainTex; // Texture sampler for _MainTex
            float4 _MainTex_ST;

            float4 _StarPositions[10];
            float _StarSizes[10];
            float _StarRotations[10];

            v2f vert(appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float2 rotate2d(float angle, float2 coord)
            {
                float c = cos(angle);
                float s = sin(angle);
                return float2(coord.x * c - coord.y * s, coord.x * s + coord.y * c);
            }

            float2 scale2d(float scale, float2 coord)
            {
                return coord * scale;
            }

            float sdfStar5(float2 p)
            {
                const float k1x = 0.809016994375;
                const float k1y = -0.587785252292;
                const float k2x = -k1x;
                const float k2y = k1y;

                p.x = abs(p.x);
                p -= 2.0 * max(dot(float2(k1x, k1y), p), 0.0) * float2(k1x, k1y);
                p -= 2.0 * max(dot(float2(k2x, k2y), p), 0.0) * float2(k2x, k2y);

                const float k3x = 0.951056516295;
                const float k3y = 0.309016994375;
                return dot(float2(abs(p.x) - 0.3, p.y), float2(k3x, k3y));
            }

            float smoothSquareWave(float a, float blur)
            {
                a = frac(a);
                if (a <= 0.25) return smoothstep(-blur, blur, a);
                if (a >= 0.75) return smoothstep(1.0 - blur, 1.0 + blur, a);
                return 1.0 - smoothstep(0.5 - blur, 0.5 + blur, a);
            }

            float4 personaStar(
                float2 fragCoord,
                float2 position,
                float angle,
                float size,
                float3 col1,
                float3 col2,
                bool rippleDir,
                float globalPixelWidth)
            {
                fragCoord = rotate2d(radians(angle), fragCoord - position);
                fragCoord = scale2d(size, fragCoord);
                float starPixelWidth = globalPixelWidth * size * 7.0;

                float dist = sdfStar5(fragCoord);

                float time = rippleDir ? (_Time.y * _RippleSpeed) : (-_Time.y * _RippleSpeed);
                float ripple = smoothSquareWave(dist * 9.0 + 0.4 * time, starPixelWidth);
                float3 color = lerp(col1, col2, ripple);

                float alpha = 1.0 - smoothstep(0.0, globalPixelWidth * 2.0, dist);

                return float4(color, alpha);
            }

            void applyColor(inout float3 existingColor, float4 inputColor)
            {
                existingColor = lerp(existingColor, inputColor.rgb, inputColor.a);
            }

            void fragMainImage(out float4 fragColor, float2 fragCoord, float2 uv)
            {
                float2 p = (2.0 * fragCoord - _Resolution.xy) / _Resolution.y;
                float3 col = tex2D(_MainTex, uv).rgb; // Sample texture using _MainTex

                for (int i = 0; i < 10; i++)
                {
                    if (_StarSizes[i] > 0.0)
                    {
                        float2 position = _StarPositions[i].xy;
                        float angle = _StarRotations[i];
                        float size = _StarSizes[i];
                        bool useGrayColors = (i % 2 == 0);

                        float3 primaryColor = useGrayColors ? _Color3.rgb : _Color1.rgb;
                        float3 secondaryColor = useGrayColors ? _Color4.rgb : _Color2.rgb;

                        applyColor(col, personaStar(p, position, angle, size, primaryColor, secondaryColor, true, _GlobalPixelWidth));
                    }
                }

                fragColor = float4(col, 1.0);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float4 color;
                fragMainImage(color, i.uv* _Resolution.xy, i.uv);
                return color;
            }
            ENDCG
        }
    }
        FallBack "Diffuse"
}
