import 'package:flutter/material.dart';

// [중요] SystemModule을 "만드는" 게 아니라 "가져오는" 겁니다.
// 만약 이 파일 안에 'class SystemModule'이라는 글자가 보이면 무조건 지우세요!
import '../modules/system_module.dart'; 

class LunaGiftBar extends StatelessWidget {
  final SystemModule? systemModule;

  const LunaGiftBar({super.key, this.systemModule});

  @override
  Widget build(BuildContext context) {
    // 모듈 연결 안 됐을 때 안전장치
    final double progress = systemModule?.currentExp ?? 0.0;
    final int maxLimit = systemModule?.currentMaxLimit ?? 30;
    final int currentUsed = systemModule?.dailyUsed ?? 0;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ENERGY CORE", 
                style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)
              ),
              Text(
                "$currentUsed / $maxLimit", 
                style: const TextStyle(color: Colors.white70, fontSize: 10)
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.9 ? const Color(0xFFFF6B6B) : const Color(0xFF4A90E2)
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}