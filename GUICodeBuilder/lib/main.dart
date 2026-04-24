import 'package:flutter/material.dart';

import 'editor/editor_screen.dart';

// 앱을 시작하고 최상위 Flutter 위젯을 실행한다.
void main() {
  runApp(const GUICodeBuilderApp());
}

// 앱 전역 테마와 첫 화면을 정의한다.
class GUICodeBuilderApp extends StatelessWidget {
  const GUICodeBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GUI Code Builder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        useMaterial3: true,
      ),
      home: const EditorScreen(),
    );
  }
}
