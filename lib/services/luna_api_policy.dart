import '../modules/system_module.dart';

/// API 호출 가능 여부 상태 정의
enum LunaApiStatus {
  apiCallAllowed,    // 정상 호출 (dailyUsed < 20)
  apiCallLimitSoft,  // 주의 단계 (20 <= dailyUsed < 40) - 딜레이/단문 응답 등
  apiCallBlocked,    // 호출 차단 (dailyUsed >= 40) - 광고/리필 필요
}

class LunaApiPolicy {
  /// SystemModule의 상태를 분석하여 현재 API 전략을 반환합니다.
  /// 
  /// [Rule]
  /// - ~19회: 자유 이용
  /// - 20~39회: 소프트 리밋 (절약 모드 등)
  /// - 40회~: 차단 (리필 유도)
  static LunaApiStatus judge(SystemModule system) {
    final int usage = system.dailyUsed;

    if (usage < 20) {
      return LunaApiStatus.apiCallAllowed;
    } else if (usage < 40) {
      return LunaApiStatus.apiCallLimitSoft;
    } else {
      return LunaApiStatus.apiCallBlocked;
    }
  }
}