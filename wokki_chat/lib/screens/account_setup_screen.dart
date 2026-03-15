import 'package:flutter/material.dart';
import 'package:wokki_chat/services/auth_service.dart';
import 'package:wokki_chat/services/user_service.dart';
import 'package:wokki_chat/services/server_service.dart';
import 'package:wokki_chat/services/socket_service.dart';
import 'package:wokki_chat/theme/app_theme.dart';

class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _disposed = false;

  String _statusText = 'Setting up your account…';
  String? _errorDetail;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _setup();
  }

  @override
  void dispose() {
    _disposed = true;
    _pulseController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) setState(fn);
  }

  Future<void> _setup() async {
    _safeSetState(() {
      _isError = false;
      _errorDetail = null;
      _statusText = 'Setting up your account…';
    });

    final authService = AuthService();
    String? token;
    try {
      token = await authService.getAccessToken();
    } catch (_) {}

    if (token == null) {
      if (!_disposed && mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
      return;
    }

    if (UserService.cachedUser != null) {
      if (!_disposed && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
      _backgroundPostSetup(token, authService);
      return;
    }

    _safeSetState(() => _statusText = 'Fetching your profile…');

    try {
      await _fetchAndNavigate(token, authService);
    } catch (e) {
      if (_disposed) return;
      final msg = e.toString();
      final isConnectionError = msg.contains('SocketException') ||
          msg.contains('Connection') ||
          msg.contains('TimeoutException') ||
          msg.contains('Failed host lookup');

      if (msg.contains('Unauthorized') || msg.contains('Session expired')) {
        try {
          await authService.clearTokens();
        } catch (_) {}
        if (!_disposed && mounted) {
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      } else if (isConnectionError) {
        _safeSetState(() => _statusText = 'Switching to backup server…');
        await Future.delayed(const Duration(milliseconds: 800));
        if (_disposed) return;

        try {
          await _fetchAndNavigate(token, authService);
        } catch (retryError) {
          _safeSetState(() {
            _isError = true;
            _statusText = 'Unable to connect to server';
            _errorDetail =
                retryError.toString().replaceAll('Exception: ', '');
          });
        }
      } else {
        _safeSetState(() {
          _isError = true;
          _statusText = 'Something went wrong';
          _errorDetail = msg.replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _fetchAndNavigate(String token, AuthService authService) async {
    if (_disposed) return;

    final user = await UserService.fetchMyProfile(token);
    if (_disposed) return;

    if (user.email != null && user.email!.isNotEmpty) {
      try {
        final refreshToken = await authService.getRefreshToken();
        if (!_disposed && refreshToken != null && refreshToken.isNotEmpty) {
          await authService.saveRefreshTokenForAccount(user.email!, refreshToken);
        }
      } catch (_) {}
    }

    if (_disposed) return;
    _safeSetState(() => _statusText = 'Loading your servers…');

    await ServerService.fetchMyServers(token);
    if (_disposed) return;

    _safeSetState(() => _statusText = 'All done!');
    await Future.delayed(const Duration(milliseconds: 350));
    if (!_disposed && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _backgroundPostSetup(String token, AuthService authService) {
    UserService.fetchMyProfile(token).then((user) {
      if (_disposed) return;
      if (user.email != null && user.email!.isNotEmpty) {
        authService.getRefreshToken().then((refreshToken) {
          if (_disposed) return;
          if (refreshToken != null && refreshToken.isNotEmpty) {
            authService.saveRefreshTokenForAccount(user.email!, refreshToken);
          }
        }).catchError((_) {});
      }
    }).catchError((_) {});
    ServerService.fetchMyServers(token).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeMode.slate.colors;

    return Scaffold(
      backgroundColor: colors.surfaceA0,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isError
                        ? colors.dangerA0.withOpacity(0.12)
                        : colors.primaryA0.withOpacity(0.12),
                  ),
                  child: Center(
                    child: _isError
                        ? Icon(Icons.error_outline_rounded,
                            size: 40, color: colors.dangerA10)
                        : ClipOval(
                            child: Image.asset(
                              'assets/icon/icon.png',
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      colors.primaryA0),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _isError ? colors.dangerA10 : colors.textA0,
                ),
              ),
              if (_errorDetail != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surfaceA10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.dangerA0.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorDetail!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: colors.textA30,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _setup,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primaryA0,
                    foregroundColor: colors.textWhiteA0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colors.primaryA30, width: 1),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
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
                    if (!_disposed && mounted) {
                      Navigator.pushReplacementNamed(context, '/welcome');
                    }
                  },
                  child: Text(
                    'Log out',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: colors.textA40,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Just a moment',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: colors.textA40,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}