import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// 👇 방금 만든 AI 시동 장치 가져오기
import 'services/luna_boot_service.dart';

// 👇 인트로 화면
import 'screens/intro_screen.dart'; 

void main() async {
  // 1. 기본 설정 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 광고 기능 켜기
  await MobileAds.instance.initialize(); 

  // 3. [핵심] 루나 AI 두뇌 깨우기 (이게 있어야 비서 기능 작동)
  await LunaBootService.boot();

  // 4. 앱 화면 띄우기
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
      home: const IntroScreen(),
    );
  }
}