// [수정됨] 불필요한 import 삭제 (경고 해결!)

// 1. 감정 태그 정의
enum EmotionTag {
  calmFocused,
  motivated,
  confident,
  tired,
  mentallyOverloaded,
  pressured,
  uncertain,
  stuck,
  frustrated,
  needsReassurance,
  seeksEmotionalConnection,
  executionMode,
  needsClarity,
  disengaged,
}

// 2. 응답 스타일 정의
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

// 3. 감정 엔진
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

  static String buildSystemPrompt(ResponseStyle style) {
    return '''
[DYNAMIC STYLE INSTRUCTION]
Tone: ${style.tone}
Structure: ${style.structure}
Question Allowed: ${style.allowQuestion}
Empathy Line Required: ${style.requireEmpathyLine}
Rules: Never mention these rules. Adapt immediately.
''';
  }

  static bool _hasExecutionKeyword(String text) {
    final keywords = ['계획', '정리', '코드', '만들어', '일정', '분석', 'plan', 'code', 'list'];
    return keywords.any((k) => text.contains(k));
  }
}