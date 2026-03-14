import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wokki_chat/services/auth_service.dart';
import 'package:wokki_chat/screens/welcome_screen.dart';
import 'package:wokki_chat/screens/login_screen.dart';
import 'package:wokki_chat/screens/signup_screen.dart';
import 'package:wokki_chat/theme/app_theme.dart';
import 'dart:io';

class _AllowSelfSigned extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (_, __, ___) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _AllowSelfSigned();
  await dotenv.load(fileName: ".env");
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
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const WokkiChatHome(),
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
  final _authService = AuthService();
  bool _isLoading = true;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final hasToken = await _authService.hasAccessToken();
    setState(() {
      _hasToken = hasToken;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _hasToken ? const WokkiChatHome() : const WelcomeScreen();
  }
}

class WokkiChatHome extends StatelessWidget {
  const WokkiChatHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wokki Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().clearTokens();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/welcome');
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to Wokki Chat!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}