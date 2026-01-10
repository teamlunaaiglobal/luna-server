import '../meeting/meeting_service.dart';
import 'memo_service.dart';
import 'schedule_service.dart';
import 'briefing_service.dart';
import 'app_launcher_service.dart';
import 'scan_service.dart';

class SecretaryService {
  static final SecretaryService instance = SecretaryService._internal();
  factory SecretaryService() => instance;
  SecretaryService._internal();

  final MemoService _memo = MemoService.instance;
  final ScheduleService _schedule = ScheduleService.instance;
  final BriefingService _briefing = BriefingService.instance;
  final AppLauncherService _appLauncher = AppLauncherService.instance;
  final ScanService _scan = ScanService.instance;
  final MeetingService _meeting = MeetingService.instance;

  /// 비서 모드 처리 가능한지 확인
  static bool canHandle(String input) {
    return MemoService.canHandle(input) ||
           ScheduleService.canHandle(input) ||
           BriefingService.canHandle(input) ||
           AppLauncherService.canHandle(input) ||
           ScanService.canHandle(input) ||
           MeetingService.canHandle(input);
  }

  /// 비서 모드 메인 라우터
  Future<String> handle(String input) async {
    // 1. 메모
    if (MemoService.canHandle(input)) {
      return await _memo.handle(input);
    }

    // 2. 일정/리마인더/할일
    if (ScheduleService.canHandle(input)) {
      return await _schedule.handle(input);
    }

    // 3. 브리핑
    if (BriefingService.canHandle(input)) {
      return await _briefing.handle(input);
    }

    // 4. 앱 실행
    if (AppLauncherService.canHandle(input)) {
      return await _appLauncher.handle(input);
    }

    // 5. 스캔
    if (ScanService.canHandle(input)) {
      return await _scan.handle(input);
    }

    // 6. 회의
    if (MeetingService.canHandle(input)) {
      return await _meeting.handle(input);
    }

    return "";
  }

  /// 이메일 초안 모드인지 확인
  static bool isEmailDraftMode(String input) {
    final lower = input.toLowerCase();
    return lower.contains('이메일 작성') || 
           lower.contains('메일 써') || 
           lower.contains('이메일 초안') || 
           lower.contains('메일 작성');
  }

  /// 대화 검색 모드인지 확인
  static bool isSearchConversationMode(String input) {
    final lower = input.toLowerCase();
    return lower.contains('대화 검색') || 
           lower.contains('대화 찾아') || 
           lower.contains('뭐라고 했') || 
           lower.contains('언제 얘기');
  }
}
