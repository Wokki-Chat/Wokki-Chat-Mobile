import 'package:flutter/material.dart';
import 'package:wokki_chat/services/auth_service.dart';
import 'package:wokki_chat/services/user_service.dart';
import 'package:wokki_chat/services/server_service.dart';
import 'package:wokki_chat/services/socket_service.dart';
import 'package:wokki_chat/services/settings_service.dart';
import 'package:wokki_chat/theme/app_theme.dart';
import 'package:wokki_chat/theme/app_colors.dart';
import 'package:wokki_chat/state/app_theme_notifier.dart';
import 'package:wokki_chat/theme/app_colors_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppThemeMode _selectedTheme = AppThemeNotifier.instance.value;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final theme = await SettingsService.getThemeMode();
    if (mounted) {
      setState(() {
        _selectedTheme = theme;
      });
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    final u = UserService.cachedUser;
    try {
      await AuthService().recordLastLogin(
        username: u?.effectiveName,
        email: u?.email,
        avatarUrl: u?.avatar,
      );
      await AuthService().clearTokens();
    } catch (_) {}
    SocketService().disconnect();
    UserService.clearCache();
    ServerService.clearCache();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsProvider.of(context);

    return Scaffold(
      backgroundColor: colors.surfaceA0,
      appBar: AppBar(
        backgroundColor: colors.surfaceA0,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: colors.textA20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: colors.textA0,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _SectionHeader(label: 'Appearance', colors: colors),
          _SettingsGroup(
            colors: colors,
            children: [
              _SettingsTile(
                icon: Icons.palette_rounded,
                label: 'Theme',
                trailing: Text(
                  _selectedTheme.displayName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: colors.textA40,
                  ),
                ),
                colors: colors,
                onTap: () => _showThemePicker(context, colors),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(label: 'Channels', colors: colors),
          ListenableBuilder(
            listenable: SettingsService.autoOpenLastChannelNotifier,
            builder: (context, _) => _SettingsGroup(
              colors: colors,
              children: [
                _SettingsToggleTile(
                  icon: Icons.bolt_rounded,
                  label: 'Auto-open last channel',
                  subtitle: 'Jump straight into a channel when selecting a server',
                  value: SettingsService.autoOpenLastChannelNotifier.value,
                  colors: colors,
                  onChanged: (val) {
                    SettingsService.setAutoOpenLastChannel(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(label: 'Account', colors: colors),
          _SettingsGroup(
            colors: colors,
            children: [
              _SettingsTile(
                icon: Icons.logout_rounded,
                label: 'Log out',
                iconColor: colors.dangerA10,
                labelColor: colors.dangerA10,
                colors: colors,
                trailing: _isLoggingOut
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(colors.dangerA10),
                        ),
                      )
                    : null,
                onTap: _isLoggingOut ? null : () => _confirmLogout(context, colors),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context, AppColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.popupA0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Theme',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textA0,
                  ),
                ),
                const SizedBox(height: 16),
                ...AppThemeMode.values.map((mode) {
                  final isSelected = _selectedTheme == mode;
                  return InkWell(
                    onTap: () async {
                      setSheetState(() {});
                      setState(() => _selectedTheme = mode);
                      AppThemeNotifier.instance.setTheme(mode);
                      if (context.mounted) Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.primaryA0.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? colors.primaryA0.withOpacity(0.4)
                              : colors.popupA20,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          _ThemePreviewDot(mode: mode),
                          const SizedBox(width: 12),
                          Text(
                            mode.displayName,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? colors.primaryA0
                                  : colors.textA0,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(Icons.check_rounded,
                                size: 18, color: colors.primaryA0),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.popupA0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log out',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textA0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to log out of your account?',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: colors.textA40,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textA0,
                      side: BorderSide(color: colors.surfaceA20),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textA0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleLogout();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.dangerA0,
                      foregroundColor: colors.textWhiteA0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ).copyWith(
                      side: WidgetStateProperty.all(
                        BorderSide(color: colors.dangerA10.withOpacity(0.4)),
                      ),
                    ),
                    child: const Text(
                      'Log out',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePreviewDot extends StatelessWidget {
  final AppThemeMode mode;

  const _ThemePreviewDot({required this.mode});

  @override
  Widget build(BuildContext context) {
    final c = mode.colors;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: c.surfaceA0,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.surfaceA20, width: 1),
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: c.primaryA0,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final dynamic colors;

  const _SectionHeader({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.textA40,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final dynamic colors;

  const _SettingsGroup({required this.children, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.popupA0,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.popupA10, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colors.popupA10,
                  indent: 48,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final dynamic colors;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.colors,
    this.trailing,
    this.iconColor,
    this.labelColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? colors.textA30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? colors.textA0,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else if (onTap != null && iconColor == null)
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: colors.textA40),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final dynamic colors;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.textA30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colors.textA0,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: colors.textA40,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colors.primaryA0,
          ),
        ],
      ),
    );
  }
}