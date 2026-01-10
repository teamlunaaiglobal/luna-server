import '../../models/proactive/anniversary.dart';
import '../../models/proactive/proactive_action.dart';
import '../../data/anniversary_repository.dart';

class AnniversaryManager {
  static final AnniversaryManager instance = AnniversaryManager._internal();
  factory AnniversaryManager() => instance;
  AnniversaryManager._internal();

  final AnniversaryRepository _repo = AnniversaryRepository.instance;

  /// 초기화
  Future<void> init() async {
    await _repo.init();
  }

  /// 기념일 추가
  Future<void> addAnniversary({
    required String name,
    required AnniversaryType type,
    required int month,
    required int day,
    int? year,
    bool isLunar = false,
  }) async {
    final anniversary = Anniversary(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
      month: month,
      day: day,
      year: year,
      isLunar: isLunar,
      checklist: _getDefaultChecklist(type),
    );
    await _repo.add(anniversary);
  }

  /// 기본 체크리스트 생성
  List<String> _getDefaultChecklist(AnniversaryType type) {
    switch (type) {
      case AnniversaryType.birthday:
        return ['선물 준비', '케이크 예약', '축하 메시지'];
      case AnniversaryType.wedding:
        return ['선물 준비', '레스토랑 예약', '꽃 주문', '카드 쓰기'];
      case AnniversaryType.dating:
        return ['선물 준비', '데이트 코스', '레스토랑 예약'];
      case AnniversaryType.memorial:
        return ['방문 준비', '꽃 준비'];
      case AnniversaryType.custom:
        return ['준비하기'];
    }
  }

  /// 오늘 체크할 기념일 액션 생성
  List<ProactiveAction> checkTodayActions() {
    List<ProactiveAction> actions = [];

    // 오늘인 기념일
    for (var anni in _repo.getToday()) {
      actions.add(ProactiveAction(
        id: 'anni_today_${anni.id}',
        type: ActionType.remind,
        timing: ActionTiming.immediate,
        message: '🎉 오늘은 ${anni.name}이에요! 잊지 않으셨죠?',
        createdAt: DateTime.now(),
      ));
    }

    // 긴급 (D-3 이내)
    for (var anni in _repo.getUrgent()) {
      if (anni.getDday() > 0) {
        actions.add(ProactiveAction(
          id: 'anni_urgent_${anni.id}',
          type: ActionType.remind,
          timing: ActionTiming.immediate,
          message: '⚠️ ${anni.name}이 D-${anni.getDday()}이에요! 준비는 되셨나요?',
          createdAt: DateTime.now(),
        ));
      }
    }

    // D-7 알림
    for (var anni in _repo.getUpcoming(withinDays: 7)) {
      if (anni.getDday() == 7) {
        actions.add(ProactiveAction(
          id: 'anni_week_${anni.id}',
          type: ActionType.remind,
          timing: ActionTiming.scheduled,
          message: '📅 ${anni.name}이 일주일 남았어요! 체크리스트: ${anni.checklist.join(", ")}',
          createdAt: DateTime.now(),
        ));
      }
    }

    // D-30 알림 (첫 알림)
    for (var anni in _repo.getUpcoming(withinDays: 30)) {
      if (anni.getDday() == 30) {
        actions.add(ProactiveAction(
          id: 'anni_month_${anni.id}',
          type: ActionType.suggest,
          timing: ActionTiming.scheduled,
          message: '💡 ${anni.name}이 한 달 남았어요. 미리 준비하시겠어요?',
          createdAt: DateTime.now(),
        ));
      }
    }

    return actions;
  }

  /// 긴급 모드 - 당일 잊었을 때 구출
  ProactiveAction? emergencyMode(String anniversaryId) {
    final anni = _repo.all.where((a) => a.id == anniversaryId).firstOrNull;
    if (anni == null || anni.getDday() != 0) return null;

    return ProactiveAction(
      id: 'emergency_${anni.id}',
      type: ActionType.suggest,
      timing: ActionTiming.immediate,
      message: '''🚨 긴급 모드 발동!
${anni.name} 오늘인데 준비 안 하셨죠?

급한 불 끄기:
1. 근처 꽃집 찾기
2. 당일 예약 가능한 레스토랑
3. 빠른 배송 선물

뭐부터 도와드릴까요?''',
      actionCommand: 'emergency_anniversary',
      createdAt: DateTime.now(),
    );
  }

  /// 모든 기념일 조회
  List<Anniversary> getAllAnniversaries() => _repo.all;

  /// 다가오는 기념일 조회
  List<Anniversary> getUpcoming({int days = 30}) => _repo.getUpcoming(withinDays: days);
}
