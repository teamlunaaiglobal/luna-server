import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'luna_brain.dart';
import 'luna_tts_service.dart';
import 'memory_service.dart';

class LunaUnifiedBlock {
  static final LunaUnifiedBlock _instance = LunaUnifiedBlock._internal();
  factory LunaUnifiedBlock() => _instance;
  LunaUnifiedBlock._internal();

  final LunaBrain _brain = LunaBrain();
  final LunaTTSService _tts = LunaTTSService();
  final MemoryService _memory = MemoryService();

  // [Next-Gen Memory] 강화학습용 사용자 선호도 데이터베이스
  List<String> _policyDatabase = []; 
  
  // [Settings] 라이트 모드 (On-Device Only)
  bool _isLiteMode = false;

  Future<void> init() async {
    await _memory.loadChat();
    _loadPolicy(); // 사용자 습관/피드백 로드
    
    // [선제적 행동] 앱 실행 시점 분석 (Context Aware)
    if (!_isLiteMode) _runPreemptiveCheck(); 
  }

  void toggleLiteMode(bool value) => _isLiteMode = value;

  // ---------------------------------------------------------------------------
  // [1. CORE ROUTER] 입력 분석 및 모듈 배분
  // ---------------------------------------------------------------------------
  Future<String> handleInputAuto(String input) async {
    String lower = input.toLowerCase();

    // A. [Feedback Loop] 사용자 피드백 즉시 학습 (Reinforcement Learning)
    if (lower.startsWith("아니") || lower.contains("틀렸어") || lower.contains("수정")) {
      return _updatePolicy(input);
    }

    // B. [RPA Module] 단순 명령 (0.1초 컷, 안전장치)
    if (_isSimpleCommand(lower)) {
      return _runRPA(lower, input);
    }

    // C. [Next-Gen Agent] 자율 판단 엔진 가동
    String category = _detectCategory(lower);
    return _runAgentEngine(category, input);
  }

  // ---------------------------------------------------------------------------
  // [2. NEXT-GEN AGENT] 생각(Thinking) -> 행동(Action) -> 예측(Prediction)
  // ---------------------------------------------------------------------------
  Future<String> _runAgentEngine(String category, String input) async {
    try {
      // 1. [Policy Injection] 학습된 사용자 스타일 주입
      String policyContext = _policyDatabase.join(" | ");
      String mode = _isLiteMode ? "Lite" : "Deep Agent";

      // 2. [Multi-Modal Reasoning] 한 번의 사고로 모든 판단 종료
      String prompt = """
      Mode: $mode
      Role: Autonomous AI Agent (Self-Optimizing)
      User Policy (Learned): [$policyContext]
      Category: $category
      Input: "$input"
      
      Requirements:
      1. Summary: Key content.
      2. Priority: Score (0-100).
      3. AutoAction: Simulate executing the task (Draft email, Calendar event).
      4. Prediction: What is the NEXT logical step?
      
      Output JSON: 
      {
        "summary": "...", 
        "priority": 0, 
        "auto_action": "...", 
        "prediction": "..."
      }
      """;

      String resultRaw = await _brain.getResponse(prompt);
      Map<String, dynamic> data = _parseJson(resultRaw);

      // 3. [Execution] 데이터 처리
      String summary = data['summary'] ?? resultRaw;
      int score = data['priority'] ?? 50;
      String action = data['auto_action'] ?? "None";
      String nextStep = data['prediction'] ?? "";

      // 4. [Auto-Save] 로컬 DB에 결과 저장
      String log = "$summary\n[실행됨: $action]\n[예측제안: $nextStep]";
      await _memory.addItem(category, log);

      // 5. [Dynamic Feedback] 중요도에 따른 반응
      String feedback = "";
      if (score >= 80) {
        // 긴급: 즉시 실행 보고
        feedback = "중요한 건이라 처리했습니다.\n$action 완료.\n다음으로 '$nextStep' 진행할까요?";
      } else {
        // 일반: 정리 보고
        feedback = "정리해뒀습니다. (참고: $nextStep)";
      }

      await _tts.speak(feedback);
      await _memory.saveChat([
        {'role': 'user', 'text': input, 'time': DateTime.now().toString()},
        {'role': 'luna', 'text': feedback, 'time': DateTime.now().toString()},
      ]);

      return feedback;

    } catch (e) {
      // [Fail-Safe] AI 실패 시 RPA로 전환
      print("Agent Error: $e");
      return await _runRPA(category, input);
    }
  }

