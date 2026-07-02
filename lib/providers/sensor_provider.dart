import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

final sensorProvider = StreamProvider<double>((ref) {
  return accelerometerEventStream().map((event) {
    // Calculate tilt angle in radians
    // event.x is the tilt along the horizontal axis
    // event.y is the tilt along the vertical axis
    double angle = atan2(event.x, event.y);
    // Convert to degrees and normalize
    double degrees = angle * 180 / pi;
    
    // We want 0 to be level (when phone is portrait, y is ~9.8, x is ~0)
    // Adjust based on device orientation if necessary, but simple x/y atan2 works for basic horizon.
    return degrees;
  });
});

final horizonLevelProvider = Provider<bool>((ref) {
  final angle = ref.watch(sensorProvider).value ?? 0.0;
  // If angle is close to 90 or -90 (landscape) or 0 (portrait), it's level.
  // Assuming portrait-first app:
  return angle.abs() < 2.0; 
});
