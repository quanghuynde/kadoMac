# Animation Patterns Guide - flutter_animate

## 📋 Quick Start

```dart
import 'package:project/utils/animation_config.dart';

// All animations use centralized config
Widget.animate().fadeIn(
  duration: AppAnimations.normal,
  curve: AppAnimations.easeOut,
);
```

## 🎯 Core Principles

1. **Use flutter_animate extensions for declarative animations**
2. **Keep AnimationController for complex interactive animations**
3. **Always use AppAnimations constants** - never hardcode durations
4. **Respect reduced motion preferences** when possible

---

## 📦 Centralized Configuration

All animation constants are defined in `animation_config.dart`:

```dart
class AppAnimations {
  // Durations
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 350);
  static const slow = Duration(milliseconds: 500);
  static const extraSlow = Duration(milliseconds: 800);

  // Delays
  static const noDelay = Duration.zero;
  static const staggerFast = Duration(milliseconds: 50);
  static const staggerNormal = Duration(milliseconds: 100);
  static const staggerSlow = Duration(milliseconds: 200);

  // Curves
  static const easeOut = Curves.easeOut;
  static const easeInOut = Curves.easeInOut;
  static const easeOutCubic = Curves.easeOutCubic;
  static const easeOutBack = Curves.easeOutBack;
  static const elasticOut = Curves.elasticOut;
  static const bounceOut = Curves.bounceOut;
}
```

---

## 🎨 Common Animation Patterns

### 1. Button Press Micro-interaction

**Use case**: All tappable buttons throughout the app

```dart
class _ButtonState extends State<Button> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        // ... button content
      ).animate().scaleXY(
        begin: _isPressed ? 1.0 : 0.92,
        end: _isPressed ? 0.92 : 1.0,
        duration: AppAnimations.fast,
        curve: AppAnimations.easeOutCubic,
      ),
    );
  }
}
```

**Files using this pattern**:
- `zoom_controls.dart` ✅
- `controls_widget.dart` ✅ (Flash, AI, Capture, Gallery buttons)
- `camera_screen.dart` ✅ (Back, Settings buttons)

---

### 2. Staggered Entrance Animation

**Use case**: Lists, grids, sequential items appearing

```dart
// Option 1: Manual stagger
ListView.builder(
  itemBuilder: (context, index) {
    return ItemWidget()
      .animate()
      .fadeIn(
        duration: AppAnimations.normal,
        delay: AppAnimations.staggerSlow + (AppAnimations.staggerNormal * index),
      )
      .slideX(
        begin: -0.2,
        end: 0,
        curve: AppAnimations.easeOutCubic,
      );
  },
)

// Option 2: Using helper from animation_config.dart
ItemWidget().animate().apply(
  effects: AppAnimations.staggeredEntrance(index),
)
```

**Files using this pattern**:
- `profile_screen.dart` - History list items ✅
- `controls_widget.dart` - Bottom control buttons ✅

---

### 3. Panel Slide Up

**Use case**: Edit panels, modals, bottom sheets

```dart
EditPanel(...)
  .animate()
  .slideY(
    begin: 1, // Start below screen
    end: 0,   // Slide to final position
    duration: AppAnimations.slow,
    curve: AppAnimations.easeOutCubic,
  )
  .fadeIn(
    duration: AppAnimations.normal,
    curve: AppAnimations.easeOut,
  )
```

**Files using this pattern**:
- `camera_screen.dart` - EditPanel slide up ✅
- `edit_panel.dart` - Individual sliders/labels

---

### 4. Fade + Scale Pop

**Use case**: Important elements that need attention (capture button, score)

```dart
Widget.animate()
  .fadeIn(
    duration: AppAnimations.normal,
    delay: AppAnimations.staggerSlow,
    curve: AppAnimations.easeOut,
  )
  .scaleXY(
    begin: 0.6,
    end: 1,
    duration: AppAnimations.slow,
    curve: AppAnimations.elasticOut, // Bouncy effect
  )
```

**Files using this pattern**:
- `controls_widget.dart` - Capture button ✅
- `profile_screen.dart` - Stats card ✅

---

### 5. Loading Shimmer Effect

**Use case**: AI analysis loading, image processing

```dart
Container(
  color: Colors.white10,
  child: Text('Analyzing...'),
).animate().shimmer(
  duration: const Duration(milliseconds: 1500),
  curve: Curves.easeInOut,
)
```

---

### 6. Score Counter Animation

**Use case**: Animated number counting up (scores, stats)

```dart
// Keep using AnimatedBuilder for precise value interpolation
AnimatedBuilder(
  animation: _scoreAnimation,
  builder: (ctx, _) {
    return Text(
      '${(_scoreAnimation.value * targetScore).toInt()}%',
      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    );
  },
)
```

