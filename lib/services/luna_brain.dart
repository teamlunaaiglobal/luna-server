// lib/services/luna_brain.dart
// [V6 FINAL INTEGRATION: Hybrid Brain + Local Body + Context Memory]
// 기능: 자동 모드 전환(Economy/Performance) + 로컬 DB 저장 + 20턴 기억 + Gemini 3.0

import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class LunaBrain {
  static final LunaBrain _instance = LunaBrain._internal();
  factory LunaBrain() => _instance;
  LunaBrain._internal();

  // [키 로테이션]
  final List<String> _geminiKeys = [
    "AIzaSyDWvQP1hSPsMc4KV2jsp5kvo2Aus854rfI",
    "AIzaSyA9hKHJcgf0VO2tXybkgxZPGxd8QEi1tM0",
    "AIzaSyBpMt1fd_SDATCs7kGVe-e7fXXOcBa1uzs",
    "AIzaSyAaEtehmP6sWVuOiNTmJup_bH4KsCNlLO4",
    "AIzaSyDa1EiDQakaJXNZf4jAliQ7xT-BdDCLaHU",
  ];
  final String _gptKey = "INSERT_YOUR_GPT_KEY_HERE";

  final UserContextManager _userContext = UserContextManager();
  final LocalMediaDB _mediaDB = LocalMediaDB(); // [V5.3 기능 복구]

  // ---------------------------------------------------------------------------
  // [1] 메인 진입점: 지능형 라우터 (V5.2 기능 복구)
  // ---------------------------------------------------------------------------
  Future<String> getResponse(String input, {String userId = "default_user"}) async {
    // 1. 컨텍스트 로드
    _userContext.loadContext(userId);
    
    // 2. 난이도 및 감정 분석
    EmotionTag tag = EmotionEngine.infer(input);
    bool isHeavyTask = (tag == EmotionTag.executionMode || tag == EmotionTag.needsClarity) || 
                       input.length > 50 || 
                       _containsComplexKeywords(input);

    String response;

    // 3. 모드 자동 전환 (Hybrid Logic)
    if (isHeavyTask) {
      debugPrint("🚀 [Performance Mode] 고부하 작업 -> 멀티코어 가동");
      response = await _executePerformanceMode(input, tag, userId);
    } else {
      debugPrint("🌱 [Economy Mode] 일반 대화 -> 싱글코어 가동");
      response = await _executeEconomyMode(input, tag, userId);
    }

    // 4. 컨텍스트 저장 및 로그
    _userContext.updateContext(userId, input, response);
    
    return response;
  }

  // ---------------------------------------------------------------------------
  // [A] Economy Mode (단일 호출)
  // ---------------------------------------------------------------------------
  Future<String> _executeEconomyMode(String input, EmotionTag tag, String userId) async {
    String contextHistory = _userContext.getPreviousContext(userId);
    String prompt = """
너는 루나(Luna). 사용자 친구(Samantha) + 비서(Jarvis).
입력에 공감 및 해결을 동시에 수행. 짧고 명확하게.
[Context]
Time: ${DateTime.now()}
Emotion: $tag
History:
$contextHistory
""";
    return await getResponseFromCore(input, prompt);
  }

  // ---------------------------------------------------------------------------
  // [B] Performance Mode (병렬 호출)
  // ---------------------------------------------------------------------------
  Future<String> _executePerformanceMode(String input, EmotionTag tag, String userId) async {
    String contextHistory = _userContext.getPreviousContext(userId);

    // 1. 사만다 (감성)
    String samandaPrompt = "Role: Samantha (Best Friend). Task: Empathy & Support. Context: $contextHistory";
    
    // 2. 자비스 (이성)
    String jarvisPrompt = "Role: Jarvis (Expert). Task: Logical Solution & Code. Context: $contextHistory";

    // 병렬 실행
    var results = await Future.wait([
      getResponseFromCore(input, samandaPrompt),
      getResponseFromCore(input, jarvisPrompt)
    ]);

    String samandaOut = results[0];
    String jarvisOut = results[1];

    if (samandaOut.isNotEmpty && jarvisOut.isNotEmpty) {
      return "$samandaOut\n\n----------------\n[상세 분석]\n$jarvisOut";
    }
    return jarvisOut.isNotEmpty ? jarvisOut : samandaOut;
  }

  // ---------------------------------------------------------------------------
  // [Core] AI 엔진 호출
  // ---------------------------------------------------------------------------
  Future<String> getResponseFromCore(String input, String systemPrompt) async {
    try {
      String randomKey = _geminiKeys[Random().nextInt(_geminiKeys.length)];
      final model = GenerativeModel(model: 'gemini-3.0-pro', apiKey: randomKey);
      final chat = model.startChat(history: [Content.text(systemPrompt)]);
      final response = await chat.sendMessage(Content.text(input));
      return response.text ?? "";
    } catch (e) {
      debugPrint("⚠️ Gemini Failed: $e");
      return await _callGPT(input, systemPrompt);
    }
  }

  Future<String> _callGPT(String input, String systemPrompt) async {
    if (_gptKey.contains("INSERT")) return "GPT Key Missing";
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_gptKey'},
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [{'role': 'system', 'content': systemPrompt}, {'role': 'user', 'content': input}],
          'temperature': 0.7,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))['choices'][0]['message']['content'];
      }
      return "GPT Error: ${response.statusCode}";
    } catch (e) {
      return "Network Error: $e";
    }
  }

  bool _containsComplexKeywords(String input) {
    final keywords = ['코드', 'code', '분석', '기획', 'plan', '일정'];
    return keywords.any((k) => input.toLowerCase().contains(k));
  }

  // [외부 공개] 로컬 미디어 저장 접근용
  LocalMediaDB get mediaDB => _mediaDB;
}

