// lib/services/luna_brain.dart
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
// [수정] shared_preferences 삭제됨 (안 써서 경고 뜸)
import 'package:path_provider/path_provider.dart';

class LunaBrain {
  static final LunaBrain _instance = LunaBrain._internal();
  factory LunaBrain() => _instance;
  LunaBrain._internal();

  final List<String> _geminiKeys = [
    "AIzaSyDWvQP1hSPsMc4KV2jsp5kvo2Aus854rfI",
    "AIzaSyA9hKHJcgf0VO2tXybkgxZPGxd8QEi1tM0",
    "AIzaSyBpMt1fd_SDATCs7kGVe-e7fXXOcBa1uzs",
    "AIzaSyAaEtehmP6sWVuOiNTmJup_bH4KsCNlLO4",
    "AIzaSyDa1EiDQakaJXNZf4jAliQ7xT-BdDCLaHU",
  ];
  final String _gptKey = "INSERT_YOUR_GPT_KEY_HERE";

  final UserContextManager _userContext = UserContextManager();
  final LocalMediaDB _mediaDB = LocalMediaDB();

  Future<String> getResponse(String input, {String userId = "default_user"}) async {
    _userContext.loadContext(userId);
    
    EmotionTag tag = EmotionEngine.infer(input);
    bool isHeavyTask = (tag == EmotionTag.executionMode || tag == EmotionTag.needsClarity) || 
                       input.length > 50 || 
                       _containsComplexKeywords(input);

    String response;

    if (isHeavyTask) {
      debugPrint("🚀 [Performance Mode] Multi-Core Active");
      response = await _executePerformanceMode(input, tag, userId);
    } else {
      debugPrint("🌱 [Economy Mode] Single-Core Active");
      response = await _executeEconomyMode(input, tag, userId);
    }

    _userContext.updateContext(userId, input, response);
    return response;
  }

  Future<String> _executeEconomyMode(String input, EmotionTag tag, String userId) async {
    String contextHistory = _userContext.getPreviousContext(userId);
    String prompt = """
Role: Luna (Friend & Assistant).
Mode: Economy (Fast).
Emotion: $tag
Context:
$contextHistory
""";
    return await getResponseFromCore(input, prompt);
  }

  Future<String> _executePerformanceMode(String input, EmotionTag tag, String userId) async {
    String contextHistory = _userContext.getPreviousContext(userId);
    String samandaPrompt = "Role: Samantha (Friend). Task: Empathy. Context: $contextHistory";
    String jarvisPrompt = "Role: Jarvis (Expert). Task: Solution. Context: $contextHistory";

    var results = await Future.wait([
      getResponseFromCore(input, samandaPrompt),
      getResponseFromCore(input, jarvisPrompt)
    ]);

    String samandaOut = results[0];
    String jarvisOut = results[1];

    if (samandaOut.isNotEmpty && jarvisOut.isNotEmpty) {
      return "$samandaOut\n\n----------------\n[Detail]\n$jarvisOut";
    }
    return jarvisOut.isNotEmpty ? jarvisOut : samandaOut;
  }

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

  LocalMediaDB get mediaDB => _mediaDB;
}

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

class UserContextManager {
  final Map<String, List<Map<String, String>>> _recentHistory = {};
  // [수정] 대문자 상수 경고 해결 (CamelCase 권장)
  static const int maxHistoryTurns = 20;

  void loadContext(String userId) {
    if (!_recentHistory.containsKey(userId)) _recentHistory[userId] = [];
  }

  void updateContext(String userId, String input, String output) {
    var history = _recentHistory[userId]!;
    history.add({"role": "user", "text": input});
    history.add({"role": "assistant", "text": output});
    if (history.length > maxHistoryTurns * 2) history.removeRange(0, 2);
  }

  String getPreviousContext(String userId) {
    var history = _recentHistory[userId];
    if (history == null || history.isEmpty) return "";
    return history.map((e) => "${e['role']?.toUpperCase() ?? 'UK'}: ${e['text']}").join("\n");
  }
}

class LocalMediaDB {
  Future<Directory> getAppMediaDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${dir.path}/media');
    if (!await mediaDir.exists()) await mediaDir.create(recursive: true);
    return mediaDir;
  }
  // (생략: 기존 코드와 동일)
}