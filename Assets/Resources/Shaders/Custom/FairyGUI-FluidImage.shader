// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "FairyGUI/FluidImage"
{
    Properties
    {
        _MainTex ("Base (RGB), Alpha (A)", 2D) = "black" {}

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        _BlendSrcFactor ("Blend SrcFactor", Float) = 5
        _BlendDstFactor ("Blend DstFactor", Float) = 10
    
        _MultiplyFactor ("Darken Factor", Float) = 0.5
        
        _Progress ("Progress", Range(0.0, 1.0)) = 0.748
        _WaterColor ("WaterColor", Color) = (1.0, 1.0, 0.2, 1.0)
        _WaveStrength ("WaveStrength", Float) = 2.0
        _WaveFrequency ("WaveFrequency", Float) = 180.0
        _WaterTransparency ("WaterTransparency", Float) = 1.49
        _WaterAngle ("WaterAngle", Float) = 1.53
        
        _HighlightColor("Rim Color", Color) = (1.0,1.0,1.0,1.0)
        _HighlightTransparency ("Rim Transparenccy", Range(0.0, 1.0)) = 1.0
        
    }
    
    SubShader
    {
        LOD 100

        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
        }
        
        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp] 
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        Fog { Mode Off }
        Blend [_BlendSrcFactor] [_BlendDstFactor], One One
        ColorMask [_ColorMask]

        Pass
        {
            CGPROGRAM
                #pragma multi_compile NOT_COMBINED COMBINED
                #pragma multi_compile NOT_GRAYED GRAYED COLOR_FILTER
                #pragma multi_compile NOT_CLIPPED CLIPPED SOFT_CLIPPED ALPHA_MASK
                #pragma vertex vert
                #pragma fragment frag
                
                #include "UnityCG.cginc"
    
                struct appdata_t
                {
                    float4 vertex : POSITION;
                    fixed4 color : COLOR;
                    float4 texcoord : TEXCOORD0;
                    float4 texcoordAlpha : TEXCOORD2;
                    
                };
    
                struct v2f
                {
                    float4 vertex : SV_POSITION;
                    fixed4 color : COLOR;
                    float4 texcoord : TEXCOORD0;

                    #ifdef CLIPPED
                    float2 clipPos : TEXCOORD1;
                    #endif

                    #ifdef SOFT_CLIPPED
                    float2 clipPos : TEXCOORD1;
                    #endif
                    
                    float4 texcoordAlpha : TEXCOORD2;
                };
    
                sampler2D _MainTex;
                
                #ifdef COMBINED
                sampler2D _AlphaTex;
                #endif

                #ifdef CLIPPED
                float4 _ClipBox = float4(-2, -2, 0, 0);
                #endif

                #ifdef SOFT_CLIPPED
                float4 _ClipBox = float4(-2, -2, 0, 0);
                float4 _ClipSoftness = float4(0, 0, 0, 0);
                #endif

                #ifdef COLOR_FILTER
                float4x4 _ColorMatrix;
                float4 _ColorOffset;
                float _ColorOption = 0;
                #endif

float _Progress;
            fixed4 _WaterColor;
            float _WaveStrength;
            float _WaveFrequency;
            float _WaterTransparency;
            float _WaterAngle;
                float _CustomTime;
               
                fixed4 _Color;
                fixed4 _HighlightColor;
                fixed _HighlightTransparency;
            
                v2f vert (appdata_t v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.texcoord = v.texcoord;
                    o.texcoordAlpha = v.texcoordAlpha;
                    
                    
                    #if !defined(UNITY_COLORSPACE_GAMMA) && (UNITY_VERSION >= 550)
                    o.color.rgb = GammaToLinearSpace(v.color.rgb);
                    o.color.a = v.color.a;
                    #else
                    o.color = v.color;
                    #endif

                    #ifdef CLIPPED
                    o.clipPos = mul(unity_ObjectToWorld, v.vertex).xy * _ClipBox.zw + _ClipBox.xy;
                    #endif

                    #ifdef SOFT_CLIPPED
                    o.clipPos = mul(unity_ObjectToWorld, v.vertex).xy * _ClipBox.zw + _ClipBox.xy;
                    #endif
                   

                    return o;
                }
               fixed4 drawWater(fixed4 water_color, sampler2D color, float transparency, float height, float angle, float wave_strength, float wave_frequency, fixed2 uv);
                 
                fixed4 frag (v2f i) : SV_Target
                {
                    fixed4 col = i.color * drawWater(_WaterColor, _MainTex,_WaterTransparency , _Progress, _WaterAngle, _WaveStrength, _WaveFrequency, i.texcoord);
                    col =  col + fixed4(_HighlightColor.rgb ,col.a)  * _HighlightTransparency;
              
                    #ifdef GRAYED
                    fixed grey = dot(col.rgb, fixed3(0.299, 0.587, 0.114));
                    col.rgb = fixed3(grey, grey, grey);
                    #endif

                    #ifdef SOFT_CLIPPED
                    float2 factor = float2(0,0);
                    if(i.clipPos.x<0)
                        factor.x = (1.0-abs(i.clipPos.x)) * _ClipSoftness.x;
                    else
                        factor.x = (1.0-i.clipPos.x) * _ClipSoftness.z;
                    if(i.clipPos.y<0)
                        factor.y = (1.0-abs(i.clipPos.y)) * _ClipSoftness.w;
                    else
                        factor.y = (1.0-i.clipPos.y) * _ClipSoftness.y;
                    col.a *= clamp(min(factor.x, factor.y), 0.0, 1.0);
                    #endif

                    #ifdef CLIPPED
                    float2 factor = abs(i.clipPos);
                    if(max(factor.x, factor.y)>1) col.a = 0;
                    #endif

                    #ifdef COLOR_FILTER
                    if (_ColorOption == 0)
                    {
                        fixed4 col2 = col;
                        col2.r = dot(col, _ColorMatrix[0]) + _ColorOffset.x;
                        col2.g = dot(col, _ColorMatrix[1]) + _ColorOffset.y;
                        col2.b = dot(col, _ColorMatrix[2]) + _ColorOffset.z;
                        col2.a = dot(col, _ColorMatrix[3]) + _ColorOffset.w;
                        col = col2;
                    }
                    else //premultiply alpha
                        col.rgb *= col.a;
                    #endif

                    #ifdef ALPHA_MASK
                    clip(col.a - 0.001);
                    #endif

                    return col;
                }
                
                fixed4 drawWater(fixed4 water_color, sampler2D color, float transparency, float height, float angle, float wave_strength, float wave_frequency, fixed2 uv)
                {
                    half lightSurfaceOffset = 0.05 - clamp( height - 0.5, 0 , 1 ) / 0.5 * 0.03;
                    float iTime = _Time.y;
     
                    angle *= uv.y / height + angle / 1.5; //3D effect
                    wave_strength /= 1000.0;
                   
                    float wave = sin( 10.0 * uv.y + 10.0 * uv.x + wave_frequency * iTime ) * wave_strength;
                    wave += sin( 20.0 * -uv.y + 20.0 * uv.x + wave_frequency * 1.0 * iTime ) * wave_strength * 0.5;
                    wave += sin( 15.0 * -uv.y + 15.0 * -uv.x + wave_frequency * 0.6 * iTime ) * wave_strength * 1.3;
                    wave += sin( 3.0 * -uv.y + 3.0 * -uv.x + wave_frequency * 0.3 * iTime ) * wave_strength * 10.0;
                   
                    half lowerWave = wave - lightSurfaceOffset * sin(uv.x * 3.14);
                    wave += lightSurfaceOffset * sin( uv.x * 3.14 );
                   
                    fixed tolerance = 0.02;
                    fixed4 col = fixed4(0,0,0,0); 
                    
                    if ( uv.y  <= height + wave )
                        col = lerp(
                        lerp(
                            tex2D(color, fixed2(uv.x, ( 1.0 + angle) * (height + wave) - angle * uv.y + wave )),
                            water_color,
                            0.6 - ( 0.3 - ( 0.3 * uv.y / height ) ) ),
                        tex2D( color, fixed2( uv.x + wave, uv.y - wave )),
                        transparency-(transparency*uv.y/height));
                    
                    col = lerp(col, col / (1 - water_color * 0.2 * smoothstep(0, 0.3, height) ), smoothstep(lowerWave + height - tolerance, lowerWave + height, uv.y)); 
                    col.a *= 1 - smoothstep(height + wave- tolerance, height + wave , uv.y);
                    
                    return col;
                }
               
            ENDCG
        }
    }
}
