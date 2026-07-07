import 'dart:math';
import 'package:flutter/material.dart';

/// Low-pass filter with exponential smoothing.
class LowPassFilter {
  double _prevRawValue = 0.0;
  double _prevFilteredValue = 0.0;
  bool _isFirst = true;

  double smooth(double value, double alpha) {
    if (_isFirst) {
      _prevRawValue = value;
      _prevFilteredValue = value;
      _isFirst = false;
      return value;
    }
    _prevRawValue = value;
    _prevFilteredValue =
        _prevFilteredValue + alpha * (value - _prevFilteredValue);
    return _prevFilteredValue;
  }

  double get prevRawValue => _prevRawValue;
  double get prevFilteredValue => _prevFilteredValue;

  void reset() {
    _prevRawValue = 0.0;
    _prevFilteredValue = 0.0;
    _isFirst = true;
  }
}

/// One Euro Filter – a low-pass filter with adaptive cutoff frequency.
///
/// Based on the paper:
/// "1€ Filter" by Géry Casiez, Nicolas Roussel, and Daniel Vogel (CHI 2012).
///
/// At low velocity, cutoff is low for smoothness.
/// At high velocity, cutoff increases to reduce lag.
class OneEuroFilter {
  final LowPassFilter _xf;
  final LowPassFilter _dxf;
  final double _minCutoff;
  final double _beta;
  final double _dCutoff;

  OneEuroFilter({
    double minCutoff = 1.0,
    double beta = 0.007,
    double dCutoff = 1.0,
  }) : _xf = LowPassFilter(),
       _dxf = LowPassFilter(),
       _minCutoff = minCutoff,
       _beta = beta,
       _dCutoff = dCutoff;

  double smooth(double value, double dt) {
    // Avoid division by zero
    dt = max(dt, 1 / 1000);

    // Estimate derivative
    double dx = (value - _xf.prevFilteredValue) / dt;
    double edx = _dxf.smooth(dx, _alphaForCutoff(_dCutoff, dt));

    // Adaptive cutoff
    double cutoff = _minCutoff + _beta * edx.abs();

    // Smooth
    return _xf.smooth(value, _alphaForCutoff(cutoff, dt));
  }

  double _alphaForCutoff(double cutoff, double dt) {
    double tau = 1.0 / (2.0 * pi * cutoff);
    double alpha = 1.0 / (1.0 + tau / dt);
    return alpha;
  }

  void reset() {
    _xf.reset();
    _dxf.reset();
  }
}

/// Helper to smooth an Offset (x, y) using two independent OneEuroFilters.
class OffsetFilter {
  final OneEuroFilter _xFilter = OneEuroFilter(minCutoff: 0.2, beta: 0.001);
  final OneEuroFilter _yFilter = OneEuroFilter(minCutoff: 0.2, beta: 0.001);

  Offset smooth(Offset value, double dt) {
    return Offset(_xFilter.smooth(value.dx, dt), _yFilter.smooth(value.dy, dt));
  }

  void reset() {
    _xFilter.reset();
    _yFilter.reset();
  }
}

/// Helper to smooth a Rect (left, top, right, bottom) using four independent OneEuroFilters.
class RectFilter {
  final OneEuroFilter _lFilter = OneEuroFilter(minCutoff: 0.2, beta: 0.001);
  final OneEuroFilter _tFilter = OneEuroFilter(minCutoff: 0.2, beta: 0.001);
  final OneEuroFilter _rFilter = OneEuroFilter(minCutoff: 0.2, beta: 0.001);
  final OneEuroFilter _bFilter = OneEuroFilter(minCutoff: 0.2, beta: 0.001);

  Rect smooth(Rect value, double dt) {
    return Rect.fromLTRB(
      _lFilter.smooth(value.left, dt),
      _tFilter.smooth(value.top, dt),
      _rFilter.smooth(value.right, dt),
      _bFilter.smooth(value.bottom, dt),
    );
  }

  void reset() {
    _lFilter.reset();
    _tFilter.reset();
    _rFilter.reset();
    _bFilter.reset();
  }
}
