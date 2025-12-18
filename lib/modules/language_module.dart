import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart'; // debugPrint 사용
import 'package:http/http.dart' as http;
import '../models/luna_module_interface.dart';
import '../services/luna_tts_service.dart';
import '../services/memory_service.dart';
import '../services/luna_unified_block.dart'; 

class LunaLanguageModule implements LunaModule {
  // [필수] 시스템 연결 고리
  final LunaUnifiedBlock core; 
  LunaLanguageModule({required this.core});

  // [설정]
  final bool _isSimulationMode = true; 
  final String _apiKey = "INSERT_YOUR_KEY_HERE"; 
  
  // [부품]
  final LunaTTSService _tts = LunaTTSService();
  final MemoryService _memory = MemoryService();
  Map<String, dynamic> _userProgress = {}; 

  @override
  String get id => 'language_core';

  // [Fix] @override 제거 (부모 인터페이스에 없는 속성이므로)
  String get moduleName => 'LanguageModule'; 

  @override
  List<LunaMode> get supportedModes => [LunaMode.tutor, LunaMode.auto];

  @override
  Future<void> initialize() async => await init();

  Future<void> init() async {
    // [수정] MemoryService #2의 getItems를 사용하여 로드
    _userProgress = await _loadProgressFromMemory();
    debugPrint('📚 Language Module Ready. Lv.${_getUserLevel("general")}');
    
    // [기능] 앱 켤 때 선제적 제안
    _suggestReviewOnBoot(); 
  }

  // ---------------------------------------------------------------------------
  // [외부 공개 메서드] IntegratedService 등에서 호출 가능하게 함
  // ---------------------------------------------------------------------------
  Future<String> startLesson(String topic) async {
    return await _startAdaptiveLesson(topic);
  }

  Future<void> reviewPastLessons(String topic) async {
    await _reviewPastLessons();
  }

  // ---------------------------------------------------------------------------
  // [실행] 명령 처리 (고도화됨)
  // ---------------------------------------------------------------------------
  @override
  Future<dynamic> execute(String command) async {
    // [업무 차단]
    if (_isSystemBusy()) {
      String msg = "🚫 [System Block] 업무(비서) 모드 실행 중입니다. 학습 프로세스를 대기합니다.";
      await _tts.speak(msg);
      return msg;
    }

    // [멀티 토픽]
    if (command.startsWith("mix:")) {
      return await _startMixedLesson(command.replaceAll("mix:", "").trim());
    }

    // [페르소나]
    if (command.startsWith("set_persona:")) {
      return _configurePersona(command.replaceAll("set_persona:", ""));
    }

    // [스타일]
    if (command.startsWith("style:")) {
      _userProgress['style'] = command.replaceAll("style:", "").trim();
      await _saveProgressToMemory();
      return "Style Updated";
    }

    // [수업 시작]
    if (command.startsWith("lesson:")) {
      return await _startAdaptiveLesson(command.replaceAll("lesson:", "").trim());
    }

    // [정답 확인]
    if (command.startsWith("conversation:") || command.startsWith("answer:")) {
      return await _checkAnswerAndFeedback(command.replaceAll(RegExp(r'^(conversation:|answer:)'), "").trim());
    }

    // [복습]
    if (command.contains("복습") || command.contains("review")) {
      return await _reviewPastLessons();
    }

    // 기본값
    return await _startAdaptiveLesson("daily_conversation");
  }

  // ---------------------------------------------------------------------------
  // [핵심 로직] Core 상태 정밀 확인
  // ---------------------------------------------------------------------------
  bool _isSystemBusy() {
    String coreStatus = core.toString();
    if (coreStatus.contains("Assist") || coreStatus.contains("assist")) return true;
    if (coreStatus.contains("Busy")) return true;
    return false;
  }

  // ---------------------------------------------------------------------------
  // [핵심 로직] 멀티 토픽 프롬프트 고도화
  // ---------------------------------------------------------------------------
  Future<String> _startMixedLesson(String rawTopics) async {
    List<String> topics = rawTopics.split(',').map((e) => e.trim()).toList();
    String personaPrompt = _buildAdvancedPersona();
    
    String prompt = """
      $personaPrompt
      Task: Create a seamless scenario merging these topics: $topics.
      User Level: ${_getUserLevel("general")}
      Requirements:
        1. Context Switching: Transition naturally between topics.
        2. Complexity: Mix vocabulary from both domains.
        3. Evaluation: Quiz must test the connection between topics.
      Output JSON: {"dialogue":"...", "prediction":"Check context switching skills", "quiz":{"question":"Combined Concept Question?", "answer":"..."}}
    """;

    if (_isSimulationMode) {
      String msg = "Mixed Lesson ($topics): Combined scenario simulation.";
      await _tts.speak(msg);
      _saveHistory("mixed", {"dialogue": msg, "prediction": "sim", "quiz": {"question": "q", "answer": "a"}});
      return msg;
    }

    String result = await _callAI(prompt);
    Map<String, dynamic> data = _parseJson(result);
    _saveHistory("mixed", data);
    
    await _tts.speak(data['dialogue']);
    return "🔀 [Mixed Scenario]\n${data['dialogue']}\n\n❓ ${data['quiz']['question']}";
  }

