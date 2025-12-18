import 'package:flutter/material.dart';
import '../modules/system_module.dart';

class LunaGiftBar extends StatelessWidget {
  final SystemModule systemModule;

  // [Fix] 최신 Dart 문법 적용 (super.key 사용)
  const LunaGiftBar({
    super.key, 
    required this.systemModule,
  });

  @override
  Widget build(BuildContext context) {
    // 1. [비밀] 스텔스 비율 계산
    // max가 30이든 24든, 사용자 눈에는 항상 꽉 찬(1.0) 게이지로 시작함
    final int used = systemModule.dailyUsed;
    final int currentMax = systemModule.currentMaxLimit;
    
    // 방어코드: 0으로 나누기 방지
    final int safeMax = currentMax > 0 ? currentMax : 1;
    
    // 남은 비율 (0.0 ~ 1.0)
    double percentage = (safeMax - used) / safeMax;
    if (percentage < 0) percentage = 0;

    // 2. 색상 심리 (게이지 색깔 변화)
    Color barColor;
    if (percentage > 0.5) {
      barColor = const Color(0xFF6C63FF); // 넉넉함 (Luna Brand Color)
    } else if (percentage > 0.2) {
      barColor = Colors.orangeAccent;    // 주의
    } else {
      barColor = Colors.redAccent;       // 경고 (방전 직전)
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 라벨 (숫자 없이 감성적인 텍스트만)
          const Text(
            "Daily Gift",
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          
          // 게이지 바
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage, // 0.0 ~ 1.0
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}