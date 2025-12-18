enum LunaActionType {
  normal,      // 정상 진행
  softDelay,   // 감정적 지연 (사용자 배려 연출)
  adAsAction,  // 휴식 제안 (실제로는 광고/리필 로직)
  deny,        // 거절
}

class LunaDecision {
  final LunaActionType type;
  final String message;

  LunaDecision(this.type, this.message);
}

class LunaDecisionRule {
  /// 외부의 모든 변수(포인트, 사용량, 감정)를 받아 '행동'을 결정합니다.
  static LunaDecision decide({
    required int userPoint,
    required int dailyUsed,
    required bool hasEmotionEvent,
  }) {
    // 1. 하루 리필 이후 첫 사용 (오프닝)
    if (dailyUsed == 0) {
      return LunaDecision(
        LunaActionType.normal,
        "오늘도 같이 시작해보자.",
      );
    }

    // 2. 포인트 부족 (광고/휴식 유도)
    if (userPoint <= 0) {
      return LunaDecision(
        LunaActionType.adAsAction,
        "잠깐 숨 고르고 오자. 내가 판단했어.",
      );
    }

    // 3. 감정 이벤트 직후 (템포 조절)
    if (hasEmotionEvent) {
      return LunaDecision(
        LunaActionType.softDelay,
        "조금만 천천히 가도 괜찮아.",
      );
    }

    // 4. 기본 상태
    return LunaDecision(
      LunaActionType.normal,
      "계속 가자.",
    );
  }
}