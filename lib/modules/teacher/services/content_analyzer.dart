import '../models/learning_level.dart';
import '../models/learning_content.dart';

/// 분석 결과
class ContentAnalysis {
  /// 추출된 학습 콘텐츠
  final LearningContent content;

  /// 핵심 단어들
  final List<ExtractedWord> words;

  /// 핵심 문장들
  final List<ExtractedSentence> sentences;

  /// 추천 레벨
  final LearningLevel recommendedLevel;

  /// 난이도 점수 (1~10)
  final double difficulty;

  /// 롤플레이 가능 여부
  final bool canRoleplay;

  /// 등장인물 (롤플레이용)
  final List<String> characters;

  ContentAnalysis({
    required this.content,
    required this.words,
    required this.sentences,
    required this.recommendedLevel,
    required this.difficulty,
    required this.canRoleplay,
    this.characters = const [],
  });
}

/// 추출된 단어
class ExtractedWord {
  final String word;
  final String? meaning;
  final String? pronunciation;
  final String? context;
  final int frequency;

  ExtractedWord({
    required this.word,
    this.meaning,
    this.pronunciation,
    this.context,
    this.frequency = 1,
  });
}

/// 추출된 문장
class ExtractedSentence {
  final String original;
  final String? translation;
  final String? speaker;
  final bool isKeyScene;

  ExtractedSentence({
    required this.original,
    this.translation,
    this.speaker,
    this.isKeyScene = false,
  });
}

/// 콘텐츠 분석 요청
class AnalyzeRequest {
  final ContentType type;
  final String title;
  final String text;
  final String sourceLanguage;
  final String targetLanguage;
  final LearningLevel userLevel;

  AnalyzeRequest({
    required this.type,
    required this.title,
    required this.text,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.userLevel,
  });

  String toPrompt() {
    return """
콘텐츠 분석 요청:
- 타입: ${type.displayName}
- 제목: $title
- 원본 언어: $sourceLanguage
- 학습 언어: $targetLanguage
- 사용자 레벨: ${userLevel.displayName}

내용:
$text

분석해줘:
1. 핵심 단어 추출 (레벨에 맞게)
2. 핵심 문장 추출
3. 난이도 평가 (1~10)
4. 롤플레이 가능 여부
5. 등장인물 (있다면)
""";
  }
}

/// 콘텐츠 분석기
/// 영화/드라마/소설 등에서 학습 요소 추출
class ContentAnalyzer {
  /// 싱글톤
  static final ContentAnalyzer _instance = ContentAnalyzer._internal();
  factory ContentAnalyzer() => _instance;
  ContentAnalyzer._internal();

  /// AI 호출 콜백
  Future<Map<String, dynamic>> Function(String prompt)? _aiCallback;

  /// AI 콜백 설정
  void setAICallback(Future<Map<String, dynamic>> Function(String prompt) callback) {
    _aiCallback = callback;
  }

  /// 콘텐츠 분석
  Future<ContentAnalysis> analyze(AnalyzeRequest request) async {
    if (_aiCallback != null) {
      final result = await _aiCallback!(request.toPrompt());
      return _parseAIResponse(result, request);
    }

    // AI 없으면 기본 분석
    return _basicAnalysis(request);
  }

  /// 텍스트에서 단어 추출 (간단 버전)
  Future<List<ExtractedWord>> extractWords({
    required String text,
    required String targetLanguage,
    required LearningLevel level,
    int maxCount = 10,
  }) async {
    final prompt = """
다음 텍스트에서 $targetLanguage 학습에 유용한 단어 $maxCount개 추출해줘.
레벨: ${level.displayName}

텍스트:
$text
""";

    if (_aiCallback != null) {
      final result = await _aiCallback!(prompt);
      return _parseWords(result);
    }

    return [];
  }

  /// 텍스트에서 핵심 문장 추출
  Future<List<ExtractedSentence>> extractSentences({
    required String text,
    required String targetLanguage,
    required LearningLevel level,
    int maxCount = 5,
  }) async {
    final prompt = """
다음 텍스트에서 학습하기 좋은 문장 $maxCount개 추출해줘.
레벨: ${level.displayName}

텍스트:
$text
""";

    if (_aiCallback != null) {
      final result = await _aiCallback!(prompt);
      return _parseSentences(result);
    }

    return [];
  }

