import 'package:flutter/material.dart';
import 'package:wokki_chat/theme/app_colors.dart';
import 'package:wokki_chat/theme/app_theme.dart';
import 'package:wokki_chat/state/app_theme_notifier.dart';

export 'package:wokki_chat/theme/app_colors.dart';

AppColors get appColors => AppThemeNotifier.instance.value.colors;

mixin ThemeAware<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    AppThemeNotifier.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    AppThemeNotifier.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});
}

class AppColorsProvider extends InheritedWidget {
  final AppColors colors;

  const AppColorsProvider({
    super.key,
    required this.colors,
    required super.child,
  });

  static AppColors of(BuildContext context) => appColors;

  @override
  bool updateShouldNotify(AppColorsProvider oldWidget) => false;
}