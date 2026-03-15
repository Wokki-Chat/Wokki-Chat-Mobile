import 'package:flutter/material.dart';
import 'package:wokki_chat/theme/app_colors_provider.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> with ThemeAware<NotificationsTab> {
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
          'Notifications',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: colors.textA0,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 64, color: colors.textA40),
            const SizedBox(height: 16),
            Text(
              "You're all caught up",
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.textA10,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No new notifications right now.',
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