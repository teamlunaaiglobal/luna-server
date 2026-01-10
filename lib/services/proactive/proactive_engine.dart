import 'package:flutter/foundation.dart';
import '../../models/proactive/detected_context.dart';
import '../../models/proactive/proactive_action.dart';
import 'context_detector.dart';
import 'timing_judge.dart';
import 'action_suggester.dart';
import 'anniversary_manager.dart';

class ProactiveEngine {
  static final ProactiveEngine instance = ProactiveEngine._internal();
  factory ProactiveEngine() => instance;
  ProactiveEngine._internal();

  final ContextDetector _detector = ContextDetector.instance;
  final TimingJudge _judge = TimingJudge.instance;
  final ActionSuggester _suggester = ActionSuggester.instance;
  final AnniversaryManager _anniversary = AnniversaryManager.instance;

  // 대기 중인 액션들 (afterConvo용)
  final List<ProactiveAction> _pendingActions = [];
  
  bool _isInitialized = false;

  /// 초기화
  Future<void> init() async {
    if (_isInitialized) return;
    await _anniversary.init();
    _isInitialized = true;
    debugPrint('🧠 ProactiveEngine 초기화 완료');
  }

  /// 메시지 분석 후 즉시 제안 반환
  ProactiveAction? analyze(String input) {
    // 1. 맥락 감지
    final context = _detector.detect(input);
    if (context == null) return null;

    debugPrint('🔍 맥락 감지: ${context.type} - "${context.keyword}"');

    // 2. 타이밍 판단
    final timing = _judge.judgeTiming(context);

    // 3. 쿨다운 체크
    if (!_judge.canSuggestNow()) {
      debugPrint('⏳ 쿨다운 중 - 제안 보류');
      return null;
    }

    // 4. 제안 생성
    final action = _suggester.suggest(context);
    if (action == null) return null;

    // 5. 타이밍에 따라 처리
    if (timing == ActionTiming.immediate) {
      _judge.markSuggestion();
      return action;
    } else if (timing == ActionTiming.afterConvo) {
      _pendingActions.add(action);
      debugPrint('📌 대화 후 제안 예약: ${action.message}');
      return null;
    }

    return null;
  }

  /// 대화 종료 시 대기 중인 제안 반환
  List<ProactiveAction> getPendingActions() {
    final actions = List<ProactiveAction>.from(_pendingActions);
    _pendingActions.clear();
    return actions;
  }

  /// 대기 중인 제안 있는지 확인
  bool hasPendingActions() => _pendingActions.isNotEmpty;

  /// 오늘의 기념일 체크
  List<ProactiveAction> checkAnniversaries() {
    return _anniversary.checkTodayActions();
  }

  /// 아침 브리핑용 기념일 정보
  String getAnniversaryBriefing() {
    final upcoming = _anniversary.getUpcoming(days: 7);
    if (upcoming.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('💝 다가오는 기념일:');
    for (var anni in upcoming) {
      final dday = anni.getDday();
      if (dday == 0) {
        buffer.writeln('  🎉 오늘: ${anni.name}');
      } else {
        buffer.writeln('  • D-$dday: ${anni.name}');
      }
    }
    return buffer.toString();
  }

  /// 기념일 긴급 모드
  ProactiveAction? triggerEmergency(String anniversaryId) {
    return _anniversary.emergencyMode(anniversaryId);
  }

  /// 기념일 추가 (대화에서 감지된 경우)
  Future<void> addAnniversaryFromContext(DetectedContext context) async {
    // TODO: 날짜 파싱 후 기념일 추가
    // 지금은 사용자에게 추가 정보 요청하는 방식으로
    debugPrint('📅 기념일 추가 요청: ${context.originalText}');
  }
}
