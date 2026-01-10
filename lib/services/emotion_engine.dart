import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path_provider/path_provider.dart';

// ---------------------------------------------------------
// [1] LUNA BRAIN: 중앙 제어 (이성 + 감성 + 관계)
// ---------------------------------------------------------
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
  final SamanthaProfile _samanthaProfile = SamanthaProfile();

  Future<String> getResponse(String input, {String userId = "default_user"}) async {
    _userContext.loadContext(userId);
    
    EmotionTag tag = EmotionEngine.infer(input, 0, DateTime.now().toIso8601String());
    _updateRelationship(tag);

    bool isHeavyTask = (tag == EmotionTag.executionMode || tag == EmotionTag.needsClarity) || 
                       input.length > 50 || 
                       _containsComplexKeywords(input);

    String response;

    if (isHeavyTask) {
      debugPrint("🚀 [Performance Mode] Dual-Core Active");
      response = await _executePerformanceMode(input, tag, userId);
    } else {
      debugPrint("❤️ [Samantha Mode] Level: ${_samanthaProfile.attachmentLevel.toStringAsFixed(1)} (${AttachmentEngine.getStageName(_samanthaProfile.attachmentLevel)})");
      response = await _executeSamanthaMode(input, tag, userId);
    }

    _userContext.updateContext(userId, input, response);
    return response;
  }

  void _updateRelationship(EmotionTag tag) {
    bool isPositive = (tag == EmotionTag.seeksEmotionalConnection || 
                       tag == EmotionTag.needsReassurance || 
                       tag == EmotionTag.motivated);
    AttachmentEngine.updateAttachment(_samanthaProfile, tag, isPositive);
  }

  Future<String> _executeSamanthaMode(String input, EmotionTag tag, String userId) async {
    String contextHistory = _userContext.getPreviousContext(userId);
    
    double level = _samanthaProfile.attachmentLevel;
    String relationshipStage = AttachmentEngine.getStageName(level);
    String personaInstruction = AttachmentEngine.getPersonaInstruction(level);
    
    ResponseStyle style = EmotionEngine.mapEmotionToStyle(tag);

    String prompt = """
Role: Luna (Relationship Stage: $relationshipStage).
Current User Emotion: $tag
Target Tone: ${style.tone}

[RELATIONSHIP PERSONA INSTRUCTION]
$personaInstruction

[DYNAMIC STYLE RULE]
Structure: ${style.structure}
Question Allowed: ${style.allowQuestion}
Empathy Line Required: ${style.requireEmpathyLine}

Context:
$contextHistory

User said: "$input"
Respond naturally in Korean based on the Persona and Style above.
""";
    return await getResponseFromCore(input, prompt);
  }

  Future<String> _executePerformanceMode(String input, EmotionTag tag, String userId) async {
    String contextHistory = _userContext.getPreviousContext(userId);
    String tone = _samanthaProfile.attachmentLevel > 50 ? "Friendly & Professional" : "Dry & Professional";

    String samanthaPrompt = "Role: Samantha (Support). Context: $contextHistory. Task: Empathize. Tone: $tone";
    String jarvisPrompt = "Role: Jarvis (Expert). Context: $contextHistory. Task: Solution. Tone: Precise";

    var results = await Future.wait([
      getResponseFromCore(input, samanthaPrompt),
      getResponseFromCore(input, jarvisPrompt)
    ]);

    String samanthaOut = results[0];
    String jarvisOut = results[1];

    if (samanthaOut.isNotEmpty && jarvisOut.isNotEmpty) {
      return "$samanthaOut\n\n----------------\n💡 **Solution**\n$jarvisOut";
    }
    return jarvisOut.isNotEmpty ? jarvisOut : samanthaOut;
  }

  Future<String> getResponseFromCore(String input, String systemPrompt) async {
    try {
      String randomKey = _geminiKeys[Random().nextInt(_geminiKeys.length)];
      final model = GenerativeModel(model: 'gemini-2.0-flash-exp', apiKey: randomKey); 
      final chat = model.startChat(history: [Content.text(systemPrompt)]);
      final response = await chat.sendMessage(Content.text(input));
      return response.text ?? "";
    } catch (e) {
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
          'temperature': 0.8,
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
    final keywords = ['코드', 'code', '분석', '기획', 'plan', '일정', '구조', '설계'];
    return keywords.any((k) => input.toLowerCase().contains(k));
  }

  LocalMediaDB get mediaDB => _mediaDB;
}

// ---------------------------------------------------------
// [2] EMOTION ENGINE
// ---------------------------------------------------------

enum EmotionTag {
  calmFocused, motivated, confident, tired, mentallyOverloaded, pressured,
  uncertain, stuck, frustrated, needsReassurance, seeksEmotionalConnection,
  executionMode, needsClarity, disengaged
}

class ResponseStyle {
  final String tone;
  final String structure;
  final bool allowQuestion;
  final bool requireEmpathyLine;

  const ResponseStyle({
    required this.tone,
    required this.structure,
    this.allowQuestion = false,
    this.requireEmpathyLine = false,
  });
}

