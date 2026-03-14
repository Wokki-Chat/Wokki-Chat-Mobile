import 'package:flutter/material.dart';
import 'package:wokki_chat/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeMode.slate.colors;

    return Scaffold(
      backgroundColor: colors.surfaceA0,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icon/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  'Wokki Chat',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: colors.textA0,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Connect with friends, share your world & make every conversation count.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: colors.textA40,
                    height: 1.4,
                  ),
                ),
              ),
              const Spacer(flex: 3),
              FilledButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primaryA0,
                  foregroundColor: colors.textWhiteA0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Log In'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primaryA0,
                  side: BorderSide(
                      color: colors.primaryA0.withOpacity(0.5), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}