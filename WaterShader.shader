Shader "sTools/WaterShader" 
{
	Properties 
	{
		_RScrollXSpeed ("R - XSpeed", float) = 0.5
		_RScrollYSpeed ("R - YSpeed", float) = 0.5
		_RWaterNormal ("R - Normal", 2D) = "blue" {}
		_RWaterHeight ("R - Height", 2D) = "black" {}

		_GScrollXSpeed ("G - XSpeed", float) = 0.5
		_GScrollYSpeed ("G - YSpeed", float) = 0.5
		_GWaterNormal ("G - Normal", 2D) = "blue" {}
		_GWaterHeight ("G - Height", 2D) = "black" {}

		_BScrollXSpeed ("B - XSpeed", float) = 0.5
		_BScrollYSpeed ("B - YSpeed", float) = 0.5
		_BWaterNormal ("B - Normal", 2D) = "blue" {}
		_BWaterHeight ("B - Height", 2D) = "black" {}

		_WaterColor ("Water Color", Color) = (1,1,1,1)
		_WaveHeight("Wave Height", Range(0, 0.9)) = 0.5
		_DepthSize ("Depth Size", Range(0, 0.9)) = 0.5
		_FlowMap ("Flow Map", 2D) = "orange" {}
		_FlowDeformation ("Flow Deform", Range(0, 1)) = 0.5
	}
	SubShader 
	{
		LOD 200
		Tags { "RenderType"="Opaque" "Queue"="Transparent" }
		ZWrite on
		
		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows vertex:vert alpha
		#pragma target 4.6
		#pragma shader_feature FLOW_MAP

		struct Input 
		{
			fixed2 RScrollUV;
			fixed RScrollX;
         	fixed RScrollY;

			fixed2 GScrollUV;
			fixed GScrollX;
         	fixed GScrollY;

			fixed2 BScrollUV;
			fixed BScrollX;
         	fixed BScrollY;

			float4 pos : SV_POSITION;
			float4 scrPos:TEXCOORD1;

			fixed4 color : COLOR;
		};


		//ZDEPTH TEST PARAMETERS
		uniform sampler2D _CameraDepthTexture;
		float _DepthSize;

		//SCROLLING PARAMETERS
		fixed _RScrollXSpeed, _RScrollYSpeed;
		fixed _GScrollXSpeed, _GScrollYSpeed;
		fixed _BScrollXSpeed, _BScrollYSpeed;

		//WATER PARAMETERS
		sampler2D _RWaterNormal, _RWaterHeight;
		sampler2D _GWaterNormal, _GWaterHeight;
		sampler2D _BWaterNormal, _BWaterHeight;

		//FLOW MAP
		sampler2D _FlowMap;
		float _FlowDeformation;

		//SCALE TRANSFORM PARAMETERS
		float4 _RWaterNormal_ST;
		float4 _GWaterNormal_ST;
		float4 _BWaterNormal_ST;

		//BASE WATER PARAMETERS
		fixed4 _WaterColor;
		float _WaveHeight;
		
		//TEMPORARY VALUE
		float4 temp_RScrollUV, temp_GScrollUV, temp_BScrollUV;
		float temp_RScrollX, temp_GScrollX, temp_BScrollX;
		float temp_RScrollY, temp_GScrollY, temp_BScrollY;
		
		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)

		void vert(inout appdata_full v, out Input o)
		{
			//ENABLE INPUT SAVE IN VERTEX
			UNITY_INITIALIZE_OUTPUT(Input, o);

#if FLOW_MAP
			// float4 flowMap = tex2Dlod(_FlowMap, float4(v.texcoord.xy ,0, 0));
			// float2 flowDeform = ((flowMap * _FlowDeformation) + (v.texcoord.xy * (1-_FlowDeformation)));

			//DEFORM MAP
			float4 flowMap = tex2Dlod(_FlowMap, float4(v.texcoord.xy ,0, 0));
			float2 flowDeform = (flowMap * _FlowDeformation) + v.texcoord.xy;

			//GENERATING SCROLLING UV
			temp_RScrollUV = fixed4 (TRANSFORM_TEX (flowDeform, _RWaterNormal), 0, 0);
			temp_RScrollX = _RScrollXSpeed * _Time;
         	temp_RScrollY = _RScrollYSpeed * _Time;
			temp_RScrollUV += fixed4(temp_RScrollX, temp_RScrollY, 1, 1);

			temp_GScrollUV = fixed4 (TRANSFORM_TEX (flowDeform, _GWaterNormal), 0, 0);
			temp_GScrollX = _GScrollXSpeed * _Time;
         	temp_GScrollY = _GScrollYSpeed * _Time;
			temp_GScrollUV += fixed4(temp_GScrollX, temp_GScrollY, 1, 1);

			temp_BScrollUV = fixed4 (TRANSFORM_TEX (flowDeform, _BWaterNormal), 0, 0);
			temp_BScrollX = _BScrollXSpeed * _Time;
         	temp_BScrollY = _BScrollYSpeed * _Time;
			temp_BScrollUV += fixed4(temp_BScrollX, temp_BScrollY, 1, 1);
		
#else
			//GENERATING SCROLLING UV
			temp_RScrollUV = fixed4 (TRANSFORM_TEX (v.texcoord.xy, _RWaterNormal), 0, 0);
			temp_RScrollX = _RScrollXSpeed * _Time;
			temp_RScrollY = _RScrollYSpeed * _Time;
			temp_RScrollUV += fixed4(temp_RScrollX, temp_RScrollY, 1, 1);

			temp_GScrollUV = fixed4 (TRANSFORM_TEX (v.texcoord.xy, _GWaterNormal), 0, 0);
			temp_GScrollX = _GScrollXSpeed * _Time;
			temp_GScrollY = _GScrollYSpeed * _Time;
			temp_GScrollUV += fixed4(temp_GScrollX, temp_GScrollY, 1, 1);

			temp_BScrollUV = fixed4 (TRANSFORM_TEX (v.texcoord.xy, _BWaterNormal), 0, 0);
			temp_BScrollX = _BScrollXSpeed * _Time;
			temp_BScrollY = _BScrollYSpeed * _Time;
			temp_BScrollUV += fixed4(temp_BScrollX, temp_BScrollY, 1, 1);
#endif
			//HEIGHT BLEND
			fixed4 RWaterHeight = tex2Dlod(_RWaterHeight, temp_RScrollUV);
			fixed4 GWaterHeight = tex2Dlod(_GWaterHeight, temp_GScrollUV);
			fixed4 BWaterHeight = tex2Dlod(_BWaterHeight, temp_BScrollUV);

			fixed4 RGLerp = lerp(RWaterHeight, GWaterHeight, v.color.g);
			fixed4 RGBLerp = lerp(RGLerp, BWaterHeight, v.color.b);
			fixed4 RGBGLerp = lerp(RGBLerp, RWaterHeight, v.color.r);

			float4 HeightMask = RGBGLerp;
			v.vertex.y -= _WaveHeight * HeightMask;

			//SAVE SCROLLED UV PARAMETERS
			o.RScrollUV = temp_RScrollUV;
			o.RScrollX = temp_RScrollX;
			o.RScrollY = temp_RScrollY;

			o.GScrollUV = temp_GScrollUV;
			o.GScrollX = temp_GScrollX;
			o.GScrollY = temp_GScrollY;

			o.BScrollUV = temp_BScrollUV;
			o.BScrollX = temp_BScrollX;
			o.BScrollY = temp_BScrollY;

			//SAVING ZDEPTH PARAMETERS
			o.pos = UnityObjectToClipPos (v.vertex);
			o.scrPos = ComputeScreenPos(o.pos);
			o.scrPos.y = o.scrPos.y;
		}

		void surf (Input IN, inout SurfaceOutputStandard o) 
		{
			//VERTEX COLOR BLEND
			fixed4 RWater = tex2D(_RWaterNormal, IN.RScrollUV);
			fixed4 GWater = tex2D(_GWaterNormal, IN.GScrollUV);
			fixed4 BWater = tex2D(_BWaterNormal, IN.BScrollUV);

			fixed4 RGLerp = lerp(RWater, GWater, IN.color.g);
			fixed4 RGBLerp = lerp(RGLerp, BWater, IN.color.b);
			fixed4 RGBGLerp = lerp(RGBLerp, RWater, IN.color.r);

			fixed4 c = _WaterColor;
			fixed4 normal = RGBGLerp;

			float depthValue = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.scrPos)));
			float rim = saturate(1 - (depthValue - IN.scrPos.w) * (1 - _DepthSize) / 0.2);

			
			o.Albedo = c.rgb * (1-rim);
			o.Smoothness = 0.8;
			o.Normal = normal;
			o.Alpha = 1 - rim;
			o.Metallic = 0;
		}
		ENDCG
	}
	FallBack "Diffuse"
	CustomEditor "WaterShaderEditor"
}
