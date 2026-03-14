import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wokki_chat/services/auth_service.dart';
import 'package:wokki_chat/services/user_service.dart';
import 'package:wokki_chat/screens/welcome_screen.dart';
import 'package:wokki_chat/screens/login_screen.dart';
import 'package:wokki_chat/screens/signup_screen.dart';
import 'package:wokki_chat/screens/account_setup_screen.dart';
import 'package:wokki_chat/screens/home_shell.dart';
import 'package:wokki_chat/theme/app_theme.dart';
import 'package:wokki_chat/config/app_config.dart';
import 'dart:io';

class _AllowSelfSigned extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) {
        if (!AppConfig.allowSelfSigned) return false;
        final allowedHosts = AppConfig.apiUrl
            .replaceAll(RegExp(r'https?://'), '')
            .split(':')
            .first;
        final fallbackHost = AppConfig.apiUrlFallback
            .replaceAll(RegExp(r'https?://'), '')
            .split(':')
            .first;
        return host == allowedHosts || host == fallbackHost;
      };
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  if (AppConfig.allowSelfSigned) {
    HttpOverrides.global = _AllowSelfSigned();
  }
  runApp(const WokkiChatApp());
}

class WokkiChatApp extends StatelessWidget {
  const WokkiChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wokki Chat',
      theme: AppTheme.createTheme(AppThemeMode.slate.colors),
      home: const AuthGate(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/welcome':
            return MaterialPageRoute(builder: (_) => const WelcomeScreen());
          case '/login':
            final email = settings.arguments as String?;
            return MaterialPageRoute(
                builder: (_) => LoginScreen(prefillEmail: email));
          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/setup':
            return MaterialPageRoute(
                builder: (_) => const AccountSetupScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeShell());
          default:
            return null;
        }
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authService = AuthService();
    final hasToken = await authService.hasAccessToken();

    Widget destination;

    if (hasToken) {
      final cachedUser = await UserService.loadCachedUser();
      if (cachedUser != null) {
        destination = const HomeShell();
        final token = await authService.getAccessToken();
        if (token != null) {
          UserService.fetchMyProfile(token).catchError((_) {});
        }
      } else {
        destination = const AccountSetupScreen();
      }
    } else {
      destination = const WelcomeScreen();
    }

    if (mounted) {
      setState(() {
        _destination = destination;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppThemeMode.slate.colors.surfaceA0,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return _destination!;
  }
}