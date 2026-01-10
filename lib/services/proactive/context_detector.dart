import '../../models/proactive/detected_context.dart';

class ContextDetector {
  static final ContextDetector instance = ContextDetector._internal();
  factory ContextDetector() => instance;
  ContextDetector._internal();

  /// 대화에서 맥락 감지
  DetectedContext? detect(String input) {
    final lower = input.toLowerCase();

    // 회식/식사 감지
    if (_matchesAny(lower, ['회식', '밥 먹', '저녁 먹', '점심 먹', '식사', '뭐 먹'])) {
      return DetectedContext(
        type: ContextType.dining,
        keyword: _findKeyword(lower, ['회식', '밥', '저녁', '점심', '식사']),
        originalText: input,
        detectedAt: DateTime.now(),
      );
    }

    // 회의/미팅 감지
    if (_matchesAny(lower, ['회의', '미팅', 'meeting', '콜', '통화 예정'])) {
      return DetectedContext(
        type: ContextType.meeting,
        keyword: _findKeyword(lower, ['회의', '미팅', 'meeting', '콜']),
        originalText: input,
        detectedAt: DateTime.now(),
        metadata: _extractDateTime(input),
      );
    }

    // 할일 감지 ("내가 할게", "해야 해", "해야겠다")
    if (_matchesAny(lower, ['내가 할게', '내가 해', '해야 해', '해야겠', '해놔야', '잊지 말'])) {
      return DetectedContext(
        type: ContextType.task,
        keyword: _findKeyword(lower, ['할게', '해야', '해놔', '잊지']),
        originalText: input,
        detectedAt: DateTime.now(),
      );
    }

    // 일정 감지 ("다음 주", "내일", "모레", "언제")
    if (_matchesAny(lower, ['다음 주', '다음주', '내일', '모레', '이번 주', '주말에', '월요일', '화요일', '수요일', '목요일', '금요일'])) {
      return DetectedContext(
        type: ContextType.schedule,
        keyword: _findKeyword(lower, ['다음 주', '내일', '모레', '이번 주', '주말']),
        originalText: input,
        detectedAt: DateTime.now(),
        metadata: _extractDateTime(input),
      );
    }

    // 기념일 감지
    if (_matchesAny(lower, ['생일', '기념일', '결혼', 'anniversary', '100일', '1주년', '돌'])) {
      return DetectedContext(
        type: ContextType.anniversary,
        keyword: _findKeyword(lower, ['생일', '기념일', '결혼', '100일', '주년']),
        originalText: input,
        detectedAt: DateTime.now(),
      );
    }

    // 여행 감지
    if (_matchesAny(lower, ['여행', '휴가', '비행기', '호텔', '예약', 'trip', 'travel'])) {
      return DetectedContext(
        type: ContextType.travel,
        keyword: _findKeyword(lower, ['여행', '휴가', '비행기', '호텔']),
        originalText: input,
        detectedAt: DateTime.now(),
      );
    }

    return null;
  }

  bool _matchesAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  String _findKeyword(String text, List<String> keywords) {
    for (var k in keywords) {
      if (text.contains(k)) return k;
    }
    return '';
  }

  Map<String, dynamic>? _extractDateTime(String input) {
    // 간단한 날짜 추출 (추후 고도화 가능)
    final now = DateTime.now();
    
    if (input.contains('내일')) {
      return {'date': now.add(const Duration(days: 1)).toIso8601String()};
    }
    if (input.contains('모레')) {
      return {'date': now.add(const Duration(days: 2)).toIso8601String()};
    }
    if (input.contains('다음 주') || input.contains('다음주')) {
      return {'date': now.add(const Duration(days: 7)).toIso8601String()};
    }
    
    return null;
  }
}
