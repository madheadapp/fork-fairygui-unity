// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "FairyGUI/RectangleGraph"
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
		
		[PerRendererData] _XScale ("X Scale", Float) = 1
		[PerRendererData] _YScale ("Y Scale", Float) = 1

	    [PerRendererData] _RoundnessFactor("Roundness Factor", float) = 0.5

	    [PerRendererData] _FillColor("Fill Color", Color) = (1, 1, 1, 1)
	    [PerRendererData] _OutlineColor("Outline Color", Color) = (1, 1, 1, 1)
	    [PerRendererData] _OutlineSize("Outline Size", Float) = 0.01
	    [PerRendererData] _PixelSize("_PixelSize", Float) = 1
	    
	    [PerRendererData] _Blur("blur", Float) = 0

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
				
				float _XScale;
                float _YScale;
                float _RoundnessFactor;
                float4 _OutlineColor;
                float _OutlineSize;
                float _OuterBlur;
                float _InnerBlur;
                float _PixelSize;
	            float _Blur;
	            float4 _FillColor;
	            
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
					
				    // o.modelPos = v.vertex;
                    // hijack modelPos.z to be distance from camera plane since it 
                    // isn't being used for anything else.  used for pixel size.
                    // o.modelPos.z = -UnityObjectToViewPos(v.vertex).z;

					return o;
				}
                    
                float4 when_eq(float4 x, float4 y) {
                  return 1.0 - abs(sign(x - y));
                }
                
                float4 when_neq(float4 x, float4 y) {
                  return abs(sign(x - y));
                }
                
                float4 when_gt(float4 x, float4 y) {
                  return max(sign(x - y), 0.0);
                }
                
                float4 when_lt(float4 x, float4 y) {
                  return max(sign(y - x), 0.0);
                }
                
                float4 when_ge(float4 x, float4 y) {
                  return 1.0 - when_lt(x, y);
                }
                
                float4 when_le(float4 x, float4 y) {
                  return 1.0 - when_gt(x, y);
                }
                
                float4 and(float4 a, float4 b) {
                  return a * b;
                }
                
                float2 prepare(float2 uv) {
                    float2 pos = float2(uv.x * _XScale, uv.y * _YScale);
                
                    // figure out the size of a pixel in world units at the z depth of the 
                    // shape, which is sort of the same as fwidth(pos) but works on more 
                    // platforms.  won't look right in 3D unless the shape is billboarded,
                    // but this is Shapes2D and not Shapes3D so we'll have to live with it.

//                    if (_PixelSize == 0) {
//                        if (unity_OrthoParams.w == 0) {
//                            // get the vertical fov, thanks http://answers.unity3d.com/questions/770838/how-can-i-extract-the-fov-information-from-the-pro.html
//                            float t = unity_CameraProjection._m11;
//                            float fov = atan(1.0 / t);
//                            // get the distance from the current point world position to the 
//                            // camera's plane, and then figure out the pixel size based on the 
//                            // fov at that distance.  probably not actually "correct" but it 
//                            // seems to work well regardless of fov or camera angle/position.
//                            float h = tan(fov) * distanceFromCameraPlane * 2;
//                            _PixelSize = h / _ScreenParams.y;
//                        } else {
//                            _PixelSize =  (_ScreenParams.z - 1);// * unity_OrthoParams.x ;
//                        }
//                    }
                
                    // put a little resolution-independent AA on things if desired
                    if (_Blur == 0) {
                        // fwidth is not supported on all GLES platforms, so we are now using
                        // the _PixelSize method which should be available everywhere (though
                        // only when using an orthographic camera)
                        
                        //float2 aa = fwidth(pos);
                        //_Blur = length(aa);
                        
                        _Blur = sqrt(_PixelSize * _PixelSize * 2);
                        if (_OutlineSize > 0) {
                            // subtract the AA blur from the outline so sizes stay mostly 
                            // correct and outlines don't look too thick when scaled down.
                            // don't clamp _OutlineSize to 0 or it will break comparisons in
                            // other places (should fix that at some point).
                            _OutlineSize -= _Blur;
                        }
                    }
                
                    float min_dim = min(_XScale, _YScale) / 2;
                    
                    // blur on the outside of the shape in world coords
                    _OuterBlur = max(min(_Blur, min_dim - _OutlineSize), 0);
                    // blur on the inside of the outline in world coords
                    _InnerBlur = max(min(_OuterBlur, min_dim - _OuterBlur - _OutlineSize), 0);
                    
                    // return the local position of the pixel in the quad centered at 0, 0 
                    return pos;
                }
                
                // this seems a little nicer than smoothstep for antialiasing, though
                // not necessarily for large amounts of blurring...there are tradeoffs,
                // might want to separate blur from antialias
                float blur(float edge1, float edge2, float amount) {
                    return clamp(lerp(0, 1, (amount - edge1) / (edge2 - edge1)), 0, 1);
                }
                
                fixed4 outline_fill_blend(float dist, fixed4 fill_color, fixed4 outline_color,
                        float outer_blur, float outline, float inner_blur) {
                        
                    float mix = blur(outline, inner_blur, dist);
                    fixed4 color;
                    
                    if(fill_color.a == 0){
                    
                       color = outline_color;
                       color.a *= (1 - mix);
                    }
                    else
                    {
                       color = lerp(outline_color, fill_color, mix);                   
                    }
                    
                    float alpha = blur(0, 1, dist / outer_blur);
                    color.a *= alpha;
                    return color;
                }
                
                fixed4 fill_blend(float dist, fixed4 fill_color, float outer_blur) {
                    float alpha = blur(0, outer_blur, dist);
                    fixed4 color = fill_color;
                    color.a *= alpha;
                    return color;
                }
                
                // given a distance from the very edge of the shape going inwards, returns the
                // color that should be at the current point
                fixed4 color_from_distance(float dist, fixed4 fill_color, fixed4 outline_color ) 
                {
                    if (_OutlineSize == 0) {
                        return fill_blend(dist, fill_color, _OuterBlur);
                    } else {
                        float outline = _OuterBlur + _OutlineSize;
                        float inner_blur = outline + _InnerBlur;
                        return outline_fill_blend(dist, fill_color, outline_color,
                                _OuterBlur, outline, inner_blur);
                    }
                }

				fixed4 frag (v2f i) : SV_Target
				{
                    // Rounded Rectangle AA
                    float2 pos = prepare(i.texcoord.xy - 0.5);
                    
                    float tl = and(when_le(pos.x, 0), when_ge(pos.y, 0)) * _RoundnessFactor;
                    float tr = and(when_ge(pos.x, 0), when_ge(pos.y, 0)) * _RoundnessFactor;
                    float bl = and(when_le(pos.x, 0), when_le(pos.y, 0)) * _RoundnessFactor;
                    float br = and(when_ge(pos.x, 0), when_le(pos.y, 0)) * _RoundnessFactor;
                    float roundness = tl + tr + bl + br;
                    
                    float radius =  min(min(_XScale / 2, roundness), _YScale / 2);
                    
                    // handy distance to round rectangle formula
                    float2 extents = float2(_XScale, _YScale) / 2 - radius;
                    float2 delta = abs(pos) - extents;
                    
                    // first component is distance to closest side when not in a corner circle, second
                    // is distance to the rounded part when in a corner circle
                    float dist = radius - (min(max(delta.x, delta.y), 0) + length(max(delta, 0)));
                    
                    fixed4 col = color_from_distance(dist, _FillColor, _OutlineColor);  
                    col.a *= i.color.a;
                    
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
					col.a *= step(max(factor.x, factor.y), 1);
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