// ==============================================================================
// 🧩 EmotionEngine
// ==============================================================================
enum EmotionTag { calmFocused, motivated, confident, tired, mentallyOverloaded, pressured, uncertain, stuck, frustrated, needsReassurance, seeksEmotionalConnection, executionMode, needsClarity, disengaged }

class EmotionEngine {
  static EmotionTag infer(String input) {
    final text = input.toLowerCase();
    if (_hasExecutionKeyword(text)) return EmotionTag.executionMode;
    if (text.contains("힘들") || text.contains("지쳐")) return EmotionTag.tired;
    if (text.contains("심심") || text.contains("놀아")) return EmotionTag.seeksEmotionalConnection;
    return EmotionTag.calmFocused;
  }
  static bool _hasExecutionKeyword(String text) {
    final keywords = ['계획', '정리', '코드', '만들어', '일정', '분석', 'plan', 'code', 'list'];
    return keywords.any((k) => text.contains(k));
  }
}

// ==============================================================================
// 🧩 UserContextManager (20턴 기억)
// ==============================================================================
class UserContextManager {
  final Map<String, List<Map<String, String>>> _recentHistory = {};
  static const int MAX_HISTORY_TURNS = 20;

  void loadContext(String userId) {
    if (!_recentHistory.containsKey(userId)) _recentHistory[userId] = [];
  }

  void updateContext(String userId, String input, String output) {
    var history = _recentHistory[userId]!;
    history.add({"role": "user", "text": input});
    history.add({"role": "assistant", "text": output});
    if (history.length > MAX_HISTORY_TURNS * 2) history.removeRange(0, 2);
  }

  String getPreviousContext(String userId) {
    var history = _recentHistory[userId];
    if (history == null || history.isEmpty) return "";
    return history.map((e) => "${e['role'].toUpperCase()}: ${e['text']}").join("\n");
  }
}

// ==============================================================================
// 🧩 LocalMediaDB (로컬 저장소 - V5.3 기능)
// ==============================================================================
class LocalMediaDB {
  Future<Directory> getAppMediaDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${dir.path}/media');
    if (!await mediaDir.exists()) await mediaDir.create(recursive: true);
    return mediaDir;
  }

  Future<File> saveImage(String userId, String fileName, List<int> bytes) async {
    final dir = await getAppMediaDir();
    final file = File('${dir.path}/${userId}_$fileName.png');
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<File> saveAudio(String userId, String fileName, List<int> bytes) async {
    final dir = await getAppMediaDir();
    final file = File('${dir.path}/${userId}_$fileName.wav');
    return file.writeAsBytes(bytes, flush: true);
  }
}