import 'package:flutter/material.dart';
import 'package:wokki_chat/services/user_service.dart';
import 'package:wokki_chat/services/background_sync.dart';
import 'package:wokki_chat/models/user_model.dart';
import 'package:wokki_chat/screens/settings_screen.dart';
import 'package:wokki_chat/theme/app_theme.dart';
import 'package:wokki_chat/theme/app_colors_provider.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> with ThemeAware<ProfileTab> {
  UserModel? _user;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _user = UserService.cachedUser;
    _backgroundRefresh();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _backgroundRefresh() async {
    try {
      if (_disposed) return;
      final result = await BackgroundSync.run();
      if (_disposed || !mounted) return;
      if (result.user != null) {
        setState(() => _user = result.user);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors;

    return Scaffold(
      backgroundColor: colors.surfaceA0,
      appBar: AppBar(
        backgroundColor: colors.surfaceA0,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: colors.textA0,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_rounded, color: colors.textA30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _user == null
          ? Center(
              child: Text(
                'No profile data',
                style: TextStyle(color: colors.textA40, fontFamily: 'Inter'),
              ),
            )
          : _ProfileContent(user: _user!, colors: colors),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final UserModel user;
  final dynamic colors;

  const _ProfileContent({required this.user, required this.colors});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          SizedBox(
            width: 90,
            height: 90,
            child: ClipOval(
              child: Image.network(
                user.avatar ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(colors),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.effectiveName,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colors.textA0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${user.username}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: colors.textA40,
            ),
          ),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceA10,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                user.bio!,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: colors.textA10,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _avatarFallback(dynamic colors) {
    return Container(
      color: colors.surfaceA20,
      child: Center(
        child: Text(
          user.effectiveName.isNotEmpty
              ? user.effectiveName[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: colors.textA20,
          ),
        ),
      ),
    );
  }
}