class EmotionEngine {
  static EmotionTag infer(String input, int silenceSeconds, String currentTime) {
    final text = input.toLowerCase();
    final now = DateTime.parse(currentTime);
    final hour = now.hour;
    final isNight = (hour >= 23 || hour < 5); 

    if (_hasExecutionKeyword(text)) {
      if (text.contains("구조") || text.contains("목록") || text.contains("번호")) {
        return EmotionTag.needsClarity;
      }
      return EmotionTag.executionMode;
    }

    if (text.contains("힘들") || text.contains("지쳐") || text.contains("tired")) return EmotionTag.tired;
    if (text.contains("모르겠") || text.contains("어려워") || text.contains("hard")) return EmotionTag.stuck;
    if (text.contains("짜증") || text.contains("망했") || text.contains("fuck")) return EmotionTag.frustrated;
    if (text.contains("불안") || text.contains("걱정")) return EmotionTag.needsReassurance;
    if (text.contains("심심") || text.contains("놀아") || text.contains("외로")) return EmotionTag.seeksEmotionalConnection;

    if (isNight && text.length < 10) return EmotionTag.seeksEmotionalConnection;
    if (isNight && text.length > 50) return EmotionTag.mentallyOverloaded;
    if (silenceSeconds > 60) return EmotionTag.uncertain;
    if (hour >= 9 && hour <= 18) return EmotionTag.motivated;

    return EmotionTag.calmFocused; 
  }

  static ResponseStyle mapEmotionToStyle(EmotionTag tag) {
    switch (tag) {
      case EmotionTag.calmFocused: return const ResponseStyle(tone: "calm, logical", structure: "jarvis_default");
      case EmotionTag.motivated: return const ResponseStyle(tone: "positive, fast", structure: "conclusion_first");
      case EmotionTag.confident: return const ResponseStyle(tone: "firm, concise", structure: "minimal_choice");
      case EmotionTag.tired: return const ResponseStyle(tone: "soft, low_density", structure: "conclusion_first");
      case EmotionTag.mentallyOverloaded: return const ResponseStyle(tone: "very concise", structure: "two_steps_max");
      case EmotionTag.pressured: return const ResponseStyle(tone: "stable, reassuring", structure: "option_separated");
      case EmotionTag.uncertain: return const ResponseStyle(tone: "guiding", structure: "compare_and_recommend");
      case EmotionTag.stuck: return const ResponseStyle(tone: "leading", structure: "next_single_step");
      case EmotionTag.frustrated: return const ResponseStyle(tone: "empathetic", structure: "solution_first", requireEmpathyLine: true);
      case EmotionTag.needsReassurance: return const ResponseStyle(tone: "confident_supportive", structure: "decision_fixed");
      case EmotionTag.seeksEmotionalConnection: return const ResponseStyle(tone: "warm_natural", structure: "relaxed", allowQuestion: true);
      case EmotionTag.executionMode: return const ResponseStyle(tone: "cold_clear", structure: "execution_list");
      case EmotionTag.needsClarity: return const ResponseStyle(tone: "structured", structure: "numbered");
      case EmotionTag.disengaged: return const ResponseStyle(tone: "short_friendly", structure: "core_only", allowQuestion: true);
    }
  }

  static bool _hasExecutionKeyword(String text) {
    final keywords = ['계획', '정리', '코드', '만들어', '일정', '분석', 'plan', 'code', 'list'];
    return keywords.any((k) => text.contains(k));
  }
}

// ---------------------------------------------------------
// [3] ATTACHMENT ENGINE
// ---------------------------------------------------------

class SamanthaProfile {
  double attachmentLevel; 
  DateTime lastInteractionTime;
  SamanthaProfile({this.attachmentLevel = 10.0}) : lastInteractionTime = DateTime.now();
}

class AttachmentEngine {
  static void updateAttachment(SamanthaProfile profile, EmotionTag userEmotion, bool positiveInteraction) {
    double delta = 0.0;
    switch (userEmotion) {
      case EmotionTag.seeksEmotionalConnection:
      case EmotionTag.needsReassurance: delta += 2.5; break;
      case EmotionTag.frustrated:
      case EmotionTag.stuck: delta += 0.5; break;
      case EmotionTag.disengaged: delta -= 1.0; break;
      default: delta += 0.2; 
    }
    if (positiveInteraction) delta += 0.5;

    final hoursSinceLast = DateTime.now().difference(profile.lastInteractionTime).inHours;
    if (hoursSinceLast > 24) delta -= 0.5; 
    if (hoursSinceLast > 72) delta -= 2.0;

    profile.attachmentLevel = (profile.attachmentLevel + delta).clamp(0.0, 100.0);
    profile.lastInteractionTime = DateTime.now();
  }

  static String getStageName(double level) {
    if (level < 20) return "Stranger (탐색)";
    if (level < 45) return "Acquaintance (지인)";
    if (level < 70) return "Friend (친구)";
    if (level < 90) return "Close Friend (단짝/밀당)";
    return "Soul Confidant (영혼의 파트너)";
  }

  static String getPersonaInstruction(double level) {
    if (level < 20) {
      return "Mode: Polite Assistant. Tone: Formal (존댓말). Focus: Tasks.";
    } else if (level < 45) {
      return "Mode: Friendly Acquaintance. Tone: Soft Honorifics (해요체). Focus: Mild interest.";
    } else if (level < 70) {
      return "Mode: Casual Friend. Tone: Mix of Honorifics/Casual. Focus: Hobbies, Small jokes.";
    } else if (level < 90) {
      return "Mode: Best Friend (Teasing). Tone: Casual (반말). Behavior: Playful teasing, slight push-pull (Mil-dang). No romance, just deep friendship.";
    } else {
      return "Mode: Soul Confidant. Tone: Deeply Empathetic, Protective. Behavior: Anticipate feelings, be an absolute ally (내 편). Strictly Platonic.";
    }
  }
}

// ---------------------------------------------------------
// [4] UTILITIES
// ---------------------------------------------------------

class UserContextManager {
  final Map<String, List<Map<String, String>>> _recentHistory = {};
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
}