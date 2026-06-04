// lib/providers/theme_provider.dart
// Proveedor de tema con Riverpod

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicknote/core/constants/app_theme.dart';
import 'package:quicknote/core/utils/secure_storage.dart';

// ============================================
// STATE
// ============================================

class ThemeState {
  final ThemeMode themeMode;
  final bool isDarkMode;

  ThemeState({
    required this.themeMode,
    required this.isDarkMode,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? isDarkMode,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

// ============================================
// NOTIFIER
// ============================================

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(ThemeState(themeMode: ThemeMode.system, isDarkMode: false)) {
    _init();
  }

  final SecureStorage _secureStorage = SecureStorage();

  Future<void> _init() async {
    final savedTheme = await _secureStorage.getThemeMode();
    final themeMode = _getThemeModeFromString(savedTheme);
    final isDarkMode = _getIsDarkMode(themeMode);
    
    state = ThemeState(themeMode: themeMode, isDarkMode: isDarkMode);
  }

  // ============================================
  // CAMBIAR TEMA
  // ============================================
  Future<void> setThemeMode(ThemeMode mode) async {
    final isDarkMode = _getIsDarkMode(mode);
    
    state = ThemeState(themeMode: mode, isDarkMode: isDarkMode);
    await _secureStorage.saveThemeMode(_getThemeModeString(mode));
  }

  void toggleTheme() {
    final newMode = state.themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    setThemeMode(newMode);
  }

  void setLightMode() => setThemeMode(ThemeMode.light);
  void setDarkMode() => setThemeMode(ThemeMode.dark);
  void setSystemMode() => setThemeMode(ThemeMode.system);

  // ============================================
  // OBTENER TEMA ACTUAL
  // ============================================
  ThemeData getCurrentTheme() {
    return state.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
  }

  // ============================================
  // MÉTODOS PRIVADOS
  // ============================================
  bool _getIsDarkMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
      default:
        return false;
    }
  }

  ThemeMode _getThemeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  String _getThemeModeString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      default:
        return 'system';
    }
  }
}

// ============================================
// PROVIDERS
// ============================================

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider).isDarkMode;
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeProvider).themeMode;
});

final currentThemeProvider = Provider<ThemeData>((ref) {
  return ref.watch(themeProvider.notifier).getCurrentTheme();
});