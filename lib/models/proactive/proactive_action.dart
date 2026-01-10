enum ActionTiming {
  immediate,    // 즉시 제안
  afterConvo,   // 대화 끝나고
  scheduled,    // 특정 시간에
  onTrigger,    // 트리거 발생 시
}

enum ActionType {
  suggest,      // 추천
  remind,       // 리마인드
  autoAdd,      // 자동 추가
  ask,          // 확인 질문
}

class ProactiveAction {
  final String id;
  final ActionType type;
  final ActionTiming timing;
  final String message;           // 사용자에게 보여줄 메시지
  final String? actionCommand;    // 실행할 명령 (옵션)
  final DateTime createdAt;
  final DateTime? executeAt;      // 예약 실행 시간

  ProactiveAction({
    required this.id,
    required this.type,
    required this.timing,
    required this.message,
    this.actionCommand,
    required this.createdAt,
    this.executeAt,
  });
}