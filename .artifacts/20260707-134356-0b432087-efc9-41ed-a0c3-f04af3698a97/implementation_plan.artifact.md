# Implementation Plan - Ultra-Stable Diverse AI Targets

Achieve absolute stability for AI target points while maintaining artistic diversity based on scene classification.

## Proposed Changes

### 1. Robust State Management

#### [ai_coach_provider.dart](file:///C:/Users/ADMIN/AndroidStudioProjects/project/lib/providers/ai_coach_provider.dart)
- **Hard Lock Logic**:
    - Introduce `_isTargetLocked` flag.
    - Once a target is selected (based on artistic scoring), lock it *completely*.
    - Ignore all score updates for the current subject as long as the lock is active.
- **Scene-Aware Re-Lock**:
    - Only allow a re-calculation of the target if:
        1. The primary scene category changes (e.g., from Portrait to Landscape).
        2. Detection is lost for > 2 seconds (32 frames).
        3. The user manually cancels the frame.

### 2. Artistic Composition (Diverse Targets)

#### [ai_coach_provider.dart](file:///C:/Users/ADMIN/AndroidStudioProjects/project/lib/providers/ai_coach_provider.dart)
- Integrate `SceneClassifier` to analyze the top 5 labels.
- Define a "Best Artistic Point" for each category:
    - **Portrait**: Upper 30% eye-level.
    - **Landscape**: Golden Ratio intersections.
    - **Macro**: Center-weighted spiral.
    - **Architecture**: Symmetrical vertical center.

### 3. Smooth Transitions

#### [ai_coach_provider.dart](file:///C:/Users/ADMIN/AndroidStudioProjects/project/lib/providers/ai_coach_provider.dart)
- Use a `TargetPositionFilter` (similar to One Euro Filter) to interpolate the white circle's movement only when a re-lock occurs, preventing instant jumps.

## Verification Plan

### Manual Verification
- **Stability Test**: Point at an object. The white circle should appear and **never move**, even if you tilt the phone slightly or the subject moves within the frame.
- **Diversity Test**: Verify that the "starting position" of the lock is different for a Person vs. a Mountain.
- **Reset Test**: Hide the subject for 3 seconds, then show it again. The AI should re-evaluate and lock onto a potentially new artistic point.
