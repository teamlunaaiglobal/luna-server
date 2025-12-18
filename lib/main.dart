// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 광고 패키지

// [중요] 아까 분리한 파일들 연결
import 'luen_colors.dart'; 
import 'services/luna_boot_service.dart';
import 'services/lang.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. 광고 초기화 (필요시 사용)
  await MobileAds.instance.initialize();

  // 2. 루나 부팅 서비스 호출 (함수명이 initialize 입니다)
  await LunaBootService().initialize();
  
  // 3. 언어팩 로드
  await Lang.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LUNA',
      
      // [디자인] 아까 분리한 LuenColors 적용
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: LuenColors.primaryBlue,
        scaffoldBackgroundColor: LuenColors.bgDeep,
        useMaterial3: true,
      ),
      
      // [다국어 지원]
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      
      // [화면] 인트로가 아니라 메인 스크린으로 직행
      home: const MainScreen(),
    );
  }
}