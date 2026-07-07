# TODO

## Refine live camera UI (zoom pills, bottom controls, AI target marker)

- [ ] Update `lib/ui/widgets/zoom_controls.dart` to show only 1x / 2x / 3x pill buttons (remove 0.5 and zoom icon), matching screenshot pill styling.
- [ ] Update `lib/ui/widgets/overlay_painter.dart` to render AI aim/marker for `frameFound` and `almostThere` in **white** (goal ring + guide line + pulse), while keeping framed/editing behavior.
- [ ] Adjust `lib/ui/widgets/camera_bottom_controls.dart` bottom control row layout/visibility to match screenshot (grid/aspect row + preview controls, spacing, icon states).
- [x] Run `flutter analyze` and fix any formatting/lint errors.

- [ ] Smoke test camera screen: zoom pills work; bottom controls layout matches; AI marker visible and white; tap-to-brightness indicator present.

