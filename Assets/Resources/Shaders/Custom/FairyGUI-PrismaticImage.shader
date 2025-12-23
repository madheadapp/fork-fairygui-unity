// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "FairyGUI/PrismaticImage"
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
        
        // Prismatic Params
        _FGTranparency ("Foreground transp (White)", Range(0, 1)) = 0
        _BGTranparency ("Background transp (Black)", Range(0, 1)) = 0
        
        _PrismColor ("Prism color", Color) = (1,1,1,1)
        _PrismRainbow ("Prism rainbow", 2D) = "white" {}
        _PrismMask ("Prism Mask", 2D) = "white" {}
        _PrismMul ("Prism multiplier", Float ) = 12
        _PrismPow ("Prism power (1-5)", Range(1, 5)) = 1.5
        _PrismContrast ("Prism contrast (1- 5)", Range(1, 5)) = 3
        
        _SilverBack ("Silver back (0 - 1)", Range(0, 1)) = 0.5
        _Speed ("Speed (0 - 5)", Range(0, 5)) = 3.5
        _FadeDist ("Fade distance", Float ) = 40
        
        _LightDirection("LightDirection", Vector) = (1.0, 1.0, 1.0, 1.0)
        _lightColor("LightColor", Color) = (1.0, 1.0, 1.0, 1.0)
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
                #include "AutoLight.cginc"
    
                struct appdata_t
                {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
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
                    
                    float4 posWorld : TEXCOORD2;
                    float3 normalDir : TEXCOORD3;
                    float4 screenPos : TEXCOORD4;
                    float4 projPos : TEXCOORD5;
                    
                    LIGHTING_COORDS(5,6)
                    UNITY_FOG_COORDS(7)
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
                
                uniform float4 _LightColor0;
                uniform float4 _Color;
                uniform float4 _PrismColor;
                uniform sampler2D _PrismRainbow; 
                uniform float4 _PrismRainbow_ST;
                uniform float _PrismPow;
                uniform float _PrismMul;
                uniform float _PrismContrast;
                uniform float _BGTranparency;
                uniform float _FGTranparency;
                uniform sampler2D _PrismMask; 
                uniform float4 _PrismMask_ST;
                uniform float _SilverBack;
                uniform float xxwxww;
                uniform float _Speed;
                uniform float _FadeDist;

                uniform float4 _LightDirection;
                uniform float4 _LightColor;

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

                    o.normalDir = UnityObjectToWorldNormal(v.normal);
                    o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                    o.projPos = ComputeScreenPos (o.vertex);
                    UNITY_TRANSFER_FOG(o,o.vertex);
                    COMPUTE_EYEDEPTH(o.projPos.z);
                
                    o.screenPos = float4( o.vertex.xy / o.vertex.w, 0, 0 );
                    o.screenPos.y *= _ProjectionParams.x;
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    
                    return o;
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


                i.normalDir = normalize(i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 normalDirection = i.normalDir;
                float3 viewReflectDirection = reflect( -viewDirection, normalDirection );
                float partZ = max(0,i.projPos.z - _ProjectionParams.g);
                
                float3 lightDirection = normalize(_LightDirection.xyz);
                float3 lightColor = _LightColor.rgb;
                
                float3 halfDirection = normalize(viewDirection+lightDirection);
                float attenuation = LIGHT_ATTENUATION(i);
                
                float3 attenColor = attenuation * _LightColor.xyz;
                
                float NdotL = max(0, dot( normalDirection, lightDirection ));
                NdotL = max(0.0,dot( normalDirection, lightDirection ));
                float3 directDiffuse = max( 0.0, NdotL) * attenColor;
                float3 indirectDiffuse = float3(0,0,0);
                indirectDiffuse += UNITY_LIGHTMODEL_AMBIENT.rgb;
                

                float3 wvvxxw = (viewReflectDirection*lightDirection*_Speed).rgb;
                float wvwwxv = (wvvxxw.r+wvvxxw.g+wvvxxw.b+(float2(i.screenPos.x*(_ScreenParams.r/_ScreenParams.g), i.screenPos.y).r*float2(i.screenPos.x*(_ScreenParams.r/_ScreenParams.g), i.screenPos.y).g));
                
                float wvxwxw_ang = wvwwxv;
                float wvxwxw_spd = 1.0;
                float wvxwxw_cos = cos(wvxwxw_spd*wvxwxw_ang);
                float wvxwxw_sin = sin(wvxwxw_spd*wvxwxw_ang);
                float2 wvxwxw_piv = float2(0.5,0.5);
                float2 node_175 = ((0.7*frac((i.texcoord*_PrismMul)))-(-0.15));
                float2 wvxwxw = (mul(node_175-wvxwxw_piv,float2x2( wvxwxw_cos, -wvxwxw_sin, wvxwxw_sin, wvxwxw_cos))+wvxwxw_piv);
                float vwvxwv = 0.0;
                float4 wvvxxv = tex2Dlod(_PrismRainbow,float4(TRANSFORM_TEX(wvxwxw, _PrismRainbow),0.0,vwvxwv));
                //float4 wvvxxv = tex2D(_PrismRainbow,TRANSFORM_TEX(i.texcoord, _PrismRainbow));
                float xwvwvw_ang = (1.0 - wvwwxv);
                float xwvwvw_spd = 1.0;
                float xwvwvw_cos = cos(xwvwvw_spd*xwvwvw_ang);
                float xwvwvw_sin = sin(xwvwvw_spd*xwvwvw_ang);
                float2 xwvwvw_piv = float2(0.5,0.5);
                float2 xwvwvw = (mul(node_175-xwvwvw_piv,float2x2( xwvwvw_cos, -xwvwvw_sin, xwvwvw_sin, xwvwvw_cos))+xwvwvw_piv);
                float4 vwxwww = tex2Dlod(_PrismMask,float4(TRANSFORM_TEX(xwvwvw, _PrismMask),0.0,vwvxwv));
                //float4 vwxwww = tex2D(_PrismMask,TRANSFORM_TEX(i.texcoord, _PrismMask));

                float3 node_1034 = (pow((wvvxxv.rgb*vwxwww.rgb),_PrismContrast)*_PrismPow);
                float vwxvww_ang = wvwwxv;
                float vwxvww_spd = 1.0;
                float vwxvww_cos = cos(vwxvww_spd*vwxvww_ang);
                float vwxvww_sin = sin(vwxvww_spd*vwxvww_ang);
                float2 vwxvww_piv = float2(0.5,0.5);
                float2 vwxvww = (mul(((i.texcoord*0.2)-(-0.15))-vwxvww_piv,float2x2( vwxvww_cos, -vwxvww_sin, vwxvww_sin, vwxvww_cos))+vwxvww_piv);
                float4 vwwvxw = tex2D(_PrismRainbow,TRANSFORM_TEX(vwxvww, _PrismRainbow));
                
                
                float3 node_3784 = lerp(((_PrismColor.rgb*node_1034)+saturate(((vwxwww.rgb*_SilverBack)-lerp(node_1034,dot(node_1034,float3(0.3,0.59,0.11)),1.0)))),vwwvxw.rgb,saturate((saturate((partZ/_FadeDist))*1.5+-0.5)));
                
                //card frame prismatic effect;
                float4 diffuseColor = lerp(
                                        lerp(col, float4(node_3784, 1), (1.0 - _BGTranparency)),
                                        col,
                                        col.a * (1.0 - _FGTranparency));
                                        
                float4 diffuse = float4((directDiffuse + indirectDiffuse), 0) + diffuseColor;

                return fixed4(diffuse.rgb * 0.5 + col.rgb * 0.5, col.a);

                }
            ENDCG
        }
    }
}
