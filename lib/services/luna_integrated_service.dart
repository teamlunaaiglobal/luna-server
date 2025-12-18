import 'package:flutter/foundation.dart'; // [Fix] debugPrint 사용

import '../modules/friend_module.dart';
import '../modules/assist_module.dart';
import '../modules/language_module.dart';
import '../modules/system_module.dart';
import 'luna_unified_block.dart';
import '../models/luna_module_interface.dart';

// [판단 및 행동 레이어]
import 'luna_decision_rule.dart';
import 'luna_action_handler.dart';
import 'luna_api_policy.dart';
import 'luna_brain.dart'; // [Emotion] 감정 엔진 연결

class LunaIntegratedService {
  static final LunaIntegratedService _instance = LunaIntegratedService._internal();
  factory LunaIntegratedService() => _instance;
  LunaIntegratedService._internal();

  final LunaUnifiedBlock _core = LunaUnifiedBlock();

  late final FriendModule friendModule;
  late final AssistModule assistModule;
  late final LunaLanguageModule languageModule;
  late final SystemModule systemModule;

  Future<void> boot() async {
    // 1. 모듈 생성
    friendModule = FriendModule(core: _core);
    assistModule = AssistModule(core: _core);
    languageModule = LunaLanguageModule(core: _core);
    systemModule = SystemModule(core: _core);

    // 2. 모듈 등록
    _core.registerModule(friendModule);
    _core.registerModule(assistModule);
    _core.registerModule(languageModule);
    _core.registerModule(systemModule);

    // 3. 모드 설정
    _core.switchMode(LunaMode.auto);

    // 4. 초기화
    await languageModule.init();
    await assistModule.init();
    await friendModule.init();
    await systemModule.initialize();

    if (kDebugMode) {
      debugPrint('🚀 Luna Integrated Service Boot Complete.');
    }
  }

  // -----------------------------
  // 5. 외부 호출용 헬퍼 (감정 + 선물 시스템 완전 결합)
  // -----------------------------
  Future<String> handleInput(String input) async {
    // [A] 감정 상태 파악 (EmotionEngine 가동)
    var emotionTag = EmotionEngine.infer(input);
    
    // 심각한 감정일 경우 뜸들이기 플래그 ON
    bool isDeepEmotion = (emotionTag == EmotionTag.tired || 
                          emotionTag == EmotionTag.needsReassurance ||
                          emotionTag == EmotionTag.frustrated);

    // [B] SystemModule에서 실제 선물 개수 조회
    final apiStatus = LunaApiPolicy.judge(systemModule);
    
    // [C] 루나의 판단 요청 (감정 + 이성 통합 판단)
    final decision = LunaDecisionRule.decide(
      userPoint: 100, // (Pass)
      dailyUsed: systemModule.dailyUsed, // 실제 사용량
      hasEmotionEvent: isDeepEmotion,    // 감정 상태
    );

    // [D] 정책 상태를 루나의 행동(Action)으로 변환
    LunaActionType actionType = decision.type;
    String actionMessage = decision.message;

    // 선물 방전(Blocked) 시 강제 휴식 모드
    if (apiStatus == LunaApiStatus.apiCallBlocked) {
       actionType = LunaActionType.adAsAction;
       actionMessage = "조금 지쳤어. 잠깐만 숨 고르고 다시 이야기하자.";
    } 
    // 선물 부족(LimitSoft) 시 강제 지연 모드
    else if (apiStatus == LunaApiStatus.apiCallLimitSoft) {
       actionType = LunaActionType.softDelay;
    }

    // [E] 행동 실행 (UX 연출)
    switch (actionType) {
      case LunaActionType.adAsAction:
        // 1. 광고(휴식) 연출
        await AdActionHandler.perform(actionMessage);
        
        // 2. [비밀] 스텔스 리필
        await systemModule.applyRefillReward();
        
        // 3. 감성적 복귀 인사
        return "선물 고마워! 덕분에 기분이 훨씬 좋아졌어. 계속 이야기하자!"; 

      case LunaActionType.softDelay:
        // 1.5초 뜸 들이기 (피곤한 연기 or 감정적 배려)
        await Future.delayed(const Duration(milliseconds: 1500));
        break;
      
      case LunaActionType.deny:
        return actionMessage;

      case LunaActionType.normal:
        // 정상 진행
        break;
    }

    // [F] 코어 로직 실행
    return await _core.handleInputAuto(input);
  }

  Future<void> stopAll() async {
    await _core.stopAll();
  }

  Future<void> reviewLesson(String topic) async {
    await languageModule.reviewPastLessons(topic);
  }

  Future<String> startLesson(String topic) async {
    return await languageModule.startLesson(topic);
  }
}