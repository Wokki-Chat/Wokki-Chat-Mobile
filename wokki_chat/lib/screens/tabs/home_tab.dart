import 'package:flutter/material.dart';
import 'package:wokki_chat/theme/app_theme.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeMode.slate.colors;

    return Scaffold(
      backgroundColor: colors.surfaceA0,
      appBar: AppBar(
        backgroundColor: colors.surfaceA0,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 64, color: colors.textA40),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.textA10,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start a conversation to get going.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: colors.textA40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}