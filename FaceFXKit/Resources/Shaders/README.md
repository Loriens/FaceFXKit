# Metal Shader Compilation Instructions

The filter system now uses compiled Metal libraries (.ci.metallib) for optimal performance.

## Compilation Steps

To compile the Metal shaders into .ci.metallib files, run these commands in the terminal:

```bash
# Navigate to the Shaders directory
cd FaceFXKit/Resources/Shaders/

# Compile HeadShrinkResize shader
xcrun metal -c HeadShrinkResize.metal -o HeadShrinkResize.air
xcrun metallib HeadShrinkResize.air -o HeadShrinkResizeFilter.ci.metallib

# Compile HeadPerspectiveResize shader  
xcrun metal -c HeadPerspectiveResize.metal -o HeadPerspectiveResize.air
xcrun metallib HeadPerspectiveResize.air -o HeadPerspectiveResizeFilter.ci.metallib

# Compile HairColor shader
xcrun metal -c HairColorFilter.ci.metal -o HairColorFilter.air
xcrun metallib HairColorFilter.air -o HairColorFilter.ci.metallib

# Compile EyesResize shader
xcrun metal -c EyesResize.metal -o EyesResize.air  
xcrun metallib EyesResize.air -o EyesResizeFilter.ci.metallib

# Clean up intermediate files
rm *.air
```

## Add to Xcode Project

After compilation, add the .ci.metallib files to your Xcode project:

1. Right-click on Resources/Shaders in Xcode
2. Select "Add Files to FaceFXKit"
3. Add all three .ci.metallib files
4. Ensure they are added to the app target

## File Structure

```
Resources/Shaders/
├── HeadShrinkResize.metal              (Source)
├── HeadShrinkResizeFilter.ci.metallib  (Compiled)
├── HeadPerspectiveResize.metal         (Source) 
├── HeadPerspectiveResizeFilter.ci.metallib (Compiled)
├── HairColorFilter.ci.metal            (Source)
├── HairColorFilter.ci.metallib         (Compiled)
├── EyesResize.metal                    (Source)
└── EyesResizeFilter.ci.metallib        (Compiled)
```

## Shader Details

### HairColorFilter.ci.metal

This shader implements a CIColorKernel for applying hair colors with mask blending. It takes:

- `originalImage`: The source image
- `hairMask`: Grayscale mask where white pixels represent hair areas
- `targetColor`: RGB color to apply to hair (0.0-1.0 range)
- `intensity`: Blending intensity (0.0-1.0)
- `blendMode`: Color blending mode (0.0-1.0):
  - 0.0-0.33: Hue replacement (keeps original saturation and brightness)
  - 0.33-0.66: Full color replacement with brightness preservation
  - 0.66-1.0: Full target color replacement

The shader converts colors to HSV space for better color manipulation and supports smooth mask blending for natural-looking hair color changes.

## Benefits

- **Pre-compiled shaders** - No runtime compilation overhead
- **Optimized performance** - Metal compiler optimizations applied
- **Smaller binary size** - Only compiled code in app bundle
- **Faster app launch** - No shader compilation at startup