  Future<String> _startAdaptiveLesson(String topic) async {
    int level = _getUserLevel(topic);
    String personaPrompt = _buildAdvancedPersona(); 

    if (_isSimulationMode) {
      String simMsg = _simulationLesson(topic, level);
      await _tts.speak(simMsg);
      return simMsg;
    }

    String prompt = """
      $personaPrompt
      Topic: $topic
      User Level: $level (1-10)
      Requirements:
        1. Immersive dialogue.
        2. Predict specific user error type (Grammar vs Vocab).
        3. Quiz based on the prediction.
      Output JSON: {"dialogue":"...", "prediction":"...", "quiz":{"question":"...", "answer":"..."}}
    """;

    String result = await _callAI(prompt);
    Map<String, dynamic> lessonData = _parseJson(result);
    _saveHistory(topic, lessonData);

    String display = "${lessonData['dialogue']}\n\n💡Tip: ${lessonData['prediction']}\n❓Quiz: ${lessonData['quiz']['question']}";
    await _tts.speak(lessonData['dialogue']); 
    return display;
  }

  // ---------------------------------------------------------------------------
  // [핵심 로직] 오답 분석 및 정교한 레벨링
  // ---------------------------------------------------------------------------
  Future<String> _checkAnswerAndFeedback(String userAnswer) async {
    // MemoryService #2 사용 (getItems)
    List<Map<String, String>> history = await _memory.getItems('language_history');
    if (history.isEmpty) return "수업 기록이 없습니다.";

    var lastItem = history.first; // 최신순 정렬 가정
    var lastLessonContent = lastItem['content'] ?? "{}";
    var lastJson = jsonDecode(lastLessonContent); // {topic:..., lesson:...}

    // JSON 구조 파싱
    String lessonStr = lastJson['lesson'];
    Map<String, dynamic> lessonDetail = jsonDecode(lessonStr);
    
    String correctAnswer = lessonDetail['quiz']['answer'];
    String topic = lastJson['topic'];

    bool isCorrect = userAnswer.toLowerCase().contains(correctAnswer.toLowerCase());

    _updateSophisticatedLevel(topic, isCorrect, userAnswer, correctAnswer);
    await _saveProgressToMemory();

    String feedback = isCorrect 
        ? "정답! (Pattern: Excellent) 🔼" 
        : "오답. 정답: $correctAnswer (Analysis Saved) ⏺";
    
    await _tts.speak(feedback);
    return feedback;
  }

  void _updateSophisticatedLevel(String topic, bool isCorrect, String userAnswer, String correctAnswer) {
    if (!_userProgress.containsKey(topic)) {
      _userProgress[topic] = {
        'level': 1, 'xp': 0, 
        'consecutive_correct': 0, 
        'error_log': [] 
      };
    }
    
    var data = _userProgress[topic];
    int currentLv = data['level'];
    int currentXp = data['xp'];
    int combo = data['consecutive_correct'] ?? 0;
    List errorLog = data['error_log'] ?? [];

    if (isCorrect) {
      combo++;
      int bonus = (combo > 3) ? 5 : 0; 
      currentXp += (10 + bonus);
      if (currentXp >= 100) { currentLv = (currentLv + 1).clamp(1, 10); currentXp = 0; }
    } else {
      combo = 0;
      currentXp = (currentXp - 5).clamp(0, 100);
      
      Map<String, String> errorAnalysis = _analyzeErrorPattern(userAnswer, correctAnswer);
      errorLog.add(errorAnalysis);
      if (errorLog.length > 10) errorLog.removeAt(0);
    }

    _userProgress[topic] = {
      'level': currentLv, 
      'xp': currentXp,
      'consecutive_correct': combo,
      'error_log': errorLog 
    };
  }

