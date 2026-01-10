import '../../models/proactive/detected_context.dart';
import '../../models/proactive/proactive_action.dart';

class ActionSuggester {
  static final ActionSuggester instance = ActionSuggester._internal();
  factory ActionSuggester() => instance;
  ActionSuggester._internal();

  /// 맥락에 맞는 제안 생성
  ProactiveAction? suggest(DetectedContext context) {
    switch (context.type) {
      case ContextType.dining:
        return _suggestDining(context);
      case ContextType.meeting:
        return _suggestMeeting(context);
      case ContextType.task:
        return _suggestTask(context);
      case ContextType.schedule:
        return _suggestSchedule(context);
      case ContextType.anniversary:
        return _suggestAnniversary(context);
      case ContextType.travel:
        return _suggestTravel(context);
      case ContextType.none:
        return null;
    }
  }

  ProactiveAction _suggestDining(DetectedContext context) {
    return ProactiveAction(
      id: 'suggest_dining_${DateTime.now().millisecondsSinceEpoch}',
      type: ActionType.suggest,
      timing: ActionTiming.afterConvo,
      message: '🍽️ 회식 장소 찾아드릴까요? 근처 맛집 추천해드릴게요!',
      actionCommand: 'search_restaurant',
      createdAt: DateTime.now(),
    );
  }

  ProactiveAction _suggestMeeting(DetectedContext context) {
    return ProactiveAction(
      id: 'suggest_meeting_${DateTime.now().millisecondsSinceEpoch}',
      type: ActionType.ask,
      timing: ActionTiming.immediate,
      message: '📅 "${ _extractMeetingInfo(context.originalText)}" 일정을 캘린더에 추가할까요?',
      actionCommand: 'add_schedule:${context.originalText}',
      createdAt: DateTime.now(),
    );
  }

  ProactiveAction _suggestTask(DetectedContext context) {
    final task = _extractTaskContent(context.originalText);
    return ProactiveAction(
      id: 'suggest_task_${DateTime.now().millisecondsSinceEpoch}',
      type: ActionType.ask,
      timing: ActionTiming.immediate,
      message: '✅ "$task" 할일 목록에 추가할까요?',
      actionCommand: 'add_todo:$task',
      createdAt: DateTime.now(),
    );
  }

  ProactiveAction _suggestSchedule(DetectedContext context) {
    return ProactiveAction(
      id: 'suggest_schedule_${DateTime.now().millisecondsSinceEpoch}',
      type: ActionType.ask,
      timing: ActionTiming.immediate,
      message: '📆 일정으로 등록해드릴까요?',
      actionCommand: 'add_schedule:${context.originalText}',
      createdAt: DateTime.now(),
    );
  }

  ProactiveAction _suggestAnniversary(DetectedContext context) {
    return ProactiveAction(
      id: 'suggest_anniversary_${DateTime.now().millisecondsSinceEpoch}',
      type: ActionType.ask,
      timing: ActionTiming.immediate,
      message: '💝 기념일로 등록해서 미리 알려드릴까요? 잊지 않게 챙겨드릴게요!',
      actionCommand: 'add_anniversary:${context.originalText}',
      createdAt: DateTime.now(),
    );
  }

  ProactiveAction _suggestTravel(DetectedContext context) {
    return ProactiveAction(
      id: 'suggest_travel_${DateTime.now().millisecondsSinceEpoch}',
      type: ActionType.suggest,
      timing: ActionTiming.afterConvo,
      message: '✈️ 여행 계획이시네요! 항공권이나 호텔 정보 찾아드릴까요?',
      actionCommand: 'search_travel',
      createdAt: DateTime.now(),
    );
  }

  /// 회의 정보 추출
  String _extractMeetingInfo(String text) {
    // 간단한 추출 - "다음 주 미팅" -> "다음 주 미팅"
    final patterns = ['회의', '미팅', 'meeting', '콜'];
    for (var p in patterns) {
      if (text.contains(p)) {
        // 앞뒤 문맥 포함해서 반환
        final idx = text.indexOf(p);
        final start = (idx - 10).clamp(0, text.length);
        final end = (idx + p.length + 10).clamp(0, text.length);
        return text.substring(start, end).trim();
      }
    }
    return text;
  }

  /// 할일 내용 추출
  String _extractTaskContent(String text) {
    // "내가 할게" 뒤의 내용 추출
    final triggers = ['내가 할게', '내가 해', '해야 해', '해야겠', '해놔야'];
    for (var t in triggers) {
      if (text.contains(t)) {
        final idx = text.indexOf(t);
        // 트리거 앞부분이 할일 내용
        if (idx > 0) {
          return text.substring(0, idx).trim();
        }
        // 트리거 뒷부분
        if (idx + t.length < text.length) {
          return text.substring(idx + t.length).trim();
        }
      }
    }
    return text;
  }
}
