import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Centralized animation configuration for the AI Camera Coach app.
/// All animation durations, delays, and curves are defined here for consistency.
class AppAnimations {
  // ========== Duration Constants ==========
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration extraSlow = Duration(milliseconds: 800);

  // ========== Delay Constants ==========
  static const Duration noDelay = Duration.zero;
  static const Duration staggerFast = Duration(milliseconds: 50);
  static const Duration staggerNormal = Duration(milliseconds: 100);
  static const Duration staggerSlow = Duration(milliseconds: 200);

  // ========== Curve Constants ==========
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeOutBack = Curves.easeOutBack;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve bounceOut = Curves.bounceOut;

  // ========== Pre-built Effect Chains ==========

  /// Fade in + slide up for elements entering from below
  static List<Effect> fadeInSlideUp({Duration? delay}) => [
    FadeEffect(duration: normal, delay: delay ?? noDelay, curve: easeOut),
    SlideEffect(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
      duration: normal,
      delay: delay ?? noDelay,
      curve: easeOutCubic,
    ),
  ];

  /// Fade in + scale for elements that should pop in
  static List<Effect> fadeInScale({Duration? delay, double beginScale = 0.8}) => [
    FadeEffect(duration: normal, delay: delay ?? noDelay, curve: easeOut),
    ScaleEffect(
      begin: Offset(beginScale, beginScale),
      end: const Offset(1, 1),
      duration: normal,
      delay: delay ?? noDelay,
      curve: elasticOut,
    ),
  ];

  /// Slide in from left
  static List<Effect> slideInLeft({Duration? delay}) => [
    SlideEffect(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
      duration: normal,
      delay: delay ?? noDelay,
      curve: easeOutCubic,
    ),
    FadeEffect(duration: fast, delay: delay ?? noDelay, curve: easeOut),
  ];

  /// Slide in from right
  static List<Effect> slideInRight({Duration? delay}) => [
    SlideEffect(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
      duration: normal,
      delay: delay ?? noDelay,
      curve: easeOutCubic,
    ),
    FadeEffect(duration: fast, delay: delay ?? noDelay, curve: easeOut),
  ];

  /// Pulse effect for attention
  static List<Effect> pulse({Duration? delay}) => [
    ScaleEffect(
      begin: const Offset(1, 1),
      end: const Offset(1.05, 1.05),
      duration: slow,
      delay: delay ?? noDelay,
      curve: easeInOut,
    ),
    ScaleEffect(
      begin: const Offset(1.05, 1.05),
      end: const Offset(1, 1),
      duration: slow,
      curve: easeInOut,
    ),
  ];

  /// Shimmer loading effect
  static List<Effect> shimmer({Duration? delay}) => [
    ShimmerEffect(
      duration: const Duration(milliseconds: 1500),
      delay: delay ?? noDelay,
      curve: easeInOut,
    ),
  ];

  /// Glow pulse for frame found / success states
  static List<Effect> glowPulse({Duration? delay}) => [
    TintEffect(
      color: Color(0xFF00FFCC),
      begin: 0,
      end: 0.5,
      duration: slow,
      delay: delay ?? noDelay,
      curve: easeInOut,
    ),
    TintEffect(
      color: Color(0xFF00FFCC),
      begin: 0.5,
      end: 0,
      duration: slow,
      curve: easeInOut,
    ),
  ];

  /// Staggered entrance for a list of items
  static List<Effect> staggeredEntrance(int index, {Duration baseDelay = staggerNormal}) => [
    FadeEffect(duration: normal, delay: baseDelay * index, curve: easeOut),
    SlideEffect(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
      duration: normal,
      delay: baseDelay * index,
      curve: easeOutCubic,
    ),
  ];

  /// Button press micro-interaction
  static List<Effect> buttonPress() => [
    ScaleEffect(
      begin: const Offset(1, 1),
      end: const Offset(0.92, 0.92),
      duration: fast,
      curve: easeOut,
    ),
    ScaleEffect(
      begin: const Offset(0.92, 0.92),
      end: const Offset(1, 1),
      duration: fast,
      curve: elasticOut,
    ),
  ];
}