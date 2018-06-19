Shader "sTools/Stylized Water" 
{
	Properties 
	{
		_DepthSize ("Depth Size", range(0.1, 0.9)) = 0.5
		_WaterColor ("Water Color", Color) = (0,0,0,1)
		_WaterTex ("Water Texture", 2D) = "white" {}
		_RimColor ("Rim Color", Color) = (0,0,0,0)
		_RimAtten ("Rim Attenuation", range(1,10)) = 1
		_RimTex ("Rim Texture", 2D) = "white" {}
	}
	SubShader 
	{
		Tags { "RenderType"="Opaque" "Queue"="Transparent" }
		ZWrite off

		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows 
		#pragma target 3.0

		//ZDEPTH PARAMETERS
		sampler2D _CameraDepthTexture;
		float _DepthSize;
		float _RimAtten;

		//WATER
		sampler2D _WaterTex, _RimTex;
		float4 _WaterColor, _RimColor;

		struct Input 
		{
			float4 screenPos;
			float2 uv_WaterTex;
			float2 uv_RimTex;
		};

		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf (Input IN, inout SurfaceOutputStandard o)  
		{
			//ZDEPTH
			float depthValue = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos)));
			float zMask = saturate((1 - (depthValue - IN.screenPos.w) * (1 - _DepthSize) / 0.2));
			float zMaskAtten = pow(saturate((1 - (depthValue - IN.screenPos.w) * (1 - _DepthSize) / 0.2)), _RimAtten);

			float4 rim = tex2D(_RimTex, IN.uv_RimTex) * zMask;
			float4 rimColor = (zMask * _RimColor);
			float4 rimLerp = lerp(rimColor, _WaterColor, (1-zMask)) * zMaskAtten;

			float4 water = (tex2D(_WaterTex, IN.uv_WaterTex) * _WaterColor) * (1-zMask);
			float4 color = rim + rimLerp + water;
			o.Albedo = color;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
