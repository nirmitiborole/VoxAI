import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const VoxAIApp());
}

class VoxAIApp extends StatelessWidget {
  const VoxAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoxAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050816),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF22C55E),
          secondary: Color(0xFF0EA5E9),
          background: Color(0xFF050816),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF050816),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
