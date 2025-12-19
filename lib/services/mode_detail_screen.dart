import 'package:flutter/material.dart';

// [1] 기억 저장소
class PreferenceManager {
  // [수정] final 키워드 추가 (경고 해결)
  static final Map<String, int> _scores = {};

  static int getScore(String contextKey, String valueKey) {
    return _scores["$contextKey|$valueKey"] ?? 0;
  }

  static void updateScore(String contextKey, String valueKey, bool isPositive) {
    String key = "$contextKey|$valueKey";
    int current = _scores[key] ?? 0;
    _scores[key] = current + (isPositive ? 1 : -1);
    
    // [수정] print -> debugPrint (경고 해결)
    debugPrint("[Brain] Memory Updated: $key = ${_scores[key]}");
  }
}

// [2] 루나 행동 제어기
class ActionHandler {
  
  // 음성 피드백을 위해 마지막 상황을 기억하는 변수들
  static String? _lastContextKey;
  static String? _lastTargetFeature;

  // ============================================================
  // [A] 외부 자극 (Trigger)
  // ============================================================

  // 1. 수동 실행 (버튼)
  static void execute(BuildContext context, String actionId, String title) {
    if (actionId == "meet_recommend_place") {
      // 강제 호출 (Force Mode)
      _triggerContextEvent(context, "context:after_meeting_dinner", isForced: true); 
      return;
    }
    
    // 시스템 위임
    if (actionId.startsWith("sch_") || actionId == "app_calendar") {
      _showToast(context, "기본 달력 앱을 엽니다.");
      return;
    }
    if (actionId.startsWith("app_")) {
      _showToast(context, "$title 앱을 실행합니다.");
      return;
    }

    _showToast(context, "['$title'] 실행");
  }

  // 2. 음성/텍스트 입력 처리 (Hybrid Input)
  // [수정] 이 함수를 추가하여 _lastContextKey 변수 사용 경고를 해결함
  static void handleUserSpeech(BuildContext context, String userText) {
    debugPrint("🗣️ User said: $userText");

    // 저장된 맥락이 없으면 종료
    if (_lastContextKey == null || _lastTargetFeature == null) {
      _showToast(context, "루나: (지금은 피드백할 주제가 없어요)");
      return;
    }

    // 긍정/부정 판단
    bool? sentiment;
    if (userText.contains("좋아") || userText.contains("응") || userText.contains("진행")) {
      sentiment = true;
    } else if (userText.contains("별로") || userText.contains("아니") || userText.contains("싫어")) {
      sentiment = false;
    }

    if (sentiment != null) {
      // 맥락 변수 사용 (_lastContextKey)
      _applyFeedback(context, _lastContextKey!, _lastTargetFeature!, sentiment);
    } else {
      _showToast(context, "루나: 긍정/부정으로 말씀해주세요.");
    }
  }

  // ============================================================
  // [B] 판단 및 개입 레이어
  // ============================================================

  static void _triggerContextEvent(BuildContext context, String contextKey, {required bool isForced}) {
    
    String targetFeature = ""; 
    // [수정] 불필요한 interventionType 변수 삭제 (경고 해결)

    if (contextKey == "context:after_meeting_dinner") {
      targetFeature = "category:meat_grill"; 
    }

    // 개입 여부 판단
    int patienceScore = PreferenceManager.getScore(contextKey, "intervention:allowed");

    if (!isForced && patienceScore <= -2) {
      debugPrint("🤫 루나: 사용자 거부 이력으로 침묵 ($contextKey)");
      return; 
    }

    // 멘트 준비
    String dialogTitle = "";
    String dialogContent = "";
    int prefScore = PreferenceManager.getScore(contextKey, targetFeature);

    if (contextKey == "context:after_meeting_dinner") {
      if (prefScore < 0) {
        dialogTitle = "🐟 식사 장소 체크";
        dialogContent = "대표님, 회의 후 식사 시간입니다.\n지난번처럼 깔끔한 일식으로 잡을까요?";
      } else {
        dialogTitle = "🥩 식사 장소 체크";
        dialogContent = "대표님, 회의 끝나셨죠?\n자주 가시던 고기집으로 준비할까요?";
      }
    }

    // [수정] 여기서 변수에 값을 할당하여 'unused' 경고 해결 및 음성 피드백 준비
    _lastContextKey = contextKey;
    _lastTargetFeature = targetFeature; 
    
    _showFeedbackDialog(context, dialogTitle, dialogContent, contextKey, targetFeature);
  }

  // ============================================================
  // [C] 피드백 처리
  // ============================================================

  static void _applyFeedback(BuildContext context, String ctxKey, String featKey, bool isPositive) {
    
    // 취향 학습
    PreferenceManager.updateScore(ctxKey, featKey, isPositive);
    // 개입 허용도 학습
    PreferenceManager.updateScore(ctxKey, "intervention:allowed", isPositive);

    String msg = isPositive 
        ? "넵, 준비하겠습니다! (취향 저장됨 📈)" 
        : "알겠습니다. (취향 저장됨 📉)";
    
    _showToast(context, msg);

    // [수정] 사용 완료 후 초기화
    _lastContextKey = null;
    _lastTargetFeature = null;
  }

  // --- Helper Methods ---
  
  static void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(milliseconds: 1000), behavior: SnackBarBehavior.floating),
    );
  }
  
  static void _showFeedbackDialog(BuildContext context, String title, String content, String ctxKey, String featKey) {
      showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _applyFeedback(context, ctxKey, featKey, false);
            },
            child: const Text("아니/됐어"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _applyFeedback(context, ctxKey, featKey, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            child: const Text("응, 부탁해"),
          ),
        ],
      ),
    );
  }
}