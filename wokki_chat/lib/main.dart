import 'package:flutter/material.dart';

void main() {
  runApp(const WokkiChatApp());
}

class WokkiChatApp extends StatelessWidget {
  const WokkiChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wokki Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WokkiChatHome(),
    );
  }
}

class WokkiChatHome extends StatelessWidget {
  const WokkiChatHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Wokki Chat',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}