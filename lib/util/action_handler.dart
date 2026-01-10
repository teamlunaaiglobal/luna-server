import '../services/secretary/secretary_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

import '../screens/tool_signature.dart';

// [1] 기억 저장소 (영구 저장 지원)
class PreferenceManager {
  static Map<String, int> _scores = {};
  static DateTime? _lastInterventionTime;
  static const String _keyScores = 'luna_preference_scores';
  static const String _keyLastIntervention = 'luna_last_intervention';
  static bool _isLoaded = false;

  // 초기 로드
  static Future<void> load() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = prefs.getString(_keyScores);
    if (scoresJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(scoresJson);
      _scores = decoded.map((k, v) => MapEntry(k, v as int));
    }
    final lastStr = prefs.getString(_keyLastIntervention);
    if (lastStr != null) {
      _lastInterventionTime = DateTime.parse(lastStr);
    }
    _isLoaded = true;
    debugPrint("📂 선호도 로드 완료: ${_scores.length}개 항목");
  }

  // 저장
  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyScores, jsonEncode(_scores));
    if (_lastInterventionTime != null) {
      await prefs.setString(_keyLastIntervention, _lastInterventionTime!.toIso8601String());
    }
  }

  static int getScore(String contextKey, String valueKey) {
    return _scores["$contextKey|$valueKey"] ?? 0;
  }

  static Future<void> updateScore(String contextKey, String valueKey, bool isPositive) async {
    String key = "$contextKey|$valueKey";
    int current = _scores[key] ?? 0;
    _scores[key] = current + (isPositive ? 1 : -1);
    await _save();
    debugPrint("💾 선호도 업데이트: $key = ${_scores[key]}");
  }

  static bool canIntervene() {
    if (_lastInterventionTime == null) return true;
    final diff = DateTime.now().difference(_lastInterventionTime!);
    return diff.inMinutes >= 30;
  }

  static Future<void> markIntervention() async {
    _lastInterventionTime = DateTime.now();
    await _save();
  }
}

// [2] 루나 행동 제어기
class ActionHandler {
  static void execute(BuildContext context, String actionId, String title) {
    debugPrint("Action Triggered: $actionId");

    // --- [비서 모드] ---
    if (actionId.startsWith("brief_")) {
      _showToast(context, "☀️ 오늘의 핵심 업무를 브리핑합니다.");
      return;
    }

    if (actionId.startsWith("sch_") || actionId == "app_calendar") {
      _launchCalendar(context);
      return;
    }

    if (actionId.startsWith("task_")) {
      // ignore: deprecated_member_use
      Share.share("✅ [$title]\n\n- ", subject: "업무 기록");
      return;
    }

    // --- [현장 도구] ---
    if (actionId == "meet_record" ||
        actionId == "quick_voice_memo" ||
        actionId == "tool_record") {
      _launchNativeRecorder(context);
      return;
    }

    if (actionId == "quick_call_memo") {
      _launchPhone(context, "");
      return;
    }

    if (actionId.startsWith("quick_")) {
      // ignore: deprecated_member_use
      Share.share("📝 [루나 메모]\n\n내용:", subject: "빠른 메모");
      return;
    }

    // 회식 추천 (눈치 모드)
    if (actionId == "meet_recommend_place") {
      _triggerSilentContext(context, "context:after_meeting_dinner");
      return;
    }

    // --- [나머지 도구들] ---
    if (actionId == "doc_trans") {
      _launchBrowser(context, "https://translate.google.com/?sl=auto&tl=ko");
      return;
    }
    if (actionId == "tool_sign") {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const ToolSignatureScreen()));
      return;
    }
    if (actionId == "tool_scan") {
      _launchNativeCamera(context);
      return;
    }
    if (actionId == "tool_timer") {
      _launchNativeTimer(context);
      return;
    }
    if (actionId == "app_map") {
      _launchMap(context);
      return;
    }
    if (actionId == "app_taxi") {
      _launchBrowser(
          context, "https://m.map.kakao.com/actions/searchView?q=택시승강장");
      return;
    }

    _showToast(context, "['$title'] 실행");
  }

  /// BuildContext 없이 실행 가능한 액션 (LunaProcessor용)
  static Future<String> executeAction(String input) async {
    // 이메일 초안 모드
    if (SecretaryService.isEmailDraftMode(input)) {
      return "EMAIL_DRAFT_MODE";
    }

    // 대화 검색 모드
    if (SecretaryService.isSearchConversationMode(input)) {
      return "SEARCH_CONVERSATION_MODE";
    }

    // 비서 서비스 처리
    if (SecretaryService.canHandle(input)) {
      return await SecretaryService.instance.handle(input);
    }

    return "";
  }

  // ============================================================
  // [C] AI 판단 (The Brain)
  // ============================================================

  static void _triggerSilentContext(BuildContext context, String contextKey) {
    if (!PreferenceManager.canIntervene()) {
      debugPrint("🤫 루나: 쿨다운 중이라 침묵합니다.");
      return;
    }

    int meatScore =
        PreferenceManager.getScore(contextKey, "category:meat_grill");

    String message = "회식 장소로 이동하실까요?";

    // [수정] 중괄호 {} 추가로 경고 해결
    if (meatScore > 0) {
      message = "자주 가시는 '고기집' 리스트를 준비했습니다.";
    } else if (meatScore < 0) {
      message = "오늘은 깔끔한 '일식' 어떠세요?";
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("💡 $message"),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: "보기",
          onPressed: () {
            _launchMap(context);
            PreferenceManager.updateScore(
                contextKey, "category:meat_grill", true);
          },
        ),
      ),
    );

    PreferenceManager.markIntervention();
  }

  // ============================================================
  // [Native Launchers]
  // ============================================================

  static Future<void> _launchNativeTimer(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        const intent = AndroidIntent(
          action: 'android.intent.action.SET_TIMER',
          arguments: <String, dynamic>{
            'android.intent.extra.alarm.SKIP_UI': false
          },
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      } else {
        final Uri uri = Uri.parse("clock-timer://");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  static Future<void> _launchNativeRecorder(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        const intent = AndroidIntent(
          action: 'android.provider.MediaStore.RECORD_SOUND',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      }
    } catch (e) {
      // Ignore
    }
  }

  static Future<void> _launchNativeCamera(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        const intent = AndroidIntent(
          action: 'android.media.action.IMAGE_CAPTURE',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      }
    } catch (e) {
      // Ignore
    }
  }

  static Future<void> _launchCalendar(BuildContext context) async {
    try {
      Uri uri = Platform.isAndroid
          ? Uri.parse(
              "content://com.android.calendar/time/${DateTime.now().millisecondsSinceEpoch}")
          : Uri.parse("calshow://");
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      // Ignore
    }
  }

  static Future<void> _launchMap(BuildContext context) async {
    try {
      Uri uri = Platform.isAndroid
          ? Uri.parse("geo:0,0?q=")
          : Uri.parse("https://maps.apple.com/?q=");
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint("Map launch failed: $e");
    }
  }

  static Future<void> _launchBrowser(BuildContext context, String url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      // Ignore
    }
  }

  static Future<void> _launchPhone(BuildContext context, String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating),
    );
  }
}