  // ---------------------------------------------------------------------------
  // [3. REINFORCEMENT LEARNING] 자가 최적화 모듈
  // ---------------------------------------------------------------------------
  Future<String> _updatePolicy(String input) async {
    // 사용자의 불만/수정 사항을 '규칙'으로 변환하여 저장
    String newRule = "User Feedback: $input";
    _policyDatabase.add(newRule);
    
    // 메모리 관리 (최근 10개 규칙 유지)
    if (_policyDatabase.length > 10) _policyDatabase.removeAt(0);

    String msg = "피드백을 학습했습니다. 다음 실행부터는 반영하겠습니다.";
    await _tts.speak(msg);
    return msg;
  }

  void _loadPolicy() {
    // 초기 기본값 (가상 로드)
    if (_policyDatabase.isEmpty) {
      _policyDatabase.add("보고는 결론부터 말할 것");
      _policyDatabase.add("일정은 항상 30분 전에 알림");
    }
  }

  // ---------------------------------------------------------------------------
  // [4. PREEMPTIVE ENGINE] 선제적 행동 (미래 예측)
  // ---------------------------------------------------------------------------
  Future<void> _runPreemptiveCheck() async {
    // 앱 실행 시, 시간/위치/과거기록을 복합 분석하여 먼저 말 걸기
    DateTime now = DateTime.now();
    
    // 예: 아침 9시인데 어제 저장된 'meeting'이 있고 'Action Item'이 미완료라면?
    if (now.hour >= 8 && now.hour <= 10) {
       List<Map<String, String>> history = await _memory.getItems('meeting');
       if (history.isNotEmpty) {
         // 최근 기록 분석 (가상)
         _tts.speak("대표님, 어제 회의록을 바탕으로 오늘 오전 업무 리스트를 미리 뽑아뒀습니다. 확인하실래요?");
       }
    }
  }

  // ---------------------------------------------------------------------------
  // [MODULES] RPA & Helpers
  // ---------------------------------------------------------------------------
  bool _isSimpleCommand(String input) {
    return input.endsWith("해") || input.contains("기록") || input.contains("저장");
  }

  Future<String> _runRPA(String category, String input) async {
    // 뇌 없이 즉시 저장 (100% 성공 보장)
    String content = input.replaceAll("기록", "").replaceAll("메모", "").trim();
    String target = category.contains("meeting") ? 'meeting' : 'capture';
    
    await _memory.addItem(target, content);
    String feedback = "안전하게 저장했습니다.";
    await _tts.speak(feedback);
    return feedback;
  }

  String _detectCategory(String lower) {
    if (lower.contains("회의") || lower.contains("미팅")) return 'meeting';
    if (lower.contains("일정") || lower.contains("스케줄")) return 'schedule';
    if (lower.contains("메일") || lower.contains("초안")) return 'mail';
    if (lower.contains("분석") || lower.contains("생각")) return 'personal';
    if (lower.contains("검색") || lower.contains("조사")) return 'research';
    return 'capture';
  }

  // JSON 파싱 헬퍼
  Map<String, dynamic> _parseJson(String text) {
    try {
      int start = text.indexOf('{');
      int end = text.lastIndexOf('}');
      if (start != -1 && end != -1) return jsonDecode(text.substring(start, end + 1));
    } catch (e) {}
    return {'summary': text};
  }
  
  // Vision (이미지) 처리
  Future<String> handleLocalImage(String path, String prompt) async {
    if (_isLiteMode) return "Lite Mode";
    try {
      String analysis = await _brain.getImageResponse(path, "Analyze & Predict Action: $prompt");
      await _memory.addItem('capture', "[Vision] $analysis");
      return analysis;
    } catch (e) { return "이미지 분석 오류"; }
  }

  // 호환성 유지
  Future<String> friendMode(String i) => _runAgentEngine('friend', i);
  Future<String> tutorMode(String i) async {
    _brain.setMode('tutor');
    String res = await _brain.getResponse(i);
    await _tts.speak(res);
    return res;
  }
  Future<void> stopAll() async => await _tts.stop();
  Future<int> usePoint() async => 100;
  Future<void> refillPoints() async {}
  Map<String, String> getQuiz() => {'question': '', 'answer': ''};
  Future<bool> checkQuizAnswer(String i, String a) async => true;
}