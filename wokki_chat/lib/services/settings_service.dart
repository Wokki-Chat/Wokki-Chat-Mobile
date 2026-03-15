import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wokki_chat/theme/app_theme.dart';

class SettingsService {
  static const _kThemeMode = 'app_theme_mode';
  static const _kAutoOpenLastChannel = 'auto_open_last_channel';

  static final ValueNotifier<bool> autoOpenLastChannelNotifier =
      ValueNotifier<bool>(true);

  static Future<void> init() async {
    final autoOpen = await getAutoOpenLastChannel();
    autoOpenLastChannelNotifier.value = autoOpen;
  }

  static Future<AppThemeMode> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_kThemeMode);
      return AppThemeMode.values.firstWhere(
        (e) => e.name == name,
        orElse: () => AppThemeMode.slate,
      );
    } catch (_) {
      return AppThemeMode.slate;
    }
  }

  static Future<void> setThemeMode(AppThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeMode, mode.name);
    } catch (_) {}
  }

  static Future<bool> getAutoOpenLastChannel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kAutoOpenLastChannel) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setAutoOpenLastChannel(bool value) async {
    autoOpenLastChannelNotifier.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kAutoOpenLastChannel, value);
    } catch (_) {}
  }
}