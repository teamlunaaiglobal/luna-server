import 'dart:async';
import 'package:flutter/material.dart';
import 'main_screen.dart';
import '../luen_colors.dart'; 

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainScreen(), 
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // [Fix] Scaffold 앞에 'const'를 붙여서 화면 전체를 고정 (성능 최고조)
    return const Scaffold(
      backgroundColor: LuenColors.bgDeep,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "LUNA",
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              color: LuenColors.primaryBlue,
            ),
            SizedBox(height: 20),
            Text(
              "Initialize System...",
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}