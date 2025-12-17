import 'package:flutter/material.dart';

class ChatBackground extends StatelessWidget {
  // [수정] key 에러 해결
  const ChatBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 기본 배경 (딥 블랙 ~ 오로라 블루 그라데이션)
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Color(0xFF1A1F3D), // 중심부 (오로라 느낌)
                Color(0xFF050508), // 외곽 (딥 블랙)
              ],
            ),
          ),
        ),
        
        // 2. (선택 사항) 여기에 희미한 별이나 패턴을 추가할 수도 있습니다.
        // 현재는 깔끔하게 그라데이션만 유지합니다.
      ],
    );
  }
}