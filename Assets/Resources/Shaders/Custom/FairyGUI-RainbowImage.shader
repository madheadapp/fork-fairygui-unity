Shader "FairyGUI/RainbowImage"
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
        
		[Space]
		_PrimaryDirectionX ("PrimaryDirectionX", Float) = 200
		_PrimaryDirectionY ("PrimaryDirectionY", Float) = 200
        _SecondaryDirectionX ("SecondaryDirectionX", Float) = 200
		_SecondaryDirectionY ("SecondaryDirectionY", Float) = 200
		
	    [Space]
		_PrimaryFrequency ("Primary Light Frequency", Float) = 10
        _PrimaryDensity("Primary Color Density", Float) = 0.2
		_PrimaryClampValue("Primary Clamp Value", Float) = 0.9
		_PrimaryLightLocation("Primary Light Location", Float) = 0.5
		
        [Space]
        _SecondaryFrequency ("Secondary Light Frequency", Float) = 10
        _SecondaryDensity("Secondary Color Density", Float) = 0.2
		_SecondaryClampValue("Primary Clamp Value", Float) = 0.9		
    
        [Space]
        _CustomTime("Custom Time", Float) = 0
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
                #include "FlashEffect.cginc"
    
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
                
            //shine variables
            float _CustomTime;

            // Primary Light
            float _PrimaryDirectionX;
            float _PrimaryDirectionY;
            float _PrimaryFrequency;
            float _PrimaryDensity;
            float _PrimaryClampValue;
            float _PrimaryLightLocation;

            // Secondary Light
            float _SecondaryDirectionX;
            float _SecondaryDirectionY;
            float _SecondaryFrequency;
            float _SecondaryDensity;
            float _SecondaryClampValue;

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
                
            float3 hsv2rgb(float3 c)
            {
                float4 K = fixed4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }
                
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.texcoord.xy / i.texcoord.w) * i.color;

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

                fixed2 screenPos = i.vertex.xy / _ScreenParams.xy;

                float2 dir = fixed2(_PrimaryDirectionX, _PrimaryDirectionY);
                float primaryDensity = col.r * col.r * lightIntensity(_PrimaryLightLocation, screenPos, dir, _PrimaryFrequency, _PrimaryClampValue, _PrimaryDensity, 0);
                
                float2 secondaryDir = fixed2(_SecondaryDirectionX, _SecondaryDirectionY);
                float secondaryDensity = col.r * col.r * lightIntensity(_CustomTime, screenPos, secondaryDir, _SecondaryFrequency, _SecondaryClampValue, _SecondaryDensity, 0);
                float secondaryLightSupport = col.r * col.r * lightIntensity(_CustomTime, screenPos, secondaryDir, _SecondaryFrequency, _SecondaryClampValue, _SecondaryDensity, 1);
                
                float3 ColorOffset = fixed3(0.5, 0.4, 0.6); 
                float3 texcoordOffset = screenPos.xyx * 7 + fixed3(0,2,4);
                
                col.rgb += hsv2rgb(float3(primaryDensity * _SinTime.w, 1, 1)) * primaryDensity;
                col.rgb += ( ColorOffset + 0.5 * cos( _CustomTime + texcoordOffset)) * secondaryDensity; 
                col.rgb += ( ColorOffset + 0.5 * cos( _CustomTime + texcoordOffset)) * secondaryLightSupport;
          
                return col;
            }
            ENDCG
        }
    }
}