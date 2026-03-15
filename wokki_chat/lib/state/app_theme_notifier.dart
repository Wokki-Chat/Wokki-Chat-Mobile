import 'package:flutter/material.dart';
import 'package:wokki_chat/theme/app_theme.dart';
import 'package:wokki_chat/services/settings_service.dart';

class AppThemeNotifier extends ValueNotifier<AppThemeMode> {
  static final AppThemeNotifier instance = AppThemeNotifier._();

  AppThemeNotifier._() : super(AppThemeMode.slate);

  static Future<void> init() async {
    final saved = await SettingsService.getThemeMode();
    instance.value = saved;
  }

  void setTheme(AppThemeMode mode) {
    value = mode;
    SettingsService.setThemeMode(mode);
  }
}