import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

// 👇 [수정] MainScreen 대신 통합 스캐폴드로 연결
import 'luna_main_scaffold.dart';
import '../services/lang.dart'; 

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _textOpacity;

  @override
  void initState() {
    super.initState();
    
    // ★★★ [ 핵심: 미리 로딩 ] ★★★
    // 애니메이션이 도는 3초 동안, 뒤에서 조용히 언어 설정을 마칩니다.
    Lang.init(); 

    // 1. 속도 개선: 5.5초 -> 3초 (한국인 맞춤 속도)
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000));

    _scale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.5)
              .chain(CurveTween(curve: Curves.easeInOut)), 
          weight: 40), // 등장
      TweenSequenceItem(
          tween: Tween(begin: 1.5, end: 1.2)
              .chain(CurveTween(curve: Curves.easeInOut)), 
          weight: 20), // 응축
      TweenSequenceItem(
          tween: Tween(begin: 1.2, end: 50.0)
              .chain(CurveTween(curve: Curves.easeInOutExpo)), 
          weight: 40), // 폭발
    ]).animate(_ctrl);

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.7, 1.0, curve: Curves.easeIn)));
    
    _ctrl.forward();

    // 3초 후 메인으로 이동
    Timer(const Duration(milliseconds: 3200), () {
      Navigator.pushReplacement(
          context,
          PageRouteBuilder(
              // 👇 [핵심 변경] MainScreen -> LunaMainScaffold
              pageBuilder: (_, __, ___) => const LunaMainScaffold(),
              transitionsBuilder: (_, a, __, c) =>
                  FadeTransition(opacity: a, child: c),
              transitionDuration: const Duration(seconds: 1))); // 전환은 부드럽게
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      body: Center(
          child: Stack(alignment: Alignment.center, children: [
        AnimatedBuilder(
            animation: _ctrl,
            builder: (ctx, child) {
              return Transform.scale(
                  scale: _scale.value,
                  child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white,
                              const Color(0xFF448AFF).withValues(alpha: 0.8),
                              const Color(0xFFE040FB).withValues(alpha: 0.5),
                              Colors.transparent
                            ], 
                            stops: const [0.0, 0.3, 0.6, 1.0]
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF448AFF).withValues(alpha: 0.6),
                                blurRadius: 20,
                                spreadRadius: 5)
                          ])));
            }),
        FadeTransition(
            opacity: _textOpacity,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 50),
              Text("L U E N",
                  style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 15,
                      shadows: [
                        BoxShadow(
                            color: const Color(0xFF448AFF).withValues(alpha: 0.5),
                            blurRadius: 30)
                      ])),
            ])),
      ])),
    );
  }
}