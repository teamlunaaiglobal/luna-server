import '../../models/proactive/detected_context.dart';
import '../../models/proactive/proactive_action.dart';

class TimingJudge {
  static final TimingJudge instance = TimingJudge._internal();
  factory TimingJudge() => instance;
  TimingJudge._internal();

  // 마지막 제안 시간 (쿨다운용)
  DateTime? _lastSuggestionTime;
  static const int _cooldownMinutes = 5;

  /// 언제 제안할지 판단
  ActionTiming judgeTiming(DetectedContext context) {
    switch (context.type) {
      case ContextType.dining:
        // 회식 → 대화 끝나고 맛집 추천
        return ActionTiming.afterConvo;

      case ContextType.meeting:
        // 회의 언급 → 즉시 캘린더 추가 제안
        return ActionTiming.immediate;

      case ContextType.task:
        // 할일 감지 → 즉시 추가 제안
        return ActionTiming.immediate;

      case ContextType.schedule:
        // 일정 언급 → 즉시 확인
        return ActionTiming.immediate;

      case ContextType.anniversary:
        // 기념일 → 즉시 등록 제안
        return ActionTiming.immediate;

      case ContextType.travel:
        // 여행 → 대화 끝나고 정보 제공
        return ActionTiming.afterConvo;

      case ContextType.none:
        return ActionTiming.immediate;
    }
  }

  /// 지금 제안해도 되는지 확인 (쿨다운 체크)
  bool canSuggestNow() {
    if (_lastSuggestionTime == null) return true;
    
    final diff = DateTime.now().difference(_lastSuggestionTime!);
    return diff.inMinutes >= _cooldownMinutes;
  }

  /// 제안 시간 기록
  void markSuggestion() {
    _lastSuggestionTime = DateTime.now();
  }

  /// 우선순위 판단 (높을수록 먼저)
  int getPriority(DetectedContext context) {
    switch (context.type) {
      case ContextType.anniversary:
        return 100;  // 기념일 최우선
      case ContextType.task:
        return 80;   // 할일 높음
      case ContextType.meeting:
        return 70;
      case ContextType.schedule:
        return 60;
      case ContextType.dining:
        return 40;
      case ContextType.travel:
        return 30;
      case ContextType.none:
        return 0;
    }
  }

  /// 긴급도 판단
  bool isUrgent(DetectedContext context) {
    // 오늘/내일 관련이면 긴급
    final meta = context.metadata;
    if (meta != null && meta['date'] != null) {
      final date = DateTime.parse(meta['date']);
      final diff = date.difference(DateTime.now()).inDays;
      return diff <= 1;
    }
    
    // 키워드에 "지금", "바로", "급" 있으면 긴급
    final urgent = ['지금', '바로', '급해', '빨리', '당장'];
    return urgent.any((k) => context.originalText.contains(k));
  }
}
