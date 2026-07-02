import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

final sensorProvider = StreamProvider<double>((ref) {
  return accelerometerEventStream()
      .map((event) {
        // Calculate tilt angle in radians
        double angle = atan2(event.x, event.y);
        double degrees = angle * 180 / pi;
        return degrees;
      })
      .distinct((previous, next) => (previous - next).abs() < 0.5);
});

final horizonLevelProvider = Provider<bool>((ref) {
  final angle = ref.watch(sensorProvider).value ?? 0.0;
  // If angle is close to 90 or -90 (landscape) or 0 (portrait), it's level.
  // Assuming portrait-first app:
  return angle.abs() < 2.0;
});
