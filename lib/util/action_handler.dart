import '../services/hardware/luna_vision_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart'; 
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

import '../screens/tool_signature.dart';
import '../core/memory_service.dart';

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
    if (actionId == "meet_record" || actionId == "quick_voice_memo" || actionId == "tool_record") {
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
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ToolSignatureScreen()));
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
      _launchBrowser(context, "https://m.map.kakao.com/actions/searchView?q=택시승강장");
      return;
    }
    
    _showToast(context, "['$title'] 실행");
  }

  /// BuildContext 없이 실행 가능한 액션 (LunaProcessor용)
  static Future<String> executeAction(String input) async {
    final lower = input.toLowerCase();
    
    // 캘린더/일정
    if (lower.contains('일정') || lower.contains('캘린더') || lower.contains('calendar')) {
      await _launchCalendarDirect();
      return "캘린더를 열었어요!";
    }
    
    // 알람/타이머
    if (lower.contains('알람') || lower.contains('타이머') || lower.contains('timer')) {
      await _launchTimerDirect();
      return "타이머를 열었어요!";
    }
    
    // 녹음
    if (lower.contains('녹음') || lower.contains('record')) {
      await _launchRecorderDirect();
      return "녹음기를 열었어요!";
    }
    
    // 카메라
    if (lower.contains('카메라') || lower.contains('camera') || lower.contains('사진')) {
      await _launchCameraDirect();
      return "카메라를 열었어요!";
    }
    
    // 지도
    if (lower.contains('지도') || lower.contains('map') || lower.contains('길')) {
      await _launchMapDirect();
      return "지도를 열었어요!";
    }
    
    // 전화
    if (lower.contains('전화') || lower.contains('call') || lower.contains('통화')) {
      await _launchPhoneDirect();
      return "전화 앱을 열었어요!";
    }

    // 메모 저장
    if (lower.contains('메모해') || lower.contains('기록해') || lower.contains('적어') || lower.contains('메모 추가')) {
      String content = input.replaceAll(RegExp(r'(메모해|기록해|적어|메모 추가|줘|해줘)'), '').trim();
      if (content.isNotEmpty) {
        await MemoryService().addItem('memo', content);
        return "메모했어! '$content'";
      }
      return "뭘 메모할까?";
    }

    // 메모 조회
    if (lower.contains('메모 보여') || lower.contains('메모 뭐') || lower.contains('메모 목록') || lower.contains('메모 확인')) {
      var memos = await MemoryService().getItems('memo');
      if (memos.isEmpty) return "저장된 메모가 없어.";
      String list = memos.asMap().entries.map((e) => "${e.key + 1}. ${e.value['content']}").join('\n');
      return "네 메모 목록이야:\n$list";
    }

    // 일정 추가
    if (lower.contains('일정 추가') || lower.contains('일정 등록') || lower.contains('스케줄 추가') || lower.contains('약속 추가')) {
      String content = input.replaceAll(RegExp(r'(일정|스케줄|약속|추가|등록|해줘|해)'), '').trim();
      if (content.isNotEmpty) {
        await MemoryService().addItem('schedule', content);
        return "일정 추가했어! '$content'";
      }
      return "어떤 일정을 추가할까?";
    }

    // 일정 조회
    if (lower.contains('일정 보여') || lower.contains('일정 뭐') || lower.contains('일정 확인') || lower.contains('오늘 일정') || lower.contains('스케줄')) {
      var schedules = await MemoryService().getItems('schedule');
      if (schedules.isEmpty) return "등록된 일정이 없어.";
      String list = schedules.asMap().entries.map((e) => "${e.key + 1}. ${e.value['content']}").join('\n');
      return "네 일정이야:\n$list";
    }

    // 리마인더/알림 추가
    if (lower.contains('리마인더') || lower.contains('알려줘') || lower.contains('remind') || lower.contains('잊지 않게')) {
      String content = input.replaceAll(RegExp(r'(리마인더|알려줘|remind|잊지 않게|해줘|해)'), '').trim();
      if (content.isNotEmpty) {
        await MemoryService().addItem('reminder', content);
        return "리마인더 설정했어! '$content'";
      }
      return "뭘 리마인드할까?";
    }

    // 리마인더 조회
    if (lower.contains('리마인더 보여') || lower.contains('리마인더 확인') || lower.contains('리마인더 목록')) {
      var reminders = await MemoryService().getItems('reminder');
      if (reminders.isEmpty) return "설정된 리마인더가 없어.";
      String list = reminders.asMap().entries.map((e) => "${e.key + 1}. ${e.value['content']}").join('\n');
      return "네 리마인더야:\n$list";
    }

    // 할일 추가
    if (lower.contains('할일 추가') || lower.contains('투두') || lower.contains('todo') || lower.contains('할 일 추가')) {
      String content = input.replaceAll(RegExp(r'(할일|할 일|투두|todo|추가|해줘|해)'), '').trim();
      if (content.isNotEmpty) {
        await MemoryService().addItem('todo', content);
        return "할일 추가했어! '$content'";
      }
      return "어떤 할일을 추가할까?";
    }

    // 할일 조회
    if (lower.contains('할일 보여') || lower.contains('할일 확인') || lower.contains('투두 목록') || lower.contains('할 일 뭐')) {
      var todos = await MemoryService().getItems('todo');
      if (todos.isEmpty) return "등록된 할일이 없어.";
      String list = todos.asMap().entries.map((e) => "${e.key + 1}. ${e.value['content']}").join('\n');
      return "네 할일 목록이야:\n$list";
    }

    // 아침 브리핑 / 오늘 요약
    if (lower.contains('브리핑') || lower.contains('오늘 뭐') || lower.contains('오늘 할') || lower.contains('morning') || lower.contains('요약해')) {
      var schedules = await MemoryService().getItems('schedule');
      var todos = await MemoryService().getItems('todo');
      var reminders = await MemoryService().getItems('reminder');
      
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
      }
      
      if (schedules.isEmpty && todos.isEmpty && reminders.isEmpty) {
        return "오늘은 등록된 일정이 없어. 여유로운 하루 보내!";
      }
      
      return briefing;
    }

    // Focus Time / 집중 모드
    if (lower.contains('집중 모드') || lower.contains('focus') || lower.contains('방해 금지') || lower.contains('조용히')) {
      await _launchFocusModeDirect();
      return "집중 모드를 켰어! 화이팅! 💪";
    }

    // 문자
    if (lower.contains('문자') || lower.contains('메시지') || lower.contains('sms') || lower.contains('message')) {
      await _launchSmsDirect();
      return "문자 앱을 열었어!";
    }

    // 이메일
    if (lower.contains('이메일') || lower.contains('메일') || lower.contains('email') || lower.contains('gmail')) {
      await _launchEmailDirect();
      return "이메일 앱을 열었어!";
    }

    // 설정
    if (lower.contains('설정') || lower.contains('세팅') || lower.contains('setting')) {
      await _launchSettingsDirect();
      return "설정을 열었어!";
    }

    // 브라우저
    if (lower.contains('브라우저') || lower.contains('인터넷') || lower.contains('browser') || lower.contains('웹')) {
      await _launchBrowserDirect();
      return "브라우저를 열었어!";
    }

    // 계산기
    if (lower.contains('계산기') || lower.contains('calculator') || lower.contains('계산해')) {
      await _launchCalculatorDirect();
      return "계산기를 열었어!";
    }

    // 이메일 초안 작성
    if (lower.contains('이메일 작성') || lower.contains('메일 써') || lower.contains('이메일 초안') || lower.contains('메일 작성')) {
      return "EMAIL_DRAFT_MODE";
    }

    // 대화 검색
    if (lower.contains('대화 검색') || lower.contains('대화 찾아') || lower.contains('뭐라고 했') || lower.contains('언제 얘기')) {
      return "SEARCH_CONVERSATION_MODE";
    }

    // 영수증 스캔
    if (lower.contains('영수증') || lower.contains('receipt') || lower.contains('스캔')) {
      String result = await LunaVisionService.instance.scanReceipt();
      if (result.contains('취소') || result.contains('인식하지')) {
        return result;
      }
      await MemoryService().addItem('receipt', result);
      return "📄 영수증 스캔 완료!\n\n$result";
    }

    // 명함 스캔
    if (lower.contains('명함') || lower.contains('business card') || lower.contains('연락처 추가')) {
      String result = await LunaVisionService.instance.scanBusinessCard();
      if (result.contains('취소') || result.contains('인식하지')) {
        return result;
      }
      await MemoryService().addItem('contact', result);
      return "📇 명함 스캔 완료!\n\n$result";
    }
    
    return ""; // 매칭 안 되면 빈 문자열
  }

  // === Direct 런처들 (BuildContext 불필요) ===

  static Future<void> _launchSmsDirect() async {
    try {
      final uri = Uri(scheme: 'sms', path: '');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (e) {
      debugPrint("SMS launch failed: $e");
    }
  }

  static Future<void> _launchEmailDirect() async {
    try {
      final uri = Uri(scheme: 'mailto', path: '');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (e) {
      debugPrint("Email launch failed: $e");
    }
  }

  static Future<void> _launchSettingsDirect() async {
    try {
      if (Platform.isAndroid) {
        const intent = AndroidIntent(
          action: 'android.settings.SETTINGS',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      } else {
        final uri = Uri.parse("app-settings:");
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      }
    } catch (e) {
      debugPrint("Settings launch failed: $e");
    }
  }

  static Future<void> _launchBrowserDirect() async {
    try {
      final uri = Uri.parse("https://www.google.com");
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Browser launch failed: $e");
    }
  }

  static Future<void> _launchCalculatorDirect() async {
    try {
      if (Platform.isAndroid) {
        const intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_CALCULATOR',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      }
    } catch (e) {
      debugPrint("Calculator launch failed: $e");
    }
  }

  static Future<void> _launchFocusModeDirect() async {
    try {
      if (Platform.isAndroid) {
        const intent = AndroidIntent(
          action: 'android.settings.ZEN_MODE_SETTINGS',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      } else {
        final uri = Uri.parse("App-prefs:root=DO_NOT_DISTURB");
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      }
    } catch (e) {
      debugPrint("Focus mode launch failed: $e");
    }
  }

  static Future<void> _launchCalendarDirect() async {
    try {
      if (Platform.isAndroid) {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'content://com.android.calendar/time/${DateTime.now().millisecondsSinceEpoch}',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      } else {
        final uri = Uri.parse("calshow://");
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      }
    } catch (e) {
      debugPrint("Calendar launch failed: $e");
    }
  }

  static Future<void> _launchTimerDirect() async {
    try {
      if (Platform.isAndroid) {
        const intent = AndroidIntent(
          action: 'android.intent.action.SET_TIMER',
          arguments: <String, dynamic>{'android.intent.extra.alarm.SKIP_UI': false},
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      } else {
        final uri = Uri.parse("clock-timer://");
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      }
    } catch (e) {
      debugPrint("Timer launch failed: $e");
    }
  }

  static Future<void> _launchRecorderDirect() async {
    try {
      if (Platform.isAndroid) {
        const intent = AndroidIntent(
          action: 'android.provider.MediaStore.RECORD_SOUND',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      }
    } catch (e) {
      debugPrint("Recorder launch failed: $e");
    }
  }

  static Future<void> _launchCameraDirect() async {
    try {
      if (Platform.isAndroid) {
        const intent = AndroidIntent(
          action: 'android.media.action.IMAGE_CAPTURE',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      } 
    } catch (e) {
      debugPrint("Camera launch failed: $e");
    }
  }

  static Future<void> _launchMapDirect() async {
    try {
      Uri uri = Platform.isAndroid 
        ? Uri.parse("geo:0,0?q=") 
        : Uri.parse("https://maps.apple.com/?q=");
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (e) {
      debugPrint("Map launch failed: $e");
    }
  }

  static Future<void> _launchPhoneDirect() async {
    try {
      final uri = Uri(scheme: 'tel', path: '');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (e) {
      debugPrint("Phone launch failed: $e");
    }
  }

  // ============================================================
  // [C] AI 판단 (The Brain)
  // ============================================================
  
  static void _triggerSilentContext(BuildContext context, String contextKey) {
    if (!PreferenceManager.canIntervene()) {
      debugPrint("🤫 루나: 쿨다운 중이라 침묵합니다.");
      return;
    }

    int meatScore = PreferenceManager.getScore(contextKey, "category:meat_grill");
    
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
            PreferenceManager.updateScore(contextKey, "category:meat_grill", true);
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
          arguments: <String, dynamic>{'android.intent.extra.alarm.SKIP_UI': false},
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
        ? Uri.parse("content://com.android.calendar/time/${DateTime.now().millisecondsSinceEpoch}")
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
      Uri uri = Platform.isAndroid ? Uri.parse("geo:0,0?q=") : Uri.parse("https://maps.apple.com/?q=");
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint("Map launch failed: $e");
    }
  }

  static Future<void> _launchBrowser(BuildContext context, String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
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
      SnackBar(content: Text(message), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating),
    );
  }
}
