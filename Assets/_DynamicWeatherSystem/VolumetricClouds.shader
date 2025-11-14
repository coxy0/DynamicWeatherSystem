Shader "Custom/VolumetricClouds"
{
    Properties
    {
        _CloudOffset ("Cloud Offset", Vector) = (0, 0, 0)
        _CloudScale ("Cloud Scale", Float) = 1.0
        _DensityThreshold ("Density Threshold", Float) = 0.5
        _DensityMultiplier ("Density Multiplier", Float) = 5.0
        _NumSteps ("Number of Steps", Int) = 64
        _ShapeNoise ("Shape Noise", 3D) = "white" {}
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
            float3 _CloudOffset;
            float _CloudScale;
            float _DensityThreshold;
            float _DensityMultiplier;
            int _NumSteps;
            Texture2D<float4> _ShapeNoise;
            SamplerState sampler_ShapeNoise;

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

            float sampleDensity(float3 position)
            {
                float uvw = position * _CloudScale * 0.001 + _CloudOffset * 0.01;
                float4 shape = _ShapeNoise.SampleLevel(sampler_ShapeNoise, uvw, 0);
                float density = max(0, shape.r - _DensityThreshold) * _DensityMultiplier;
                return density;
            }

            float4 frag(Varyings input) : SV_Target
            {
                float4 colour = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord);

                float depth = SampleSceneDepth(input.texcoord);
                float3 worldPos = ComputeWorldSpacePosition(input.texcoord, depth, UNITY_MATRIX_I_VP);

                float3 ro = _WorldSpaceCameraPos;
                float3 rd = normalize(worldPos - _WorldSpaceCameraPos);

                float2 rayBoxInfo = rayBoxDst(_BoundsMin, _BoundsMax, ro, rd);
                float dstToBox = rayBoxInfo.x;
                float dstInsideBox = rayBoxInfo.y;

                float dstToWorldPos = distance(worldPos, ro);
                // bool rayHitBox = dstInsideBox > 0 && dstToBox < distance(worldPos, ro);
                // if (rayHitBox) colour = 0;

                // return colour;

                float dstTravelled = 0;
                float stepSize = dstInsideBox / _NumSteps;
                float dstLimit = min(dstToWorldPos - dstToBox, dstInsideBox);

                float totalDensity = 0;
                while (dstTravelled < dstLimit) {
                    float3 p = ro + rd * (dstToBox + dstTravelled);
                    totalDensity += sampleDensity(p) * stepSize;
                    dstTravelled += stepSize;
                }

                float transmittance = exp(-totalDensity);
                return colour * transmittance;
            }
            ENDHLSL
        }
    }
}
