import 'package:flutter/material.dart';
import 'package:wokki_chat/services/auth_service.dart';
import 'package:wokki_chat/services/user_service.dart';
import 'package:wokki_chat/models/user_model.dart';
import 'package:wokki_chat/theme/app_theme.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeMode.slate.colors;
    final user = UserService.cachedUser;

    return Scaffold(
      backgroundColor: colors.surfaceA0,
      appBar: AppBar(
        backgroundColor: colors.surfaceA0,
        elevation: 0,
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
            icon: Icon(Icons.logout_rounded, color: colors.textA30),
            onPressed: () async {
              await AuthService().clearTokens();
              UserService.clearCache();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/welcome');
              }
            },
          ),
        ],
      ),
      body: user == null
          ? Center(
              child: Text(
                'No profile data',
                style: TextStyle(color: colors.textA40, fontFamily: 'Inter'),
              ),
            )
          : _ProfileContent(user: user, colors: colors),
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
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primaryA0.withOpacity(0.2),
              border: Border.all(color: colors.primaryA0, width: 2.5),
            ),
            child: ClipOval(
              child: Image.network(
                user.avatar ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(),
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

  Widget _avatarFallback() {
    return Center(
      child: Text(
        user.effectiveName.isNotEmpty
            ? user.effectiveName[0].toUpperCase()
            : '?',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: colors.primaryA0,
        ),
      ),
    );
  }
}