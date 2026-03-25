import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Keys ────────────────────────────────────────────────────────────────────

abstract class _Keys {
  static const String themeMode = 'app_theme_mode';
  static const String firstDayOfWeek = 'app_first_day_of_week';
}

// ── Service ─────────────────────────────────────────────────────────────────

class LocalPreferences {
  const LocalPreferences(this._prefs);

  final SharedPreferences _prefs;

  // ── Theme ─────────────────────────────────────────────────────────────────

  /// Returns the stored theme mode. Defaults to [ThemeMode.system].
  ThemeMode getThemeMode() {
    final value = _prefs.getString(_Keys.themeMode);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_Keys.themeMode, value);
  }

  // ── First day of week ─────────────────────────────────────────────────────

  /// Returns the first day of week (1 = Monday, 7 = Sunday). Defaults to 1.
  int getFirstDayOfWeek() => _prefs.getInt(_Keys.firstDayOfWeek) ?? 1;

  Future<void> setFirstDayOfWeek(int day) async {
    await _prefs.setInt(_Keys.firstDayOfWeek, day);
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize with ProviderScope overrides');
});

final localPreferencesProvider = Provider<LocalPreferences>(
  (ref) => LocalPreferences(ref.read(sharedPreferencesProvider)),
);
