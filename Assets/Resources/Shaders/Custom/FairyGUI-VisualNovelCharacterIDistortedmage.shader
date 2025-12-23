// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "FairyGUI/VisualNovelCharacterDistortedImage"
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
      
        [Toggle] _FadeLeft("FadeLeft", Int) = 0  
        [Toggle] _FadeRight("FadeRight", Int) = 0  
        [Toggle] _IsDarkened("IsDarkened", Int) = 0  
        
        _Size("Size", float) = 1
    
        _CustomTime("Custom Time", Float) = 0
        
        [Toggle] _UseEmbeddedAlpha("Use Split Alpha Mode", Int) = 1 
        
        _FadeSmoothStepRatio("Fade Smoothstep Ratio", Float) = 0.075
        _EdgeSmoothStepRatio("Edge Smoothstep Ratio", Float) = 0.03
        
        _FadeSize("Fade Ratio", Float) = 0.26
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

                float _MultiplyFactor;
                int _FadeLeft;
                int _FadeRight;
                int _IsDarkened;

                float _CustomTime;
                int _UseEmbeddedAlpha;

                float _FadeSmoothStepRatio;
                float _EdgeSmoothStepRatio;
                float _FadeSize;
               
                fixed4 _Color;

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
                
                fixed4 frag (v2f i) : SV_Target
                {
                    float2 originalUV = i.texcoord.xy / i.texcoord.w;                
                    float offsetX = sin( 70 * originalUV.y + _CustomTime) * 0.01;
                    float2 offset = originalUV + float2(offsetX * i.texcoord.w, 0);
                
                    fixed4 col = tex2D(_MainTex, offset) * i.color * fixed4(_Color.rgb, 1);

                    if(_UseEmbeddedAlpha)
                    {
                        originalUV = i.texcoordAlpha.xy / i.texcoordAlpha.w;
                        offset = originalUV + float2(offsetX * (1-i.texcoord.w), 0);
                    
                        fixed4 alphaCol = tex2D(_MainTex, offset);
                        col.a *= alphaCol.r / 3 + alphaCol.g / 3 + alphaCol.b / 3;
                    }
                    
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

                    float alphaMultiplier = 1;
                    if(_FadeLeft)
                        alphaMultiplier *= smoothstep( i.texcoord.w * (_FadeSize - _FadeSmoothStepRatio), i.texcoord.w * _FadeSize, i.texcoord.x/i.texcoord.w );
                    else
                        alphaMultiplier *= smoothstep(0, _EdgeSmoothStepRatio * i.texcoord.w, i.texcoord.x/i.texcoord.w );
                    
                    if(_FadeRight)
                        alphaMultiplier *= 1 - smoothstep( i.texcoord.w * (i.texcoord.w - _FadeSize - _FadeSmoothStepRatio), i.texcoord.w - _FadeSize, i.texcoord.x/i.texcoord.w );
                    else
                        alphaMultiplier *= 1 - smoothstep(i.texcoord.w * ( 1 - _EdgeSmoothStepRatio), i.texcoord.w, i.texcoord.x/i.texcoord.w );
                        
                    return fixed4(col.rgb * (1 - _MultiplyFactor * _IsDarkened), alphaMultiplier * col.a);
                }
            ENDCG
        }
    }
}