  Map<String, String> _analyzeErrorPattern(String user, String correct) {
    String type = "Unknown";
    String advice = "Try again.";

    if (user.isEmpty) {
      type = "Silence";
      advice = "Please say something.";
    } else if (correct.contains(user)) {
      type = "Incomplete"; 
      advice = "Full sentence required.";
    } else if (user.length < correct.length * 0.5) {
      type = "Vocab_Gap"; 
      advice = "Review vocabulary.";
    } else {
      type = "Grammar/Context"; 
      advice = "Check structure.";
    }
    return {"type": type, "advice": advice, "time": DateTime.now().toString()};
  }

  // ---------------------------------------------------------------------------
  // [메모리 연동 어댑터] MemoryService #2 (List<Map>) 호환용
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> _loadProgressFromMemory() async {
    // getItems는 List<Map<String, String>> 반환
    var items = await _memory.getItems('user_language_progress');
    if (items.isEmpty) return {};
    try {
      // 가장 최신 항목(first)의 content를 파싱
      String jsonStr = items.first['content'] ?? "{}";
      return jsonDecode(jsonStr);
    } catch (e) {
      debugPrint("⚠️ Progress Load Error: $e");
      return {};
    }
  }

  Future<void> _saveProgressToMemory() async {
    // addItem은 리스트에 추가함 (History처럼 쌓이지만, 로드할 땐 최신만 봄)
    await _memory.addItem('user_language_progress', jsonEncode(_userProgress));
  }

  // ---------------------------------------------------------------------------
  // [기타 유틸리티]
  // ---------------------------------------------------------------------------
  String _configurePersona(String settings) {
    _userProgress['persona_settings'] = settings;
    _saveProgressToMemory();
    return "Persona set: $settings";
  }

  String _buildAdvancedPersona() {
    String settings = _userProgress['persona_settings'] ?? "Friendly/Normal";
    String tone = "Friendly";
    String strictness = "Normal"; 
    
    if (settings.contains("Strict") || settings.contains("Spartan")) {
      tone = "Strict & Professional";
      strictness = "High";
    } else if (settings.contains("Funny")) {
      tone = "Humorous";
    }
    return "Role Persona: [Tone: $tone], [Strictness: $strictness].";
  }

  Future<void> _suggestReviewOnBoot() async {
    List<Map<String, String>> history = await _memory.getItems('language_history');
    if (history.isNotEmpty) await _tts.speak("대표님, 어제 학습한 내용을 복습하시겠습니까?");
  }

  Future<String> _reviewPastLessons() async {
     List<Map<String, String>> history = await _memory.getItems('language_history');
     if (history.isEmpty) return "기록 없음";
     
     var lastItem = history.first;
     var lastJson = jsonDecode(lastItem['content']!);
     var lessonDetail = jsonDecode(lastJson['lesson']);
     
     String msg = "Review: ${lessonDetail['dialogue']}";
     await _tts.speak(msg);
     return msg;
  }

  int _getUserLevel(String topic) {
    if (!_userProgress.containsKey(topic)) return 1;
    return _userProgress[topic]['level'] ?? 1;
  }

  Future<String> _callAI(String prompt) async {
    if (_apiKey.contains("INSERT")) return '{"dialogue": "API Key Missing", "quiz": {"question": "Key?", "answer": "Key"}}';
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [{'role': 'system', 'content': 'You are a JSON generator.'}, {'role': 'user', 'content': prompt}],
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))['choices'][0]['message']['content'];
      }
    } catch (e) {
      debugPrint("⚠️ AI Call Error: $e");
    }
    return _simulationLesson("Error", 1);
  }

  String _simulationLesson(String topic, int level) {
    String text = "Tutor: (Lv.$level) Let's study $topic. Ready?";
    _saveHistory(topic, {"dialogue": text, "prediction": "None", "quiz": {"question": "Ready?", "answer": "Yes"}});
    return text;
  }

  void _saveHistory(String topic, Map<String, dynamic> data) {
    String jsonContent = jsonEncode({
      'topic': topic,
      'lesson': jsonEncode(data),
      'time': DateTime.now().toString()
    });
    _memory.addItem('language_history', jsonContent);
  }

  Map<String, dynamic> _parseJson(String text) {
    try {
      int start = text.indexOf('{');
      int end = text.lastIndexOf('}');
      if (start != -1 && end != -1) return jsonDecode(text.substring(start, end + 1));
    } catch (e) {
      debugPrint("⚠️ JSON Parse Error: $e");
    }
    return {"dialogue": text, "prediction": "", "quiz": {"question": "Error", "answer": ""}};
  }

  @override
  Future<void> handleFailure(dynamic error) async {
    debugPrint("⚠️ LanguageModule Failure: $error");
  }
}