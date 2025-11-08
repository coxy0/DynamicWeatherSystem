Shader "Custom/VolumetricClouds"
{
    Properties
    {
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/RunTime/Utilities/Blit.hlsl"

            float4 _BoundsMin;
            float4 _BoundsMax;

            float2 rayBoxDst(float3 boundsMin, float3 boundsMax, float3 ro, float3 rd)
            {
                float3 t0 = (boundsMin - ro) / rd;
                float3 t1 = (boundsMax - ro) / rd;
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);

                float dstA = max(max(tmin.x, tmin.y), tmin.z);
                float dstB = min(tmax.x, min(tmax.y, tmax.z));

                float dstToBox = max(0, dstA);
                float dstInsideBox = max(0, dstB - dstToBox);
                return float2(dstToBox, dstInsideBox);
            }

            float4 frag(Varyings input) : SV_Target
            {
                // half4 colour = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord);

                float4 colour = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord);

                float depth = SampleSceneDepth(input.texcoord);
                float3 worldPos = ComputeWorldSpacePosition(input.texcoord, depth, UNITY_MATRIX_I_VP);
                float3 ro = _WorldSpaceCameraPos;
                float3 rd = normalize(worldPos - _WorldSpaceCameraPos);

                float2 rayBoxInfo = rayBoxDst(_BoundsMin, _BoundsMax, ro, rd);
                float dstToBox = rayBoxInfo.x;
                float dstInsideBox = rayBoxInfo.y;
                bool rayHitBox = dstInsideBox > 0;
                if (!rayHitBox) colour = 0;

                return colour;
            }
            ENDHLSL
        }
    }
}
