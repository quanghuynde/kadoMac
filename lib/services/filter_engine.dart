import 'package:flutter/material.dart';
import 'package:project/models/filter_model.dart';

/// GPU-accelerated filter rendering engine
/// Applies color matrix filters to camera preview or captured images
class FilterEngine extends ChangeNotifier {
  static final FilterEngine instance = FilterEngine._();
  FilterEngine._();

  FilterPreset _currentFilter = FilterPreset.original;

  FilterPreset get currentFilter => _currentFilter;

  void setFilter(FilterPreset filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void reset() {
    _currentFilter = FilterPreset.original;
    notifyListeners();
  }

  /// Get ColorFilter widget for the current filter
  ColorFilter get colorFilter {
    return ColorFilter.matrix(_currentFilter.colorMatrix);
  }

  /// Get ColorFilter for a specific filter ID
  ColorFilter getFilterColorFilter(String filterId) {
    final filter = FilterPreset.all.firstWhere(
      (f) => f.id == filterId,
      orElse: () => FilterPreset.original,
    );
    return ColorFilter.matrix(filter.colorMatrix);
  }

  /// Recommend filters based on scene label
  static List<FilterPreset> recommendForScene(String sceneLabel) {
    return FilterPreset.recommendForScene(sceneLabel);
  }
}