import '../../core/memory_service.dart';
import '../proactive/proactive_engine.dart';

class BriefingService {
  static final BriefingService instance = BriefingService._internal();
  factory BriefingService() => instance;
  BriefingService._internal();

  final MemoryService _memory = MemoryService();

  /// 아침 브리핑 생성
  Future<String> generateBriefing() async {
    var schedules = await _memory.getItems('schedule');
    var todos = await _memory.getItems('todo');
    var reminders = await _memory.getItems('reminder');
    
    String briefing = "☀️ 오늘의 브리핑이야!\n\n";
    
    if (schedules.isNotEmpty) {
      briefing += "📅 일정:\n";
      briefing += schedules.take(3).map((e) => "• ${e['content']}").join('\n');
      briefing += "\n\n";
    }
    
    if (todos.isNotEmpty) {
      briefing += "✅ 할일:\n";
      briefing += todos.take(3).map((e) => "• ${e['content']}").join('\n');
      briefing += "\n\n";
    }
    
    if (reminders.isNotEmpty) {
      briefing += "🔔 리마인더:\n";
      briefing += reminders.take(3).map((e) => "• ${e['content']}").join('\n');
      briefing += "\n\n";
    }

    // 기념일 정보 추가
    try {
      String anniversaryInfo = ProactiveEngine.instance.getAnniversaryBriefing();
      if (anniversaryInfo.isNotEmpty) {
        briefing += anniversaryInfo;
      }
    } catch (e) {
      // ProactiveEngine 초기화 안 됐으면 스킵
    }
    
    if (schedules.isEmpty && todos.isEmpty && reminders.isEmpty) {
      return "오늘은 등록된 일정이 없어. 여유로운 하루 보내!";
    }
    
    return briefing;
  }

  /// 브리핑 관련 입력인지 확인
  static bool canHandle(String input) {
    final lower = input.toLowerCase();
    return lower.contains('브리핑') || 
           lower.contains('오늘 뭐') || 
           lower.contains('오늘 할') || 
           lower.contains('morning') || 
           lower.contains('요약해');
  }

  /// 브리핑 처리
  Future<String> handle(String input) async {
    return await generateBriefing();
  }
}
