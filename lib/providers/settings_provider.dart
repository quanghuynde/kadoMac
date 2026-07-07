import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool autoZoom;
  final bool showGrid;
  final bool useOpenAIVision;
  final String openAIApiKey;

  SettingsState({
    this.autoZoom = true,
    this.showGrid = true,
    this.useOpenAIVision = true,
    this.openAIApiKey = _kDefaultApiKey,
  });
  
  static const String _kDefaultApiKey = '';

  SettingsState copyWith({
    bool? autoZoom,
    bool? showGrid,
    bool? useOpenAIVision,
    String? openAIApiKey,
  }) {
    return SettingsState(
      autoZoom: autoZoom ?? this.autoZoom,
      showGrid: showGrid ?? this.showGrid,
      useOpenAIVision: useOpenAIVision ?? this.useOpenAIVision,
      openAIApiKey: openAIApiKey ?? this.openAIApiKey,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String _autoZoomKey = 'autoZoom';
  static const String _showGridKey = 'showGrid';
  static const String _useOpenAIVisionKey = 'useOpenAIVision';
  static const String _openAIApiKeyKey = 'openAIApiKey';

  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = SettingsState(
        autoZoom: prefs.getBool(_autoZoomKey) ?? true,
        showGrid: prefs.getBool(_showGridKey) ?? true,
        useOpenAIVision: prefs.getBool(_useOpenAIVisionKey) ?? true,
        openAIApiKey: prefs.getString(_openAIApiKeyKey) ?? SettingsState._kDefaultApiKey,
      );
    } catch (e) {
      // In case of error (e.g. testing context) use defaults
    }
  }

  Future<void> setAutoZoom(bool value) async {
    state = state.copyWith(autoZoom: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoZoomKey, value);
  }

  Future<void> setShowGrid(bool value) async {
    state = state.copyWith(showGrid: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showGridKey, value);
  }

  Future<void> setUseOpenAIVision(bool value) async {
    state = state.copyWith(useOpenAIVision: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useOpenAIVisionKey, value);
  }

  Future<void> setOpenAIApiKey(String value) async {
    state = state.copyWith(openAIApiKey: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openAIApiKeyKey, value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((
  ref,
) {
  return SettingsNotifier();
});