**Files using this pattern**:
- `result_screen.dart` - Score display ✅
- `profile_screen.dart` - Stats counter ✅

**Why AnimatedBuilder?**
- Precise control over value interpolation
- No need to rebuild entire widget tree
- Cleaner for numeric values that change frequently

---

### 7. Scanning/Pulsing Animation

**Use case**: AI scanning, loading indicators

```dart
@override
Widget build(BuildContext context) {
  return Icon(Icons.hourglass_empty)
    .animate(onPlay: (controller) => controller.repeat(reverse: true))
    .fadeIn(
      duration: AppAnimations.normal,
      curve: AppAnimations.easeInOut,
    )
    .scaleXY(
      begin: 0.9,
      end: 1.1,
      duration: AppAnimations.slow,
      curve: AppAnimations.easeInOut,
    );
}
```

**Files using this pattern**:
- `guidance_overlay.dart` - Status icon pulse/rotate ✅

---

### 8. Status Bar Entrance

**Use case**: Notification banners, status indicators

```dart
Widget.animate()
  .fadeIn(
    duration: AppAnimations.normal,
    curve: AppAnimations.easeOut,
  )
  .slideY(
    begin: -0.5, // Slide from top
    end: 0,
    curve: AppAnimations.easeOutCubic,
  )
```

**Files using this pattern**:
- `guidance_overlay.dart` - AI status bar ✅
- `camera_screen.dart` - Top bar ✅

---

## 🏗️ When to Use What

| Pattern | Use Case | Tool |
|---------|----------|------|
| Entrance animations | Initial load, list items, panels | `animate().fadeIn().slideY()` |
| Button press | All tappable UI | `GestureDetector` + `animate().scaleXY()` |
| State changes | Toggles, selection | `AnimatedContainer` for multi-property |
| Loading/Analysis | AI processing | `AnimatedBuilder` + `CircularProgressIndicator` |
| Score/Stats | Numeric counter | `AnimatedBuilder` + `AnimationController` |
| Attention/Pulse | Active scanning, notifications | `.animate().repeat()` |

---

## ⚡ Performance Best Practices

### ✅ DO:
```dart
// Use const widgets for static content
const Icon(Icons.camera, size: 24)

// RepaintBoundary for heavy animations
RepaintBoundary(
  child: AnimatedWidget(...),
)

// Dispose controllers properly
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

### ❌ DON'T:
```dart
// Don't animate too many widgets simultaneously (>10)
// Don't animate large images or complex paths
// Don't use duration > 800ms for micro-interactions
// Don't forget to check MediaQuery.disableAnimations
```

---

## ♿ Accessibility

```dart
// Check if user prefers reduced motion
final prefersReducedMotion = MediaQuery.of(context).disableAnimations;

if (!prefersReducedMotion) {
  return Widget.animate().fadeIn(...);
} else {
  return Widget; // No animation
}
```

---

## 📁 File Structure

```
lib/
├── utils/
│   ├── animation_config.dart      # Centralized config
│   └── ANIMATION_GUIDE.md         # This file
├── ui/
│   ├── camera_screen.dart         # Main camera with animations
│   ├── result_screen.dart         # Score counter with AnimatedBuilder
│   ├── profile_screen.dart        # Stats with staggered list
│   └── widgets/
│       ├── controls_widget.dart   # Button press effects
│       ├── zoom_controls.dart     # Scale button press
│       ├── guidance_overlay.dart  # Status bar animations
│       └── edit_panel.dart        # Panel slide effects
```

---

## 🔧 Implementation Checklist

When adding new animations:

- [ ] Import `animation_config.dart`
- [ ] Use `AppAnimations` constants (no magic numbers)
- [ ] Add button press effects for new buttons
- [ ] Add stagger delays for list items
- [ ] Test on low-end device (performance)
- [ ] Check reduced motion accessibility
- [ ] Dispose AnimationController in `dispose()`

---

## 📊 Current Coverage

| Screen/Widget | Animations | Status |
|---------------|------------|--------|
| CameraScreen | Entrance, TopBar, Zoom, EditPanel | ✅ |
| ControlsWidget | Staggered entrance, Button press | ✅ |
| ZoomControls | Scale on press | ✅ |
| GuidanceOverlay | Scanning ring, Status bar | ✅ |
| ResultScreen | Score counter, Staggered metrics | ✅ |
| ProfileScreen | Stats card, History list | ✅ |
| EditPanel | Slide up, Staggered children | ✅ |

**Total**: 8/8 major screens/widgets have animations ✅

---

## 🚀 Next Steps

Potential enhancements (not yet implemented):
- Shimmer loading for AI analysis states
- Haptic feedback integration on button press
- Swipe gestures with slide effects in PhotoPreview
- Confetti effect on high scores (90%+)
- Transition animations between screens