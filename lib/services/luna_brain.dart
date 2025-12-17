// lib/services/luna_brain.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

// [수정됨] 경로 수정
import '../util/luna_prompts.dart'; 
import 'emotion_engine.dart'; 

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

  final String _gptKey = "KEY_REMOVED_FOR_SECURITY";

  String _mode = 'friend';

  void setMode(String mode) {
    _mode = mode;
    debugPrint("🧠 Luna UI Mode: $_mode");
  }

  Future<String> getResponse(String input) async {
    final prefs = await SharedPreferences.getInstance();
    
    String lastTimeStr = prefs.getString('luna_last_time') ?? DateTime.now().toString();
    DateTime lastTime = DateTime.parse(lastTimeStr);
    DateTime now = DateTime.now();
    int silenceSeconds = now.difference(lastTime).inSeconds;

    EmotionTag detectedTag = EmotionEngine.infer(input, silenceSeconds, now.toString());
    
    ResponseStyle style = EmotionEngine.mapEmotionToStyle(detectedTag);
    String dynamicStylePrompt = EmotionEngine.buildSystemPrompt(style);

    String hiddenContext = """
[HIDDEN CONTEXT]
Current Time: $now
Silence Duration: ${silenceSeconds}s
Detected State: $detectedTag
""";

    // [수정됨] 변수명 lunaSystemPrompt로 변경
    String finalSystemPrompt = "$lunaSystemPrompt\n\n$dynamicStylePrompt\n\n$hiddenContext";

    debugPrint("🧠 DETECTED: $detectedTag | TONE: ${style.tone}");

    try {
      await prefs.setString('luna_last_time', now.toString());
      await prefs.setString('luna_emotion_tag', detectedTag.toString());

      String randomKey = _geminiKeys[Random().nextInt(_geminiKeys.length)];
      return await _callGemini(input, randomKey, finalSystemPrompt);

    } catch (e) {
      debugPrint("⚠️ Gemini Failed: $e");
      debugPrint("🔄 Switching to GPT Backup...");
      try {
        return await _callGPT(input, finalSystemPrompt);
      } catch (e2) {
        debugPrint("💥 All AI Failed: $e2");
        return "죄송해요, 잠시 연결이 불안해요. 조금만 있다가 다시 말 걸어주세요.";
      }
    }
  }

  Future<String> _callGemini(String input, String apiKey, String systemPrompt) async {
    // [수정됨] 모델명을 gemini-3-pro-preview 로 교체 완료
    final model = GenerativeModel(model: 'gemini-3-pro-preview', apiKey: apiKey);
    final chat = model.startChat(history: [
      Content.text(systemPrompt), 
    ]);
    final response = await chat.sendMessage(Content.text(input));
    return response.text ?? "";
  }

  Future<String> _callGPT(String input, String systemPrompt) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_gptKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo', 
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': input},
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('GPT API Error: ${response.statusCode}');
    }
  }

  Future<String> getWelcomeMessage() async {
    final prefs = await SharedPreferences.getInstance();
    String lastTimeStr = prefs.getString('luna_last_time') ?? "";
    DateTime now = DateTime.now();
    
    if (lastTimeStr == "") {
      return "반가워요! 당신의 하루를 함께할 루나(Luna)예요. 우리 잘 지내봐요.";
    }

    DateTime lastTime = DateTime.parse(lastTimeStr);
    int diffHours = now.difference(lastTime).inHours;
    int hour = now.hour;

    if (hour >= 23 || hour <= 5) {
      if (diffHours < 2) return "아직 안 주무셨네요? 생각이 많은 밤인가요?";
      return "늦은 시간이네요. 잠이 안 와서 켰어요?";
    }
    if (hour >= 6 && hour <= 10) {
      return "좋은 아침이에요! 오늘 컨디션은 어때요?";
    }
    if (hour >= 11 && hour <= 18) {
      if (diffHours > 24) return "오랜만이네요! 바쁜 건 좀 끝났어요?";
      return "오셨군요. 잠깐 머리 좀 식힐까요, 아니면 바로 도울까요?";
    }
    return "오늘 하루도 고생 많았어요. 푹 쉬고 있었나요?";
  }
}