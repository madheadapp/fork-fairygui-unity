Shader "FairyGUI/WaveTransitionFadeInEffect"
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
    	_NoiseTex ("Noise (A)", 2D) = "white" {}	
        [Toggle] _IsYAxis ("Lerp Along Y Axis", Int) = 1
    	[Toggle] _IsFlip ("Flip", Int) = 1
    	_TiltAmount ("Tilt Amount", Float) = 0
    	_RandomFactor ("Random Factor", Float) = 0
        _Mask ("Mask Amount", Float) = 0
		_MaskTransitionFeather ("MaskTransitionFeather( Larger -> Harder )", Float) = 1000
        _EdgeColorFeather ("Edge Color Feather( Larger -> Harder )", Float) = 1000
    	_EdgeColorThickness ("Edge Color Thickness", Float) = 0	
    	_EdgeColor("Edge Color" , color) = (1,1,1,1)	
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
    	
		pass
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
				float2 texcoord2 : TEXCOORD1;
                
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float4 texcoord : TEXCOORD0;
            	float2 texcoord2 : TEXCOORD1;

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
			
			uniform sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
			int _IsYAxis;
			int _IsFlip;
			uniform float _TiltAmount;
			uniform float _RandomFactor;
			uniform float _Mask;
			uniform float _MaskTransitionFeather;
			uniform float _EdgeColorFeather;
			uniform float _EdgeColorThickness;
			uniform float4 _EdgeColor;

			
			v2f vert(appdata_t v){
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = v.texcoord;
				o.texcoord2 = TRANSFORM_TEX(v.texcoord2, _NoiseTex);
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

			fixed4 frag(v2f i) : COLOR{
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


				float4 noiseValue = tex2D(_NoiseTex, i.texcoord2);
				float brightness = noiseValue.r ;
				float percentage;
				if( _IsYAxis )
				{
					percentage = i.texcoord.y + _TiltAmount * i.texcoord.x - _Mask + ( brightness - 0.5 ) * _RandomFactor;
				}
				else
				{
					percentage = i.texcoord.x + _TiltAmount * i.texcoord.y - _Mask + ( brightness - 0.5 ) * _RandomFactor;
				}

				if( _IsFlip )
				{
					col.a = lerp( 0, col.a, clamp( percentage * _MaskTransitionFeather, 0, 1 ) );
					col.rgb = lerp( _EdgeColor.rgb, col.rgb, clamp( percentage * _EdgeColorFeather - _EdgeColorThickness, 0, 1 ) );	
				}
				else
				{
					col.a = lerp( col.a, 0, clamp( percentage * _MaskTransitionFeather, 0, 1 ) );
					col.rgb = lerp( col.rgb, _EdgeColor.rgb, clamp( percentage * _EdgeColorFeather + _EdgeColorThickness, 0, 1 ) );	
				}
				return col ;
			}			
	         ENDCG				
		}	
    }
}
