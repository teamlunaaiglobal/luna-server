import 'package:flutter/material.dart';
import '../modules/system_module.dart';

class LunaBatteryWidget extends StatelessWidget {
  final SystemModule systemModule;

  const LunaBatteryWidget({super.key, required this.systemModule});

  @override
  Widget build(BuildContext context) {
    // 배터리 상태 계산 (0.0 ~ 1.0)
    final double percent = systemModule.currentExp;
    final int current = systemModule.dailyUsed;
    final int max = systemModule.currentMaxLimit;

    // 색상: 꽉 차면 빨강(위험), 널널하면 초록/파랑
    Color batteryColor = const Color(0xFF4A90E2); // 기본 파랑
    if (percent > 0.8) batteryColor = const Color(0xFFFF6B6B); // 위험(빨강)

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 숫자 표시 (예: 15 / 30)
          Text(
            "$current / $max",
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),

          // 2. 배터리 아이콘 그림
          SizedBox(
            width: 24,
            height: 12,
            child: Stack(
              children: [
                // 테두리
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70, width: 1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 채워지는 부분
                FractionallySizedBox(
                  widthFactor: percent.clamp(0.0, 1.0), // 0~1 사이
                  child: Container(
                    margin: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      color: batteryColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 배터리 꼬다리
          Container(
            margin: const EdgeInsets.only(left: 24),
            width: 2, height: 6,
            decoration: const BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(2),
                bottomRight: Radius.circular(2),
              )
            ),
          )
        ],
      ),
    );
  }
}