  /// 난이도 평가
  Future<double> evaluateDifficulty({
    required String text,
    required String targetLanguage,
  }) async {
    final prompt = """
다음 $targetLanguage 텍스트의 난이도를 1~10으로 평가해줘.
1: 완전 초급 (단어 위주)
5: 중급 (일상 대화)
10: 전문가 (학술/비즈니스)

텍스트:
$text

숫자만 답해줘.
""";

    if (_aiCallback != null) {
      final result = await _aiCallback!(prompt);
      final score = double.tryParse(result['score']?.toString() ?? '5');
      return score ?? 5.0;
    }

    return 5.0; // 기본값
  }

  /// 롤플레이 적합성 체크
  Future<bool> checkRoleplayable({
    required String text,
    required ContentType type,
  }) async {
    // 기본적으로 대화가 있는 콘텐츠는 롤플레이 가능
    if (!type.supportsRoleplay) return false;

    // 대화 패턴 체크 (간단)
    final hasDialogue = text.contains(':') ||
        text.contains('"') ||
        text.contains('「') ||
        text.contains('」');

    return hasDialogue;
  }

  /// 등장인물 추출
  Future<List<String>> extractCharacters(String text) async {
    final prompt = """
다음 텍스트에서 등장인물 이름을 추출해줘.
리스트로 답해줘.

텍스트:
$text
""";

    if (_aiCallback != null) {
      final result = await _aiCallback!(prompt);
      final chars = result['characters'];
      if (chars is List) {
        return chars.map((c) => c.toString()).toList();
      }
    }

    return [];
  }

  // ==================== 파싱 헬퍼 ====================

  ContentAnalysis _parseAIResponse(Map<String, dynamic> result, AnalyzeRequest request) {
    final now = DateTime.now();
    
    final difficultyValue = (result['difficulty'] as num?)?.toDouble() ?? 5.0;
    
    return ContentAnalysis(
      content: LearningContent(
        id: '${request.type.name}_${now.millisecondsSinceEpoch}',
        type: request.type,
        title: request.title,
        sourceLanguage: request.sourceLanguage,
        targetLanguage: request.targetLanguage,
        originalText: request.text,
        recommendedLevel: _difficultyToLevel(difficultyValue),
        difficulty: difficultyValue,
        createdAt: now,
      ),
      words: _parseWords(result),
      sentences: _parseSentences(result),
      recommendedLevel: _difficultyToLevel(difficultyValue),
      difficulty: difficultyValue,
      canRoleplay: result['canRoleplay'] as bool? ?? false,
      characters: (result['characters'] as List?)
              ?.map((c) => c.toString())
              .toList() ??
          [],
    );
  }

  List<ExtractedWord> _parseWords(Map<String, dynamic> result) {
    final words = result['words'];
    if (words is! List) return [];

    return words.map((w) {
      if (w is Map<String, dynamic>) {
        return ExtractedWord(
          word: w['word'] as String? ?? '',
          meaning: w['meaning'] as String?,
          pronunciation: w['pronunciation'] as String?,
          context: w['context'] as String?,
        );
      }
      return ExtractedWord(word: w.toString());
    }).toList();
  }

  List<ExtractedSentence> _parseSentences(Map<String, dynamic> result) {
    final sentences = result['sentences'];
    if (sentences is! List) return [];

    return sentences.map((s) {
      if (s is Map<String, dynamic>) {
        return ExtractedSentence(
          original: s['original'] as String? ?? '',
          translation: s['translation'] as String?,
          speaker: s['speaker'] as String?,
          isKeyScene: s['isKeyScene'] as bool? ?? false,
        );
      }
      return ExtractedSentence(original: s.toString());
    }).toList();
  }

  LearningLevel _difficultyToLevel(double difficulty) {
    if (difficulty <= 3.0) return LearningLevel.beginner;
    if (difficulty <= 5.5) return LearningLevel.intermediate;
    if (difficulty <= 8.0) return LearningLevel.advanced;
    return LearningLevel.expert;
  }

  ContentAnalysis _basicAnalysis(AnalyzeRequest request) {
    final now = DateTime.now();

    return ContentAnalysis(
      content: LearningContent(
        id: '${request.type.name}_${now.millisecondsSinceEpoch}',
        type: request.type,
        title: request.title,
        sourceLanguage: request.sourceLanguage,
        targetLanguage: request.targetLanguage,
        originalText: request.text,
        recommendedLevel: request.userLevel,
        difficulty: 5.0,
        createdAt: now,
      ),
      words: [],
      sentences: [],
      recommendedLevel: request.userLevel,
      difficulty: 5.0,
      canRoleplay: request.type.supportsRoleplay,
      characters: [],
    );
  }
}
