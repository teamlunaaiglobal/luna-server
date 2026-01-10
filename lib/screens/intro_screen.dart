import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/luen_colors.dart';
import 'main_screen.dart';

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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuenColors.bgDeep, // 배경: 리얼 블랙
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 텍스트
            const Text(
              "LUNA",
              style: TextStyle(
                // [수정 완료] mainAccent -> neonPoint
                color: LuenColors.neonPoint, 
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 20),
            // 로딩 인디케이터
            const CircularProgressIndicator(
              // [수정 완료] mainAccent -> neonPoint
              color: LuenColors.neonPoint,
            ),
            const SizedBox(height: 20),
            Text(
              "Initialize System...",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontFamily: "Courier",
              ),
            ),
          ],
        ),
      ),
    );
  }
}