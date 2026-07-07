import 'package:flutter/material.dart';

/// Camera filter preset model - inspired by Doka Cam
class FilterPreset {
  final String name;
  final String id;
  final Color swatchColor;
  final List<double> colorMatrix; // 4x5 color matrix for ColorFiltered

  const FilterPreset({
    required this.name,
    required this.id,
    required this.swatchColor,
    required this.colorMatrix,
  });

  static const FilterPreset original = FilterPreset(
    name: 'Original',
    id: 'original',
    swatchColor: Colors.grey,
    colorMatrix: [
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset velvia = FilterPreset(
    name: 'Velvia',
    id: 'velvia',
    swatchColor: Color(0xFFFF6B35),
    colorMatrix: [
      1.2, 0, 0, 0, 0,
      0, 1.1, 0, 0, 0,
      0, 0, 0.9, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset kodakGold = FilterPreset(
    name: 'Kodak Gold',
    id: 'kodak_gold',
    swatchColor: Color(0xFFD4A017),
    colorMatrix: [
      1.1, 0.05, 0, 0, 10,
      0, 1.0, 0, 0, 5,
      0, 0, 0.85, 0, -5,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset summerFresh = FilterPreset(
    name: 'Summer',
    id: 'summer_fresh',
    swatchColor: Color(0xFF4CAF50),
    colorMatrix: [
      1, 0, 0, 0, 0,
      0, 1.15, 0, 0, 5,
      0, 0, 1.1, 0, 10,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset softPortrait = FilterPreset(
    name: 'Portrait',
    id: 'soft_portrait',
    swatchColor: Color(0xFFE91E63),
    colorMatrix: [
      1.0, 0, 0, 0, 5,
      0, 0.95, 0, 0, 5,
      0, 0, 1.0, 0, 10,
      0, 0, 0, 0.9, 0,
    ],
  );

  static const FilterPreset noir = FilterPreset(
    name: 'Noir',
    id: 'noir',
    swatchColor: Colors.black,
    colorMatrix: [
      0.3, 0.3, 0.3, 0, 0,
      0.3, 0.3, 0.3, 0, 0,
      0.3, 0.3, 0.3, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset vividFood = FilterPreset(
    name: 'Food',
    id: 'vivid_food',
    swatchColor: Color(0xFFFF5722),
    colorMatrix: [
      1.2, 0, 0, 0, 0,
      0, 1.0, 0, 0, 0,
      0, 0, 0.8, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset coolVibes = FilterPreset(
    name: 'Cool',
    id: 'cool_vibes',
    swatchColor: Color(0xFF00BCD4),
    colorMatrix: [
      0.9, 0, 0, 0, 0,
      0, 1.0, 0, 0, 0,
      0, 0, 1.2, 0, 10,
      0, 0, 0, 1, 0,
    ],
  );

  // New Film Themes
  static const FilterPreset cc = FilterPreset(
    name: 'CC',
    id: 'cc',
    swatchColor: Color(0xFF8D6E63),
    colorMatrix: [
      1.05, 0, 0, 0, 5,
      0, 1.0, 0, 0, 0,
      0, 0, 0.95, 0, -5,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset cn = FilterPreset(
    name: 'CN',
    id: 'cn',
    swatchColor: Color(0xFF37474F),
    colorMatrix: [
      0.9, 0.1, 0, 0, 0,
      0.05, 1.0, 0.05, 0, 0,
      0, 0.1, 1.1, 0, -10,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset c160 = FilterPreset(
    name: '160C',
    id: '160c',
    swatchColor: Color(0xFFBCAAA4),
    colorMatrix: [
      1.0, 0, 0, 0, 10,
      0, 1.05, 0, 0, 5,
      0, 0, 1.0, 0, 10,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset superia100 = FilterPreset(
    name: 'Superia 100',
    id: 'superia100',
    swatchColor: Color(0xFF43A047),
    colorMatrix: [
      1.0, 0.05, 0, 0, 0,
      0.05, 1.1, 0, 0, 0,
      0, 0, 0.95, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset hh400 = FilterPreset(
    name: '400HH',
    id: '400hh',
    swatchColor: Color(0xFF689F38),
    colorMatrix: [
      1.1, 0, 0, 0, 10,
      0, 1.1, 0, 0, 5,
      0, 0, 0.9, 0, -5,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset hs400 = FilterPreset(
    name: '400HS',
    id: '400hs',
    swatchColor: Color(0xFF2E7D32),
    colorMatrix: [
      0.95, 0, 0, 0, 0,
      0, 1.0, 0, 0, 0,
      0.05, 0.05, 1.05, 0, 5,
      0, 0, 0, 1, 0,
    ],
  );

  static const FilterPreset vista800 = FilterPreset(
    name: 'Vista 800',
    id: 'vista800',
    swatchColor: Color(0xFFEF5350),
    colorMatrix: [
      1.1, 0.1, 0, 0, 5,
      0, 1.0, 0, 0, 0,
      0, 0, 0.9, 0, -5,
      0, 0, 0, 1, 0,
    ],
  );

  static List<FilterPreset> get all => [
    original, cc, cn, c160, superia100, hh400, hs400, vista800,
  ];

  /// Map scene type to recommended filters
  static List<FilterPreset> recommendForScene(String scene) {
    final lower = scene.toLowerCase();
    if (lower.contains('nature') || lower.contains('landscape') || lower.contains('sky')) {
      return [velvia, summerFresh, coolVibes];
    }
    if (lower.contains('food') || lower.contains('drink')) {
      return [vividFood, kodakGold];
    }
    if (lower.contains('person') || lower.contains('face') || lower.contains('portrait')) {
      return [softPortrait, kodakGold, original];
    }
    if (lower.contains('street') || lower.contains('city') || lower.contains('urban')) {
      return [noir, coolVibes];
    }
    if (lower.contains('sunset') || lower.contains('sunrise')) {
      return [kodakGold, velvia];
    }
    return [original, velvia, kodakGold];
  }
}