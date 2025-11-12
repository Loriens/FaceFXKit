//
//  HeadSize.metal
//  FaceFXKit
//
//  Created by Vladislav Markov on 23/08/2025.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

extern "C" {
    namespace coreimage {
        
        /**
         * Head Size Filter
         *
         * Creates a perspective distortion effect, simulating the head becoming larger or smaller.
         *
         * @param center             The center of the ellipse defining the area of effect
         * @param radiusA           Horizontal radius of an ellipse
         * @param radiusB           Vertical radius of an ellipse
         * @param value               Сила искажения (положительные значения увеличивают, отрицательные уменьшают)
         * @param headAngle      The angle of rotation of an ellipse in radians
         * @param dest                 Destination pixel coordinates
         */
        float2 headSize(float2 center,
                                   float radiusA,
                                   float radiusB,
                                   float value,
                                   float headAngle,
                                   destination dest) {
            const float2 destCoord = dest.coord();

            if (radiusA <= 0.0 || radiusB <= 0.0) {
                return destCoord;
            }
            
            // Rotation data
            const float cosTheta = cos(-headAngle);
            const float sinTheta = sin(-headAngle);

            // Rotated coordinates of the center
            const float2 rotatedCenter = float2(
                center.x * cosTheta - center.y * sinTheta,
                center.y * cosTheta + center.x * sinTheta
            );

            // Rotated coordinates of the current point
            const float2 rotatedDest = float2(
                destCoord.x * cosTheta - destCoord.y * sinTheta,
                destCoord.y * cosTheta + destCoord.x * sinTheta
            );
            
            // Calculating the angle of a point relative to the center of an ellipse
            const float2 deltaRotated = rotatedDest - rotatedCenter;
            float cosPhi, sinPhi;

            const float distanceFromCenter = distance(center, destCoord);

            if (distanceFromCenter > 0.0) {
                cosPhi = deltaRotated.x / distanceFromCenter;
                sinPhi = deltaRotated.y / distanceFromCenter;
            } else {
                cosPhi = 0.0;
                sinPhi = 0.0;
            }
            
            // Calculating the radius of an ellipse in the direction of a point
            const float denominator = sqrt(pow(radiusB * cosPhi, 2.0) + pow(radiusA * sinPhi, 2.0));
            const float ellipseRadius = (denominator > 0.0)
                ? (radiusA * radiusB) / denominator
                : max(radiusA, radiusB);

            // Apply distortion if point is inside ellipse
            if (distanceFromCenter <= ellipseRadius) {
                const float2 destCoordFromCenter = destCoord - center;

                // Calculating the distortion coefficient
                const float distortionFactor = (ellipseRadius > 0.0) ?
                    1.0 - ((ellipseRadius - distanceFromCenter) / ellipseRadius) * value :
                    1.0;

                // Applying distortion to a coordinate
                const float2 transformedCoord = destCoordFromCenter * distortionFactor + center;

                return transformedCoord;
            }
            
            // If the point is outside the ellipse, return the original coordinates
            return destCoord;
        }
        
    }
}
