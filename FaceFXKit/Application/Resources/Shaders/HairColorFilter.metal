//
//  HairColorFilter.ci.metal
//  FaceFXKit
//
//  Created by Vladislav Markov on 30/07/2025.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

extern "C" {
    namespace coreimage {
        float4 hairColor(float4 pixel,
                         float3 targetColor,
                         float value) {
            float3 rgb = pixel.rgb;
            float3 finalColor = mix(rgb, targetColor, value);
            return float4(finalColor, pixel.a);
        }
    }
}
