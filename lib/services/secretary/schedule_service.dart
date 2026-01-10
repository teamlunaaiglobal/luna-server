import '../../core/memory_service.dart';

class ScheduleService {
  static final ScheduleService instance = ScheduleService._internal();
  factory ScheduleService() => instance;
  ScheduleService._internal();

  final MemoryService _memory = MemoryService();

  /// 일정 추가
  Future<String> addSchedule(String input) async {
    String content = input.replaceAll(RegExp(r'(일정|스케줄|약속|추가|등록|해줘|해)'), '').trim();
    if (content.isNotEmpty) {
      await _memory.addItem('schedule', content);
      return "일정 추가했어! '$content'";
    }
    return "어떤 일정을 추가할까?";
  }

  /// 일정 조회
  Future<String> getSchedules() async {
    var schedules = await _memory.getItems('schedule');
    if (schedules.isEmpty) return "등록된 일정이 없어.";
    String list = schedules.asMap().entries.map((e) => "${e.key + 1}. ${e.value['content']}").join('\n');
    return "네 일정이야:\n$list";
  }

  /// 리마인더 추가
  Future<String> addReminder(String input) async {
    String content = input.replaceAll(RegExp(r'(리마인더|알려줘|remind|잊지 않게|해줘|해)'), '').trim();
    if (content.isNotEmpty) {
      await _memory.addItem('reminder', content);
      return "리마인더 설정했어! '$content'";
    }
    return "뭘 리마인드할까?";
  }

  /// 리마인더 조회
  Future<String> getReminders() async {
    var reminders = await _memory.getItems('reminder');
    if (reminders.isEmpty) return "설정된 리마인더가 없어.";
    String list = reminders.asMap().entries.map((e) => "${e.key + 1}. ${e.value['content']}").join('\n');
    return "네 리마인더야:\n$list";
  }

  /// 할일 추가
  Future<String> addTodo(String input) async {
    String content = input.replaceAll(RegExp(r'(할일|할 일|투두|todo|추가|해줘|해)'), '').trim();
    if (content.isNotEmpty) {
      await _memory.addItem('todo', content);
      return "할일 추가했어! '$content'";
    }
    return "어떤 할일을 추가할까?";
  }

  /// 할일 조회
  Future<String> getTodos() async {
    var todos = await _memory.getItems('todo');
    if (todos.isEmpty) return "등록된 할일이 없어.";
    String list = todos.asMap().entries.map((e) => "${e.key + 1}. ${e.value['content']}").join('\n');
    return "네 할일 목록이야:\n$list";
  }

  /// 일정 관련 입력인지 확인
  static bool canHandle(String input) {
    final lower = input.toLowerCase();
    return lower.contains('일정') || 
           lower.contains('스케줄') || 
           lower.contains('약속') ||
           lower.contains('리마인더') || 
           lower.contains('remind') ||
           lower.contains('할일') || 
           lower.contains('할 일') || 
           lower.contains('투두') || 
           lower.contains('todo');
  }

  /// 일정 관련 처리
  Future<String> handle(String input) async {
    final lower = input.toLowerCase();
    
    // 일정
    if (lower.contains('일정 보여') || lower.contains('일정 뭐') || 
        lower.contains('일정 확인') || lower.contains('오늘 일정') || 
        lower.contains('스케줄')) {
      if (!lower.contains('추가') && !lower.contains('등록')) {
        return await getSchedules();
      }
    }
    if (lower.contains('일정 추가') || lower.contains('일정 등록') || 
        lower.contains('스케줄 추가') || lower.contains('약속 추가')) {
      return await addSchedule(input);
    }

    // 리마인더
    if (lower.contains('리마인더 보여') || lower.contains('리마인더 확인') || 
        lower.contains('리마인더 목록')) {
      return await getReminders();
    }
    if (lower.contains('리마인더') || lower.contains('알려줘') || 
        lower.contains('remind') || lower.contains('잊지 않게')) {
      return await addReminder(input);
    }

    // 할일
    if (lower.contains('할일 보여') || lower.contains('할일 확인') || 
        lower.contains('투두 목록') || lower.contains('할 일 뭐')) {
      return await getTodos();
    }
    if (lower.contains('할일 추가') || lower.contains('투두') || 
        lower.contains('todo') || lower.contains('할 일 추가')) {
      return await addTodo(input);
    }

    return "";
  }
}
