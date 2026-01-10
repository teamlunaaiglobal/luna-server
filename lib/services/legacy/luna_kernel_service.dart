/// 루나 시스템의 모드 정의
enum LunaMode {
  assistant, // [신규] 비서 모드 (일정, 업무, 정보)
  teacher,   // [신규] 선생님 모드 (학습, 교육)
  friend,    // 친구 모드 (감성 대화)
  system,    // 시스템/설정
}

/// 모든 기능 모듈이 구현해야 하는 공통 규약 (인터페이스)
abstract class LunaModule {
  /// 모듈의 고유 ID (예: 'schedule_manager', 'english_tutor')
  String get id;

  /// 이 모듈이 작동하는 모드 리스트 (하나의 모듈이 여러 모드에서 동작 가능)
  List<LunaMode> get supportedModes;

  /// 모듈 초기화 로직 (앱 실행 시 또는 모듈 로드 시 호출)
  Future<void> initialize();

  /// 명령어 실행 (커널이 명령을 내릴 때 호출)
  Future<void> execute(String command);

  /// 에러 처리 (실행 중 문제 발생 시 호출)
  Future<void> handleFailure(String error);
}