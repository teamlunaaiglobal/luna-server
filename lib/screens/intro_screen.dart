// lib/screens/intro_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
// [수정] 옛날 파일(luna_main_scaffold) 대신 새 파일(main_screen) import
import 'main_screen.dart';
import '../luen_colors.dart'; // 색상 참조

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  @override
  void initState() {
    super.initState();
    // 3초 후 메인 화면으로 이동
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()), // [수정] MainScreen으로 이동
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuenColors.bgDeep, // 배경색 통일
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고나 텍스트 애니메이션
            const Text(
              "LUNA",
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // 로딩 인디케이터
            CircularProgressIndicator(
              color: LuenColors.primaryBlue,
            ),
            const SizedBox(height: 20),
            const Text(
              "Initialize System...",
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}