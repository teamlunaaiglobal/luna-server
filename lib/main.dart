// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// 👇 인트로 화면으로 시작
import 'screens/intro_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize(); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Luna AI',
      theme: ThemeData(
        brightness: Brightness.light, 
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        useMaterial3: true,
      ),
      // 👇 앱이 켜지면 인트로가 가장 먼저 나옴
      home: const IntroScreen(),
    );
  }
}