// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "FairyGUI/AdvancedImage"
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
        
        // HSV Adjust
        _HSVRangeMin ("HSV Affect Range Min", Range(0, 1)) = 0
        _HSVRangeMax ("HSV Affect Range Max", Range(0, 1)) = 1
        _HSVAAdjust ("HSVA Adjust", Vector) = (0, 0, 0, 0)
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

                // HSV Control Variables
                float _HSVRangeMin;
                float _HSVRangeMax;
                float4 _HSVAAdjust;

                v2f vert (appdata_t v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.texcoord = v.texcoord;
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
                
                fixed3 rgb2hsv(fixed3 c) 
                {
                    fixed4 K = fixed4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                    fixed4 p = lerp(fixed4(c.bg, K.wz), fixed4(c.gb, K.xy), step(c.b, c.g));
                    fixed4 q = lerp(fixed4(p.xyw, c.r), fixed4(c.r, p.yzx), step(p.x, c.r));
    
                    fixed d = q.x - min(q.w, q.y);
                    fixed e = 1.0e-10;
                    return fixed3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
                }

                fixed3 hsv2rgb(fixed3 c) 
                {
                    c = fixed3(c.x, clamp(c.yz, 0.0, 1.0));
                    fixed4 K = fixed4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                    fixed3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                    return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
                }
                
                fixed4 frag (v2f i) : SV_Target
                {
                    fixed4 col = tex2D(_MainTex, i.texcoord.xy / i.texcoord.w) * i.color;

                    fixed3 hsv = rgb2hsv(col.rgb);
                    fixed affectMult = step(_HSVRangeMin, hsv.r) * step(hsv.r, _HSVRangeMax);
                    col = fixed4(hsv2rgb(hsv + _HSVAAdjust.xyz * affectMult), col.a + _HSVAAdjust.a);

                    #ifdef COMBINED
                    col.a *= tex2D(_AlphaTex, i.texcoord.xy / i.texcoord.w).g;
                    #endif

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
            ENDCG
        }
    }
}
