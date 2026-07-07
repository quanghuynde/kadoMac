# Implementation Plan - Dynamic Framing & Correct Themed Results

Fix the mismatch between AI framing and capture results, implement flexible framing box sizes, and ensure themes are correctly saved.

## Proposed Changes

### 1. Dynamic Framing & Masking

#### [ai_coach_provider.dart](file:///C:/Users/ADMIN/AndroidStudioProjects/project/lib/providers/ai_coach_provider.dart)
- **Flexible Frame Size**: Instead of a fixed 240px box, calculate the target framing size based on the AI-detected `subjectBounds`.
- **Dynamic Suggested Frame**: Ensure `aiSuggestedFrame` in `AICoachState` reflects a square or appropriately aspect-ratioed box that encompasses the subject with a 20% margin.

#### [guidance_overlay.dart](file:///C:/Users/ADMIN/AndroidStudioProjects/project/lib/ui/widgets/guidance_overlay.dart)
- **Synchronized Masking**: Update the `InvertedRectClipper` and expansion logic to use the dynamic `aiSuggestedFrame` size instead of hardcoded 240px.

#### [overlay_painter.dart](file:///C:/Users/ADMIN/AndroidStudioProjects/project/lib/ui/widgets/overlay_painter.dart)
- **Expanding Flexible Box**: Adjust `_drawFramingBox` to expand from a small point to the dynamic subject-based frame size.

### 2. Precise Capture Processing

#### [camera_bottom_controls.dart](file:///C:/Users/ADMIN/AndroidStudioProjects/project/lib/ui/widgets/camera_bottom_controls.dart)
- **Accurate Crop Data**: Pass the *exact* Rect used for the framing box (translated to image coordinates) to `ImageCropService`.
- **Theme Application**: Ensure the `FilterPreset` color matrix is applied to the image bytes *before* saving.

#### [image_crop_service.dart](file:///C:/Users/ADMIN/AndroidStudioProjects/project/lib/services/image_crop_service.dart)
- **Fixed `applyFilterAndCrop`**: Ensure the crop Rect is correctly mapped to the high-res image pixels, regardless of screen aspect ratio.

### 3. UI & Localization Refinement

#### [camera_bottom_controls.dart](file:///C:/Users/ADMIN/AndroidStudioProjects/project/lib/ui/widgets/camera_bottom_controls.dart)
- **Vietnamese UI**: Ensure all theme selector text is in Vietnamese.
- **Dismiss on Select**: Selecting a theme should immediately close the panel and return to the camera view.

## Verification Plan

### Manual Verification
- **Flexible Framing**: Detect a small object vs a large object. Verify the colorful framing box size changes accordingly.
- **Correct Crop**: Take a framed photo. Verify the saved result in `ResultScreen` is identical to what was seen inside the framing box.
- **Theme Save**: Select a theme, take a photo. Verify the colors in the saved image match the preview.
- **Stability**: Ensure the "sticky" center remains locked and doesn't jump during expansion.
