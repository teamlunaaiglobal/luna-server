import 'services/user/user_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'widgets/luen_colors.dart'; 
import 'screens/intro_screen.dart';
import 'core/luna_processor.dart';
import 'services/hardware/luna_tts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // [핵심 초기화]
  await UserSettingsService.instance.init(); // 유저 설정 (언어, 시간대)
  await LunaProcessor.instance.init();  // 친밀도 + 기억 + AI
  await LunaTTSService.instance.init(); // TTS
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LUNA',
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
      ),
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: LuenColors.neonPoint, 
        scaffoldBackgroundColor: LuenColors.bgDeep,
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      home: const IntroScreen(),
    );
  }
}